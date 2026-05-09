// Copyright (C) 2026 5V Network LLC <5vnetwork@proton.me>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/app/api/api.pbgrpc.dart';
import 'package:tm/protos/vx/outbound/outbound.pb.dart';
import 'package:tm/protos/vx/proxy/freedom/freedom.pb.dart';
import 'package:tm/protos/vx/transport/dlhelper.pb.dart';
import 'package:tm/protos/vx/transport/transport.pb.dart';
import 'package:tm/tm.dart';
import 'package:vx/app/outbound/outbound_repo.dart';
import 'package:vx/app/outbound/outbounds_bloc.dart';
import 'package:vx/data/database_provider.dart';
import 'package:vx/main.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/random.dart';
import 'package:vx/data/database.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/xapi_client.dart';
import 'package:vx/common/share_link_query_extra.dart';

class MySubscription extends Subscription implements NodeGroup {
  MySubscription({
    required super.id,
    required super.name,
    required super.link,
    super.remainingData,
    super.endTime,
    super.website = '',
    super.description = '',
    required super.lastUpdate,
    required super.lastSuccessUpdate,
    required super.placeOnTop,
    super.shareLinkQueryExtra = '',
  });
}

/// Notify its liseners when subscriptions are updated
class AutoSubscriptionUpdater with ChangeNotifier {
  AutoSubscriptionUpdater({
    required SharedPreferences pref,
    required XApiClient api,
    required OutboundRepo outboundRepo,
    required DatabaseProvider databaseProvider,
  }) : _pref = pref,
       _apiClient = api,
       _outRepo = outboundRepo,
       _databaseProvider = databaseProvider {
    Tm.instance.stateStream.listen((state) {
      if (state.status == TmStatus.disconnected ||
          state.status == TmStatus.connected) {
        reset();
      }
    });
    reset();
  }

  final SharedPreferences _pref;
  final XApiClient _apiClient;
  final OutboundRepo _outRepo;
  final DatabaseProvider _databaseProvider;

  Timer? timer;

  Future<DateTime> _getLastUpdate() async {
    // get the subscription with the smallest lastUpdate
    final database = _databaseProvider.database;
    final sub =
        await ((database.select(database.subscriptions)
              ..orderBy([(t) => OrderingTerm(expression: t.lastUpdate)])
              ..limit(1))
            .get());
    if (sub.isEmpty) {
      return DateTime.now();
    }
    return DateTime.fromMillisecondsSinceEpoch(sub[0].lastUpdate);
  }

  void reset() {
    if (_pref.autoUpdate &&
        Tm.instance.state == TmStatus.disconnected &&
        !running) {
      _scheduleUpdate();
    } else {
      _stopTimer();
    }
  }

  bool get running => timer != null;

  void onIntervalChange(int interval) {
    if (running) {
      _stopTimer();
      _scheduleUpdate();
    }
  }

  void _scheduleUpdate() async {
    final lastUpdate = await _getLastUpdate();
    final updateInterval = Duration(minutes: _pref.updateInterval);
    DateTime nextUpdate = lastUpdate.add(updateInterval);
    late final Duration initialDelay;
    if (nextUpdate.isBefore(DateTime.now())) {
      initialDelay = const Duration();
    } else {
      initialDelay = nextUpdate.difference(DateTime.now());
    }
    logger.d("next update in ${initialDelay.inMinutes} minutes");
    timer?.cancel();
    timer = Timer(initialDelay, () async {
      await updateAllSubs();
    });
  }

  Future<void> updateSub(int id) async {
    await _updateSub(false, id);
  }

  Future<UpdateSubscriptionResponse> _updateSingleSub(
    Subscription sub,
    List<HandlerConfig> handlers,
  ) async {
    final db = _databaseProvider.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await db.updateById(
        db.subscriptions,
        sub.id,
        SubscriptionsCompanion(lastUpdate: Value(now)),
      );

      final fetchReq = FetchSubscriptionContentRequest(
        link: sub.link,
        handlers: handlers,
      );
      fetchReq.shareLinkQueryExtra.addAll(
        shareLinkQueryExtraFromStored(sub.shareLinkQueryExtra),
      );
      final fetchRes = await _apiClient.fetchSubscriptionContent(fetchReq);
      await db.transaction(() async {
        final existingHandlers = await _outRepo.getHandlers(subId: sub.id);
        final existingByFingerprint = <String, OutboundHandler>{};
        for (final handler in existingHandlers) {
          if (handler.config.hasOutbound()) {
            final key = _outboundFingerprint(handler.config.outbound);
            existingByFingerprint[key] = handler;
          }
        }
        int newHandlerId = SnowflakeId.generate();
        final updatedIds = <int>{};
        inspect(existingByFingerprint);
        for (final config in fetchRes.handlers) {
          final key = _outboundFingerprint(config);
          logger.d("key: $key, config: ${config.tag}");
          final existing = existingByFingerprint[key];
          final nextConfig = OutboundHandlerConfig()..mergeFromMessage(config);
          if (existing != null && existing.config.hasOutbound()) {
            logger.d(
              "replace handler ${existing.config.outbound.tag} with ${config.tag}",
            );
            nextConfig.enableMux = existing.config.outbound.enableMux;
            nextConfig.muxConfig = existing.config.outbound.muxConfig;
            nextConfig.uot = existing.config.outbound.uot;
            nextConfig.domainStrategy = existing.config.outbound.domainStrategy;
            await _outRepo.replaceHandler(
              existing.copyWith(config: HandlerConfig(outbound: nextConfig)),
            );
            updatedIds.add(existing.id);
          } else {
            final inserted = await db.insertReturning(
              db.outboundHandlers,
              OutboundHandlersCompanion(
                id: Value(newHandlerId++),
                config: Value(HandlerConfig(outbound: nextConfig)),
                subId: Value(sub.id),
              ),
            );
            updatedIds.add(inserted.id);
          }
        }
        final toDelete = existingHandlers
            .where((h) => !updatedIds.contains(h.id))
            .map((h) => h.id)
            .toList();
        if (toDelete.isNotEmpty) {
          await _outRepo.removeHandlersByIds(toDelete);
        }
        await db.updateById(
          db.subscriptions,
          sub.id,
          SubscriptionsCompanion(
            lastSuccessUpdate: Value(now),
            description: Value(
              fetchRes.description.isNotEmpty
                  ? fetchRes.description
                  : sub.description,
            ),
          ),
        );
      });
      return UpdateSubscriptionResponse(
        success: 1,
        fail: 0,
        successNodes: fetchRes.handlers.length,
        failedNodes: fetchRes.failedNodes,
      );
    } catch (e) {
      final response = UpdateSubscriptionResponse(
        success: 0,
        fail: 1,
        successNodes: 0,
      );
      response.errorReasons[sub.name] = e.toString();
      return response;
    }
  }

  String _outboundFingerprint(OutboundHandlerConfig config) {
    final transportBytes = config.hasTransport()
        ? config.transport.writeToJson()
        : const <int>[];
    final protocolBytes = config.hasProtocol()
        ? config.protocol.writeToJson()
        : const <int>[];
    return Object.hash(
      config.address,
      config.port,
      transportBytes,
      protocolBytes,
    ).toString();
  }

  /// notify users about the result
  /// TODO: improve update experience
  Future<void> _updateSub(bool all, int id) async {
    final handlers = <HandlerConfig>[
      HandlerConfig(
        outbound: OutboundHandlerConfig(
          tag: 'direct',
          protocol: Any.pack(FreedomConfig()),
          domainStrategy: DomainStrategy.Speed,
          transport: TransportConfig(socket: SocketConfig()),
        ),
      ),
    ];
    handlers.addAll(
      (await _outRepo.getHandlers(
        usable: true,
        limit: 10,
        orderBySpeed1MBDesc: true,
      )).map((e) => e.toConfig()),
    );
    late final UpdateSubscriptionResponse res;
    if (all) {
      final subs = await _outRepo.getAllSubs();
      int success = 0;
      int fail = 0;
      int successNodes = 0;
      final failedNodes = <String>[];
      final errorReasons = <String, String>{};
      for (final sub in subs) {
        final r = await _updateSingleSub(sub, handlers);
        success += r.success;
        fail += r.fail;
        successNodes += r.successNodes;
        failedNodes.addAll(r.failedNodes);
        errorReasons.addAll(r.errorReasons);
      }
      res = UpdateSubscriptionResponse(
        success: success,
        fail: fail,
        successNodes: successNodes,
        failedNodes: failedNodes,
      );
      res.errorReasons.addEntries(errorReasons.entries);
    } else {
      final sub = await _outRepo.getSubById(id);
      if (sub == null) {
        final response = UpdateSubscriptionResponse(success: 0, fail: 1);
        response.errorReasons['$id'] = 'subscription not found';
        res = response;
      } else {
        res = await _updateSingleSub(sub, handlers);
      }
    }

    rootScaffoldMessengerKey.currentState?.removeCurrentSnackBar();
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        action:
            res.failedNodes.isNotEmpty || res.errorReasons.entries.isNotEmpty
            ? SnackBarAction(
                label: rootLocalizations()?.failureDetail ?? '',
                onPressed: () {
                  showDialog(
                    context: rootNavigationKey.currentContext!,
                    // TODO: improve, scrollable
                    builder: (context) => AlertDialog(
                      scrollable: true,
                      title: Text(rootLocalizations()?.failureDetail ?? ''),
                      content: Column(
                        children: [
                          if (res.errorReasons.entries.isNotEmpty)
                            Column(
                              children: [
                                Text(
                                  rootLocalizations()?.failedSub ?? '',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const Gap(10),
                                ...res.errorReasons.entries.indexed.map(
                                  (e) => ListTile(
                                    leading: Text((e.$1 + 1).toString()),
                                    title: Text(e.$2.key),
                                    subtitle: Text(e.$2.value),
                                  ),
                                ),
                                const Gap(10),
                              ],
                            ),
                          Text(
                            rootLocalizations()?.failedNodes ?? '',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Gap(10),
                          ...res.failedNodes.indexed.map(
                            (e) => ListTile(
                              leading: Text((e.$1 + 1).toString()),
                              title: Text(e.$2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            : null,
        content: Text(
          rootLocalizations()?.updateSubResult(
                res.success,
                res.fail,
                res.successNodes,
                res.failedNodes.length,
              ) ??
              '',
        ),
      ),
    );
    onSubscriptionUpdated();
  }

  void onSubscriptionUpdated() {
    notifyListeners();
  }

  /// update all subscriptons and schedule the next update
  Future<void> updateAllSubs() async {
    logger.d("update subscriptions");
    try {
      await _updateSub(true, 0);
    } catch (e) {
      logger.d("update subscirptions failed", error: e);
    }
    final updateInterval = Duration(minutes: _pref.updateInterval);
    logger.d("next update in ${updateInterval.inMinutes} minutes");
    _stopTimer();
    timer = Timer.periodic(updateInterval, (_) {
      updateAllSubs();
    });
  }

  void _stopTimer() {
    timer?.cancel();
    timer = null;
  }
}
