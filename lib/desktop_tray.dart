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

part of 'main.dart';

class _DesktopBackForwardHandler extends StatelessWidget {
  const _DesktopBackForwardHandler({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (PointerDownEvent event) {
        if (event.kind != PointerDeviceKind.mouse) return;
        if (event.buttons & kBackMouseButton != 0) {
          logger.d(
            'mouse back button → desktopNavigateBack, history: $_historyStack',
          );
          desktopNavigateBack();
        } else if (event.buttons & kForwardMouseButton != 0) {
          logger.d(
            'mouse forward button → desktopNavigateForward, forward: $_forwardStack',
          );
          desktopNavigateForward();
        }
      },
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.browserBack):
              desktopNavigateBack,
          const SingleActivator(LogicalKeyboardKey.browserForward):
              desktopNavigateForward,
        },
        child: child,
      ),
    );
  }
}

class DesktopTray extends StatefulWidget {
  const DesktopTray({super.key, required this.child});
  final Widget child;

  @override
  State<DesktopTray> createState() => _DesktopTrayState();
}

class _DesktopTrayState extends State<DesktopTray>
    with TrayListener, WindowListener {
  @override
  void initState() {
    super.initState();
    _initTray();
    trayManager.addListener(this);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() async {
    if (Platform.isWindows) {
      await windowManager.show();
    } else {
      trayManager.popUpContextMenu();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu(bringAppToFront: true);
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (kDebugMode) {
      logger.d(menuItem.toJson());
    }
  }

  // on mac this is called when the window is closed
  // on windows this seems to be called when the app is exited
  @override
  void onWindowClose() async {
    logger.d('onWindowClose');
    if (Platform.isWindows) {
      await context.read<XController>().beforeExitCleanup();
    } else if (Platform.isLinux) {
      await exitCurrentApp(context.read<XController>());
      return;
    }
    await windowManager.hide();
    if (Platform.isMacOS) {
      await windowManager.setSkipTaskbar(true);
    }
  }

  @override
  void onWindowMove() async {
    final position = await windowManager.getPosition();
    logger.d('window move x: ${position.dx}, y: ${position.dy}');
    context.read<SharedPreferences>().setWindowX(position.dx);
    context.read<SharedPreferences>().setWindowY(position.dy);
  }

  @override
  void onWindowResize() async {
    final size = await windowManager.getSize();
    // logger.d('window resize width: ${size.width}, height: ${size.height}');
    context.read<SharedPreferences>().setWindowWidth(size.width);
    context.read<SharedPreferences>().setWindowHeight(size.height);
  }

  Future<void> _setIcon(XStatus status) async {
    late String iconPath;
    if (Platform.isWindows) {
      if (status == XStatus.connected ||
          status == XStatus.connecting ||
          status == XStatus.preparing) {
        iconPath = 'assets/icons/windows_icon.ico';
      } else {
        iconPath = 'assets/icons/windows_icon_outline.ico';
      }
    } else {
      if (status == XStatus.connected ||
          status == XStatus.connecting ||
          status == XStatus.preparing) {
        iconPath = 'assets/icons/V.png';
      } else {
        iconPath = 'assets/icons/V_outline.png';
      }
    }
    await trayManager.setIcon(
      iconPath,
      isTemplate: true,
      iconSize: Platform.isWindows ? 12 : 14,
    );
    if (!Platform.isLinux) {
      await trayManager.setToolTip('VX');
    }
  }

  void _initTray() async {
    // await _setIcon();
    context.read<XController>().statusStream().listen((status) async {
      await _setIcon(status);
      await _updateMenu(status);
    });
    await windowManager.setPreventClose(true);
    logger.d('tray manager initialized');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMenu(context.read<XController>().status);
  }

  Future<void> _updateMenu(XStatus status) async {
    logger.d('update menu status: $status');
    late MenuItem? connectMenuItem;
    switch (status) {
      case XStatus.connected:
        connectMenuItem = MenuItem(
          key: 'toggle_connection',
          label: AppLocalizations.of(context)!.disconnect,
          onClick: (menuItem) {
            Provider.of<StartCloseCubit>(context, listen: false).stop();
          },
        );
      case XStatus.disconnected:
        connectMenuItem = MenuItem(
          key: 'toggle_connection',
          label: AppLocalizations.of(context)!.connect,
          onClick: (menuItem) {
            Provider.of<StartCloseCubit>(context, listen: false).start();
          },
        );
      case XStatus.connecting || XStatus.preparing:
        connectMenuItem = MenuItem(
          key: 'toggle_connection',
          label: AppLocalizations.of(context)!.connecting,
          disabled: true,
        );
      case XStatus.disconnecting:
        connectMenuItem = MenuItem(
          key: 'toggle_connection',
          label: AppLocalizations.of(context)!.disconnecting,
          disabled: true,
        );
      case XStatus.reconnecting:
        connectMenuItem = MenuItem(
          key: 'toggle_connection',
          label: AppLocalizations.of(context)!.reconnecting,
          disabled: true,
        );
      case XStatus.unknown:
        connectMenuItem = MenuItem(
          key: 'unknown',
          label: AppLocalizations.of(context)!.unknown,
          disabled: true,
        );
      default:
        connectMenuItem = null;
    }

    await trayManager.setContextMenu(
      Menu(
        items: [
          if (connectMenuItem != null) connectMenuItem,
          MenuItem.separator(),
          if (!Platform.isWindows)
            MenuItem(
              key: 'show_window',
              label: AppLocalizations.of(context)!.showClient,
              onClick: (menuItem) async {
                await windowManager.show();
                if (Platform.isMacOS) {
                  await windowManager.setSkipTaskbar(false);
                }
              },
            ),
          MenuItem(
            key: 'quit',
            label: AppLocalizations.of(context)!.quit,
            onClick: (menuItem) async {
              await exitCurrentApp(context.read<XController>());
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DesktopBackForwardHandler(child: widget.child);
  }
}

Future<void> exitCurrentApp(XController xController) async {
  if (desktopPlatforms) {
    await xController.beforeExitCleanup();
    await trayManager.destroy();
    await windowManager.destroy();
  } else {
    exit(0);
  }
}
