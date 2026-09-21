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

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vx/app/file_transfer/file_transfer_controller.dart';
import 'package:vx/app/file_transfer/file_transfer_page.dart';
import 'package:vx/app/home/home.dart';
import 'package:vx/app/layout_provider.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/data/sync.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/main.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/upload_log.dart';
import 'package:window_manager/window_manager.dart';

import 'package:vx/app/navigation.dart';
import 'package:vx/common/common.dart';

class GlobalQuicActionMenuAnchor extends StatelessWidget {
  const GlobalQuicActionMenuAnchor({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final transfer = context.watch<FileTransferController>();
    final receiving = transfer.isReceiving;
    final receiveSubtitle = !receiving
        ? null
        : transfer.isReceiveTransferring
        ? l10n.fileTransferTransferring
        : l10n.fileTransferWaiting;
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: Badge(
            isLabelVisible: receiving,
            child: const Icon(Icons.swap_vert_rounded),
          ),
          child: receiveSubtitle == null
              ? Text(l10n.fileTransfer)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.fileTransfer),
                    Text(
                      receiveSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
          onPressed: () => openFileTransferPage(context),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.sync),
          child: Text(l10n.sync),
          onPressed: () {
            context.read<SyncService>().sync();
          },
        ),
      ],
      builder: (context, c, child) {
        return Tooltip(
          message: receiveSubtitle ?? l10n.fileTransfer,
          waitDuration: const Duration(milliseconds: 400),
          child: Container(
            width: 80,
            height: double.infinity,
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              hoverColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.08),
              onTapDown: (_) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (c.isOpen) return;
                  c.open();
                });
              },
              child: Center(
                child: Badge(
                  alignment: Alignment(1.5, -1.2),
                  isLabelVisible: receiving,
                  backgroundColor: Theme.of(context).colorScheme.error,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class TopBar extends StatelessWidget {
  const TopBar({super.key, this.isHomeRoute = false});

  final bool isHomeRoute;

  @override
  Widget build(BuildContext context) {
    late final Widget child;
    if (Platform.isMacOS || Platform.isIOS || Platform.isAndroid) {
      child = SizedBox(
        height: 50,
        child: Row(
          children: [
            if (!desktopPlatforms)
              GlobalQuicActionMenuAnchor(
                child: SizedBox(
                  width: 80,
                  child: Image.asset(
                    'assets/icons/V.png',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            const Expanded(child: SizedBox()),
            if (isHomeRoute) const HomeEditButton(),
            if (!isProduction())
              IconButton(
                onPressed: () async {
                  final logUploadService = context.read<LogUploadService>();
                  await logUploadService.performUpload();
                  logUploadService.stopPeriodicUpload();
                },
                icon: const Icon(Icons.upload),
              ),
            IconButton(
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
              icon: const Icon(Icons.tune_rounded),
            ),
            const Gap(10),
          ],
        ),
      );
    }
    if (Platform.isWindows || Platform.isLinux) {
      child = Row(
        children: [
          GlobalQuicActionMenuAnchor(
            child: Image.asset(
              'assets/icons/V.png',
              width: 18,
              height: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(child: MoveWindow(child: const SizedBox())),
          if (isHomeRoute) const HomeEditButton(),
          if (!isProduction())
            TextButton(
              onPressed: () async {
                final logUploadService = context.read<LogUploadService>();
                await logUploadService.performUpload();
              },
              child: const Text("Upload"),
            ),
          if (context.read<MyLayout>().isCompact)
            IconButton(
              onPressed: () {
                context.push('/setting');
              },
              icon: const Icon(Icons.settings_rounded),
            ),
          IconButton(
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
            icon: const Icon(Icons.tune_rounded),
          ),
          const Gap(5),
          const WindowButtons(),
          const Gap(5),
        ],
      );
    }
    return SizedBox(height: 44, child: child);
  }
}

class MyMenuBar extends StatelessWidget {
  const MyMenuBar({super.key, required this.naviDestination});

  final NaviDestination? naviDestination;

  @override
  Widget build(BuildContext context) {
    return MenuBar(
      style: const MenuStyle(
        elevation: WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(Colors.transparent),
      ),
      children: [
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              leadingIcon: const Icon(Icons.content_paste),
              child: const Text('From Clipboard'),
              onPressed: () {},
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.edit_outlined),
              child: const Text('Input Manually'),
              onPressed: () {},
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.photo),
              child: const Text('Select QR Code'),
              onPressed: () {},
            ),
          ],
          child: Center(
            child: Text(
              'Add',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const borderColor = Color(0xFF805306);
const sidebarColor = Color(0xFFF6A00C);

const backgroundStartColor = Color(0xFFFFD500);
const backgroundEndColor = Color(0xFFF6A00C);

final buttonColors = WindowButtonColors(
  iconNormal: const Color(0xFF805306),
  mouseOver: const Color(0xFFF6A00C),
  mouseDown: const Color(0xFF805306),
  iconMouseOver: const Color(0xFF805306),
  iconMouseDown: const Color(0xFFFFD500),
);

final closeButtonColors = WindowButtonColors(
  mouseOver: const Color(0xFFD32F2F),
  mouseDown: const Color(0xFFB71C1C),
  iconNormal: const Color(0xFF805306),
  iconMouseOver: Colors.white,
);

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: appWindow.minimize,
          icon: const Icon(Icons.remove_rounded),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: appWindow.maximizeOrRestore,
          icon: Icon(
            size: 20,
            appWindow.isMaximized
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () async {
            if (Platform.isLinux) {
              await exitCurrentApp(context.read<XController>());
            } else {
              await windowManager.hide();
            }
          },
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class MinimizeWindowButton extends WindowButton {
  MinimizeWindowButton({
    super.key,
    super.colors,
    VoidCallback? onPressed,
    bool? animate,
  }) : super(
         animate: animate ?? false,
         iconBuilder: (buttonContext) =>
             MinimizeIcon(color: buttonContext.iconColor),
         onPressed: onPressed ?? () => appWindow.minimize(),
       );
}
