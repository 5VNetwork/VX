import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/main.dart';
import 'package:tm_windows/tm_windows_bindings_generated.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/path.dart';

class WindowsServiceButtons extends StatefulWidget {
  const WindowsServiceButtons({super.key});

  @override
  State<WindowsServiceButtons> createState() => _WindowsServiceButtonsState();
}

class _WindowsServiceButtonsState extends State<WindowsServiceButtons> {
  bool _busy = false;

  static const serviceName = "vx";

  Future<void> installWindowsService() async {
    final l10n = AppLocalizations.of(context)!;
    if (!isRunningAsAdmin) {
      dialog(l10n.windowsServiceRequiresAdmin);
      return;
    }
    final tmWindowsBindings = TmWindowsBindings(
      DynamicLibrary.open(getDllPath()),
    );
    final serviceExePath = getServicePath();
    final serviceExePathPtr = serviceExePath.toNativeUtf8();
    final serviceNamePtr = serviceName.toNativeUtf8();
    final resultPtr = tmWindowsBindings.InstallService(
      serviceExePathPtr.cast<Char>(),
      serviceNamePtr.cast<Char>(),
    );
    final result = resultPtr.cast<Utf8>().toDartString();
    tmWindowsBindings.FreeString(resultPtr);
    calloc.free(serviceExePathPtr);
    calloc.free(serviceNamePtr);
    if (result != "") {
      snack(l10n.windowsServiceInstallFailed(result));
    } else {
      snack(l10n.windowsServiceInstalled);
    }
  }

  /// Uninstalls the Windows Store Umi background service (`umi`). Requires admin.
  Future<void> removeWindowsService() async {
    final l10n = AppLocalizations.of(context)!;
    if (!isRunningAsAdmin) {
      dialog(l10n.windowsServiceRequiresAdmin);
      return;
    }
    try {
      final tmWindowsBindings = TmWindowsBindings(
        DynamicLibrary.open(getDllPath()),
      );
      final serviceNamePtr = serviceName.toNativeUtf8();
      try {
        final resultPtr = tmWindowsBindings.RemoveService(
          serviceNamePtr.cast<Char>(),
        );
        final result = resultPtr.cast<Utf8>().toDartString();
        tmWindowsBindings.FreeString(resultPtr);
        if (result != "") {
          snack(result);
          return;
        }
        snack(l10n.windowsServiceRemoved);
      } finally {
        calloc.free(serviceNamePtr);
      }
    } catch (e, st) {
      logger.e('removeWindowsService', error: e, stackTrace: st);
      snack(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    try {
                      await installWindowsService();
                    } finally {
                      if (mounted) {
                        setState(() => _busy = false);
                      }
                    }
                  },
            icon: _busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : const Icon(Icons.install_desktop_rounded),
            label: Text(l10n.windowsServiceInstall),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    try {
                      await removeWindowsService();
                    } finally {
                      if (mounted) {
                        setState(() => _busy = false);
                      }
                    }
                  },
            icon: _busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : const Icon(Icons.delete_outline_rounded),
            label: Text(l10n.windowsServiceRemove),
          ),
        ),
      ],
    );
  }
}
