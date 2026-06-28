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
import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift/remote.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive_io.dart';
import 'package:vx/app/routing/default.dart';
import 'package:vx/app/blocs/proxy_selector/proxy_selector_bloc.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/common/common.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/main.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/path.dart';
import 'package:vx/utils/system_managed_vpn.dart';
import 'package:vx/xconfig_helper.dart';
import 'package:tm_windows/tm_windows_bindings_generated.dart';

enum StartCloseButtonSize {
  small(24, 16),
  middle(32, 16),
  large(32, 16);

  const StartCloseButtonSize(this.iconSize, this.progressIndicatorSize);

  final double iconSize;
  final double progressIndicatorSize;
}

class StartCloseState {
  const StartCloseState({
    required this.status,
    this.systemManagedVpn = false,
  });

  final XStatus status;
  final bool systemManagedVpn;

  StartCloseState copyWith({XStatus? status, bool? systemManagedVpn}) {
    return StartCloseState(
      status: status ?? this.status,
      systemManagedVpn: systemManagedVpn ?? this.systemManagedVpn,
    );
  }
}

class StartCloseCubit extends Cubit<StartCloseState> {
  StartCloseCubit({
    required SharedPreferences pref,
    required XController xController,
    required AuthBloc authBloc,
  }) : _pref = pref,
       _xController = xController,
       _authBloc = authBloc,
       super(const StartCloseState(status: XStatus.unknown)) {
    _statusSubscription = xController.statusStream().listen(
      (status) {
        emit(state.copyWith(status: status));
      },
      onError: (error, stackTrace) {
        logger.e("x state stream error", error: error, stackTrace: stackTrace);
        reportError("x state stream error", error);
        emit(const StartCloseState(status: XStatus.unknown));
      },
    );
    if (Platform.isAndroid) {
      final stream = systemManagedVpnStream();
      if (stream != null) {
        _systemManagedSubscription = stream.listen(
          (systemManagedVpn) {
            emit(state.copyWith(systemManagedVpn: systemManagedVpn));
          },
        );
      }
      emit(
        state.copyWith(systemManagedVpn: isSystemManagedVpn()),
      );
    }
  }

  final SharedPreferences _pref;
  final XController _xController;
  late final StreamSubscription<XStatus> _statusSubscription;
  StreamSubscription<bool>? _systemManagedSubscription;
  final AuthBloc _authBloc;

  @override
  Future<void> close() async {
    _statusSubscription.cancel();
    await _systemManagedSubscription?.cancel();
    await super.close();
    return;
  }

  /// returns a non-null string if cannot start
  Future<String?> _canStart() async {
    if (_pref.routingMode == null) {
      return rootLocalizations()?.pleaseSelectARoutingMode;
    }
    if (isProduction() &&
        Platform.isWindows &&
        _pref.inboundMode == InboundMode.tun &&
        !isRunningAsAdmin &&
        isWinStore) {
      if (!await _serviceInstalled()) {
        return rootLocalizations()?.startFailedReasonTunNeedAdmin;
      }
      final destServiceExePath = getServicePath();
      if (_pref.installedWindowsServiceVersion != version ||
          !File(destServiceExePath).existsSync()) {
        final serviceExeZipPath = getServiceExeZipPath();
        // extract vx_service.exe from vx_service.zip to destServiceExePath
        try {
          if (!File(serviceExeZipPath).existsSync()) {
            return rootLocalizations()?.windowsServiceInstallFailed(
                  'service archive not found: $serviceExeZipPath',
                ) ??
                'service archive not found: $serviceExeZipPath';
          }

          final serviceDir = Directory(resourceDirectory.path);
          if (!serviceDir.existsSync()) {
            serviceDir.createSync(recursive: true);
          }

          await extractFileToDisk(serviceExeZipPath, serviceDir.path);
          if (!File(destServiceExePath).existsSync()) {
            return rootLocalizations()?.windowsServiceInstallFailed(
                  'service executable missing after extraction: $destServiceExePath',
                ) ??
                'service executable missing after extraction: $destServiceExePath';
          }

          _pref.setInstalledWindowsServiceVersion(version);
        } catch (e) {
          return rootLocalizations()?.windowsServiceInstallFailed(
                e.toString(),
              ) ??
              'failed to prepare Windows service: $e';
        }
        // snack(
        //   rootLocalizations()?.downloading('Windows Service') ??
        //       'Downloading Windows Service...',
        //   persistent: true,
        // );
        // await makeWinServiceAvailable(_downloader, _pref);
        // snack(
        //   rootLocalizations()?.windowsServiceInstalled ??
        //       'Windows service installed',
        // );
      }
    }

    return null;
  }

  Future<bool> _serviceInstalled() async {
    final tmWindowsBindings = TmWindowsBindings(
      DynamicLibrary.open(getDllPath()),
    );
    const serviceName = "vx";
    final serviceNamePtr = serviceName.toNativeUtf8();
    final resultPtr = tmWindowsBindings.GetServiceStatus(
      serviceNamePtr.cast<Char>(),
    );
    final result = resultPtr.cast<Utf8>().toDartString();
    tmWindowsBindings.FreeString(resultPtr);
    calloc.free(serviceNamePtr);
    if (result == "uninstalled") {
      return false;
    } else {
      return true;
    }
  }

  Future<void> start() async {
    if (state.systemManagedVpn) {
      return;
    }
    final canStartError = await _canStart();
    if (canStartError != null) {
      snack(
        rootLocalizations()?.startFailedWithReason(canStartError, ''),
        duration: const Duration(seconds: 60),
      );
      return;
    }

    _pref.setConnect(true);
    try {
      await _xController.start();
    } on ConfigException catch (e, s) {
      snack(
        rootLocalizations()?.startFailedWithReason(e.message, s.toString()),
        duration: const Duration(seconds: 60),
      );
      logger.e('start error', error: e, stackTrace: s);
    } on DriftRemoteException catch (e, s) {
      if (e.remoteCause is SqliteException &&
          (e.remoteCause as SqliteException).extendedResultCode == 5) {
        snack(
          rootLocalizations()?.dbError(e.remoteCause.toString()),
          duration: const Duration(seconds: 60),
        );
      } else {
        logger.e('start error', error: e, stackTrace: s);
        snack(
          rootLocalizations()?.startFailedWithReason(
            e.remoteCause.toString(),
            s.toString(),
          ),
          duration: const Duration(seconds: 60),
        );
      }
    } catch (e, s) {
      logger.e('start error', error: e, stackTrace: s);
      reportError("start error", e, stackTrace: s);
      snack(
        rootLocalizations()?.startFailedWithReason(e.toString(), s.toString()),
        duration: const Duration(seconds: 60),
      );
    }
  }

  Future<void> stop() async {
    if (state.systemManagedVpn) {
      return;
    }
    _pref.setConnect(false);
    try {
      await _xController.stop();
    } catch (e) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
  Future<void> openVpnSettings() async {
    await openAndroidVpnSettings();
  }
}

class SystemManagedVpnNotice extends StatefulWidget {
  const SystemManagedVpnNotice({super.key});

  @override
  State<SystemManagedVpnNotice> createState() => _SystemManagedVpnNoticeState();
}

class _SystemManagedVpnNoticeState extends State<SystemManagedVpnNotice> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return const SizedBox.shrink();
    }
    return BlocBuilder<StartCloseCubit, StartCloseState>(
      buildWhen: (previous, current) =>
          previous.systemManagedVpn != current.systemManagedVpn,
      builder: (context, state) {
        if (!state.systemManagedVpn) {
          if (_dismissed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _dismissed = false);
              }
            });
          }
          return const SizedBox.shrink();
        }
        if (_dismissed) {
          return const SizedBox.shrink();
        }
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        return Container(
          width: 280,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.settings,
                    size: 18,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      l10n.systemManagedVpnNotice,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    tooltip: l10n.close,
                    onPressed: () => setState(() => _dismissed = true),
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    context.read<StartCloseCubit>().openVpnSettings();
                  },
                  child: Text(l10n.openVpnSettings),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StartCloseButton extends StatelessWidget {
  const StartCloseButton({
    super.key,
    this.floating = false,
    this.size = StartCloseButtonSize.middle,
  });

  final StartCloseButtonSize size;
  final bool floating;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StartCloseCubit, StartCloseState>(
      builder: (ctx, startCloseState) {
        final state = startCloseState.status;
        final systemManagedVpn = startCloseState.systemManagedVpn;
        Widget icon;
        Text text;
        Function()? onPressed;
        Color? backgroundColor;
        final progressIndicator = Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: size.progressIndicatorSize,
            height: size.progressIndicatorSize,
            child: const CircularProgressIndicator(strokeWidth: 3),
          ),
        );
        switch (state) {
          case XStatus.connected:
            icon = Icon(
              Icons.stop,
              color: Theme.of(context).colorScheme.onErrorContainer,
              size: size.iconSize,
            );
            text = Text(AppLocalizations.of(context)!.disconnect);
            onPressed = systemManagedVpn
                ? null
                : () {
                    ctx.read<StartCloseCubit>().stop();
                  };
            backgroundColor = Theme.of(context).colorScheme.errorContainer;
          case XStatus.disconnected:
            icon = Icon(Icons.play_arrow_rounded, size: size.iconSize);
            text = Text(AppLocalizations.of(context)!.start);
            onPressed = systemManagedVpn
                ? null
                : () {
                    ctx.read<StartCloseCubit>().start();
                  };
          case XStatus.connecting:
            icon = progressIndicator;
            text = Text(AppLocalizations.of(context)!.connecting);
          case XStatus.disconnecting:
            icon = Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: size.progressIndicatorSize,
                height: size.progressIndicatorSize,
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  strokeWidth: 3,
                ),
              ),
            );
            text = Text(AppLocalizations.of(context)!.disconnecting);
            backgroundColor = Theme.of(context).colorScheme.errorContainer;
          case XStatus.reconnecting:
            icon = progressIndicator;
            text = Text(AppLocalizations.of(context)!.reconnecting);
          case XStatus.preparing:
            icon = progressIndicator;
            text = Text(AppLocalizations.of(context)!.preparing);
          case XStatus.unknown:
            icon = const Icon(Icons.play_arrow_rounded);
            text = Text(AppLocalizations.of(context)!.unknown);
            onPressed = systemManagedVpn
                ? null
                : () {
                    ctx.read<StartCloseCubit>().start();
                  };
        }
        if (size == StartCloseButtonSize.small) {
          return FloatingActionButton.small(
            splashColor: Colors.transparent,
            hoverElevation: 0,
            elevation: floating ? 1 : 0,
            backgroundColor: backgroundColor,
            onPressed: onPressed,
            child: icon,
          );
        } else if (size == StartCloseButtonSize.large) {
          return FloatingActionButton.extended(
            splashColor: Colors.transparent,
            hoverElevation: 0,
            elevation: floating ? 1 : 0,
            backgroundColor: backgroundColor,
            onPressed: onPressed,
            label: text,
            icon: icon,
          );
        } else {
          return FloatingActionButton(
            heroTag: null,
            splashColor: Colors.transparent,
            hoverElevation: 0,
            elevation: floating ? 1 : 0,
            backgroundColor: backgroundColor,
            onPressed: onPressed,
            child: icon,
          );
        }
      },
    );
  }
}
