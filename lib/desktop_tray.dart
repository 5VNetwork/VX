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

class _BackIntent extends Intent {
  const _BackIntent();
}

class _ForwardIntent extends Intent {
  const _ForwardIntent();
}

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
      child: Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.browserBack):
              const _BackIntent(),
          const SingleActivator(LogicalKeyboardKey.browserForward):
              const _ForwardIntent(),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _BackIntent: CallbackAction<_BackIntent>(
              onInvoke: (_) {
                desktopNavigateBack();
                return null;
              },
            ),
            _ForwardIntent: CallbackAction<_ForwardIntent>(
              onInvoke: (_) {
                desktopNavigateForward();
                return null;
              },
            ),
          },
          child: child,
        ),
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
    with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return _DesktopBackForwardHandler(child: widget.child);
  }
}

Future<void> exitCurrentApp(XController xController) async {
  await xController.beforeExitCleanup();
  await windowManager.destroy();
}
