import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:vx/app/settings/general/language.dart';
import 'package:vx/app/settings/general/sync.dart';
import 'package:vx/common/common.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/main.dart';
import 'package:vx/utils/auto_update_service.dart';
import 'package:vx/utils/github_release.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/widgets/circular_progress_indicator.dart';
import 'package:flutter_sparkle/flutter_sparkle.dart';

class GeneralSettingPage extends StatelessWidget {
  const GeneralSettingPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(AppLocalizations.of(context)!.general),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.only(top: 8, right: 8),
        child: ListView(
          children: [
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              leading: const Icon(Icons.language),
              title: Text(AppLocalizations.of(context)!.language,
                  style: Theme.of(context).textTheme.bodyLarge),
              subtitle: Language.fromCode(
                              Localizations.localeOf(context).languageCode)
                          ?.localText !=
                      null
                  ? Text(Language.fromCode(
                          Localizations.localeOf(context).languageCode)!
                      .localText)
                  : null,
              trailing: const Icon(Icons.keyboard_arrow_right_rounded),
              onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(builder: (ctx) {
                  return const LanguagePage();
                }));
              },
            ),
            ListTile(
              minTileHeight: 64,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              leading: const Icon(Icons.sync),
              title: Text(AppLocalizations.of(context)!.syncBackup,
                  style: Theme.of(context).textTheme.bodyLarge),
              trailing: const Icon(Icons.keyboard_arrow_right_rounded),
              onTap: () {
                Navigator.of(context).push(CupertinoPageRoute(builder: (ctx) {
                  return const SyncPage();
                }));
              },
            ),
            if (androidApkRelease ||
                (Platform.isWindows && !isStore) ||
                Platform.isLinux)
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(),
                  AutoUpdateSettings(),
                ],
              ),
            const Divider(),
            const Padding(
              padding: const EdgeInsets.only(
                  top: 10, bottom: 10, left: 16, right: 16),
              child: ThemeModeSetting(),
            ),
            const Divider(),
            const Padding(
              padding:
                  EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
              child: PingModeSetting(),
            ),
            const Divider(),
            const Padding(
              padding:
                  EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
              child: NodeTestSettings(),
            ),
            if (Platform.isWindows)
              const Column(children: [
                Divider(),
                Padding(
                  padding:
                      EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
                  child: StartOnBootSetting(),
                ),
                Divider(),
                Padding(
                  padding:
                      EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
                  child: AlwaysOnSetting(),
                ),
              ]),
            if (isPkg)
              Column(children: [
                Divider(),
                Padding(
                    padding: EdgeInsets.only(
                        top: 10, bottom: 10, left: 16, right: 16),
                    child: TextButton(
                      onPressed: () async {
                        FlutterSparkle.checkMacUpdate(isProduction()
                            ? 'https://download.5vnetwork.com/appcast.xml'
                            : 'https://pub-f52ca93bef2c463eabe42dfcf7d05b21.r2.dev/appcast.xml');
                      },
                      child: Text(AppLocalizations.of(context)!.checkUpdate),
                    ))
              ])
          ],
        ),
      ),
    );
  }
}

class PingModeSetting extends StatefulWidget {
  const PingModeSetting({super.key});

  @override
  State<PingModeSetting> createState() => _PingModeSettingState();
}

class _PingModeSettingState extends State<PingModeSetting> {
  PingMode _pingMode = PingMode.Real;

  @override
  void initState() {
    super.initState();
    _pingMode = persistentStateRepo.pingMode;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.pingTestMethod,
            style: Theme.of(context).textTheme.bodyLarge),
        Gap(10),
        DropdownMenu<PingMode>(
            initialSelection: _pingMode,
            requestFocusOnTap: false,
            dropdownMenuEntries: [
              DropdownMenuEntry(
                  value: PingMode.Real,
                  label: AppLocalizations.of(context)!.pingReal),
              DropdownMenuEntry(value: PingMode.Rtt, label: 'RTT'),
            ],
            onSelected: (value) {
              persistentStateRepo.setPingMode(value ?? PingMode.Real);
              setState(() {
                _pingMode = value ?? PingMode.Real;
              });
            }),
        Gap(10),
        if (_pingMode == PingMode.Real)
          Text(AppLocalizations.of(context)!.pingRealDesc,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
      ],
    );
  }
}

class ThemeModeSetting extends StatefulWidget {
  const ThemeModeSetting({super.key});

  @override
  State<ThemeModeSetting> createState() => _ThemeModeSettingState();
}

class _ThemeModeSettingState extends State<ThemeModeSetting> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _themeMode = persistentStateRepo.themeMode;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.themeMode,
            style: Theme.of(context).textTheme.bodyLarge),
        Gap(10),
        DropdownMenu<ThemeMode>(
            initialSelection: _themeMode,
            requestFocusOnTap: false,
            dropdownMenuEntries: [
              DropdownMenuEntry(
                  value: ThemeMode.light,
                  label: AppLocalizations.of(context)!.light),
              DropdownMenuEntry(
                  value: ThemeMode.dark,
                  label: AppLocalizations.of(context)!.dark),
              DropdownMenuEntry(
                  value: ThemeMode.system,
                  label: AppLocalizations.of(context)!.system),
            ],
            onSelected: (value) {
              persistentStateRepo.setThemeMode(value ?? ThemeMode.system);
              App.of(context)?.setThemeMode(value);
              setState(() {
                _themeMode = value ?? ThemeMode.system;
              });
            }),
      ],
    );
  }
}

class AutoUpdateSettings extends StatelessWidget {
  const AutoUpdateSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AutoUpdateService>(
      builder: (context, autoUpdateService, child) {
        return Padding(
          padding:
              const EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.autoUpdate,
                      style: Theme.of(context).textTheme.bodyLarge),
                  Switch(
                    value: autoUpdateService.autoUpdate,
                    onChanged: autoUpdateService.setAutoUpdate,
                  ),
                ],
              ),
              const Gap(10),
              Text(AppLocalizations.of(context)!.autoUpdateDescription,
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
              if (autoUpdateService.downloadingVersion != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      const Gap(2),
                      smallCircularProgressIndicator,
                      const Gap(10),
                      Text(
                          AppLocalizations.of(context)!.downloading(
                              autoUpdateService.downloadingVersion ?? ''),
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ))
                    ],
                  ),
                ),
              // if (!isProduction())
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: TextButton(
                  onPressed: () async {
                    final result = await GitHubReleaseService.checkForUpdates(
                      (await PackageInfo.fromPlatform()).version,
                      await AutoUpdateService.assetName(),
                    );
                    if (result == null) {
                      snack(AppLocalizations.of(context)!.noNewVersion);
                    } else {
                      autoUpdateService.checkAndUpdate();
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.checkAndUpdate),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class StartOnBootSetting extends StatefulWidget {
  const StartOnBootSetting({super.key});

  @override
  State<StartOnBootSetting> createState() => _StartOnBootSettingState();
}

class _StartOnBootSettingState extends State<StartOnBootSetting> {
  bool _startOnBoot = false;

  @override
  void initState() {
    super.initState();
    _startOnBoot = persistentStateRepo.startOnBoot;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(AppLocalizations.of(context)!.startOnBoot,
                style: Theme.of(context).textTheme.bodyLarge),
            Expanded(child: SizedBox()),
            Switch(
              value: _startOnBoot,
              onChanged: (value) async {
                persistentStateRepo.setStartOnBoot(value);
                setState(() {
                  _startOnBoot = value;
                });
                if (value) {
                  await launchAtStartup.enable();
                } else {
                  await launchAtStartup.disable();
                }
              },
            ),
          ],
        ),
        const Gap(10),
        Text(AppLocalizations.of(context)!.startOnBootDesc,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      ],
    );
  }
}

class AlwaysOnSetting extends StatefulWidget {
  const AlwaysOnSetting({super.key});

  @override
  State<AlwaysOnSetting> createState() => _AlwaysOnSettingState();
}

class _AlwaysOnSettingState extends State<AlwaysOnSetting> {
  bool _alwaysOn = false;

  @override
  void initState() {
    super.initState();
    _alwaysOn = persistentStateRepo.alwaysOn;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(AppLocalizations.of(context)!.alwaysOn,
                style: Theme.of(context).textTheme.bodyLarge),
            Expanded(child: SizedBox()),
            Switch(
              value: _alwaysOn,
              onChanged: (value) {
                persistentStateRepo.setAlwaysOn(value);
                setState(() {
                  _alwaysOn = !_alwaysOn;
                });
              },
            ),
          ],
        ),
        const Gap(10),
        Text(AppLocalizations.of(context)!.alwaysOnDesc,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
      ],
    );
  }
}

class NodeTestSettings extends StatefulWidget {
  const NodeTestSettings({super.key});

  @override
  State<NodeTestSettings> createState() => _NodeTestSettingsState();
}

class _NodeTestSettingsState extends State<NodeTestSettings> {
  bool _autoTestNodes = false;
  late final TextEditingController _intervalController;

  @override
  void initState() {
    super.initState();
    _autoTestNodes = persistentStateRepo.autoTestNodes;
    _intervalController =
        TextEditingController(text: '${persistentStateRepo.nodeTestInterval}');
  }

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.autoTestNodes,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Switch(
              value: _autoTestNodes,
              onChanged: (value) {
                persistentStateRepo.setAutoTestNodes(value);
                setState(() {
                  _autoTestNodes = value;
                });
                // Restart the service if it exists
                if (nodeTestService != null) {
                  nodeTestService!.restart();
                }
              },
            ),
          ],
        ),
        Text(
          AppLocalizations.of(context)!.autoTestNodesDesc,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        if (_autoTestNodes) ...[
          const Gap(15),
          TextField(
            controller: _intervalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '${AppLocalizations.of(context)!.interval}',
              suffixText: 'min',
              border: OutlineInputBorder(),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (event) {
              final parsedValue = int.tryParse(_intervalController.text);
              if (parsedValue != null && parsedValue >= 0) {
                persistentStateRepo.setNodeTestInterval(parsedValue);
                if (nodeTestService != null) {
                  nodeTestService!.restart();
                }
              }
            },
          ),
        ],
      ],
    );
  }
}
