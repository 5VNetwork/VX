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
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:ads/ads_provider.dart';
import 'package:app_links/app_links.dart';
import 'package:drift/drift.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:macos_window_utils/macos/ns_window_button_type.dart';
import 'package:macos_window_utils/window_manipulator.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:tm/protos/vx/outbound/outbound.pb.dart';
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
import 'package:vx/common/config.dart';
import 'package:vx/common/const.dart';
import 'package:vx/common/extension.dart';
import 'package:vx/data/database_provider.dart';
import 'package:vx/data/realm_device.dart';
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
import 'package:vx/utils/node_test_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vx/utils/random.dart';
import 'package:vx/utils/root.dart';
import 'package:flutter_common/auth/auth_provider.dart';
import 'package:flutter_common/l10n/app_localizations.dart' as xv_localizations;
import 'package:ads/l10n/app_localizations.dart' as ads_localizations;
import 'package:flutter_common/services/auto_update.dart';
import 'package:vx/widgets/circular_progress_indicator.dart';
import 'firebase_options_production.dart' as production;
import 'package:vx/utils/logger.dart';
import 'package:vx/common/serial.dart';
import 'package:vx/data/database.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/path.dart';
import 'package:vx/utils/db_recovery.dart';
import 'package:vx/utils/recover_and_open.dart';
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
import 'package:tray_manager/tray_manager.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options_staging.dart' as staging;
import 'firebase_options_cn.dart' as cn;
part 'init.dart';
part 'desktop_tray.dart';
part 'router.dart';

void main() async {
  final startTime = DateTime.now();
  WidgetsFlutterBinding.ensureInitialized();

  // fonts are bundled, disable runtime fetching on linux
  if (Platform.isLinux || Platform.isWindows) {
    GoogleFonts.config.allowRuntimeFetching = false;
  }

  if (enableFirebase) {
    await initializeFirebaseApp();
  }

  final pref = await SharedPreferences.getInstance();
  SnowflakeId.setMachineId(pref.machineId);

  resourceDirectory = await resourceDir();
  cacheDirectory = await getCacheDir();
  version = (await PackageInfo.fromPlatform()).version;
  logger.d('resourceDirectory: ${resourceDirectory.path}');

  initRouter(pref); // Initialize router after preferences are loaded
  await initLogger(pref);
  await initNotification();
  await initSupabase();
  await setStartOnBoot(pref);

  bool isActivated = false;
  AppDatabase? database;
  FlutterSecureStorage storage = const FlutterSecureStorage();
  await Future.wait([
    _initDatabase(pref).then((value) => database = value),
    _initWindow(pref),
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
              Licence.fromJson(jsonDecode(licence)),
              uniqueId,
            );
            if (!isActivated) {
              await storage.delete(key: 'licence');
            }
          }
        }
      } catch (e) {
        logger.e('Error validating licence', error: e);
      }
    }),
  ]);

  final authProvider = SupabaseAuth(
    webClientId: webClientId,
    iosClientId: iosClientId,
    loginCallbackUrl: 'vx://login-callback/',
  );
  final proPurchases = Platform.isWindows || Platform.isLinux
      ? null
      : ProPurchases(authProvider);

  if (kDebugMode) {
    Bloc.observer = const AppBlocObserver();
  }
  logger.d(
    "App start time: ${DateTime.now().difference(startTime).inSeconds}s",
  );

  final githubAssetName = await assetName();
  final app = MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (context) => DatabaseProvider(
          database: database ?? AppDatabase(path: '', interceptor: null),
        ),
      ),
      Provider(create: (ctx) => XApiClient(pref, storage)..init(), lazy: false),
      ChangeNotifierProvider.value(value: proPurchases),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      Provider.value(value: pref),
      Provider.value(value: storage),
      Provider(
        create: (ctx) =>
            OutboundRepo(databaseProvider: ctx.read<DatabaseProvider>()),
      ),
      ProxyProvider<DatabaseProvider, DbHelper>(
        create: (ctx) =>
            DbHelper(databaseProvider: ctx.read<DatabaseProvider>()),
        update: (ctx, databaseProvider, dbHelper) =>
            DbHelper(databaseProvider: databaseProvider),
      ),
      Provider(
        create: (context) {
          final downloader = Downloader(
            context.read<OutboundRepo>(),
            context.read<XApiClient>(),
          );
          // makeWinTunAvailable(downloader);
          return downloader;
        },
      ),
      BlocProvider(create: (ctx) => AuthBloc(authProvider, isActivated)),
      Provider<LogUploadService>(
        lazy: false,
        create: (ctx) {
          final logUploadService = LogUploadService(
            flutterLogDir: getFlutterLogDir(),
            tunnelLogDir: getTunnelLogDir(),
            secret: logKey,
            httpClient: HttpClient(),
            useReportLogger: () => pref.shareLog && !enableCrashlytics,
            uploadUrl: kDebugMode
                ? 'https://127.0.0.1:11111/api/upload-logs'
                : 'https://vproxybackend.5vnetwork.com/api/upload-logs',
          );
          if (pref.shareLog) {
            logUploadService.start();
          }
          return logUploadService;
        },
      ),
      ChangeNotifierProvider(
        create: (ctx) => AutoSubscriptionUpdater(
          pref: pref,
          api: ctx.read<XApiClient>(),
          outboundRepo: ctx.read<OutboundRepo>(),
          databaseProvider: ctx.read<DatabaseProvider>(),
        ),
      ),
      Provider(
        lazy: false,
        create: (ctx) =>
            GeoDataHelper(
                downloader: ctx.read<Downloader>(),
                pref: pref,
                xApiClient: ctx.read<XApiClient>(),
                databaseHelper: ctx.read<DbHelper>(),
                resouceDirPath: resourceDirectory.path,
                geoSiteUrl: geositeUrls[0],
                geoIpUrl: geoipUrls[0],
              )
              ..makeGeoDataAvailable()
              ..reset(),
      ),
      Provider(
        create: (ctx) => XConfigHelper(
          outboundRepo: ctx.read<OutboundRepo>(),
          psr: pref,
          downloader: ctx.read<Downloader>(),
          geoDataHelper: ctx.read<GeoDataHelper>(),
          databaseProvider: ctx.read<DatabaseProvider>(),
          xApiClient: ctx.read<XApiClient>(),
        ),
      ),
      Provider(
        create: (ctx) {
          final controller = XController(
            xConfigHelper: ctx.read<XConfigHelper>(),
            pref: pref,
            xApiClient: ctx.read<XApiClient>(),
            logUploadService: ctx.read<LogUploadService>(),
            databaseProvider: ctx.read<DatabaseProvider>(),
            autoSubscriptionUpdater: ctx.read<AutoSubscriptionUpdater>(),
          );
          if (Platform.isWindows) {
            MessageFlutterApi.setUp(controller);
          }
          return controller;
        },
        lazy: false,
      ),
      ChangeNotifierProvider(
        create: (ctx) {
          final dp = ctx.read<DatabaseProvider>();
          final ss = SyncService(
            deviceId: pref.uniqueDeviceId,
            prefHelper: pref,
            storage: storage,
            authBloc: ctx.read<AuthBloc>(),
            databaseProvider: dp,
          );
          dp.database.syncService = ss;
          return ss;
        },
      ),
      Provider(
        create: (ctx) =>
            RealmDeviceService(deviceId: pref.uniqueDeviceId, prefHelper: pref),
      ),
      BlocProvider(
        create: (ctx) => StartCloseCubit(
          pref: pref,
          xController: ctx.read<XController>(),
          authBloc: ctx.read<AuthBloc>(),
        ),
      ),
      ChangeNotifierProvider<AdsProvider>(
        lazy: false,
        create: (ctx) {
          final adsProvider = AdsProvider(
            adsDirectory: path.join(resourceDirectory.path, 'ads'),
            sharedPreferences: pref,
            logger: logger,
            downloadFunction: ctx.read<Downloader>().downloadProxyFirst,
          );
          ctx.read<AuthBloc>().stream.listen((state) {
            if (state.proUser) {
              adsProvider.stop();
            } else {
              adsProvider.start();
            }
          });
          if (!ctx.read<AuthBloc>().state.proUser) {
            adsProvider.start();
          }
          return adsProvider;
        },
      ),
      ProxyProvider<DatabaseProvider, SetRepo>(
        create: (ctx) => ctx.read<DbHelper>(),
        update: (ctx, databaseProvider, dbHelper) => ctx.read<DbHelper>(),
      ),
      ProxyProvider<DatabaseProvider, RouteRepo>(
        create: (ctx) => ctx.read<DbHelper>(),
        update: (ctx, databaseProvider, dbHelper) => ctx.read<DbHelper>(),
      ),
      ProxyProvider<DatabaseProvider, DnsRepo>(
        create: (ctx) => ctx.read<DbHelper>(),
        update: (ctx, databaseProvider, dbHelper) => ctx.read<DbHelper>(),
      ),
      ProxyProvider<DatabaseProvider, SelectorRepo>(
        create: (ctx) => ctx.read<DbHelper>(),
        update: (ctx, databaseProvider, dbHelper) => ctx.read<DbHelper>(),
      ),
      BlocProvider(
        create: (ctx) => InboundCubit(pref, ctx.read<XController>()),
      ),
      ChangeNotifierProvider<RealtimeSpeedNotifier>(
        create: (ctx) => RealtimeSpeedNotifier(
          controller: ctx.read<XController>(),
          outboundRepo: ctx.read<OutboundRepo>(),
        ),
      ),
      ChangeNotifierProvider<RealmServerStatusNotifier>(
        create: (ctx) => RealmServerStatusNotifier(
          controller: ctx.read<XController>(),
          prefs: ctx.read<SharedPreferences>(),
        ),
      ),
      Provider<MyLayout>(create: (_) => MyLayout()),
      if (autoUpdateSupported)
        ChangeNotifierProvider(
          lazy: false,
          create: (ctx) {
            final a = AutoUpdateService(
              pref: pref,
              downloadUrl: 'https://download.5vnetwork.com',
              downloader: ctx.read<Downloader>().download,
              currentVersion: version,
              logger: logger,
              assetName: githubAssetName,
              repository: '5vnetwork/vx',
              autoCheck: true,
              autoDownload: false,
              exitCurrentApp: () {
                return exitCurrentApp(ctx.read<XController>());
              },
              onNewVersionAvailable: (release) {
                if (rootNavigationKey.currentContext == null) {
                  return;
                }
                showDialog(
                  context: rootNavigationKey.currentContext!,
                  barrierDismissible: false,
                  builder: (context) => HasNewerVersionDialog(
                    release: release,
                    setSkipCurrentVersion: () {
                      rootNavigationKey.currentContext!
                          .read<AutoUpdateService>()
                          .setSkipCurrentVersion();
                    },
                    updateToRelease: (release) async {
                      final ctx = rootNavigationKey.currentContext!;
                      final messenger = ScaffoldMessenger.of(ctx);
                      final snackBarController = messenger.showSnackBar(
                        SnackBar(
                          persist: true,
                          content: Row(
                            children: [
                              Text(
                                AppLocalizations.of(
                                  ctx,
                                )!.downloading(release.version),
                              ),
                              const SizedBox(width: 12),
                              smallCircularProgressIndicator,
                            ],
                          ),
                        ),
                      );
                      try {
                        await ctx.read<AutoUpdateService>().updateToRelease(
                          release,
                        );
                      } finally {
                        snackBarController.close();
                      }
                    },
                  ),
                );
              },
              onDownloadComplete: (downloadedInstaller) {
                if (rootNavigationKey.currentContext == null) {
                  return;
                }
                showDialog(
                  context: rootNavigationKey.currentContext!,
                  barrierDismissible: false,
                  builder: (context) => InstallNewerVersionDialog(
                    downloadedInstaller: downloadedInstaller,
                    setSkipCurrentInstaller: rootNavigationKey.currentContext!
                        .read<AutoUpdateService>()
                        .setSkipCurrentVersion,
                    installLocalInstaller: () async {
                      // stop vpn first
                      await context.read<XController>().stopIfConnected();
                      rootNavigationKey.currentContext!
                          .read<AutoUpdateService>()
                          .installLocalInstaller();
                    },
                  ),
                );
              },
              cacheDir: cacheDirectory,
            );

            return a;
          },
        ),
      ChangeNotifierProvider(
        create: (ctx) => BackupSerevice(
          authProvider: ctx.read<AuthBloc>(),
          prefHelper: pref,
          storage: storage,
          databaseProvider: ctx.read<DatabaseProvider>(),
          xController: ctx.read<XController>(),
          xApiClient: ctx.read<XApiClient>(),
          syncService: ctx.read<SyncService>(),
        ),
      ),
      ChangeNotifierProvider(
        create: (ctx) => Deployer(xApiClient: ctx.read<XApiClient>()),
      ),
      BlocProvider(
        lazy: false,
        create: (ctx) => LogBloc(
          pref: pref,
          xController: ctx.read<XController>(),
          outboundRepo: ctx.read<OutboundRepo>(),
        ),
      ),
      BlocProvider(
        create: (ctx) {
          final proxySelectorBloc = ProxySelectorBloc(
            pref: pref,
            databaseProvider: ctx.read<DbHelper>(),
            xConfigController: ctx.read<XController>(),
          )..add(XBlocInitialEvent());
          return proxySelectorBloc;
        },
      ),
      BlocProvider(
        create: (ctx) {
          final outboundBloc = OutboundBloc(
            ctx.read<OutboundRepo>(),
            ctx.read<XController>(),
            ctx.read<AutoSubscriptionUpdater>(),
            ctx.read<AuthBloc>(),
            ctx.read<SharedPreferences>(),
            ctx.read<XApiClient>(),
          )..add(InitialEvent());
          ctx.read<SyncService>().outboundBloc = outboundBloc;
          return outboundBloc;
        },
      ),
      BlocProvider(
        create: (ctx) => SubscriptionBloc(
          ctx.read<OutboundRepo>(),
          ctx.read<AutoSubscriptionUpdater>(),
        ),
      ),
    ],
    child: const App(),
  );

  if (isProduction() && enableSentry) {
    await SentryFlutter.init((options) {
      options.dsn =
          'https://009ab463981b5d206a8d733ebd4182ec@o4510866353618944.ingest.us.sentry.io/4510866355257344';
      // Adds request headers and IP for users, for more info visit:
      // https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
      options.sendDefaultPii = false;
      // if (!isProduction()) {
      //   options.enableLogs = true;
      //   // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      //   // We recommend adjusting this value in production.
      //   options.tracesSampleRate = 1.0;
      //   // The sampling rate for profiling is relative to tracesSampleRate
      //   // Setting to 1.0 will profile 100% of sampled transactions:
      //   options.profilesSampleRate = 1.0;
      //   // Configure Session Replay
      //   options.replay.sessionSampleRate = 0.1;
      //   options.replay.onErrorSampleRate = 1.0;
      // }
    }, appRunner: () => runApp(SentryWidget(child: app)));
  } else {
    runApp(app);
  }
}

// global variables
late final Directory resourceDirectory;
late final String cacheDirectory;
late final String version;
final bool enableFirebase = !Platform.isWindows && !Platform.isLinux;
final enableCrashlytics = !Platform.isWindows && !Platform.isLinux;
final enableSentry = Platform.isWindows || Platform.isLinux;
bool googleApiAvailable = false;
bool fcmEnabled = false;
late final AndroidNotificationChannel androidChannel;
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
late final SupabaseClient supabase;
bool demo = const bool.fromEnvironment('DEMO');

// late final Directory appCache;
final WindowsHostApi? windowsHostApi = Platform.isWindows
    ? WindowsHostApi()
    : null;
bool isRunningAsAdmin = false;
final DarwinHostApi? darwinHostApi = Platform.isIOS || Platform.isMacOS
    ? DarwinHostApi()
    : null;
final AndroidHostApi? androidHostApi = Platform.isAndroid
    ? AndroidHostApi()
    : null;

final isAdPlatforms = Platform.isAndroid || Platform.isIOS;

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();

  static _AppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_AppState>();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  static const int _reviewMinOpenCount = kDebugMode ? 0 : 8;
  static const int _reviewMinDaysSinceFirstUse = kDebugMode ? 0 : 7;
  static const int _reviewPromptMaxTimes = 1;

  Locale? _locale;
  ThemeMode? _themeMode;
  // AppLifecycleListener must be kept alive to receive lifecycle events
  // ignore: unused_field
  late final AppLifecycleListener _listener;
  final appLinks = AppLinks();
  late final SyncService syncService;
  final InAppReview _inAppReview = InAppReview.instance;
  bool _reviewPromptInProgress = false;

  void setLocale(Locale? value) async {
    setState(() {
      _locale = value;
    });
    try {
      await insertDefault(
        rootNavigationKey.currentContext!,
        context.read<SharedPreferences>(),
        context.read<DatabaseProvider>().database,
      );
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

  @override
  void initState() {
    super.initState();
    syncService = context.read<SyncService>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      if (fatalErrorMessage != null) {
        fatalMessageDialog(
          _withAndroidDisableCoreDatabaseHint(
            context,
            fatalErrorMessage!,
            isDatabaseIssue:
                fatalErrorMessage!.toLowerCase().contains('database') ||
                looksLikeCorruptDbError(fatalErrorMessage!),
          ),
        );
        fatalErrorMessage = null;
        return;
      }
      try {
        await insertDefault(
          rootNavigationKey.currentContext!,
          context.read<SharedPreferences>(),
          context.read<DatabaseProvider>().database,
        );
      } catch (e) {
        logger.e('Error inserting default', error: e);
        snack(rootLocalizations()?.insertDefaultError(e.toString()));
      }
      if (databaseRecoveryMessage != null) {
        fatalMessageDialog(
          _withAndroidDisableCoreDatabaseHint(
            context,
            databaseRecoveryMessage!,
            isDatabaseIssue: true,
          ),
        );
        databaseRecoveryMessage = null;
      }
    });

    final pref = context.read<SharedPreferences>();
    if (pref.initialLaunch) {
      pref.setInitialLaunch();
      androidHostApi?.requestAddTile();
    }
    _recordUsageAndScheduleReview(pref);
    _locale = pref.language?.locale ?? PlatformDispatcher.instance.locale;
    _themeMode = pref.themeMode;
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isWindows && !isRunningAsAdmin) {
      _register('vx');
    }
    appLinks.uriLinkStream.listen(handlerAppLinks);
    if (fcmEnabled) {
      // fcm foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        logger.d('Got a message whilst in the foreground! ${message.data}');

        if (message.notification != null) {
          logger.d(
            'Message also contained a notification: ${message.notification}',
          );
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
          await context.read<XController>().beforeExitCleanup();
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
    RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();

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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.d(state);
    if (state == AppLifecycleState.resumed) {
      final pref = context.read<SharedPreferences>();
      if (pref.getBool('shouldSync') ?? false) {
        syncService.sync();
      }
      _recordUsageAndScheduleReview(pref);
    }
    super.didChangeAppLifecycleState(state);
  }

  void _recordUsageAndScheduleReview(SharedPreferences pref) {
    final now = DateTime.now();
    pref.setReviewFirstUseAt(pref.reviewFirstUseAt ?? now);
    pref.setReviewAppOpenCount(pref.reviewAppOpenCount + 1);
    _scheduleReviewPrompt(pref);
  }

  void _scheduleReviewPrompt(SharedPreferences pref) {
    Future<void>.delayed(const Duration(seconds: 5), () async {
      await _maybePromptForReview(pref);
    });
  }

  Future<void> _maybePromptForReview(SharedPreferences pref) async {
    if (!mounted || _reviewPromptInProgress) return;
    if (pref.reviewAutoPromptDisabled) return;
    if (pref.reviewPromptCount >= _reviewPromptMaxTimes) return;

    final firstUseAt = pref.reviewFirstUseAt;
    if (firstUseAt == null ||
        DateTime.now().difference(firstUseAt).inDays <
            _reviewMinDaysSinceFirstUse) {
      return;
    }

    if (pref.reviewAppOpenCount < _reviewMinOpenCount) {
      return;
    }

    final lastPromptAt = pref.reviewLastPromptAt;
    if (lastPromptAt != null) {
      return;
    }

    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState != AppLifecycleState.resumed) {
      return;
    }

    _reviewPromptInProgress = true;
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        pref.setReviewLastPromptAt(DateTime.now());
        pref.setReviewPromptCount(pref.reviewPromptCount + 1);
        pref.setReviewAutoPromptDisabled(true);
      }
    } catch (e, stackTrace) {
      logger.e('Auto review prompt failed', error: e, stackTrace: stackTrace);
    } finally {
      _reviewPromptInProgress = false;
    }
  }

  void handlerAppLinks(Uri uri) async {
    logger.d(uri);
    if (uri.host == 'add') {
      if (uri.path.startsWith('/sub://')) {
        final base64Content = uri.path.substring(7);
        final url = decodeBase64(base64Content);
        context.read<SubscriptionBloc>().add(
          AddSubscriptionEvent(uri.queryParameters['remarks'] ?? '', url),
        );
      }
    } else if (uri.host == 'install-config') {
      if (uri.queryParameters['url'] != null) {
        context.read<SubscriptionBloc>().add(
          AddSubscriptionEvent(
            uri.queryParameters['name'] ?? '',
            uri.queryParameters['url']!,
          ),
        );
      }
    } else if (uri.host == 'login-callback') {
      // Handle Supabase auth callback
      logger.d('Auth callback received: $uri');
      snack(AppLocalizations.of(context)?.loginSuccess);
      // The Supabase client should handle this automatically
    } else if (uri.host == 'nodes') {
      final outboundBloc = context.read<OutboundBloc>();
      final groupName = uri.queryParameters['name'] ?? '';
      final data = uri.queryParameters['content'] ?? '';
      final result = await context.read<XApiClient>().decode(data);
      final replaceAll = uri.queryParameters['replace'] == 'true';
      logger.d('replaceAll: $replaceAll');
      outboundBloc.add(
        AddHandlersEvent(
          replaceAll: replaceAll,
          groupName: groupName,
          result.handlers.map((e) => HandlerConfig(outbound: e)).toList(),
        ),
      );
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
          ? (context, child) => DesktopTray(child: child!)
          : null,
      routerConfig: _router,
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        ...xv_localizations.AppLocalizations.localizationsDelegates,
        ...ads_localizations.AppLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
    return MultiProvider(
      providers: [
        Provider(
          lazy: false,
          create: (ctx) => NodeTestService(
            outboundRepo: ctx.read<OutboundRepo>(),
            outboundBloc: ctx.read<OutboundBloc>(),
            pref: ctx.read<SharedPreferences>(),
          ),
        ),
        ChangeNotifierProvider<StandardHomeWidgetVisibilityNotifier>(
          create: (ctx) => StandardHomeWidgetVisibilityNotifier(
            ctx.read<SharedPreferences>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => HomeLayoutRepo(ctx.read<SharedPreferences>()),
        ),
        ChangeNotifierProvider<CustomHomePageLayoutProvider>(
          create: (ctx) =>
              CustomHomePageLayoutProvider(ctx.read<HomeLayoutRepo>()),
        ),
        BlocProvider(
          create: (ctx) => HomePageCubit(ctx.read<SharedPreferences>()),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          logger.d("W: ${constraints.maxWidth}, H: ${constraints.maxHeight}");
          Provider.of<MyLayout>(
            context,
            listen: false,
          ).setFields(constraints.maxWidth, constraints.maxHeight);
          if (constraints.isCompact) {
            myRoutingConfig.value = compactRouteConfig;
          } else {
            myRoutingConfig.value = largeScreenRouteConfig(
              context.read<SharedPreferences>(),
            );
          }
          return app;
        },
      ),
    );
  }
}

String? fatalErrorMessage;
String? databaseRecoveryMessage;

String _withAndroidDisableCoreDatabaseHint(
  BuildContext context,
  String message, {
  required bool isDatabaseIssue,
}) {
  if (!isDatabaseIssue || !Platform.isAndroid) {
    return message;
  }
  final pref = context.read<SharedPreferences>();
  if (pref.disableCoreDatabase) {
    return message;
  }
  final al = AppLocalizations.of(context)!;
  return '$message\n\n${al.databaseIssueTurnOnDisableCoreDatabase(
    al.disableCoreDatabase,
    al.settings,
    al.advanced,
  )}';
}

void fatalMessageDialog(String message) {
  if (rootNavigationKey.currentContext == null) {
    return;
  }
  showDialog(
    context: rootNavigationKey.currentContext!,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Icon(Icons.error_outline_rounded),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Text(message),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.close),
        ),
        FilledButton(
          onPressed: () {
            exitCurrentApp(context.read<XController>());
          },
          child: Text(AppLocalizations.of(context)!.exit),
        ),
      ],
    ),
  );
}

void snack(String? message, {Duration? duration, bool? persistent}) {
  if (message == null) {
    return;
  }
  rootScaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration ?? const Duration(seconds: 4),
      persist: persistent ?? false,
    ),
  );
}

void dialog(String message) {
  if (rootNavigationKey.currentContext == null) {
    return;
  }
  showDialog(
    context: rootNavigationKey.currentContext!,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.close),
        ),
      ],
    ),
  );
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
Future<void> _initWindow(SharedPreferences pref) async {
  if (desktopPlatforms) {
    await windowManager.ensureInitialized();
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
        offset: const Offset(15, 15),
      );
      WindowManipulator.overrideStandardWindowButtonPosition(
        buttonType: NSWindowButtonType.miniaturizeButton,
        offset: const Offset(35, 15),
      );
      WindowManipulator.overrideStandardWindowButtonPosition(
        buttonType: NSWindowButtonType.zoomButton,
        offset: const Offset(55, 15),
      );
    }
    if (Platform.isWindows || Platform.isLinux) {
      WindowOptions windowOptions = WindowOptions(
        titleBarStyle: TitleBarStyle.hidden,
        alwaysOnTop: false,
        skipTaskbar: false,
        size: Size(pref.windowWidth, pref.windowHeight),
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        if (pref.windowX != null && pref.windowY != null) {
          await windowManager.setPosition(Offset(pref.windowX!, pref.windowY!));
        } else {
          await windowManager.center();
        }
        await windowManager.show();
      });
    } else {
      if (pref.windowX != null && pref.windowY != null) {
        await windowManager.setPosition(Offset(pref.windowX!, pref.windowY!));
      } else {
        await windowManager.center();
      }
      await windowManager.setSize(Size(pref.windowWidth, pref.windowHeight));
    }
  }

  logger.d('window initialized');
}

Future<void> initSupabase() async {
  logger.d('supabaseUrl: $supabaseUrl');
  await Supabase.initialize(
    authOptions: const FlutterAuthClientOptions(
      detectSessionInUri: !kDebugMode,
    ),
    headers: Platform.isWindows
        ? {'X-Supabase-Client-Platform-Version': 'Windows'}
        : null,
    url: supabaseUrl,
    anonKey: false
        ? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0'
        : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFnZXdndXF4eXRlb293Ynhlb2ZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE2OTc2ODAsImV4cCI6MjA2NzI3MzY4MH0.UmaVdCukolvrboBhEDhgvXVVbxKZSV0r1TDjlozq0TI',
  );
  supabase = Supabase.instance.client;
}

Future<void> setStartOnBoot(SharedPreferences pref) async {
  if (Platform.isWindows) {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      launchAtStartup.setup(
        appName: packageInfo.appName,
        appPath: Platform.resolvedExecutable,
        // Set packageName parameter to support MSIX.
        packageName: packageInfo.packageName,
      );
      if (pref.startOnBoot && !await launchAtStartup.isEnabled()) {
        await launchAtStartup.enable();
      }
    } catch (e) {
      logger.e('Error setting up launch at startup', error: e);
    }
  }
}

Future<void> initNotification() async {
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
  logger.d('fcmEnabled: $fcmEnabled');

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
              AndroidFlutterLocalNotificationsPlugin
            >()
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
      FirebaseMessaging.instance
          .getToken()
          .then((token) {
            logger.d('FCM token: $token');
          })
          .catchError((err) {
            logger.e('Error getting FCM token', error: err);
          });
      FirebaseMessaging.instance.onTokenRefresh
          .listen((fcmToken) {
            // TODO: If necessary send token to application server.
            logger.d('FCM token: $fcmToken');
            // Note: This callback is fired at each app startup and whenever a new
            // token is generated.
          })
          .onError((err) {
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

Future<void> initializeFirebaseApp() async {
  // Determine which Firebase options to use based on the flavor
  final firebaseOptions = switch (appFlavor) {
    'production' ||
    'pkg' ||
    'apk' => production.DefaultFirebaseOptions.currentPlatform,
    'staging' => staging.DefaultFirebaseOptions.currentPlatform,
    'cn' => cn.DefaultFirebaseOptions.currentPlatform,
    _ => null,
  };
  await Firebase.initializeApp(options: firebaseOptions);
}
