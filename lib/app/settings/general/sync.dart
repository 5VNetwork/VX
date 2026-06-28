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

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gap/gap.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vx/app/outbound/outbounds_bloc.dart';
import 'package:vx/app/settings/setting.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/data/sync.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/main.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/backup_service.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/widgets/circular_progress_indicator.dart';
import 'package:vx/widgets/pro_promotion.dart';
import 'package:vx/widgets/text_divider.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key, this.showAppBar = true});
  final bool showAppBar;

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getAdaptiveAppBar(
        context,
        Text(AppLocalizations.of(context)!.syncBackup),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (context.read<AuthBloc>().state.isAuthenticated) ...[
                  const _Sync(),
                  TextDivider(text: AppLocalizations.of(context)!.backup),
                ],
                const _Backup(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Backup extends StatefulWidget {
  const _Backup();

  @override
  State<_Backup> createState() => __BackupState();
}

class __BackupState extends State<_Backup> {
  String? _latestBackup;
  final _passwordController = TextEditingController();
  String? _errorText;
  String? _password;
  @override
  void initState() {
    super.initState();
    final backupService = context.read<BackupSerevice>();
    backupService.getLatestBackup().then((value) {
      if (mounted) {
        setState(() {
          _latestBackup = value;
        });
      }
    });
    context.read<FlutterSecureStorage>().read(key: 'backupPassword').then((
      value,
    ) {
      if (mounted) {
        setState(() {
          _passwordController.text = value ?? '';
          _password = value;
        });
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _setPassword(String value) {
    context.read<FlutterSecureStorage>().write(
      key: 'backupPassword',
      value: value,
    );
    setState(() {
      _password = value;
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final backupService = context.watch<BackupSerevice>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_latestBackup != null)
          Padding(
            padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 10),
            child: Text(
              '${AppLocalizations.of(context)!.currentBackup} ${DateTime.parse(_latestBackup!.replaceAll('.db', '')).toLocal().toString().split('.').first}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        const Gap(10),
        if (context.read<AuthBloc>().state.user?.lifetimePro ?? false) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilledButton(
                  onPressed: backupService.uploading
                      ? null
                      : () async {
                          try {
                            final fileName = await backupService.uploadBackup();
                            snack(rootLocalizations()!.uploadDbSuccess);
                            if (fileName != null) {
                              setState(() {
                                _latestBackup = fileName;
                              });
                            }
                          } catch (e) {
                            logger.e("uploadBackup", error: e);
                            snack(e.toString());
                          }
                        },
                  child: backupService.uploading
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : Text(AppLocalizations.of(context)!.uploadDb),
                ),
                const Gap(10),
                FilledButton(
                  onPressed: backupService.restoring
                      ? null
                      : () async {
                          try {
                            final appState = App.of(context);
                            final outBloc = context.read<OutboundBloc>();
                            await backupService.restoreBackup();
                            snack(rootLocalizations()!.restoreDbSuccess);
                            appState?.rebuildAllChildren();
                            // to stop query stream and relisten
                            outBloc.add(InitialEvent());
                          } catch (e) {
                            logger.e("restoreBackup", error: e);
                            snack(e.toString());
                          }
                        },
                  child: backupService.restoring
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : Text(AppLocalizations.of(context)!.restoreDb),
                ),
                const Gap(10),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.errorContainer,
                  ),
                  onPressed: () async {
                    try {
                      await backupService.deleteBackup();
                      snack(rootLocalizations()!.deleteDbSuccess);
                      setState(() {
                        _latestBackup = null;
                      });
                    } catch (e) {
                      logger.e("deleteBackup", error: e);
                      snack(e.toString());
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.deleteCloudDb),
                ),
              ],
            ),
          ),
          const Gap(10),
        ],
        Row(
          children: [
            FilledButton.tonal(
              onPressed: backupService.uploading
                  ? null
                  : () async {
                      try {
                        final directoryPath = await FilePicker.platform
                            .getDirectoryPath();
                        if (directoryPath == null) {
                          return;
                        }
                        final fileName =
                            'vx_backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.db';
                        final destPath = p.join(directoryPath, fileName);
                        await backupService.saveLocalBackup(destPath);
                        snack('Local backup saved');
                      } catch (e) {
                        logger.e("saveLocalBackup", error: e);
                        snack(e.toString());
                      }
                    },
              child: backupService.uploading
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : Text(AppLocalizations.of(context)!.exportToFile),
            ),
            const Gap(10),
            FilledButton.tonal(
              onPressed: backupService.restoring
                  ? null
                  : () async {
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['db', 'encrypted'],
                        );
                        if (result == null ||
                            result.files.single.path == null) {
                          return;
                        }
                        final path = result.files.single.path!;
                        final appState = App.of(context);
                        final outBloc = context.read<OutboundBloc>();
                        await backupService.restoreFromLocalBackup(path);
                        snack('Local backup restored');
                        appState?.rebuildAllChildren();
                        outBloc.add(InitialEvent());
                      } catch (e) {
                        logger.e("restoreFromLocalBackup", error: e);
                        snack(e.toString());
                      }
                    },
              child: backupService.restoring
                  ? SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : Text(AppLocalizations.of(context)!.selectFromFile),
            ),
            const Gap(10),
          ],
        ),
        const Gap(10),
        TextField(
          controller: _passwordController,
          obscureText: true,
          obscuringCharacter: '*',
          onChanged: (value) {
            if (value != _password) {
              setState(() {
                _errorText = AppLocalizations.of(context)!.unsaved;
              });
            }
          },
          decoration: InputDecoration(
            errorText: _errorText,
            border: const OutlineInputBorder(),
            labelText: AppLocalizations.of(context)!.password,
            helperText: AppLocalizations.of(context)!.backupPasswordDesc,
            helperMaxLines: 2,
          ),
        ),
        const Gap(5),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () {
              _setPassword(_passwordController.text);
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ),
      ],
    );
  }
}

class _Sync extends StatefulWidget {
  const _Sync();

  @override
  State<_Sync> createState() => __SyncState();
}

class __SyncState extends State<_Sync> {
  bool _cloudSync = false;
  bool _nodeSub = false;
  bool _route = false;
  bool _server = false;
  bool _selector = false;
  final _passwordController = TextEditingController();
  late final SyncService _syncService;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final pref = context.read<SharedPreferences>();
    _cloudSync = pref.cloudSync;
    _nodeSub = pref.syncNodeSub;
    _route = pref.syncRoute;
    _server = pref.syncServer;
    _selector = pref.syncSelectorSetting;
    _syncService = context.read<SyncService>();
    _passwordController.text = _syncService.password ?? '';
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ChoiceChip(
              onSelected: (value) {},
              label: Text(AppLocalizations.of(context)!.cloudSync),
              selected: _cloudSync,
            ),
            const Gap(10),
            ChoiceChip(
              label: Text(AppLocalizations.of(context)!.lanSync),
              selected: !_cloudSync,
            ),
            const Expanded(child: SizedBox()),
            Consumer<SyncService>(
              builder: (context, syncService, child) {
                if (syncService.syncing) {
                  return mdCircularProgressIndicator;
                }
                return IconButton(
                  tooltip: AppLocalizations.of(context)!.sync,
                  onPressed: syncService.syncing
                      ? null
                      : () {
                          context.read<SyncService>().sync();
                        },
                  icon: syncService.syncing
                      ? smallCircularProgressIndicator
                      : const Icon(Icons.sync),
                );
              },
            ),
          ],
        ),
        const Gap(10),
        Row(
          children: [
            Text(
              '•',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(5),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.cloudSyncDesc1,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const Gap(5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '•',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(5),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.cloudSyncDesc2,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const Gap(5),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '•',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(5),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.cloudSyncDesc3,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              const Gap(10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.nodeSub),
                  Switch(
                    value: _nodeSub,
                    onChanged: (value) {
                      setState(() {
                        _nodeSub = value;
                      });
                      context.read<SharedPreferences>().setSyncNodeSub(value);
                      context.read<SyncService>().reset();
                    },
                  ),
                ],
              ),
              const Gap(10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.routeSetDNSSelector),
                  Switch(
                    value: _route,
                    onChanged: (value) {
                      setState(() {
                        _route = value;
                      });
                      context.read<SharedPreferences>().setSyncRuleDnsSet(
                        value,
                      );
                      context.read<SyncService>().reset();
                    },
                  ),
                ],
              ),
              const Gap(10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.selectorSetting),
                  Switch(
                    value: _selector,
                    onChanged: (value) {
                      setState(() {
                        _selector = value;
                      });
                      context.read<SharedPreferences>().setSyncSelectorSetting(
                        value,
                      );
                      context.read<SyncService>().reset();
                    },
                  ),
                ],
              ),
              const Gap(10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.serverKey),
                  Switch(
                    value: _server,
                    onChanged: (value) {
                      setState(() {
                        _server = value;
                      });
                      context.read<SharedPreferences>().setSyncServer(value);
                      context.read<SyncService>().reset();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const Gap(10),
        TextField(
          controller: _passwordController,
          obscureText: true,
          obscuringCharacter: '*',
          onChanged: (value) {
            if (value != _syncService.password) {
              setState(() {
                _errorText = AppLocalizations.of(context)!.unsaved;
              });
            }
          },
          decoration: InputDecoration(
            errorText: _errorText,
            border: const OutlineInputBorder(),
            labelText: AppLocalizations.of(context)!.password,
            helperText: AppLocalizations.of(context)!.syncPasswordDesc,
            helperMaxLines: 2,
          ),
        ),
        const Gap(5),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () {
              context.read<SyncService>().setPassword(_passwordController.text);
              setState(() {
                _errorText = null;
              });
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ),
      ],
    );
  }
}
