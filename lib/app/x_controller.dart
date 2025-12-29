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
import 'dart:ffi';
import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/vx/userlogger/userlogger.pb.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vx/app/routing/default.dart';
import 'package:vx/data/database_provider.dart';
import 'package:vx/utils/geodata.dart';
import 'package:vx/utils/os.dart';
import 'package:vx/utils/process.dart';
import 'package:vx/utils/system_proxy.dart';
import 'package:grpc/grpc.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';
import 'package:system_proxy/messages.g.dart';
import 'package:system_proxy/system_proxy.dart';
import 'package:tm/protos/app/grpcservice/grpc.pbgrpc.dart';
import 'package:tm/protos/vx/common/geo/geo.pb.dart';
import 'package:tm/protos/vx/client.pb.dart';
import 'package:tm/protos/vx/router/router.pb.dart';
import 'package:tm/protos/vx/sysproxy/sysproxy.pb.dart';
import 'package:tm/protos/vx/transport/security/tls/certificate.pb.dart';
import 'package:tm/tm.dart';
import 'package:uuid/uuid.dart';
import 'package:vx/app/outbound/outbounds_bloc.dart';
import 'package:vx/app/outbound/subscription.dart';
import 'package:vx/app/routing/routing_page.dart';
import 'package:vx/app/blocs/proxy_selector/proxy_selector_bloc.dart';
import 'package:vx/common/common.dart';
import 'package:vx/data/remotedb/database_server.dart';
import 'package:vx/utils/channel_credentials.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/data/database.dart';
import 'package:vx/main.dart' hide App;
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/path.dart';
import 'package:vx/utils/system_managed_vpn.dart';
import 'package:vx/utils/upload_log.dart';
import 'package:vx/utils/wintun.dart';
import 'package:vx/utils/xapi_client.dart';
import 'package:vx/xconfig_helper.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/app/windows_host_api.g.dart';

const int androidRemoteDbPort = 17890;

/// Its duty is to make sure x core is running as expected
/// Control Xcore
class XController implements MessageFlutterApi {
  final XConfigHelper _xConfigHelper;
  final _tm = Tm.instance;
  final SharedPreferences _pref;
  final LogUploadService _logUploadService;
  final XApiClient _xApiClient;
  final AutoSubscriptionUpdater _autoSubscriptionUpdater;
  final DatabaseProvider _databaseProvider;

  OutboundBloc? outboundBloc;
  // windows only
  bool shuttingDown = false;
  // windows only and pkg only
  bool systemProxySet = false;
  bool dnsBlocked = false;

  XController({
    required XConfigHelper xConfigHelper,
    required SharedPreferences pref,
    required AutoSubscriptionUpdater autoSubscriptionUpdater,
    required XApiClient xApiClient,
    required LogUploadService logUploadService,
    required DatabaseProvider databaseProvider,
  }) : _xConfigHelper = xConfigHelper,
       _pref = pref,
       _xApiClient = xApiClient,
       _autoSubscriptionUpdater = autoSubscriptionUpdater,
       _logUploadService = logUploadService,
       _databaseProvider = databaseProvider {
    Tm.instance.stateStream.listen(_onTmStatusChange);
    if (_androidUseRemoteDb() && Tm.instance.state == TmStatus.connected) {
      _ensureRemoteDbServer();
    }

    // Set up shutdown notification handling on macOS
    // if (isPkg) {
    //   SystemShutdownNotifier.instance.onShutdown(_handleSystemShutdown);
    //   // SystemShutdownNotifier.instance.onRestart(_handleSystemShutdown);
    // }

    autoSubscriptionUpdater.addListener(() {
      subscriptionUpdated();
    });
  }

  final _statusStreamCtrl = BehaviorSubject<XStatus>.seeded(XStatus.unknown);
  Stream<XStatus> statusStream() {
    return _statusStreamCtrl.asBroadcastStream();
  }

  XStatus get status => _statusStreamCtrl.value;

  void _onTmStatusChange(TmStatusChange statusChange) {
    _statusStreamCtrl.add(XStatus.fromTmStatus(statusChange.status));
    if (statusChange.status == TmStatus.connected) {
      if (_androidUseRemoteDb()) {
        _ensureRemoteDbServer();
      }
      _communicate();
      _listenGeoRoute();
    }
    if (statusChange.status == TmStatus.disconnected) {
      cancelCommuStream();
      // cancelListenSelectedOutboundHandler();
      _cancelListenGeoRoute();
      if (statusChange.error != null && statusChange.error!.isNotEmpty) {
        snack(
          rootLocalizations()?.disconnectedUnexpectedly(statusChange.error!),
        );
        logger.e("disconnected!", error: statusChange.error);
        reportError("disconnected due to", statusChange.error!);
        if (_pref.shareLog) {
          _logUploadService.performUpload();
        }
      }
      if (_pref.connect &&
          _pref.alwaysOn &&
          !restarting &&
          !isSystemManagedVpn()) {
        start();
      }
    }
  }

  /// Handle system shutdown or user exit notifications
  ///
  /// pkg only
  // void _handleSystemShutdown() {
  //   logger.i('System shutdown/restart detected - performing cleanup');
  //   shuttingDown = true;
  //   beforeExitCleanup();
  // }

  ClientChannel? _grpcChannel;
  GrpcServiceClient? _grpcServiceClient;
  Completer<GrpcServiceClient>? _completer;
  // windows only
  int? grpcPort;
  Certificate? _certificate;

  Future<GrpcServiceClient> getXClient() async {
    if (_grpcChannel != null) return _grpcServiceClient!;
    if (_completer != null) {
      return await _completer!.future;
    }
    _completer = Completer<GrpcServiceClient>();
    if (useTcpForGrpc && _certificate == null) {
      throw Exception("certificate not found");
    }
    try {
      late InternetAddress address;
      late ChannelOptions channelOptions;
      if (useTcpForGrpc) {
        address = InternetAddress("127.0.0.1");
        final channelCredentials = MyChannelCredentials.secure(
          clientCertBytes: Uint8List.fromList(_certificate!.certificate),
          clientCertPrivateKeyBytes: Uint8List.fromList(_certificate!.key),
          badCertificate: (certificate, host) {
            return true;
          },
        );
        channelOptions = ChannelOptions(credentials: channelCredentials);
      } else {
        address = InternetAddress(
          await grpcListenAddrUnix(),
          type: InternetAddressType.unix,
        );
        channelOptions = const ChannelOptions(
          credentials: ChannelCredentials.insecure(),
        );
      }
      _grpcChannel = ClientChannel(
        address,
        port: grpcPort ?? 0,
        options: channelOptions,
      );
      _grpcServiceClient = GrpcServiceClient(_grpcChannel!);
      _completer?.complete(_grpcServiceClient!);
      return _grpcServiceClient!;
    } catch (e) {
      snack(e.toString());
      logger.e("get x client error", error: e);
      _completer?.completeError(e);
      reportError("get x client error", e);
      rethrow;
    } finally {
      _completer = null;
    }
  }

  Future<ResponseStream<UserLogMessage>> userLogStream() async {
    final client = await getXClient();
    return client.userLogStream(UserLogStreamRequest());
  }

  Future<ResponseStream<StatsResponse>> outboundStatsStream(
    int interval,
  ) async {
    final client = await getXClient();
    return client.getStatsStream(GetStatsRequest(interval: interval));
  }

  Future<ResponseStream<RealmServerStatus>> realmStatusStream(
    int interval,
  ) async {
    final client = await getXClient();
    return client.getRealmStatusStream(
      GetRealmStatusStreamRequest(interval: interval),
    );
  }

  Future<void> resetUserLogging(
    bool enable,
    bool appId,
    bool sessionEnd,
    bool realtimeUsage,
  ) async {
    await waitForConnectedIfConnecting();
    if (Tm.instance.state == TmStatus.connected) {
      final client = await getXClient();
      await client.resetUserLogging(
        ResetUserLoggingRequest(
          enable: enable,
          appId: appId,
          sessionEnd: sessionEnd,
          realtimeUsage: realtimeUsage,
        ),
      );
    }
  }

  Future<TmConfig> _getTmConfig() async {
    return await _xConfigHelper.getAndOrStoreConfig(
      dbSecretAndPort: (isPkg || _androidUseRemoteDb())
          ? (_dbSecret ?? '', _dbServerPort ?? 0)
          : null,
      certBytes: _certificate == null
          ? null
          : Uint8List.fromList(_certificate!.certificate),
    );
  }

  bool _androidUseRemoteDb() => Platform.isAndroid && _pref.disableCoreDatabase;

  String _remoteDbSecret() {
    var secret = _pref.coreRemoteDbSecret;
    if (secret.isEmpty) {
      secret = const Uuid().v4();
      _pref.setCoreRemoteDbSecret(secret);
    }
    return secret;
  }

  Future<void> _ensureRemoteDbServer() async {
    if (_dbServer != null) {
      return;
    }
    try {
      _dbSecret ??= _remoteDbSecret();
      _certificate ??= await _xApiClient.getCertificate();
      await startDbServer();
    } catch (e) {
      logger.e('_ensureRemoteDbServer', error: e);
    }
  }

  String? _sudoPassword;

  Future<void> start() async {
    if (_statusStreamCtrl.value != XStatus.disconnected &&
        _statusStreamCtrl.value != XStatus.unknown) {
      throw Exception("cannot start when not disconnected");
    }
    _statusStreamCtrl.add(XStatus.preparing);

    TmConfig? config;
    String? sudoPassword;

    try {
      _dbSecret = _androidUseRemoteDb() ? _remoteDbSecret() : const Uuid().v4();
      logger.d("start");
      if (useTcpForGrpc || _androidUseRemoteDb()) {
        _certificate = await _xApiClient.getCertificate();
      }
      if (isPkg || _androidUseRemoteDb()) {
        await startDbServer();
      }
      config = await _getTmConfig();
      grpcPort = config.grpc.port;

      logger.d('db server port: ${config.servicePort}');

      if (Platform.isLinux &&
          _pref.inboundMode == InboundMode.tun &&
          _pref.showRpmNotice &&
          isRpm()) {
        final value = await showDialog(
          context: rootNavigationKey.currentContext!,
          barrierDismissible: false,
          builder: (ctx) {
            return AlertDialog(
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(rootLocalizations()!.rpmTunNotice),
                    const Gap(10),
                    TextButton.icon(
                      onPressed: () {
                        launchUrl(
                          Uri.parse(
                            'https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/6/html/security_guide/sect-security_guide-server_security-reverse_path_forwarding',
                          ),
                        );
                      },
                      label: Text(rootLocalizations()!.website),
                      icon: const Icon(Icons.link),
                    ),
                    const Gap(10),
                    StatefulBuilder(
                      builder: (context, setState) {
                        return Row(
                          children: [
                            Checkbox(
                              value: _pref.showRpmNotice,
                              onChanged: (v) {
                                _pref.setShowRpmNotice(v ?? false);
                                setState(() {});
                              },
                            ),
                            Text(
                              rootLocalizations()!.doNotShowAgain,
                              style: Theme.of(context).textTheme.bodySmall!
                                  .copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(rootLocalizations()!.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(rootLocalizations()!.okay),
                ),
              ],
            );
          },
        );
        _pref.setShowRpmNotice(false);
        if (value == false) {
          _statusStreamCtrl.add(XStatus.disconnected);
          return;
        }
      }

      sudoPassword = _sudoPassword;
      if (sudoPassword == null &&
          Platform.isLinux &&
          _pref.inboundMode == InboundMode.tun &&
          !isRunningAsAdmin) {
        final result = await showDialog<(String, bool)>(
          context: rootNavigationKey.currentContext!,
          barrierDismissible: false,
          builder: (ctx) {
            return const _SudoPasswordDialog();
          },
        );
        if (result != null) {
          sudoPassword = result.$1;
          if (result.$2) {
            _sudoPassword = sudoPassword;
          }
        } else {
          _statusStreamCtrl.add(XStatus.disconnected);
          return;
        }
      }

      if (kDebugMode && Platform.isWindows) {
        await installWindowsService();
      }
    } catch (e) {
      _statusStreamCtrl.add(XStatus.disconnected);
      rethrow;
    }

    try {
      await _tm.start(
        config: config,
        onSelfShutdown: (String e) {
          logger.e('onSelfShutdown', error: e);
        },
        configPath: Platform.isWindows || Platform.isMacOS || Platform.isLinux
            ? await configFilePath()
            : null,
        sudoPassword: sudoPassword,
        connectOnDemand: Platform.isIOS ? _pref.connectOnDemand : null,
      );
    } catch (e) {
      if (e.toString().contains('needs user approval')) {
        showDialog(
          context: rootNavigationKey.currentContext!,
          builder: (context) => AlertDialog(
            title: Text(rootLocalizations()!.enableSystemExtension),
          ),
        );
      } else if (e.toString().contains('failed to UpdateGeo')) {
        await writeStaticGeo();
        await _tm.start(
          config: config,
          onSelfShutdown: (String e) {
            logger.e('onSelfShutdown', error: e);
          },
          configPath: Platform.isWindows || Platform.isMacOS || Platform.isLinux
              ? await configFilePath()
              : null,
          sudoPassword: sudoPassword,
          connectOnDemand: Platform.isIOS ? _pref.connectOnDemand : null,
        );
      } else {
        _statusStreamCtrl.add(XStatus.unknown);
        rethrow;
      }
    }

    // since running "networksetup" in system extension is not feasible, set system proxy in containing
    // app
    if ((Platform.isWindows || isPkg || Platform.isLinux) &&
        _pref.inboundMode == InboundMode.systemProxy &&
        !shuttingDown) {
      try {
        await _setSystemProxy(config);
        systemProxySet = true;
      } catch (e) {
        reportError("start setSystemProxy", e);
        _tm.stop();
        rethrow;
      }
    }
    // when not running as admin, block dns is done in golang part
    if (Platform.isWindows &&
        _pref.inboundMode == InboundMode.tun &&
        isRunningAsAdmin) {
      try {
        await _blockDns(config.tun.device.name);
        dnsBlocked = true;
      } catch (e) {
        reportError("start block dns", e);
        _tm.stop();
        rethrow;
      }
    }

    // flush dns
    if (Platform.isLinux) {
      try {
        await _flushLinuxDns(sudoPassword);
      } catch (e) {
        logger.w("Failed to flush DNS cache: $e");
        // Non-critical, continue anyway
      }
    }
    logger.d("start done");
  }

  // only run in debug mode
  Future<void> installWindowsService() async {
    if (kDebugMode) {
      print(Directory.current.path);
      final process = await Process.run(
        'powershell.exe',
        [
          '-Command',
          'Start-Process',
          '..\\vx-core\\win_service\\service_install\\service_install.exe',
          'install',
          '-Verb',
          'RunAs',
        ],
        stderrEncoding: utf8,
        stdoutEncoding: utf8,
        /* runInShell: true */
        runInShell: true,
      );
      final exitCode = process.exitCode;
      logger.d('Windows service installed with exit code: $exitCode');
      // get stdout and stderr
      final stdout = process.stdout;
      final stderr = process.stderr;
      logger.d('Windows service installed with stdout: $stdout');
      logger.d('Windows service installed with stderr: $stderr');
      if (exitCode != 0) {
        throw Exception(
          'Windows service installation failed with exit code: $exitCode. stdout: $stdout, stderr: $stderr',
        );
      }
      // the process might takes some time to finish. so wait for 1 second
      await Future.delayed(const Duration(seconds: 1));
    }
    // final process = await Process.run('powershell.exe', [
    //   '-Command',
    //   'Start-Process',
    //   getServiceInstallExePath(),
    //   'install',
    //   '-Verb',
    //   'RunAs'
    // ]);
    // final geoFile = await rootBundle.load('assets/geo/simplified_geosite.dat');
  }

  Future<void> _setSystemProxy(TmConfig config) async {
    final sysConfig = SysProxyConfig(
      httpProxyAddress: "127.0.0.1",
      httpProxyPort: config.inboundManager.handlers
          .firstWhere((e) => e.tag == 'http')
          .port,
      socksProxyAddress: "127.0.0.1",
      socksProxyPort: config.inboundManager.handlers
          .firstWhere((e) => e.tag == 'socks')
          .port,
    );
    if (Platform.isWindows) {
      await SystemProxy.setSystemProxy(
        SystemProxySettings(
          bypass:
              'localhost;127.*;10.*;172.16.*;172.17.*;172.18.*;172.19.*;172.20.*;172.21.*;172.22.*;172.23.*;172.24.*;172.25.*;172.26.*;172.27.*;172.28.*;172.29.*;172.30.*;172.31.*;192.168.*',
          httpProxy: '${sysConfig.httpProxyAddress}:${sysConfig.httpProxyPort}',
          socksProxy: Platform.isWindows
              ? null
              : 'socks=${sysConfig.socksProxyAddress}:${sysConfig.socksProxyPort}',
        ),
      );
    } else if (Platform.isLinux) {
      await LinuxSystemProxy.setSystemProxy(sysConfig);
    } else if (isPkg) {
      await _xApiClient.setSystemProxy(sysConfig);
    }
  }

  //TODO: use a separate status set from tm status.
  //TODO: seperate this Class into three class: one for controlling(start, stop),
  //one for communicating and call event handlers, one for updating geo and route.
  /// Stop the VPN, returns until it's disconnected.
  Future<void> stop() async {
    logger.d("stop");
    cancelCommuStream();
    // cancelListenSelectedOutboundHandler();
    _cancelListenGeoRoute();
    try {
      await _tm.stop();
      _grpcServiceClient = null;
      if (_grpcChannel != null) {
        _grpcChannel!.shutdown();
        _grpcChannel = null;
      }
      logger.d("stop done");
    } catch (e) {
      logger.e("stop error", error: e);
      await reportError("stop error", e);
      rethrow;
    } finally {
      if (systemProxySet) {
        try {
          await unsetSystemProxy();
          systemProxySet = false;
        } catch (e) {
          logger.e('removeSystemProxy error', error: e);
          reportError("removeSystemProxy error", e);
          snack(rootLocalizations()?.failedToRemoveSystemProxy);
        }
      } else if (dnsBlocked) {
        await _undoBlockDns()
            .then((_) {
              dnsBlocked = false;
            })
            .catchError((e) {
              logger.e('undoBlockDns error', error: e);
              reportError("undoBlockDns error", e);
              snack(rootLocalizations()?.failedToUndoBlockDns);
            });
      }
    }
  }

  Future<void> stopIfConnected() async {
    await waitForConnectedIfConnecting();
    if (Tm.instance.state == TmStatus.connected) {
      await stop();
    }
  }

  /// Should be called before the app is exiting
  Future<void> beforeExitCleanup() async {
    logger.d('beforeExitCleanup');
    try {
      if (Platform.isWindows &&
          Tm.instance.state == TmStatus.connected &&
          ((!isRunningAsAdmin && _pref.inboundMode == InboundMode.tun))) {
        // close the service
        await stop();
      } else if (Tm.instance.state == TmStatus.connected && isPkg) {
        await stop();
      } else if (Platform.isLinux &&
          Tm.instance.state == TmStatus.connected &&
          _pref.inboundMode == InboundMode.tun) {
        await stop();
      }
      if (systemProxySet) {
        await unsetSystemProxy();
        systemProxySet = false;
      }
    } catch (e) {
      reportError("_beforeExitCleanup", e);
      logger.e('_beforeExitCleanup', error: e);
    }
  }

  Future<void> unsetSystemProxy() async {
    if (Platform.isWindows) {
      await SystemProxy.removeSystemProxy();
    } else if (Platform.isLinux) {
      await LinuxSystemProxy.unsetSystemProxy();
    } else {
      assert(isPkg);
      await _xApiClient.stopSystemProxy();
    }
  }

  Server? _dbServer;
  int? _dbServerPort;
  String? _dbSecret;

  FutureOr<GrpcError?> _grpcAuthInterceptor(
    ServiceCall call,
    ServiceMethod<dynamic, dynamic> method,
  ) {
    final metadata = call.clientMetadata;
    if (metadata == null) {
      return const GrpcError.unauthenticated('Missing metadata');
    }
    if (metadata['secret'] != _dbSecret) {
      return const GrpcError.unauthenticated('Invalid credentials');
    }
    return null;
  }

  Future<void> startDbServer() async {
    if (_dbServer != null) {
      _dbServer!.shutdown();
    }
    _dbServer = Server.create(
      services: [DatabaseServer(database: _databaseProvider.database)],
      interceptors: [_grpcAuthInterceptor],
    );

    if (_androidUseRemoteDb()) {
      final port = androidRemoteDbPort;
      try {
        await _dbServer!.serve(
          address: InternetAddress.loopbackIPv4,
          port: port,
          security: ServerTlsCredentials(
            certificate: _certificate!.certificate,
            privateKey: _certificate!.key,
          ),
        );
      } catch (e) {
        logger.w('stable db port $port busy, using ephemeral', error: e);
        await _dbServer!.serve(
          address: InternetAddress.loopbackIPv4,
          port: 0,
          security: ServerTlsCredentials(
            certificate: _certificate!.certificate,
            privateKey: _certificate!.key,
          ),
        );
      }
    } else {
      await _dbServer!.serve(
        address: InternetAddress.loopbackIPv4,
        port: 0,
        security: ServerTlsCredentials(
          certificate: _certificate!.certificate,
          privateKey: _certificate!.key,
        ),
      );
    }

    _dbServerPort = _dbServer!.port;
    logger.d('db server started on port $_dbServerPort');
  }

  /// Notified by the native side when the system is shutting down
  @override
  Future<void> notifyShutdown() async {
    shuttingDown = true;
    logger.d('notifyShutdown');
    if (systemProxySet) {
      await unsetSystemProxy();
      systemProxySet = false;
    }
  }

  Future<void> changeInboundMode() async {
    await waitForConnectedIfConnecting();
    if (Tm.instance.state == TmStatus.connected) {
      await stop();
      await _waitForDisconnected();
      await start();
    }
  }

  Future<void> landHandlersChange() async {
    await waitForConnectedIfConnecting();
    if (Tm.instance.state == TmStatus.connected) {
      await stop();
      await _waitForDisconnected();
      await start();
    }
  }

  /// Block dns queries that will be sent to default physical interface other than [tunName]
  /// This is to prevent dns leak.
  Future<void> _blockDns(String tunName) async {
    if (Platform.isWindows) {
      final interfaces = await NetworkInterface.list();
      final iff = interfaces.firstWhere((e) => e.name == tunName);
      await windowsHostApi!.disableDNS(index: iff.index);
    }
  }

  Future<void> _undoBlockDns() async {
    await windowsHostApi?.undoDisableDNS();
  }

  Future<void> _flushLinuxDns(String? sudoPassword) async {
    if (!Platform.isLinux) return;

    logger.d("Attempting to flush DNS cache on Linux");

    // Try systemd-resolved (most modern systems like Ubuntu 20.04+)
    try {
      final result = await Process.run('resolvectl', ['flush-caches']);
      if (result.exitCode == 0) {
        logger.d("DNS cache flushed successfully using resolvectl");
        return;
      }
    } catch (e) {
      logger.d("resolvectl not available: $e");
    }

    // Try older systemd-resolved command
    try {
      final result = await Process.run('systemd-resolve', ['--flush-caches']);
      if (result.exitCode == 0) {
        logger.d("DNS cache flushed successfully using systemd-resolve");
        return;
      }
    } catch (e) {
      logger.d("systemd-resolve not available: $e");
    }

    if (sudoPassword != null) {
      // Try nscd (Name Service Cache Daemon)
      try {
        final result = await runCmds([
          'systemctl',
          'restart',
          'nscd',
        ], sudoPassword);
        if (result == 0) {
          logger.d("DNS cache flushed successfully by restarting nscd");
          return;
        }
      } catch (e) {
        logger.d("nscd not available: $e");
      }

      // Try dnsmasq
      try {
        final result = await runCmds([
          'systemctl',
          'restart',
          'dnsmasq',
        ], sudoPassword);
        if (result == 0) {
          logger.d("DNS cache flushed successfully by restarting dnsmasq");
          return;
        }
      } catch (e) {
        logger.d("dnsmasq not available: $e");
      }
    }

    logger.w(
      "Could not flush DNS cache - no supported DNS caching service found",
    );
  }

  StreamSubscription<CommunicateMessage>? _commuStreamSub;
  void cancelCommuStream() {
    _commuStreamSub?.cancel();
    _commuStreamSub = null;
  }

  void _communicate() async {
    logger.d("communicate");
    if (_tm.state == TmStatus.connected) {
      final client = await getXClient();
      _commuStreamSub ??= (client.communicate(CommunicateRequest())).listen(
        (m) {
          if (m.hasHandlerError()) _onHandlerError(m.handlerError);
          if (m.hasHandlerBeingUsed()) _onHandlerUsing(m.handlerBeingUsed);
          if (m.hasHandlerUpdated()) _onHandlerUpdated(m.handlerUpdated);
          if (m.hasSubscriptionUpdate()) {
            _onSubscriptionUpdate(m.subscriptionUpdate);
          }
        },
        onDone: cancelCommuStream,
        onError: (e) async {
          // for windows, this might due to the service crashes, so query the service state
          if (Platform.isWindows) {
            _statusStreamCtrl.add(XStatus.fromTmStatus(Tm.instance.state));
          }
          logger.e("communicate stream on error", error: e);
          cancelCommuStream();
          // on windows platform, this can trigger a status sync
          final status = Tm.instance.state;
          logger.d("current status: $status");
          // reconnect to the server
          await Future.delayed(const Duration(seconds: 1));
          if (status == TmStatus.connected) {
            _communicate();
          }
        },
      );
    }
  }

  void _onSubscriptionUpdate(SubscriptionUpdated subscriptionUpdate) {
    logger.d("subscription update");
    _autoSubscriptionUpdater.onSubscriptionUpdated();
    _databaseProvider.database.notifyUpdates({
      TableUpdate.onTable(
        _databaseProvider.database.subscriptions,
        kind: UpdateKind.update,
      ),
    });
  }

  void _onHandlerError(HandlerError handlerError) async {
    logger.i("${handlerError.tag} handler error", error: handlerError.error);
    // if (_pref.proxySelectorMode == ProxySelectorMode.manual) {
    //   // test handler usability
    //   final handler =
    //       await _outboundRepo.getHandlerById(int.parse(handlerError.tag));
    //   if (handler != null) {
    //     final res = await testHandler(handler);
    //     if (res != null) {
    //       if (res.ok != handler.ok) {
    //         outboundBloc?.add(HandlerUpdatedEvent(handler.id));
    //         if (res.ok == -1) {
    //           // TODO: notify
    //         }
    //       }
    //     }
    //   }
    // }
  }

  final StreamController<HandlerBeingUsed> _handlerBeingUsedController =
      BehaviorSubject<HandlerBeingUsed>();
  Stream<HandlerBeingUsed> handlerBeingUsedStream() {
    return _handlerBeingUsedController.stream;
  }

  void _onHandlerUsing(HandlerBeingUsed handlerBeingUsed) {
    logger.i(
      "handler being used, ${handlerBeingUsed.selector}, ${handlerBeingUsed.tags.join(', ')}",
    );
    // if (_handlerBeingUsedController.hasListener) {
    _handlerBeingUsedController.add(handlerBeingUsed);
    // }
  }

  void _onHandlerUpdated(HandlerUpdated handlerUpdated) {
    logger.d("handler updated, ${handlerUpdated.id}");
    outboundBloc?.add(HandlerUpdatedEvent(handlerUpdated.id.toInt()));
  }

  StreamSubscription<List<App>>? _appIdSub;
  // StreamSubscription<List<GeoDomain>>? _geoDomainSub;
  StreamSubscription<List<Cidr>>? _cidrSub;
  StreamSubscription<List<AtomicDomainSet>>? _atomicDomainSetsSub;
  StreamSubscription<List<GreatDomainSet>>? _greatDomainSetsSub;
  StreamSubscription<List<AtomicIpSet>>? _atomicIpSetsSub;
  StreamSubscription<List<GreatIpSet>>? _greatIpSetsSub;

  void _listenGeoRoute() async {
    void updateGeo() async {
      try {
        final config = await _getTmConfig();
        final client = await getXClient();
        client.updateGeo(UpdateGeoRequest(geo: config.geo));
      } catch (e) {
        logger.e("updateGeo error", error: e);
        snack(e.toString());
        stop();
      }
    }

    final database = _databaseProvider.database;
    _atomicDomainSetsSub = database
        .select(database.atomicDomainSets)
        .watch()
        .skip(1)
        .listen((e) async {
          logger.d("atomic domain set update");
          updateGeo();
        });
    _greatDomainSetsSub = database
        .select(database.greatDomainSets)
        .watch()
        .skip(1)
        .listen((e) async {
          logger.d("geo domain set update");
          updateGeo();
        });
    _atomicIpSetsSub = database
        .select(database.atomicIpSets)
        .watch()
        .skip(1)
        .listen((e) async {
          logger.d("atomic ip set update");
          updateGeo();
        });
    _greatIpSetsSub = database
        .select(database.greatIpSets)
        .watch()
        .skip(1)
        .listen((e) async {
          logger.d("great ip set update");
          updateGeo();
        });
    // _geoDomainSub =
    //     database.select(database.geoDomains).watch().skip(1).listen((e) async {
    //   logger.d("geo update");
    //   updateGeo();
    // });
    _cidrSub = database.select(database.cidrs).watch().skip(1).listen((
      e,
    ) async {
      logger.d("cidr update");
      updateGeo();
    });
    _appIdSub = database.select(database.apps).watch().skip(1).listen((
      e,
    ) async {
      logger.d("app id update");
      if (Platform.isAndroid) {
        await stop();
        await start();
      } else {
        updateGeo();
      }
    });
  }

  Future<void> addGeoDomain(String setName, Domain domain) async {
    await waitForConnectedIfConnecting();
    if (Tm.instance.state == TmStatus.connected) {
      final client = await getXClient();
      try {
        await client.addGeoDomain(
          AddGeoDomainRequest(domainSetName: setName, domain: domain),
        );
      } catch (e) {
        logger.e("addGeoDomain error", error: e);
        snack(e.toString());
        stop();
      }
    }
  }

  Future<void> removeGeoDomain(String setName, Domain domain) async {
    await waitForConnectedIfConnecting();
    if (Tm.instance.state == TmStatus.connected) {
      final client = await getXClient();
      try {
        await client.removeGeoDomain(
          RemoveGeoDomainRequest(domainSetName: setName, domain: domain),
        );
      } catch (e) {
        logger.e("removeGeoDomain error", error: e);
        snack(e.toString());
        stop();
      }
    }
  }

  void _cancelListenGeoRoute() async {
    _appIdSub?.cancel();
    _appIdSub = null;
    _cidrSub?.cancel();
    _cidrSub = null;
    _atomicDomainSetsSub?.cancel();
    _atomicDomainSetsSub = null;
    _greatDomainSetsSub?.cancel();
    _greatDomainSetsSub = null;
    _atomicIpSetsSub?.cancel();
    _atomicIpSetsSub = null;
    _greatIpSetsSub?.cancel();
    _greatIpSetsSub = null;
  }

  Future<void> waitForConnectedIfConnecting() async {
    if (_statusStreamCtrl.value == XStatus.connecting ||
        _statusStreamCtrl.value == XStatus.preparing) {
      await _statusStreamCtrl.stream.firstWhere(
        (e) =>
            _statusStreamCtrl.value != XStatus.connecting &&
            _statusStreamCtrl.value != XStatus.preparing,
      );
    }
  }

  Future<void> _waitForDisconnected() async {
    if (Tm.instance.state == TmStatus.disconnected) {
      return;
    }
    await Tm.instance.stateStream.firstWhere(
      (e) => e.status == TmStatus.disconnected,
    );
  }

  Future<List<String>> getCurrentSelectors() async {
    if (_pref.routingMode is DefaultRouteMode) {
      return [defaultProxySelectorTag];
    } else {
      final customRouteMode = await _databaseProvider
          .database
          .managers
          .customRouteModes
          .filter((e) => e.name.equals(_pref.routingMode as String))
          .getSingleOrNull();
      if (customRouteMode != null) {
        return customRouteMode.getSelectorTags();
      }
    }
    return [];
  }

  // when selector's strategy or land handlers is changed
  Future<void> selectorSelectStrategyOrLandhandlerChange(
    SelectorConfig selector,
  ) async {
    logger.d('selector select strategy or land handler change');
    await waitForConnectedIfConnecting();
    if (Tm.instance.state == TmStatus.connected) {
      if ((await getCurrentSelectors()).contains(selector.tag)) {
        try {
          final client = await getXClient();
          await client.changeSelector(
            ChangeSelectorRequest(selectorsToAdd: [selector]),
          );
          if (selector.tag == defaultProxySelectorTag) {
            if (selector.strategy !=
                    SelectorConfig_SelectingStrategy.MOST_THROUGHPUT &&
                selector.strategy !=
                    SelectorConfig_SelectingStrategy.LEAST_PING) {
              _handlerBeingUsedController.add(HandlerBeingUsed());
            }
          }

          await _getTmConfig();
        } catch (e) {
          stop();
          rethrow;
        }
      }
    }
  }

  Future<void> selectorFilterChange(SelectorConfig selector) async {
    logger.d('selector filter change');
    await waitForConnectedIfConnecting();
    if (Tm.instance.state == TmStatus.connected) {
      if ((await getCurrentSelectors()).contains(selector.tag)) {
        try {
          final client = await getXClient();
          await client.updateSelectorFilter(
            UpdateSelectorFilterRequest(
              tag: selector.tag,
              filter: selector.filter,
            ),
          );
          await _getTmConfig();
        } catch (e) {
          stop();
          rethrow;
        }
      }
    }
  }

  Future<void> selectorBalancingStrategyChange(
    String tag,
    SelectorConfig_BalanceStrategy balanceStrategy,
  ) async {
    logger.d('selector balancing strategy change');
    await waitForConnectedIfConnecting();
    if (Tm.instance.state == TmStatus.connected) {
      if ((await getCurrentSelectors()).contains(tag)) {
        try {
          final client = await getXClient();
          await client.updateSelectorBalancer(
            UpdateSelectorBalancerRequest(
              tag: tag,
              balanceStrategy: balanceStrategy,
            ),
          );
          await _getTmConfig();
        } catch (e) {
          stop();
          rethrow;
        }
      }
    }
  }

  Future<void> selectorRemove(String tag) async {
    await waitForConnectedIfConnecting();
    if (Tm.instance.state == TmStatus.connected) {
      try {
        final client = await getXClient();
        await client.changeSelector(
          ChangeSelectorRequest(selectorToRemove: tag),
        );
        await _getTmConfig();
      } catch (e) {
        stop();
        rethrow;
      }
    }
  }

  Future<void> setFakeDns(bool enable) async {
    await waitForConnectedIfConnecting();
    try {
      if (Tm.instance.state == TmStatus.connected) {
        final client = await getXClient();
        client.switchFakeDns(SwitchFakeDnsRequest(enable: enable));
        await _getTmConfig();
      }
    } catch (e) {
      stop();
      rethrow;
    }
  }

  Future<void> routingModeChange(
    String? oldRouteMode,
    String newRouteMode,
  ) async {
    await waitForConnectedIfConnecting();
    if (Tm.instance.state == TmStatus.connected) {
      if (oldRouteMode is DefaultRouteMode &&
          newRouteMode is DefaultRouteMode) {
        try {
          final config = await _getTmConfig();
          final client = await getXClient();
          client.changeRoutingMode(
            ChangeRoutingModeRequest(
              geoConfig: config.geo,
              routerConfig: config.router,
            ),
          );
        } catch (e) {
          stop();
          rethrow;
        }
      } else {
        await restart();
      }
    }
  }

  Future<void> _replaceNodeSet() async {
    if (_statusStreamCtrl.value == XStatus.connected) {
      final (nodeDomainSet, nodeIpSet) = await _xConfigHelper.getNodeSet();
      final client = await getXClient();
      await client.replaceGeoDomains(
        ReplaceDomainSetRequest(set: nodeDomainSet),
      );
      await client.replaceGeoIPs(ReplaceIPSetRequest(set: nodeIpSet));
    }
  }

  void handlerAdded() async {
    await notifyHandlerChange();
    if (!_androidUseRemoteDb()) {
      return;
    }
    await _syncHandlersToCore(
      storeChange: ChangeHandlerStoreRequest(
        deleteAll: true,
        outboundHandlers: await _xConfigHelper.getOutboundHandlers(),
      ),
    );
    await _replaceNodeSet();
  }

  Future<void> notifyHandlerChange() async {
    await waitForConnectedIfConnecting();
    if (Tm.instance.state == TmStatus.connected) {
      final client = await getXClient();
      await client.notifyHandlerChange(HandlerChangeNotify());
    }
  }

  Future<void> handlerSelectedChange() async {
    await notifyHandlerChange();
    if (!_androidUseRemoteDb()) {
      return;
    }
    await _syncHandlersToCore(
      storeChange: ChangeHandlerStoreRequest(
        deleteAll: true,
        outboundHandlers: await _xConfigHelper.getOutboundHandlers(),
      ),
    );
  }

  Future<void> handlersRemoved(List<int> ids) async {
    await notifyHandlerChange();
    if (!_androidUseRemoteDb()) {
      return;
    }
    final tags = ids.map((id) => '$id').toList();
    await _syncHandlersToCore(
      storeChange: ChangeHandlerStoreRequest(tags: tags),
    );
    await _replaceNodeSet();
  }

  void handlerUpdated(OutboundHandler handler) async {
    await notifyHandlerChange();
    if (!_androidUseRemoteDb()) {
      return;
    }
    await _syncHandlersToCore(
      storeChange: ChangeHandlerStoreRequest(
        tags: ['${handler.id}'],
        outboundHandlers: [await _xConfigHelper.outboundHandler(handler)],
      ),
    );
    await _replaceNodeSet();
  }

  void subscriptionUpdated() async {
    await notifyHandlerChange();
    if (!_androidUseRemoteDb()) {
      return;
    }
    await _syncHandlersToCore(
      storeChange: ChangeHandlerStoreRequest(
        deleteAll: true,
        outboundHandlers: await _xConfigHelper.getOutboundHandlers(),
      ),
    );
    await _replaceNodeSet();
  }

  Future<void> _syncHandlersToCore({
    required ChangeHandlerStoreRequest storeChange,
  }) async {
    await waitForConnectedIfConnecting();
    if (Tm.instance.state != TmStatus.connected) {
      return;
    }
    final client = await getXClient();
    await client.changeHandlerStore(storeChange);
    await _getTmConfig();
  }

  void setSubscriptionInterval(int interval) async {
    await waitForConnectedIfConnecting();
    if (Tm.instance.state == TmStatus.connected) {
      final client = await getXClient();
      client.setSubscriptionInterval(
        SetSubscriptionIntervalRequest(interval: interval),
      );
    }
  }

  Future<void> updateHandlerSpeed(String tag, int speed) async {
    if (Tm.instance.state == TmStatus.connected) {
      final client = await getXClient();
      client.setOutboundHandlerSpeed(
        SetOutboundHandlerSpeedRequest(tag: tag, speed: speed),
      );
    }
  }

  Future<void> onSystemProxyChange() async {
    await waitForConnectedIfConnecting();
    if (Tm.instance.state == TmStatus.connected) {
      final client = await getXClient();
      final config = await _getTmConfig();
      if (_pref.proxyShare) {
        try {
          await client.addInbound(
            AddInboundRequest(
              handlerConfig: config.inboundManager.handlers.firstWhere(
                (c) => c.tag == 'proxyShare',
              ),
            ),
          );
          logger.d("proxyShare inbound added");
        } catch (e) {
          logger.d("add proxyShare inbound error", error: e);
        }
      } else {
        try {
          await client.removeInbound(RemoveInboundRequest(tag: 'proxyShare'));
          logger.d("proxyShare inbound removed");
        } catch (e) {
          logger.d("remove proxyShare inbound error", error: e);
        }
      }
    }
  }

  Future<void> setSubscriptionAutoUpdate(bool autoUpdate) async {
    await waitForConnectedIfConnecting();
    if (Tm.instance.state == TmStatus.connected) {
      final client = await getXClient();
      client.setAutoSubscriptionUpdate(
        SetAutoSubscriptionUpdateRequest(enable: autoUpdate),
      );
    }
  }

  bool restarting = false;
  Future<void> restart() async {
    if (restarting) {
      return;
    }
    restarting = true;
    try {
      await waitForConnectedIfConnecting();
      if (Tm.instance.state == TmStatus.connected) {
        await stop();
        await _waitForDisconnected();
        await start();
      }
    } catch (e) {
      rethrow;
    } finally {
      restarting = false;
    }
  }

  Future<int> rttTest(String addr, int port) async {
    await waitForConnectedIfConnecting();
    if (Tm.instance.state == TmStatus.connected) {
      final client = await getXClient();
      return (await client.rttTest(
        RttTestRequest(addr: addr, port: port),
      )).ping;
    }
    throw Exception("not connected");
  }

  Future<Map<String, List<String>>> selectedHandlers() async {
    await waitForConnectedIfConnecting();
    if (Tm.instance.state == TmStatus.connected) {
      final client = await getXClient();
      final response = await client.selectedHandlers(SelectedHandlersRequest());
      return response.selectedHandlers.map(
        (key, value) => MapEntry(key, value.strings),
      );
    }
    throw Exception("not connected");
  }

  Future<List<String>> outboundHandlers() async {
    await waitForConnectedIfConnecting();
    if (Tm.instance.state == TmStatus.connected) {
      final client = await getXClient();
      final response = await client.currentOutbound(CurrentOutboundRequest());
      return response.outboundTags;
    }
    throw Exception("not connected");
  }
}

class _SudoPasswordDialog extends StatefulWidget {
  const _SudoPasswordDialog();

  @override
  State<_SudoPasswordDialog> createState() => __SudoPasswordDialogState();
}

class __SudoPasswordDialogState extends State<_SudoPasswordDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberPassword = false;

  @override
  void initState() {
    super.initState();
    _rememberPassword = context
        .read<SharedPreferences>()
        .storeSudoPasswordInMemory;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.sudoPassword),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _passwordController,
            obscureText: true,
            onEditingComplete: () {
              Navigator.of(
                context,
              ).pop((_passwordController.text, _rememberPassword));
            },
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.sudoPassword,
              border: const OutlineInputBorder(),
            ),
          ),
          const Gap(10),
          Row(
            children: [
              Text(AppLocalizations.of(context)!.rememberPasswordInMemory),
              const Gap(10),
              const Spacer(),
              Switch(
                value: _rememberPassword,
                onChanged: (value) {
                  setState(() {
                    _rememberPassword = value;
                    context
                        .read<SharedPreferences>()
                        .setStoreSudoPasswordInMemory(value);
                  });
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop((_passwordController.text, _rememberPassword));
          },
          child: Text(AppLocalizations.of(context)!.confirm),
        ),
      ],
    );
  }
}
