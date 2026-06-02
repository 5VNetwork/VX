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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:json_editor_flutter/json_editor_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:vx/main.dart';
import 'package:vx/utils/xapi_client.dart';
import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart';
import 'package:tm/protos/vx/inbound/inbound.pb.dart';
import 'package:tm/protos/vx/log/logger.pb.dart';
import 'package:tm/protos/vx/server.pb.dart';
import 'package:vx/app/routing/mode_widget.dart';
import 'package:vx/app/server/vx_bloc.dart';
import 'package:vx/common/config.dart';
import 'package:vx/data/database.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/widgets/clickable_card.dart';
import 'package:vx/widgets/form_dialog.dart';
import 'package:vx/widgets/outbound_handler_form/outbound_handler_form.dart';

part 'vx_config_inbound.dart';
part 'vx_config_json.dart';
part 'vx_config_routing.dart';

class VXConfig extends StatelessWidget {
  const VXConfig({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VXBloc, VXState>(
      buildWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType,
      builder: (context, state) {
        switch (state) {
          case VXInstalledState():
            return const _Config();
          case VXLoadingState():
            return const Center(child: CircularProgressIndicator());
          case VXNotInstalledState():
            return Center(
              child: Text(AppLocalizations.of(context)!.installVXCoreFirst),
            );
          case VXErrorState():
            return Center(child: Text(state.error));
        }
      },
    );
  }
}

enum ServerDetailSegment { inbounds, routing, geo, outbounds, others }

class _Config extends StatelessWidget {
  const _Config();
  @override
  Widget build(BuildContext context) {
    // final config = context.select((VproxyBloc bloc) =>
    //     bloc.state is VproxyInstalledState
    //         ? (bloc.state as VproxyInstalledState).config
    //         : null);
    // if (config == null) {
    //   return const Center(
    //     child: CircularProgressIndicator(),
    //   );
    // }
    // print('object');
    return BlocBuilder<VXBloc, VXState>(
      buildWhen: (previous, current) {
        if (previous is VXInstalledState && current is VXInstalledState) {
          print(previous.config != current.config);
          return previous.config != current.config;
        }
        return false;
      },
      builder: (context, state) {
        if (state is! VXInstalledState || state.config == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.inbound),
                  // Tab(text: AppLocalizations.of(context)!.routing),
                  // Tab(text: AppLocalizations.of(context)!.set),
                  // Tab(text: AppLocalizations.of(context)!.outboundMode),
                  Tab(text: AppLocalizations.of(context)!.others),
                ],
              ),
              const Gap(10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TabBarView(
                    children: [
                      _Inbounds(config: state.config!),
                      // _Routing(config: state.config!),
                      // const _Geo(),
                      // const _Outbounds(),
                      const _Others(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Geo extends StatelessWidget {
  const _Geo();
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class _Outbounds extends StatelessWidget {
  const _Outbounds();
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class _Others extends StatelessWidget {
  const _Others();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        _LoggerConfigExpansionTile(),
        _ServerConfigJsonExpansionTile(),
      ],
    );
  }
}

class _LoggerConfigExpansionTile extends StatelessWidget {
  const _LoggerConfigExpansionTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ExpansionTile(
        title: Text(
          AppLocalizations.of(context)!.log,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          'Configure logger settings',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        collapsedBackgroundColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerLow,
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: const [_LoggerConfig()],
      ),
    );
  }
}

class _LoggerConfig extends StatefulWidget {
  const _LoggerConfig();

  @override
  State<_LoggerConfig> createState() => _LoggerConfigState();
}

class _LoggerConfigState extends State<_LoggerConfig> {
  late TextEditingController _filePathController;
  late TextEditingController _logFileDirController;

  @override
  void initState() {
    super.initState();
    _filePathController = TextEditingController();
    _logFileDirController = TextEditingController();
  }

  @override
  void dispose() {
    _filePathController.dispose();
    _logFileDirController.dispose();
    super.dispose();
  }

  void _updateLoggerConfig(LoggerConfig Function(LoggerConfig) updater) {
    final bloc = context.read<VXBloc>();
    if (bloc.state is! VXInstalledState) return;
    final state = bloc.state as VXInstalledState;
    if (state.config == null) return;

    final current = state.config!.hasLog() ? state.config!.log : LoggerConfig();
    // Create a new LoggerConfig with all current values, then apply updates
    final updated = updater(
      LoggerConfig()
        ..logLevel = current.logLevel
        ..filePath = current.filePath
        ..consoleWriter = current.consoleWriter
        ..showColor = current.showColor
        ..showCaller = current.showCaller
        ..logFileDir = current.logFileDir
        ..redact = current.redact,
    );

    context.read<VXBloc>().add(VXSetLoggerConfigEvent(updated));
  }

  @override
  Widget build(BuildContext context) {
    final loggerConfig = context.select((VXBloc bloc) {
      if (bloc.state is VXInstalledState) {
        final state = bloc.state as VXInstalledState;
        if (state.config == null) {
          return null;
        }
        if (state.config!.hasLog()) {
          return state.config!.log;
        }
      }
      return null;
    });

    // Update controllers when config changes
    if (loggerConfig != null) {
      if (_filePathController.text != loggerConfig.filePath) {
        _filePathController.text = loggerConfig.filePath;
      }
      if (_logFileDirController.text != loggerConfig.logFileDir) {
        _logFileDirController.text = loggerConfig.logFileDir;
      }
    }

    final defaultConfig = LoggerConfig()..logLevel = Level.DISABLED;
    final config = loggerConfig ?? defaultConfig;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.logLevel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const Gap(5),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: Level.values
              .map(
                (e) => ChoiceChip(
                  label: Text(e.name),
                  selected: config.logLevel == e,
                  onSelected: (selected) {
                    _updateLoggerConfig((c) => c..logLevel = e);
                  },
                ),
              )
              .toList(),
        ),
        const Gap(20),
        Text('File Path', style: Theme.of(context).textTheme.titleSmall),
        const Gap(5),
        TextField(
          controller: _filePathController,
          decoration: InputDecoration(
            hintText: '/var/log/vx/vx.log',
            helperText: 'Where to write logs',
            border: const OutlineInputBorder(),
            helperStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          onChanged: (value) {
            _updateLoggerConfig((c) => c..filePath = value);
          },
        ),
        const Gap(15),
        Text(
          'Log File Directory',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const Gap(5),
        TextField(
          controller: _logFileDirController,
          decoration: InputDecoration(
            helperText:
                'If specified and file_path is not set, logs will be written to the directory. Log file name will be the current timestamp: 2006-01-02T15:04:05.txt',
            border: const OutlineInputBorder(),
            helperStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          onChanged: (value) {
            _updateLoggerConfig((c) => c..logFileDir = value);
          },
        ),
        const Gap(20),
        SwitchListTile(
          title: const Text('Console Writer'),
          subtitle: const Text('Console writer makes logs more human-readable'),
          value: config.consoleWriter,
          onChanged: (value) {
            _updateLoggerConfig((c) => c..consoleWriter = value);
          },
        ),
        SwitchListTile(
          title: const Text('Show Color'),
          subtitle: const Text('Use color logging'),
          value: config.showColor,
          onChanged: (value) {
            _updateLoggerConfig((c) => c..showColor = value);
          },
        ),
        SwitchListTile(
          title: const Text('Show Caller'),
          subtitle: const Text(
            'Show caller information (file and line number) in logs',
          ),
          value: config.showCaller,
          onChanged: (value) {
            _updateLoggerConfig((c) => c..showCaller = value);
          },
        ),
        SwitchListTile(
          title: const Text('Redact'),
          subtitle: const Text('Redact domain and ip address in logs'),
          value: config.redact,
          onChanged: (value) {
            _updateLoggerConfig((c) => c..redact = value);
          },
        ),
      ],
    );
  }
}
