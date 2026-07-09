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

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vx/app/home/home.dart';
import 'package:vx/app/settings/general/language.dart';
import 'package:vx/app/settings/general/sync.dart';
import 'package:vx/common/common.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/main.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/node_test_service.dart';
import 'package:vx/utils/geodata.dart';
import 'package:vx/widgets/circular_progress_indicator.dart';
import 'package:tm/tm.dart';
// import 'package:flutter_sparkle/flutter_sparkle.dart';
import 'package:flutter_sparkle/flutter_sparkle.dart';

class GeneralSettingPage extends StatelessWidget {
  const GeneralSettingPage({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(title: Text(AppLocalizations.of(context)!.general))
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
              title: Text(
                AppLocalizations.of(context)!.language,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              subtitle:
                  Language.fromCode(
                        Localizations.localeOf(context).languageCode,
                      )?.localText !=
                      null
                  ? Text(
                      Language.fromCode(
                        Localizations.localeOf(context).languageCode,
                      )!.localText,
                    )
                  : null,
              trailing: const Icon(Icons.keyboard_arrow_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (ctx) {
                      return const LanguagePage();
                    },
                  ),
                );
              },
            ),
            ListTile(
              minTileHeight: 64,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              leading: const Icon(Icons.sync),
              title: Text(
                AppLocalizations.of(context)!.syncBackup,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              trailing: const Icon(Icons.keyboard_arrow_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (ctx) {
                      return const SyncPage();
                    },
                  ),
                );
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(
                top: 10,
                bottom: 10,
                left: 16,
                right: 16,
              ),
              child: ThemeModeSetting(),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(
                top: 10,
                bottom: 10,
                left: 16,
                right: 16,
              ),
              child: PingModeSetting(),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(
                top: 10,
                bottom: 10,
                left: 16,
                right: 16,
              ),
              child: GeoFileUpdateSettings(),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(
                top: 10,
                bottom: 10,
                left: 16,
                right: 16,
              ),
              child: NodeTestSettings(),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(
                top: 10,
                bottom: 10,
                left: 16,
                right: 16,
              ),
              child: OutboundSpeedTestSizeSetting(),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(
                top: 10,
                bottom: 10,
                left: 16,
                right: 16,
              ),
              child: RealtimeSpeedSamplingSetting(),
            ),
            if (Platform.isWindows)
              const Column(
                children: [
                  Divider(),
                  Padding(
                    padding: EdgeInsets.only(
                      top: 10,
                      bottom: 10,
                      left: 16,
                      right: 16,
                    ),
                    child: StartOnBootSetting(),
                  ),
                  Divider(),
                  Padding(
                    padding: EdgeInsets.only(
                      top: 10,
                      bottom: 10,
                      left: 16,
                      right: 16,
                    ),
                    child: AlwaysOnSetting(),
                  ),
                ],
              ),
            if (Platform.isIOS)
              const Column(
                children: [
                  Divider(),
                  Padding(
                    padding: EdgeInsets.only(
                      top: 10,
                      bottom: 10,
                      left: 16,
                      right: 16,
                    ),
                    child: ConnectOnDemandSetting(),
                  ),
                ],
              ),
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
    _pingMode = context.read<SharedPreferences>().pingMode;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.pingTestMethod,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Gap(10),
        DropdownMenu<PingMode>(
          initialSelection: _pingMode,
          requestFocusOnTap: false,
          dropdownMenuEntries: [
            DropdownMenuEntry(
              value: PingMode.Real,
              label: AppLocalizations.of(context)!.pingReal,
            ),
            const DropdownMenuEntry(value: PingMode.Rtt, label: 'RTT'),
          ],
          onSelected: (value) {
            context.read<SharedPreferences>().setPingMode(
              value ?? PingMode.Real,
            );
            setState(() {
              _pingMode = value ?? PingMode.Real;
            });
          },
        ),
        const Gap(10),
        if (_pingMode == PingMode.Real)
          Text(
            AppLocalizations.of(context)!.pingRealDesc,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
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
    _themeMode = context.read<SharedPreferences>().themeMode;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.themeMode,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Gap(10),
        DropdownMenu<ThemeMode>(
          initialSelection: _themeMode,
          requestFocusOnTap: false,
          dropdownMenuEntries: [
            DropdownMenuEntry(
              value: ThemeMode.light,
              label: AppLocalizations.of(context)!.light,
            ),
            DropdownMenuEntry(
              value: ThemeMode.dark,
              label: AppLocalizations.of(context)!.dark,
            ),
            DropdownMenuEntry(
              value: ThemeMode.system,
              label: AppLocalizations.of(context)!.system,
            ),
          ],
          onSelected: (value) {
            context.read<SharedPreferences>().setThemeMode(
              value ?? ThemeMode.system,
            );
            App.of(context)?.setThemeMode(value);
            setState(() {
              _themeMode = value ?? ThemeMode.system;
            });
          },
        ),
      ],
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
    _startOnBoot = context.read<SharedPreferences>().startOnBoot;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.startOnBoot,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Expanded(child: SizedBox()),
            Switch(
              value: _startOnBoot,
              onChanged: (value) async {
                context.read<SharedPreferences>().setStartOnBoot(value);
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
        Text(
          AppLocalizations.of(context)!.startOnBootDesc,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
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
    _alwaysOn = context.read<SharedPreferences>().alwaysOn;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.alwaysOn,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Expanded(child: SizedBox()),
            Switch(
              value: _alwaysOn,
              onChanged: (value) {
                context.read<SharedPreferences>().setAlwaysOn(value);
                setState(() {
                  _alwaysOn = !_alwaysOn;
                });
              },
            ),
          ],
        ),
        const Gap(10),
        Text(
          AppLocalizations.of(context)!.alwaysOnDesc,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// iOS-only: VPN On Demand so the packet tunnel starts after device reboot.
class ConnectOnDemandSetting extends StatefulWidget {
  const ConnectOnDemandSetting({super.key});

  @override
  State<ConnectOnDemandSetting> createState() => _ConnectOnDemandSettingState();
}

class _ConnectOnDemandSettingState extends State<ConnectOnDemandSetting> {
  bool _connectOnDemand = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _connectOnDemand = context.read<SharedPreferences>().connectOnDemand;
  }

  Future<void> _onChanged(bool value) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _connectOnDemand = value;
    });
    context.read<SharedPreferences>().setConnectOnDemand(value);
    // Apply immediately when a VPN profile is already active so reboot
    // behavior matches the toggle without requiring reconnect.
    if (Tm.instance.state == TmStatus.connected ||
        Tm.instance.state == TmStatus.connecting) {
      try {
        await Tm.instance.setConnectOnDemand(value);
      } catch (e) {
        logger.e('setConnectOnDemand failed', error: e);
      }
    }
    if (mounted) {
      setState(() {
        _busy = false;
      });
    }
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
                AppLocalizations.of(context)!.connectOnDemand,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Switch(
              value: _connectOnDemand,
              onChanged: _busy ? null : _onChanged,
            ),
          ],
        ),
        const Gap(10),
        Text(
          AppLocalizations.of(context)!.connectOnDemandDesc,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class GeoFileUpdateSettings extends StatefulWidget {
  const GeoFileUpdateSettings({super.key});

  @override
  State<GeoFileUpdateSettings> createState() => _GeoFileUpdateSettingsState();
}

class _GeoFileUpdateSettingsState extends State<GeoFileUpdateSettings> {
  bool _autoUpdateGeoFiles = false;
  late final TextEditingController _intervalController;
  bool _isUpdating = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _autoUpdateGeoFiles = context.read<SharedPreferences>().autoUpdateGeoFiles;
    _intervalController = TextEditingController(
      text: '${context.read<SharedPreferences>().geoUpdateInterval}',
    );
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
                AppLocalizations.of(context)!.autoUpdateGeoFiles,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Switch(
              value: _autoUpdateGeoFiles,
              onChanged: (value) {
                context.read<SharedPreferences>().setAutoUpdateGeoFiles(value);
                setState(() {
                  _autoUpdateGeoFiles = value;
                });
                // Restart the service if it exists
                context.read<GeoDataHelper>().reset();
              },
            ),
          ],
        ),
        Text(
          AppLocalizations.of(context)!.autoUpdateGeoFilesDesc,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (_autoUpdateGeoFiles) ...[
          const Gap(15),
          TextField(
            controller: _intervalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.geoUpdateInterval,
              suffixText: AppLocalizations.of(context)!.days,
              border: const OutlineInputBorder(),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (event) {
              final parsedValue = int.tryParse(_intervalController.text);
              if (parsedValue != null && parsedValue >= 1) {
                context.read<SharedPreferences>().setGeoUpdateInterval(
                  parsedValue,
                );
                context.read<GeoDataHelper>().reset();
              } else if (parsedValue != null && parsedValue < 1) {
                // Reset to minimum if user enters invalid value
                _intervalController.text = '1';
                context.read<SharedPreferences>().setGeoUpdateInterval(1);
                context.read<GeoDataHelper>().reset();
              }
            },
          ),
        ],
        const Gap(10),
        Row(
          children: [
            TextButton(
              onPressed: () async {
                setState(() {
                  _isUpdating = true;
                });
                try {
                  await context.read<GeoDataHelper>().downloadAndProcessGeo();
                  snack(AppLocalizations.of(context)!.geoUpdateSuccess);
                } catch (e) {
                  logger.e('Error updating geo files: $e');
                  snack(e.toString());
                } finally {
                  setState(() {
                    _isUpdating = false;
                  });
                }
              },
              child: _isUpdating
                  ? smallCircularProgressIndicator
                  : Text(AppLocalizations.of(context)!.geoUpdateNow),
            ),
            const Gap(10),
            TextButton(
              onPressed: () async {
                setState(() {
                  _isRestoring = true;
                });
                try {
                  await writeStaticGeo();
                  snack(AppLocalizations.of(context)!.geoUpdateSuccess);
                } catch (e) {
                  logger.e('Error restoring geo files: $e');
                  snack(e.toString());
                } finally {
                  setState(() {
                    _isRestoring = false;
                  });
                }
              },
              child: _isRestoring
                  ? smallCircularProgressIndicator
                  : Text(AppLocalizations.of(context)!.geoRestoreToDefault),
            ),
          ],
        ),
      ],
    );
  }
}

class NodeTestSettings extends StatefulWidget {
  const NodeTestSettings({super.key});

  @override
  State<NodeTestSettings> createState() => _NodeTestSettingsState();
}

class OutboundSpeedTestSizeSetting extends StatefulWidget {
  const OutboundSpeedTestSizeSetting({super.key});

  @override
  State<OutboundSpeedTestSizeSetting> createState() =>
      _OutboundSpeedTestSizeSettingState();
}

class RealtimeSpeedSamplingSetting extends StatefulWidget {
  const RealtimeSpeedSamplingSetting({super.key});

  @override
  State<RealtimeSpeedSamplingSetting> createState() =>
      _RealtimeSpeedSamplingSettingState();
}

class _RealtimeSpeedSamplingSettingState
    extends State<RealtimeSpeedSamplingSetting> {
  static const List<int> _options = [1, 2, 3, 5, 10];
  int _interval = 3;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _interval = context.read<RealtimeSpeedNotifier>().sampleIntervalSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.realtimeSpeedSamplingInterval,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Gap(10),
        DropdownMenu<int>(
          initialSelection: _interval,
          requestFocusOnTap: false,
          dropdownMenuEntries: _options
              .map(
                (seconds) => DropdownMenuEntry<int>(
                  value: seconds,
                  label: AppLocalizations.of(
                    context,
                  )!.realtimeSpeedSamplingSeconds(seconds),
                ),
              )
              .toList(),
          onSelected: (value) async {
            final next = value ?? _interval;
            setState(() {
              _interval = next;
            });
            await context
                .read<RealtimeSpeedNotifier>()
                .setSampleIntervalSeconds(next);
          },
        ),
      ],
    );
  }
}

class _OutboundSpeedTestSizeSettingState
    extends State<OutboundSpeedTestSizeSetting> {
  static const int _minBytes = 1000;
  static const int _maxBytes = 100000000;

  late final TextEditingController _bytesController;

  @override
  void initState() {
    super.initState();
    final pref = context.read<SharedPreferences>();
    _bytesController = TextEditingController(
      text: '${pref.outboundSpeedTestBytes}',
    );
  }

  @override
  void dispose() {
    _bytesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.selectorTestSpeedTestSizeLabel,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Gap(6),
        Text(
          AppLocalizations.of(context)!.selectorTestSpeedTestSizeHelper,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Gap(12),
        TextField(
          controller: _bytesController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(
              context,
            )!.selectorTestSpeedTestSizeLabel,
            border: const OutlineInputBorder(),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) {
            final pref = context.read<SharedPreferences>();
            final parsed = int.tryParse(_bytesController.text.trim());
            if (parsed != null && parsed >= _minBytes && parsed <= _maxBytes) {
              pref.setOutboundSpeedTestBytes(parsed);
            }
          },
        ),
      ],
    );
  }
}

class _NodeTestSettingsState extends State<NodeTestSettings> {
  bool _autoTestNodes = false;
  late final TextEditingController _intervalController;

  @override
  void initState() {
    super.initState();
    _autoTestNodes = context.read<SharedPreferences>().autoTestNodes;
    _intervalController = TextEditingController(
      text: '${context.read<SharedPreferences>().nodeTestInterval}',
    );
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
                context.read<SharedPreferences>().setAutoTestNodes(value);
                setState(() {
                  _autoTestNodes = value;
                });
                if (value) {
                  context.read<NodeTestService>().start();
                } else {
                  context.read<NodeTestService>().stop();
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
              labelText: AppLocalizations.of(context)!.interval,
              suffixText: 'min',
              border: const OutlineInputBorder(),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (event) {
              final parsedValue = int.tryParse(_intervalController.text);
              if (parsedValue != null && parsedValue >= 0) {
                context.read<NodeTestService>().resetInterval(parsedValue);
              }
            },
          ),
        ],
      ],
    );
  }
}
