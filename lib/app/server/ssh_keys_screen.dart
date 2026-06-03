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

import 'package:ads/ad.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:drift/native.dart';
import 'package:drift/remote.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:vx/app/layout_provider.dart';
import 'package:vx/app/server/add_ssh_key.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/data/database_provider.dart';
import 'package:vx/data/sync.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/data/database.dart';
import 'package:vx/data/ssh_server.dart';
import 'package:vx/main.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/random.dart';

class SshKeys extends StatefulWidget {
  const SshKeys({super.key});

  @override
  State<SshKeys> createState() => _SshKeysState();
}

class _SshKeysState extends State<SshKeys> {
  StreamSubscription? _subscription;
  List<CommonSshKey> _keys = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _subscription?.cancel();
    final database = context.watch<DatabaseProvider>().database;
    _subscription = database.select(database.commonSshKeys).watch().listen((
      event,
    ) {
      setState(() {
        _keys = event;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.tonalIcon(
            onPressed: () async {
              final syncService = context.read<SyncService>();
              final database = context.read<DatabaseProvider>().database;
              final storage = context.read<FlutterSecureStorage>();
              final fullScreen = Provider.of<MyLayout>(
                context,
                listen: false,
              ).isCompact;
              late final AddSshKeyForm? form;
              if (fullScreen) {
                form = await Navigator.of(context, rootNavigator: true).push(
                  CupertinoPageRoute(
                    builder: (ctx) {
                      return const AddSshKeyDialog(fullScreen: true);
                    },
                  ),
                );
              } else {
                form = await showDialog<AddSshKeyForm>(
                  context: context,
                  builder: (context) => const AddSshKeyDialog(),
                );
              }
              if (form == null) {
                return;
              }
              try {
                final k = await database
                    .into(database.commonSshKeys)
                    .insertReturning(
                      CommonSshKeysCompanion(
                        id: Value(SnowflakeId.generate()),
                        name: Value(form.name),
                        remark: Value(form.remark),
                      ),
                    );

                final sss = CommonSshKeySecureStorage(
                  sshKey: form.sshKey,
                  sshKeyPath: form.sshKeyPath,
                  passphrase: form.sshKeyPassphrase ?? "",
                );
                final sssName = "common_ssh_key_${form.name}";
                await storage.write(
                  key: sssName,
                  value: jsonEncode(sss.toJson()),
                );
                syncService.addCommonSshKeyOperation(k, sssName, sss);
              } on DriftRemoteException catch (e) {
                if (e.remoteCause is SqliteException &&
                    (e.remoteCause as SqliteException).extendedResultCode ==
                        2067) {
                  snack(
                    rootLocalizations()
                        ?.failedToAddCommonSshKeyDueToDuplicateName,
                  );
                }
              } catch (e) {
                logger.d('add common ssh key error', error: e);
                snack(rootLocalizations()?.failedToAddCommonSshKey);
              }
            },
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.add),
          ),
          const Gap(10),
          Expanded(
            child: SizedBox.expand(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _keys
                          .map(
                            (e) => MenuAnchor(
                              menuChildren: [
                                MenuItemButton(
                                  onPressed: () async {
                                    final syncService = context
                                        .read<SyncService>();
                                    final database = context
                                        .read<DatabaseProvider>()
                                        .database;
                                    await context
                                        .read<FlutterSecureStorage>()
                                        .delete(
                                          key: "common_ssh_key_${e.name}",
                                        );
                                    (database.delete(
                                      database.commonSshKeys,
                                    )..where((t) => t.id.equals(e.id))).go();
                                    syncService.removeCommonSshKeyOperation(e);
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.delete,
                                  ),
                                ),
                              ],
                              builder: (context, controller, child) {
                                return GestureDetector(
                                  onSecondaryTapDown: (details) {
                                    controller.open(
                                      position: details.localPosition,
                                    );
                                  },
                                  onLongPressDown: (details) {
                                    controller.open(
                                      position: details.localPosition,
                                    );
                                  },
                                  child: Chip(
                                    label: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(e.name),
                                        if (e.remark != null &&
                                            e.remark!.isNotEmpty)
                                          Text(
                                            e.remark!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.outline,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                  if (!context.watch<AuthBloc>().state.proUser) const Ads(),
                  const SliverToBoxAdapter(child: SizedBox(height: 70)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
