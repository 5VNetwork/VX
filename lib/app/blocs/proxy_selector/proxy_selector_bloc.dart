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
import 'package:equatable/equatable.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/vx/router/router.pb.dart';
import 'package:tm/tm.dart';
import 'package:vx/app/control.dart';
import 'package:vx/app/routing/default.dart';
import 'package:vx/app/routing/repo.dart';
import 'package:vx/app/routing/routing_page.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/data/database.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/main.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tm_state.dart';
part 'tm_event.dart';

class ProxySelectorBloc extends Bloc<ProxySelectorEvent, ProxySelectorState> {
  ProxySelectorBloc({
    required SharedPreferences pref,
    required XController xConfigController,
    required DbHelper databaseProvider,
    required bool pro,
  }) : _pref = pref,
       _xController = xConfigController,
       _databaseProvider = databaseProvider,
       super(
         ProxySelectorState(
           routeMode: pref.routingMode,
           showProxySelector: pref.routingMode is DefaultRouteMode
               ? true
               : null,
           proxySelectorEnabled: pro,
           proxySelectorMode: pro
               ? pref.proxySelectorMode
               : ProxySelectorMode.manual,
           manualNodeSetting: pro
               ? ManualNodeSetting(
                   nodeMode: pref.proxySelectorManualMode,
                   balanceStrategy:
                       pref.proxySelectorManualMultipleBalanceStrategy,
                   landHandlers: pref.proxySelectorManualLandHandlers,
                 )
               : ManualNodeSetting(landHandlers: []),
         ),
       ) {
    on<XBlocInitialEvent>(_initial);
    on<AuthUserChangedEvent>(_authUserChanged);
    on<RoutingModeSelectionChangeEvent>(_routingModeSelectionChange);
    on<CustomRouteModeChangeEvent>(_customRouteModeChange);
    on<CustomRouteModeDeleteEvent>(_customRouteModeDelete);
    on<ProxySelectorModeChangeEvent>(_proxySelectorChange);
    on<ManualSelectionModeChangeEvent>(_manualNodeModeChange);
    on<ManualNodeBalanceStrategyChangeEvent>(_manualNodeBalanceStrategyChange);
    on<ManualModeLandHandlersChangeEvent>(_manualModeLandHandlersChange);
    on<AutoNodeSelectorConfigChangeEvent>(_autoNodeSelectorConfigChange);
    on<TestParametersChangeEvent>(_testParametersChange);
    {
      makeSureConssitency(pro, null);
    }
  }
  final SharedPreferences _pref;
  final XController _xController;
  final DbHelper _databaseProvider;

  // @override
  // void onTransition(Transition<TmEvent, XState> transition) {
  //   return;
  // }

  Future<void> _initial(
    XBlocInitialEvent e,
    Emitter<ProxySelectorState> emit,
  ) async {
    // update routeMode and showProxySelector
    // when it is null, it means _pref.routingMode is a custom route mode
    final rm = _pref.routingMode;
    if (rm != null) {
      try {
        final customRouteMode = await _databaseProvider.getCustomRouteMode(rm);
        if (customRouteMode != null) {
          emit(
            state.copyWith(
              routeMode: customRouteMode.name,
              showProxySelector: customRouteMode.hasDefaultProxySelector,
            ),
          );
        }
      } catch (e) {
        logger.e("cannot get custom route mode", error: e);
        reportError("cannot get custom route mode", e);
      }
    }

    try {
      final proxySelectorConfig = await _databaseProvider.getSelector(
        defaultProxySelectorTag,
      );
      assert(proxySelectorConfig != null);
      emit(state.copyWith(autoNodeSetting: proxySelectorConfig));
    } catch (e) {
      logger.e("cannot get proxy selector config", error: e);
      reportError("cannot get proxy selector config", e);
    }
  }

  Future<void> _authUserChanged(
    AuthUserChangedEvent e,
    Emitter<ProxySelectorState> emit,
  ) async {
    logger.d("authUserChanged: $e");
    await makeSureConssitency(e.unlockPro, emit);
  }

  Future<void> makeSureConssitency(
    bool unlockPro,
    Emitter<ProxySelectorState>? emit,
  ) async {
    logger.d("makeSureConssitency: $unlockPro");
    if (unlockPro) {
      emit?.call(state.copyWith(proxySelectorEnabled: true));
    } else {
      bool ideal = true;
      if (state.proxySelectorMode != ProxySelectorMode.manual ||
          _pref.proxySelectorMode != ProxySelectorMode.manual) {
        _pref.setProxySelectorMode(ProxySelectorMode.manual);
        ideal = false;
      }
      if (rootNavigationKey.currentContext != null && state.routeMode != null) {
        if (isDefaultRouteMode(
          state.routeMode!,
          rootNavigationKey.currentContext!,
        )) {
          ideal = false;
        }
      }
      if (state.manualNodeSetting.landHandlers.isNotEmpty ||
          _pref.proxySelectorManualLandHandlers.isNotEmpty) {
        _pref.setProxySelectorLandHandlers([]);
        ideal = false;
      }
      if (state.manualNodeSetting.nodeMode !=
              ProxySelectorManualNodeSelectionMode.single ||
          _pref.proxySelectorManualMode !=
              ProxySelectorManualNodeSelectionMode.single) {
        _pref.setProxySelectorManualMode(
          ProxySelectorManualNodeSelectionMode.single,
        );
        ideal = false;
      }
      if (ideal) {
        emit?.call(
          state.copyWith(proxySelectorEnabled: false, showProxySelector: true),
        );
      } else {
        // await _xController.stop();
        emit?.call(
          state.copyWith(
            outboundMode: ProxySelectorMode.manual,
            manualNodeSetting: ManualNodeSetting(landHandlers: []),
            proxySelectorEnabled: false,
            showProxySelector: true,
          ),
        );
      }
    }
  }

  Future<void> _routingModeSelectionChange(
    RoutingModeSelectionChangeEvent e,
    Emitter<ProxySelectorState> emit,
  ) async {
    final oldRouteMode = state.routeMode;
    // if (e.routeMode is DefaultRouteMode) {
    //   emit(state.copyWith(routeMode: e.routeMode, showProxySelector: true));
    //   _pref.setRoutingMode(e.routeMode as DefaultRouteMode);
    // } else {
    emit(
      state.copyWith(
        showProxySelector: (e.routeMode).hasDefaultProxySelector,
        routeMode: e.routeMode.name,
      ),
    );
    _pref.setRoutingMode(e.routeMode.name);
    // }
    try {
      await _xController.routingModeChange(oldRouteMode, e.routeMode.name);
    } catch (e) {
      logger.e('routingModeChange error', error: e);
      snack(rootLocalizations()?.failedToChangeRoutingMode);
      // await reportError(e, StackTrace.current);
    }
  }

  Future<void> _customRouteModeChange(
    CustomRouteModeChangeEvent e,
    Emitter<ProxySelectorState> emit,
  ) async {
    print("customRouteModeChange: ${e.routeMode.name}");
    if (state.routeMode == e.routeMode.name) {
      await _routingModeSelectionChange(
        RoutingModeSelectionChangeEvent(e.routeMode),
        emit,
      );
    }
  }

  Future<void> _customRouteModeDelete(
    CustomRouteModeDeleteEvent e,
    Emitter<ProxySelectorState> emit,
  ) async {
    if (state.routeMode == e.routeMode.name) {
      // await _routingModeSelectionChange(
      //     const RoutingModeSelectionChangeEvent(DefaultRouteMode.black), emit);
      _pref.setRoutingMode(null);
      emit(state.copyWith(routeMode: null, showProxySelector: false));
      if (_xController.status == XStatus.connected) {
        await _xController.stop();
      }
    }
  }

  void _proxySelectorChange(
    ProxySelectorModeChangeEvent e,
    Emitter<ProxySelectorState> emit,
  ) async {
    _pref.setProxySelectorMode(e.mode);
    emit(state.copyWith(outboundMode: e.mode));
    if (e.mode == ProxySelectorMode.manual) {
      await _xController.selectorSelectStrategyOrLandhandlerChange(
        _pref.manualSelectorConfig,
      );
    } else {
      await _xController.selectorSelectStrategyOrLandhandlerChange(
        state.autoNodeSetting!,
      );
    }
  }

  void _manualNodeModeChange(
    ManualSelectionModeChangeEvent e,
    Emitter<ProxySelectorState> emit,
  ) async {
    emit(
      state.copyWith(
        manualNodeSetting: state.manualNodeSetting.copyWith(nodeMode: e.mode),
      ),
    );
    _pref.setProxySelectorManualMode(e.mode);
    // if single, routeModeChange is called by outboundBloc
    if (e.mode == ProxySelectorManualNodeSelectionMode.multiple) {
      await _xController.selectorBalancingStrategyChange(
        defaultProxySelectorTag,
        _pref.proxySelectorManualMultipleBalanceStrategy,
      );
    }
  }

  void _manualNodeBalanceStrategyChange(
    ManualNodeBalanceStrategyChangeEvent e,
    Emitter<ProxySelectorState> emit,
  ) async {
    emit(
      state.copyWith(
        manualNodeSetting: state.manualNodeSetting.copyWith(
          balanceStrategy: e.strategy,
        ),
      ),
    );
    _pref.setProxySelectorManualMultipleBalanceStrategy(e.strategy);
    await _xController.selectorBalancingStrategyChange(
      defaultProxySelectorTag,
      e.strategy,
    );
  }

  void _manualModeLandHandlersChange(
    ManualModeLandHandlersChangeEvent e,
    Emitter<ProxySelectorState> emit,
  ) async {
    // emit(state.copyWith(
    //     manualNodeSetting:
    //         state.manualNodeSetting.copyWith(landHandlers: e.landHandlers)));
    _pref.setProxySelectorLandHandlers(state.manualNodeSetting.landHandlers);
    await _xController.selectorSelectStrategyOrLandhandlerChange(
      _pref.manualSelectorConfig,
    );
  }

  void _autoNodeSelectorConfigChange(
    AutoNodeSelectorConfigChangeEvent e,
    Emitter<ProxySelectorState> emit,
  ) async {
    if (e.selectorStrategyOrLandHandlers) {
      await _xController.selectorSelectStrategyOrLandhandlerChange(
        state.autoNodeSetting!,
      );
    } else if (e.balancingStragegy) {
      await _xController.selectorBalancingStrategyChange(
        defaultProxySelectorTag,
        state.autoNodeSetting!.balanceStrategy,
      );
    } else if (e.filterLandHandlers) {
      await _xController.selectorFilterChange(state.autoNodeSetting!);
    }
  }

  void _testParametersChange(
    TestParametersChangeEvent e,
    Emitter<ProxySelectorState> emit,
  ) async {
    emit(state.copyWith(autoNodeSetting: e.config));
    await _databaseProvider.updateSelector(e.config);
    await _xController.selectorSelectStrategyOrLandhandlerChange(e.config);
  }
}

// abstract class AutoHandlerSelect {
//   AutoHandlerSelect();
//   Future<void> start();
//   void dispose();
//   void handlerError(int id);

/// return a usable handler with highest speed; update _handlerHighestSpeedIdSubject;
//   static Future<OutboundHandler?> getBestHandler() async {
//     final handlers = await outboundRepo.getHandlers(enabled: true);
//     handlers.sort((a, b) {
//       final aSpeed = a.speed == 0
//           ? (a.monitorSpeed == 0 ? a.speed1MB : a.monitorSpeed)
//           : a.speed;
//       final bSpeed = b.speed == 0
//           ? (b.monitorSpeed == 0 ? b.speed1MB : b.monitorSpeed)
//           : b.speed;
//       return bSpeed.compareTo(aSpeed);
//     });
//     for (var handler in handlers) {
//       if (handler.ok == 1) {
//         return handler;
//       }
//     }
//     for (var handler in handlers) {
//       updateHandlerUsability(handler);
//     }
//     await Future.delayed(const Duration(seconds: 1));
//     for (var handler in handlers) {
//       if (handler.ok == 1) {
//         return handler;
//       }
//     }
//     return null;
//   }
// }

// class AutoSingleHandlerSelect extends AutoHandlerSelect {
//   AutoSingleHandlerSelect(this.currentHandlerId, this._xConfigHelper) : super();
//   int? currentHandlerId;
//   double? _currentHandlerSpeed1MB;
//   StreamSubscription? _bestHandlerChangeSub;
//   StreamSubscription? _obseleteHandlersSub;
//   StreamSubscription<OutboundStats>? _outboundStatsSub;
//   void cancelStatsStream() {
//     _outboundStatsSub?.cancel();
//     _outboundStatsSub = null;
//   }

//   final XConfigHelper _xConfigHelper;
//   Timer? _periodicTestSpeed1Timer;
//   Timer? _periodicTestUnUsableHandlersTimer;

//   @override
//   Future<void> start() async {
//     await _getCurrentHandlerId();
//     // 2h
//     _periodicTestSpeed1();
//     // 10m
//     _periodicTestUnUsableHandlers();
//     _subscribeToBestHandlerChange();
//     _updatingHandlersWithEmptySpeed1();
//     await _monitorCurrentHandlerSpeed();
//   }

//   @override
//   void dispose() {
//     _periodicTestSpeed1Timer?.cancel();
//     _periodicTestUnUsableHandlersTimer?.cancel();
//     _bestHandlerChangeSub?.cancel();
//     _bestHandlerChangeSub = null;
//     _obseleteHandlersSub?.cancel();
//     _obseleteHandlersSub = null;
//     cancelStatsStream();
//   }

//   @override
//   void handlerError(int id) async {
//     final handler = await outboundRepo.getHandlerById(id);
//     if (handler != null) {
//       await updateHandlerUsability(
//           handler); //this will trigger an event for _bestHandlerChangeSub
//     }
//   }

//   Future<void> _getCurrentHandlerId() async {
//     if (currentHandlerId == null) {
//       final tags = await Tm.instance.getOutboundList();
//       if (tags.isNotEmpty) {
//         assert(tags.length == 1);
//         currentHandlerId = int.parse(tags.first);
//       } else {
//         throw Exception("no outbound");
//       }
//     }
//   }

//   void _periodicTestSpeed1() async {
//     _updateHandlerSpeed1(await outboundRepo.getHandlers(enabled: true));
//     _periodicTestSpeed1Timer =
//         Timer.periodic(const Duration(minutes: 120), (_) async {
//       logger.i("periodically update handler speed1MBs");
//       _updateHandlerSpeed1(await outboundRepo.getHandlers(enabled: true));
//     });
//   }

//   void _subscribeToBestHandlerChange() {
//     // Whenever the best handler is different from the current handler, update the current handler
//     _bestHandlerChangeSub = outboundRepo
//         .getHandlersStream(orderBySpeed1MBDesc: true, usableEqual: 1, limit: 1)
//         .asyncMap((list) async {
//       if (list.isNotEmpty) {
//         final handler = list.first;
//         if (handler.id != currentHandlerId) {
//           final ok = await updateHandlerUsability(handler);
//           if (ok != true) return;
//           final config = handler.toConfig();
//           await Tm.instance.setOutbound(
//               ChangeOutboundRequest(deleteAll: true, handlers: [config]));
//           logger.i("set outbound to ${handler.id}");
//           currentHandlerId = handler.id;
//           _currentHandlerSpeed1MB = handler.speed1MB;
//           await _xConfigHelper.storeConfig();
//         }
//       }
//     }).listen((_) {});
//   }

//   void _updatingHandlersWithEmptySpeed1() {
//     // If there is a usable handler with 0 speed1MB, test it
//     _obseleteHandlersSub = outboundRepo
//         .getHandlersStream(speed1MBLessEqual: 0, usableEqual: 1)
//         .listen((list) {
//       if (list.isNotEmpty) {
//         _updateHandlerSpeed1(list);
//       }
//     });
//   }

//   Future<void> _monitorCurrentHandlerSpeed() async {
//     // monitor the current handler's speed, if it differs from speed1, re-test it
//     final statsStream =
//         await Tm.instance.outboundStatsStream(GetOutboundStatsRequest(
//       interval: 5,
//     ));
//     _outboundStatsSub = statsStream.listen(
//         (e) async {
//           final dspeed = bytesToMbps(e.rate.toDouble());
//           // If the dspeed is very different than the current handler's speed1MB,
//           // re-test the current handler's speed1MB
//           if (currentHandlerId != null &&
//               e.id == currentHandlerId.toString() &&
//               _currentHandlerSpeed1MB != null &&
//               dspeed <= _currentHandlerSpeed1MB! * 0.7) {
//             final currentHandler =
//                 await outboundRepo.getHandlerById(currentHandlerId!);
//             if (currentHandler != null) {
//               _updateHandlerSpeed1([currentHandler]);
//             }
//           }
//           logger.i("handler ${e.id} dspeed: $dspeed");
//           outboundRepo.updateHandler(int.parse(e.id),
//               dspeed: dspeed, dping: e.ping.toInt());
//         },
//         onDone: cancelStatsStream,
//         onError: (e) {
//           logger.e("outbound stats stream on error", error: e);
//           cancelStatsStream();
//           // TODO: re-subscribe?
//         });
//   }

//   void _periodicTestUnUsableHandlers() {
//     _testUnUsableHandlers();
//     _periodicTestUnUsableHandlersTimer =
//         Timer.periodic(const Duration(minutes: 10), (_) {
//       _testUnUsableHandlers();
//     });
//   }

//   List<int> _updatingHandlers = [];

//   /// speed test all [handlers] using 1MB data, and update them.
//   Future<void> _updateHandlerSpeed1(List<OutboundHandler> handlers) async {
//     final handlersToBeTested = <OutboundHandler>[];
//     for (var handler in handlers) {
//       if (_updatingHandlers.contains(handler.id)) continue;
//       _updatingHandlers.add(handler.id);
//       handlersToBeTested.add(handler);
//     }
//     if (handlersToBeTested.isNotEmpty) {
//       try {
//         final s = await xApiClient.speedTest(SpeedTestRequest(
//             size: 1,
//             handlers: handlersToBeTested.map((e) => e.toConfig()).toList()));
//         final results = await s.toList();
//         for (var result in results) {
//           if (result.ok) {
//             logger.i(
//                 "handler ${result.tag} speed1MB: ${bytesToMbps(result.down.toDouble())} ping: ${result.ping}");
//             outboundRepo.updateHandler(int.parse(result.tag),
//                 speed1: bytesToMbps(result.down.toDouble()),
//                 ping: result.ping,
//                 ok: 1);
//           } else {
//             // If failed, update its usability
//             final handler =
//                 await outboundRepo.getHandlerById(int.parse(result.tag));
//             if (handler != null) {
//               updateHandlerUsability(handler);
//             }
//           }
//         }
//       } catch (e) {
//         logger.e("update handler speed1MB error", error: e);
//       } finally {
//         _updatingHandlers
//             .removeWhere((e) => handlersToBeTested.any((h) => h.id == e));
//       }
//     }
//   }

//   void _testUnUsableHandlers() async {
//     final unUsableHandlers = await outboundRepo.getHandlers(usableNotEqual: 1);
//     for (var handler in unUsableHandlers) {
//       updateHandlerUsability(handler);
//     }
//   }
// }
