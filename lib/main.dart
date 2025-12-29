import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:app_links/app_links.dart';
import 'package:drift/drift.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:macos_window_utils/macos/ns_window_button_type.dart';
import 'package:macos_window_utils/window_manipulator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:tm/tm.dart';
import 'package:uuid/uuid.dart';
import 'package:vx/app/blocs/inbound.dart';
import 'package:vx/app/home/home.dart';
import 'package:vx/app/start_close_button.dart';
import 'package:vx/app/android_host_api.g.dart';
import 'package:vx/app/darwin_host_api.g.dart';
import 'package:vx/app/log/log_bloc.dart';
import 'package:vx/app/outbound/outbounds_bloc.dart';
import 'package:vx/app/outbound/subscription.dart';
import 'package:vx/app/outbound/subscription_bloc.dart';
import 'package:vx/app/routing/repo.dart';
import 'package:vx/app/server/deployer.dart';
import 'package:vx/app/settings/ads.dart';
import 'package:vx/app/settings/debug.dart';
import 'package:vx/app/settings/general/general.dart';
import 'package:vx/app/windows_host_api.g.dart';
import 'package:vx/app/blocs/proxy_selector/proxy_selector_bloc.dart';
import 'package:vx/app/outbound/outbound_repo.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/auth/auth_provider.dart';
import 'package:vx/common/bloc_observer.dart';
import 'package:vx/common/common.dart';
import 'package:vx/common/extension.dart';
import 'package:vx/data/ads_provider.dart';
import 'package:vx/data/sync.dart';
import 'package:vx/iap/pro.dart';
import 'package:flutter/cupertino.dart';
import 'package:vx/app/outbound/outbound_page.dart';
import 'package:vx/app/settings/account.dart';
import 'package:vx/app/settings/advanced/advanced.dart';
import 'package:vx/app/settings/advanced/proxy_share.dart';
import 'package:vx/app/shell_page.dart';
import 'package:vx/app/server/server_page.dart';
import 'package:vx/app/settings/contact.dart';
import 'package:vx/app/settings/open_source_software_notice_screen.dart';
import 'package:vx/app/settings/privacy.dart';
import 'package:vx/app/settings/setting.dart';
import 'package:vx/app/log/log_page.dart';
import 'package:vx/app/routing/routing_page.dart';
import 'package:vx/utils/activate.dart';
import 'package:vx/utils/backup_service.dart';
import 'package:vx/utils/device.dart';
import 'package:vx/utils/github_release.dart';
import 'package:vx/utils/node_test_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vx/utils/random.dart';
import 'package:vx/utils/root.dart';
import 'firebase_options.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/common/serial.dart';
import 'package:vx/data/database.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/path.dart';
import 'package:vx/utils/upload_log.dart';
import 'package:vx/utils/wintun.dart';
import 'package:vx/utils/xapi_client.dart';
import 'package:vx/xconfig_helper.dart';
import 'package:vx/app/layout_provider.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/utils/download.dart';
import 'package:vx/utils/geodata.dart';
import 'package:vx/utils/auto_update_service.dart';
import 'package:vx/theme.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:google_fonts/google_fonts.dart';

part 'init.dart';
part 'desktop_tray.dart';
part 'router.dart';

void main() async {
  await _init();
  runApp(const App());
}

Future<void> _init() async {
  final startTime = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();

  // fonts are bundled, disable runtime fetching on linux
  if (Platform.isLinux || Platform.isWindows) {
    GoogleFonts.config.allowRuntimeFetching = false;
  }

  if (enableFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await _initPref();
  SnowflakeId.setMachineId(persistentStateRepo.machineId);
  await initLogger();

  // local notification
  // flutterLocalNotificationsPlugin
  //     .resolvePlatformSpecificImplementation<
  //         AndroidFlutterLocalNotificationsPlugin>()
  //     ?.requestNotificationsPermission();

  // set fcm enabled
  if (Platform.isAndroid) {
    GooglePlayServicesAvailability availability = await GoogleApiAvailability
        .instance
        .checkGooglePlayServicesAvailability();
    googleApiAvailable = availability == GooglePlayServicesAvailability.success;
    fcmEnabled = googleApiAvailable;
  } else if (Platform.isIOS || Platform.isMacOS) {
    fcmEnabled = true;
  }
  print('fcmEnabled: $fcmEnabled');

  // fcm
  if (fcmEnabled) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    if (Platform.isAndroid) {
      // Android applications are not required to request permission.
      // enable foreground notification
      androidChannel = const AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description:
            'This channel is used for important notifications.', // description
        importance: Importance.defaultImportance,
        enableVibration: false,
        showBadge: false,
        playSound: false,
      );
      try {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(androidChannel);
      } catch (e) {
        logger.e('createNotificationChannel', error: e);
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      // You may set the permission requests to "provisional" which allows the user to choose what type
      // of notifications they would like to receive once the user receives a notification.
      try {
        final notificationSettings = await FirebaseMessaging.instance
            .requestPermission(provisional: true);
        logger.d('FCM permission: ${notificationSettings.authorizationStatus}');
      } catch (e) {
        logger.e('requestPermission', error: e);
      }
      try {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true, // Required to display a heads up notification
          badge: true,
          sound: true,
        );
      } catch (e) {
        logger.e('setForegroundNotificationPresentationOptions', error: e);
      }
    }
    if (!isProduction()) {
      FirebaseMessaging.instance.getToken().then((token) {
        print('FCM token: $token');
      }).catchError((err) {
        print('Error getting FCM token: $err');
      });
      FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
        // TODO: If necessary send token to application server.
        logger.d('FCM token: $fcmToken');
        // Note: This callback is fired at each app startup and whenever a new
        // token is generated.
      }).onError((err) {
        // Error getting token.
        logger.e('Error getting FCM token', error: err);
      });
      if (Platform.isIOS || Platform.isMacOS) {
        // For apple platforms, ensure the APNS token is available before making any FCM plugin API calls
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          // APNS token is available, make FCM plugin API requests...
          logger.d('APNS token: $apnsToken');
        } else {
          logger.d('APNS token is not available');
        }
      }
    }
  }

  await Supabase.initialize(
    authOptions: FlutterAuthClientOptions(detectSessionInUri: !kDebugMode),
    headers: Platform.isWindows
        ? {
            'X-Supabase-Client-Platform-Version': 'Windows',
          }
        : null,
    url: false
        ? 'http://127.0.0.1:14572'
        : 'https://qgewguqxyteoowbxeofi.supabase.co',
    anonKey: false
        ? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0'
        : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFnZXdndXF4eXRlb293Ynhlb2ZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE2OTc2ODAsImV4cCI6MjA2NzI3MzY4MH0.UmaVdCukolvrboBhEDhgvXVVbxKZSV0r1TDjlozq0TI',
  );

  if (Platform.isWindows) {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      launchAtStartup.setup(
        appName: packageInfo.appName,
        appPath: Platform.resolvedExecutable,
        // Set packageName parameter to support MSIX.
        packageName: packageInfo.packageName,
      );
      if (persistentStateRepo.startOnBoot &&
          !await launchAtStartup.isEnabled()) {
        await launchAtStartup.enable();
      }
    } catch (e) {
      logger.e('Error setting up launch at startup', error: e);
    }
  }

  resourceDirectory = await resourceDir();
  print('resourceDirectory: ${resourceDirectory.path}');
  storage = const FlutterSecureStorage();

  bool isActivated = false;
  await Future.wait([
    _initDatabase(),
    _initWindow(),
    Future(() async {
      if (Platform.isWindows) {
        isRunningAsAdmin = await windowsHostApi!.isRunningAsAdmin();
      } else if (Platform.isLinux) {
        isRunningAsAdmin = await checkLinuxRootPrivileges();
      }
      logger.d('isRunningAsAdmin: $isRunningAsAdmin');
    }),
    Future(() async {
      try {
        // auth
        String? licence = await storage.read(key: 'licence');
        if (licence != null) {
          String? uniqueId = await storage.read(key: uniqueIdKey);
          if (uniqueId != null) {
            isActivated = await validateLicence(
                Licence.fromJson(jsonDecode(licence)), uniqueId);
          }
        }
      } catch (e) {
        logger.e('Error validating licence', error: e);
      }
    }),
  ]);

  // outbound repo
  _outboundRepo = OutboundRepo(database);
  //  sync service
  syncService = SyncService(
      deviceId: await getUniqueDeviceId(),
      prefHelper: persistentStateRepo,
      storage: storage,
      outboundRepo: _outboundRepo,
      authProvider: authProvider);

  authBloc = AuthBloc(authProvider, isActivated);
  xConfigHelper = XConfigHelper(
    outboundRepo: _outboundRepo,
    psr: persistentStateRepo,
    authBloc: authBloc,
  );

  geoDataHelper = GeoDataHelper(
      downloader: downloader,
      psr: persistentStateRepo,
      xApiClient: xApiClient,
      resouceDirPath: resourceDirectory.path,
      databaseHelper: dbHelper);
  _prepare();

  subUpdater = AutoSubscriptionUpdater(
      pref: persistentStateRepo, api: xApiClient, outboundRepo: _outboundRepo);

  // Initialize auto-update service
  if (androidApkRelease ||
      (Platform.isWindows && !isStore) ||
      Platform.isLinux) {
    autoUpdateService = AutoUpdateService(
        prefHelper: persistentStateRepo,
        currentVersion: (await PackageInfo.fromPlatform()).version,
        downloader: downloader,
        checkForUpdate: GitHubReleaseService.checkForUpdates);
  }

  xController = XController(
    xConfigHelper: xConfigHelper,
    pref: persistentStateRepo,
    autoSubscriptionUpdater: subUpdater,
  );
  if (kDebugMode) {
    Bloc.observer = const AppBlocObserver();
  }
  xApiClient.init();
  if (Platform.isWindows) {
    MessageFlutterApi.setUp(xController);
  }

  logger
      .d("App start time: ${DateTime.now().difference(startTime).inSeconds}s");
}

// const IAdIdManager adIdManager = TestAdIdManager();

// global variables
// late final Store store;
// TODO: use repo to do CRUD, remove global [database]
late AppDatabase database;
final DbHelper dbHelper = DbHelper();
late final SharedPreferences pref;
late final Directory resourceDirectory;
late final FlutterSecureStorage storage;
late final PrefHelper persistentStateRepo;
late final AutoSubscriptionUpdater subUpdater;
late final XController xController;
late final SyncService syncService;
late final OutboundRepo _outboundRepo;
NodeTestService? nodeTestService;
final bool enableFirebase = !Platform.isWindows && !Platform.isLinux;
bool googleApiAvailable = false;
bool fcmEnabled = false;
late final AndroidNotificationChannel androidChannel;
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
bool demo = bool.fromEnvironment('DEMO');

// late final Directory appCache;
final WindowsHostApi? windowsHostApi =
    Platform.isWindows ? WindowsHostApi() : null;
bool isRunningAsAdmin = false;
final DarwinHostApi? darwinHostApi =
    Platform.isIOS || Platform.isMacOS ? DarwinHostApi() : null;
final AndroidHostApi? androidHostApi =
    Platform.isAndroid ? AndroidHostApi() : null;
// Router
final ValueNotifier<RoutingConfig> myRoutingConfig =
    ValueNotifier<RoutingConfig>(
  const RoutingConfig(
    routes: <RouteBase>[],
  ),
);
GlobalKey<NavigatorState> rootNavigationKey = GlobalKey<NavigatorState>();
GoRouter _router = GoRouter.routingConfig(
    debugLogDiagnostics: true,
    initialLocation: persistentStateRepo.initialLocation,
    navigatorKey: rootNavigationKey,
    routingConfig: myRoutingConfig)
  ..routerDelegate.addListener(() {
    try {
      final location = _router.routeInformationProvider.value.uri.toString();
      // Only save if location is valid and not empty
      if (location.isNotEmpty && location != '/') {
        logger.d('set initial location: $location');
        persistentStateRepo.setInitialLocation(location);
      }
    } catch (e) {
      // Ignore errors during initialization
    }
  });
// final globalKey = GlobalKey();
final downloader = Downloader(_outboundRepo);
late final GeoDataHelper geoDataHelper;
final authProvider = SupabaseAuth();
late final AuthBloc authBloc;
late final XConfigHelper xConfigHelper;
final xApiClient = XApiClient();
final appLinks = AppLinks();
LogUploadService? logUploadService;
final supabase = Supabase.instance.client;
final proPurchases =
    Platform.isWindows || Platform.isLinux ? null : ProPurchases(authProvider);
final isAdPlatforms = Platform.isAndroid || Platform.isIOS;
AutoUpdateService? autoUpdateService;

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();

  static _AppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_AppState>();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  Locale? _locale;
  ThemeMode? _themeMode;
  late final AppLifecycleListener _listener;

  void setLocale(Locale? value) async {
    setState(() {
      _locale = value;
    });
    try {
      await insertDefault(rootNavigationKey.currentContext!);
    } catch (e) {
      logger.e('Error inserting default', error: e);
      snack(rootLocalizations()?.insertDefaultError(e.toString()));
    }
  }

  void setThemeMode(ThemeMode? value) {
    setState(() {
      _themeMode = value;
    });
  }

  Key _refreshKey = GlobalKey();
  void rebuildAllChildren() {
    _refreshKey = GlobalKey();
    setState(() {});
  }

  late final OutboundBloc outboundBloc;
  late final SubscriptionBloc subBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (fatalErrorMessage != null) {
        dialog(fatalErrorMessage!);
        fatalErrorMessage = null;
      } else {
        try {
          await insertDefault(rootNavigationKey.currentContext!);
        } catch (e) {
          logger.e('Error inserting default', error: e);
          snack(rootLocalizations()?.insertDefaultError(e.toString()));
        }
      }
    });

    if (persistentStateRepo.initialLaunch) {
      persistentStateRepo.setInitialLaunch();
      androidHostApi?.requestAddTile();
    }
    _locale = persistentStateRepo.language?.locale;
    _themeMode = persistentStateRepo.themeMode;
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isWindows && !isRunningAsAdmin) {
      _register('vx');
    }
    appLinks.uriLinkStream.listen(handlerAppLinks);
    outboundBloc = OutboundBloc(
      _outboundRepo,
      xController,
      subUpdater,
      authBloc,
    )..add(InitialEvent());
    syncService.outboundBloc = outboundBloc;
    subBloc = SubscriptionBloc(_outboundRepo, subUpdater);

    // Initialize node test service
    nodeTestService = NodeTestService(
      outboundRepo: _outboundRepo,
      outboundBloc: outboundBloc,
      prefHelper: persistentStateRepo,
    );
    if (persistentStateRepo.autoTestNodes) {
      nodeTestService!.start();
    }
    // auto update service
    autoUpdateService?.addListener(() {
      if (rootNavigationKey.currentContext == null) {
        return;
      }
      final localInstaller = autoUpdateService!.hasLocalInstallerToInstall;
      if (localInstaller != null) {
        final version = localInstaller.version;
        showDialog(
          context: rootNavigationKey.currentContext!,
          builder: (context) => AlertDialog(
            title:
                Text(rootLocalizations()!.newVersionDownloadedDialog(version)),
            content: Text(localInstaller.newFeatures),
            actions: [
              OutlinedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    autoUpdateService!.setSkipVersion(version);
                  },
                  child: Text(rootLocalizations()!.skipThisVersion)),
              FilledButton.tonal(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    try {
                      await autoUpdateService!.installLocalInstaller();
                    } catch (e) {
                      logger.e('Error installing update', error: e);
                      snack(rootLocalizations()?.installFailed(e.toString()));
                    }
                  },
                  child: Text(rootLocalizations()!.install)),
            ],
          ),
        );
      }
    });
    if (fcmEnabled) {
      // fcm foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        logger.d('Got a message whilst in the foreground! ${message.data}');

        if (message.notification != null) {
          logger.d(
              'Message also contained a notification: ${message.notification}');
          final notification = message.notification;
          final android = message.notification?.android;
          if (notification != null && android != null) {
            // flutterLocalNotificationsPlugin.show(
            //     notification.hashCode,
            //     notification.title,
            //     notification.body,
            //     NotificationDetails(
            //       android: AndroidNotificationDetails(
            //           androidChannel.id, androidChannel.name,
            //           channelDescription: androidChannel.description,
            //           icon: android.smallIcon,
            //           playSound: false
            //           // other properties...
            //           ),
            //     ));
          }
        }
        if (message.data['sync'] == 'true') {
          syncService.sync();
        }
      });
      // Run code required to handle interacted messages in an async function
      // as initState() must not be async
      setupInteractedMessage();
    }

    _listener = AppLifecycleListener(
      // onShow: () => logger.d('show'),
      // onResume: () => logger.d('resume'),
      // onHide: () => logger.d('hide'),
      // onInactive: () => logger.d('inactive'),
      // onPause: () => logger.d('pause'),
      // onDetach: () => logger.d('detach'),
      // onRestart: () => logger.d('restart'),
      onExitRequested: () async {
        logger.d('exit requested');
        if (isPkg) {
          await beforeExitCleanup();
        }
        return AppExitResponse.exit;
      },
      // This fires for each state change. Callbacks above fire only for
      // specific state transitions.
      // onStateChange: (state) => logger.d('state change: $state'),
    );
  }

  // It is assumed that all messages contain a data field with the key 'type'
  Future<void> setupInteractedMessage() async {
    // Get any messages which caused the application to open from
    // a terminated state.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    // If the message also contains a data property with a "type" of "chat",
    // navigate to a chat screen
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
    // Also handle any interaction when the app is in the background via a
    // Stream listener
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) {
    logger.d('FCM message: ${message.data}');
  }

  Future<void> _register(String scheme) async {
    String appPath = Platform.resolvedExecutable;

    String protocolRegKey = 'Software\\Classes\\$scheme';
    RegistryValue protocolRegValue = const RegistryValue.string(
      'URL Protocol',
      '',
    );
    String protocolCmdRegKey = 'shell\\open\\command';
    RegistryValue protocolCmdRegValue = RegistryValue.string(
      '',
      '"$appPath" "%1"',
    );

    final regKey = Registry.currentUser.createKey(protocolRegKey);
    regKey.createValue(protocolRegValue);
    regKey.createKey(protocolCmdRegKey).createValue(protocolCmdRegValue);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    outboundBloc.close();
    subBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.d(state);
    if (state == AppLifecycleState.resumed) {
      if (pref.getBool('shouldSync') ?? false) {
        syncService.sync();
      }
    }
    super.didChangeAppLifecycleState(state);
  }

  void handlerAppLinks(Uri uri) {
    logger.d(uri);
    if (uri.host == 'add') {
      if (uri.path.startsWith('/sub://')) {
        final base64Content = uri.path.substring(7);
        final url = decodeBase64(base64Content);
        subBloc.add(
            AddSubscriptionEvent(uri.queryParameters['remarks'] ?? '', url));
      }
    } else if (uri.host == 'install-config') {
      if (uri.queryParameters['url'] != null) {
        final decodedUrl = Uri.decodeComponent(uri.queryParameters['url']!);
        String name = '';
        if (uri.queryParameters['name'] != null) {
          name = Uri.decodeComponent(uri.queryParameters['name']!);
        }
        subBloc.add(AddSubscriptionEvent(name, decodedUrl));
      }
    } else if (uri.host == 'login-callback') {
      // Handle Supabase auth callback
      logger.d('Auth callback received: $uri');
      snack(AppLocalizations.of(context)?.loginSuccess);
      // The Supabase client should handle this automatically
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp.router(
      key: _refreshKey,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      locale: _locale,
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: getTheme(_locale),
      darkTheme: getDarkTheme(_locale),
      builder: desktopPlatforms
          ? (context, child) => DesktopTray(
                child: child!,
              )
          : null,
      routerConfig: _router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AdsProvider>(
            create: (ctx) => AdsProvider(
                adsDirectory: path.join(resourceDirectory.path, 'ads'),
                sharedPreferences: pref,
                authBloc: authBloc,
                downloader: downloader)),
        Provider<XApiClient>.value(value: xApiClient),
        ChangeNotifierProvider.value(value: dbHelper),
        ChangeNotifierProvider<SetRepo>.value(value: dbHelper),
        ChangeNotifierProvider<RouteRepo>.value(value: dbHelper),
        RepositoryProvider.value(value: _outboundRepo),
        ChangeNotifierProvider<DnsRepo>.value(value: dbHelper),
        ChangeNotifierProvider<SelectorRepo>.value(value: dbHelper),
        Provider<XController>.value(value: xController),
        BlocProvider(
            create: (ctx) => InboundCubit(persistentStateRepo, xController)),
        ChangeNotifierProvider<RealtimeSpeedNotifier>(
            create: (ctx) => RealtimeSpeedNotifier(
                controller: xController, outboundRepo: _outboundRepo)),
        Provider<MyLayout>(create: (_) => MyLayout()),
        ChangeNotifierProvider.value(value: proPurchases),
        Provider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider.value(value: syncService),
        BlocProvider(
            create: (ctx) => StartCloseCubit(
                pref: persistentStateRepo,
                xController: xController,
                authBloc: authBloc)),
        ChangeNotifierProvider(
            create: (ctx) => BackupSerevice(
                authProvider: authProvider, prefHelper: persistentStateRepo)),
        BlocProvider.value(value: authBloc),
        BlocProvider.value(
          value: outboundBloc,
        ),
        BlocProvider.value(
          value: subBloc,
        ),
        ChangeNotifierProvider(create: (ctx) => Deployer()),
        BlocProvider(
            lazy: false,
            create: (ctx) =>
                LogBloc(sp: persistentStateRepo, outboundRepo: _outboundRepo)),
        BlocProvider(
            create: (ctx) => ProxySelectorBloc(
                  sp: persistentStateRepo,
                  xConfigController: xController,
                  authBloc: authBloc,
                )..add(XBlocInitialEvent())),
        ChangeNotifierProvider.value(value: autoUpdateService),
      ],
      child: Builder(builder: (context) {
        return BlocConsumer<AuthBloc, AuthState>(
          listenWhen: (previous, current) => previous.pro != current.pro,
          listener: (context, state) {
            context
                .read<ProxySelectorBloc>()
                .add(AuthUserChangedEvent(state.pro));
            if (!state.pro) {
              context.read<OutboundBloc>().add(const UserIsNotProEvent());
            } else {}
          },
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                // logger.d(
                //     "W: ${constraints.maxWidth}, H: ${constraints.maxHeight}");
                Provider.of<MyLayout>(context, listen: false)
                    .setFields(constraints.maxWidth, constraints.maxHeight);
                if (constraints.isCompact) {
                  myRoutingConfig.value = compactRouteConfig;
                } else {
                  myRoutingConfig.value = largeScreenRouteConfig;
                }
                return app;
              },
            );
          },
        );
      }),
    );
  }
}

Future<void> beforeExitCleanup() async {
  logger.d('beforeExitCleanup');
  try {
    if (Platform.isWindows &&
        Tm.instance.state == TmStatus.connected &&
        ((!isRunningAsAdmin &&
            persistentStateRepo.inboundMode == InboundMode.tun))) {
      // close the service
      await xController.stop();
    } else if (Tm.instance.state == TmStatus.connected && isPkg) {
      await xController.stop();
    } else if (Platform.isLinux &&
        Tm.instance.state == TmStatus.connected &&
        persistentStateRepo.inboundMode == InboundMode.tun) {
      await xController.stop();
    }
    if (xController.systemProxySet) {
      await xController.unsetSystemProxy();
      xController.systemProxySet = false;
    }
  } catch (e) {
    reportError("_beforeExitCleanup", e);
    logger.e('_beforeExitCleanup', error: e);
  }
}

String? fatalErrorMessage;

void dialog(String message) {
  if (rootNavigationKey.currentContext == null) {
    return;
  }
  showDialog(
    context: rootNavigationKey.currentContext!,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Icon(Icons.error_outline_rounded),
      content: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400), child: Text(message)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.close),
        ),
        FilledButton(
          onPressed: () {
            exitCurrentApp();
          },
          child: Text(AppLocalizations.of(context)!.exit),
        ),
      ],
    ),
  );
}

void snack(
  String? message, {
  Duration? duration,
}) {
  if (message == null) {
    return;
  }
  rootScaffoldMessengerKey.currentState?.showSnackBar(SnackBar(
    content: Text(message),
    duration: duration ?? const Duration(seconds: 4),
  ));
}

AppLocalizations? rootLocalizations() {
  if (rootNavigationKey.currentContext == null) {
    return null;
  }
  return AppLocalizations.of(rootNavigationKey.currentContext!);
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// customize window
Future<void> _initWindow() async {
  if (desktopPlatforms) {
    if (desktopPlatforms) {
      await windowManager.ensureInitialized();
    }
    if (Platform.isMacOS) {
      await WindowManipulator.initialize();

      // if (isPkg) {
      //   // Initialize system shutdown notifier
      //   await SystemShutdownNotifier.instance.initialize();
      // }

      WindowManipulator.hideTitle();
      WindowManipulator.makeTitlebarTransparent();
      WindowManipulator.enableFullSizeContentView();
      WindowManipulator.overrideStandardWindowButtonPosition(
          buttonType: NSWindowButtonType.closeButton,
          offset: const Offset(15, 15));
      WindowManipulator.overrideStandardWindowButtonPosition(
          buttonType: NSWindowButtonType.miniaturizeButton,
          offset: const Offset(35, 15));
      WindowManipulator.overrideStandardWindowButtonPosition(
          buttonType: NSWindowButtonType.zoomButton,
          offset: const Offset(55, 15));
    }
    if (Platform.isWindows || Platform.isLinux) {
      WindowOptions windowOptions = WindowOptions(
        titleBarStyle: TitleBarStyle.hidden,
        alwaysOnTop: false,
        skipTaskbar: false,
        size: Size(
            persistentStateRepo.windowWidth, persistentStateRepo.windowHeight),
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        if (persistentStateRepo.windowX != null &&
            persistentStateRepo.windowY != null) {
          await windowManager.setPosition(Offset(
              persistentStateRepo.windowX!, persistentStateRepo.windowY!));
        } else {
          await windowManager.center();
        }
        await windowManager.show();
      });
    } else {
      if (persistentStateRepo.windowX != null &&
          persistentStateRepo.windowY != null) {
        await windowManager.setPosition(
            Offset(persistentStateRepo.windowX!, persistentStateRepo.windowY!));
      } else {
        await windowManager.center();
      }
      await windowManager.setSize(Size(
          persistentStateRepo.windowWidth, persistentStateRepo.windowHeight));
    }
  }

  logger.d('window initialized');
}

/// download resources that are needed for VX to work in advance.
void _prepare() async {
  if (Platform.isWindows) {
    makeWinTunAvailable();
  }
  // geo data
  geoDataHelper.makeGeoDataAvailable();
  geoDataHelper.geoFilesFridayUpdate();
}

Future<void> _initPref() async {
  pref = await SharedPreferences.getInstance();
  persistentStateRepo = PrefHelper(pref: pref);
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background handlers run in a separate isolate, so we need to initialize
  // everything from scratch. SharedPreferences and database CAN be used,
  // but must be initialized in this isolate.

  print("Handling a background message: ${message.messageId}");
  final sharedPref = await SharedPreferences.getInstance();
  sharedPref.setBool('shouldSync', true);
}
