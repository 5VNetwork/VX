part of 'main.dart';

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
    print('onWindowClose');
    if (Platform.isWindows) {
      await beforeExitCleanup();
    } else if (Platform.isLinux) {
      await exitCurrentApp();
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
    persistentStateRepo.setWindowX(position.dx);
    persistentStateRepo.setWindowY(position.dy);
  }

  @override
  void onWindowResize() async {
    final size = await windowManager.getSize();
    // logger.d('window resize width: ${size.width}, height: ${size.height}');
    persistentStateRepo.setWindowWidth(size.width);
    persistentStateRepo.setWindowHeight(size.height);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

Future<void> exitCurrentApp() async {
  await beforeExitCleanup();
  await windowManager.destroy();
}
