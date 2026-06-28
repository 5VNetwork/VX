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

import 'package:device_info_plus/device_info_plus.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:grpc/grpc.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/app/api/api.pbgrpc.dart';
import 'package:tm/protos/vx/common/geo/geo.pb.dart';
import 'package:tm/protos/vx/geo/geo.pb.dart';
import 'package:tm/protos/vx/inbound/inbound.pb.dart';
import 'package:tm/protos/vx/log/logger.pb.dart';
import 'package:tm/protos/vx/outbound/outbound.pb.dart';
import 'package:tm/protos/vx/server.pb.dart';
import 'package:tm/protos/vx/sysproxy/sysproxy.pb.dart';
import 'package:tm/protos/vx/transport/security/tls/certificate.pb.dart';
import 'package:tm/tm.dart';
import 'package:vx/app/server/add_server.dart';
import 'package:vx/data/ssh_server.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/channel_credentials.dart';
import 'package:vx/utils/logger.dart';
import 'package:flutter_common/util/net.dart';
import 'package:vx/data/database.dart';
import 'package:vx/main.dart';
import 'package:vx/utils/path.dart';
import 'package:vx/utils/x_api_bindings_generated.dart';
import 'package:vx/utils/x_api_linux_bindings_generated.dart';
import 'package:vx/xconfig_helper.dart';

class XApiClient {
  late ClientChannel _grpcChannel;
  late StreamSubscription<TmStatusChange> _tmStateSubscription;
  late ApiClient _xApiClient;
  final Completer<void> _completer = Completer();

  XApiClient(SharedPreferences pref, FlutterSecureStorage storage)
    : _pref = pref,
      _storage = storage;
  final SharedPreferences _pref;
  final FlutterSecureStorage _storage;

  /// Must be called before using this client
  Future<void> init() async {
    try {
      late String listenAddress;
      final certificate = await getCertificate();
      final channelCredentials = MyChannelCredentials.secure(
        clientCertBytes: Uint8List.fromList(certificate.certificate),
        clientCertPrivateKeyBytes: Uint8List.fromList(certificate.key),
        badCertificate: (certificate, host) {
          return true;
        },
      );
      late LoggerConfig logConfig;
      if (isProduction()) {
        if (_pref.enableDebugLog) {
          logConfig = LoggerConfig(
            logLevel: Level.DEBUG,
            consoleWriter: true,
            showCaller: true,
            showColor: true,
            filePath: await getDebugFlutterLogDir().then(
              (value) => join(value.path, 'vx-go.txt'),
            ),
          );
        } else {
          logConfig = LoggerConfig(logLevel: Level.DISABLED);
        }
      } else {
        logConfig = LoggerConfig(
          logLevel: Level.DEBUG,
          consoleWriter: true,
          showCaller: true,
          showColor: true,
        );
      }
      if (Platform.isMacOS ||
          (Platform.isIOS) ||
          Platform.isAndroid ||
          Platform.isLinux) {
        // if using support dir, listenUnix on ios fails
        // if use getCacheDir, ios bind returns error(invalid argument,
        // probably due to long path)
        if (await isIOSSimulator()) {
          listenAddress = '127.0.0.1:21426';
        } else {
          final dir = (await getApplicationDocumentsDirectory()).path;
          listenAddress = join(dir, 'xapi.sock');
        }

        final config = ApiServerConfig(
          logConfig: logConfig,
          // dbPath: await getDbPath(_pref),
          listenAddr: listenAddress,
          bindToDefaultNic:
              (Platform.isIOS || Platform.isMacOS || Platform.isLinux),
          tunName: Platform.isIOS || Platform.isMacOS
              ? "utun"
              : XConfigHelper.tunName,
          geoipPath: await getGeoIPPath(),
        );
        config.clientCert = certificate.certificate;
        if (Platform.isIOS || Platform.isMacOS) {
          await darwinHostApi!.startXApiServer(config.writeToBuffer());
        } else if (Platform.isAndroid) {
          await androidHostApi!.startXApiServer(config.writeToBuffer());
        } else {
          final so = DynamicLibrary.open(getSoPath());
          final bindings = XApiLinuxBindings(so);
          final cfgRaw = config.writeToBuffer();
          final cfgPtr = calloc<Uint8>(cfgRaw.length);
          for (var i = 0; i < cfgRaw.length; i++) {
            cfgPtr[i] = cfgRaw[i];
          }
          final errStrPtr = bindings.StartApiServer(
            cfgPtr.cast<Void>(),
            cfgRaw.length,
          );
          final errStr = errStrPtr.cast<Utf8>().toDartString();
          bindings.FreeString(errStrPtr);
          calloc.free(cfgPtr);
          if (errStr.isNotEmpty) {
            throw Exception(errStr);
          }
        }
        if (listenAddress.startsWith('127.0.0.1:')) {
          final channelOptions = ChannelOptions(
            credentials: channelCredentials,
          );
          _grpcChannel = ClientChannel(
            InternetAddress('127.0.0.1'),
            port: 21426,
            options: channelOptions,
          );
        } else {
          _grpcChannel = ClientChannel(
            InternetAddress(listenAddress, type: InternetAddressType.unix),
            options: ChannelOptions(credentials: channelCredentials),
          );
        }
        _xApiClient = ApiClient(_grpcChannel);
      }
      if (Platform.isWindows) {
        logger.d('current working directory: ${Directory.current.path}');
        final dll = DynamicLibrary.open(getDllPath());
        final bindings = XApiBindings(dll);
        int port = 0;
        bool success = false;
        for (var i = 0; i < 5; i++) {
          try {
            port = await getUnusedPort();
            listenAddress = '127.0.0.1:$port';
            final config = ApiServerConfig(
              logConfig: logConfig,
              // dbPath: await getDbPath(_pref),
              // bindToDefaultNic: true,
              listenAddr: listenAddress,
              tunName: XConfigHelper.tunName,
              geoipPath: await getGeoIPPath(),
            );
            config.clientCert = certificate.certificate;
            final cfgRaw = config.writeToBuffer();
            final cfgPtr = calloc<Uint8>(cfgRaw.length);
            for (var i = 0; i < cfgRaw.length; i++) {
              cfgPtr[i] = cfgRaw[i];
            }
            final errStrPtr = bindings.StartApiServer(
              cfgPtr.cast<Void>(),
              cfgRaw.length,
            );
            final errStr = errStrPtr.cast<Utf8>().toDartString();
            bindings.FreeString(errStrPtr);
            calloc.free(cfgPtr);
            if (errStr.isNotEmpty) {
              throw Exception(errStr);
            }
            success = true;
            break;
          } catch (e) {
            logger.d("xapi client start error", error: e);
          }
        }
        if (!success) {
          throw Exception(
            "xapi client start failed, no available port found in 5 attempts",
          );
        }
        final channelOptions = ChannelOptions(credentials: channelCredentials);
        _grpcChannel = ClientChannel(
          InternetAddress('127.0.0.1'),
          port: port,
          options: channelOptions,
        );
        _xApiClient = ApiClient(_grpcChannel);
        logger.d("xapi client started");
      }
      _completer.complete();
      // inform tm status
      _tmStateSubscription = Tm.instance.stateStream.listen((state) async {
        if (state.status == TmStatus.connected) {
          _xApiClient.updateTmStatus(UpdateTmStatusRequest(on: true));
        } else if (state.status == TmStatus.disconnected) {
          _xApiClient.updateTmStatus(UpdateTmStatusRequest(on: false));
        }
      });
    } catch (e) {
      _completer.completeError(e);
      // TODO: show error dialog
      logger.e("xapi client init error", error: e);
      reportError("xapi client init error", e);
      // disk I/O error: no such file or directory
      if (e.toString().contains('disk I/O error: no such file or directory')) {
        //TODO: recreate database
      }
      if (rootNavigationKey.currentContext != null) {
        fatalMessageDialog(
          rootLocalizations()?.fatalError(
                rootLocalizations()?.failedToInitGrpcClient(e.toString()) ??
                    e.toString(),
              ) ??
              e.toString(),
        );
      } else {
        fatalErrorMessage = e.toString();
      }
      rethrow;
    }
  }

  Future<void> _stop() async {
    await _grpcChannel.shutdown();
    _tmStateSubscription.cancel();
  }

  Future<Certificate> getCertificate() async {
    if (Platform.isWindows) {
      final dll = DynamicLibrary.open(getDllPath());
      final bindings = XApiBindings(dll);
      final ret = bindings.GenerateTls();
      final errStrPtr = ret.r2;
      final errStr = errStrPtr.cast<Utf8>().toDartString();
      bindings.FreeString(errStrPtr);
      if (errStr.isNotEmpty) {
        throw Exception(errStr);
      }
      final certificateBytesPointer = ret.r0;
      final certificateBytes = certificateBytesPointer
          .cast<Uint8>()
          .asTypedList(ret.r1);
      final certificate = Certificate.fromBuffer(certificateBytes);
      bindings.FreeBytes(certificateBytesPointer);
      return certificate;
    } else if (Platform.isLinux) {
      final dll = DynamicLibrary.open(getSoPath());
      final bindings = XApiLinuxBindings(dll);
      final ret = bindings.GenerateTls();
      final errStrPtr = ret.r2;
      final errStr = errStrPtr.cast<Utf8>().toDartString();
      bindings.FreeString(errStrPtr);
      if (errStr.isNotEmpty) {
        throw Exception(errStr);
      }
      final certificateBytesPointer = ret.r0;
      final certificateBytes = certificateBytesPointer
          .cast<Uint8>()
          .asTypedList(ret.r1);
      final certificate = Certificate.fromBuffer(certificateBytes);
      bindings.FreeBytes(certificateBytesPointer);
      return certificate;
    } else if (Platform.isMacOS || Platform.isIOS) {
      final ret = await darwinHostApi!.generateTls();
      final certificate = Certificate.fromBuffer(ret);
      return certificate;
    } else {
      final ret = await androidHostApi!.generateTls();
      final certificate = Certificate.fromBuffer(ret);
      return certificate;
    }
  }

  Future<DownloadResponse> download(DownloadRequest request) async {
    await _completer.future;
    return await _xApiClient.download(request);
  }

  /// Try to get handler usability, retry once if failed
  Future<HandlerUsableResponse> handlerUsable(
    HandlerUsableRequest request,
  ) async {
    await _completer.future;
    return await _xApiClient.handlerUsable(request);
  }

  Future<HandlerCountryTestResponse> handlerCountryTest(
    HandlerCountryTestRequest request,
  ) async {
    await _completer.future;
    return await _xApiClient.handlerCountryTest(request);
  }

  Future<int> rtt(RttTestRequest request) async {
    await _completer.future;
    return (await _xApiClient.rttTest(request)).ping;
  }

  Future<ResponseStream<SpeedTestResponse>> speedTest(
    SpeedTestRequest request,
  ) async {
    await _completer.future;
    return _xApiClient.speedTest(request);
  }

  // Future<GeoIPResponse> geoIP(GeoIPRequest request) async {
  //   await _completer.future;
  //   if (!File(await getGeoIPPath()).existsSync()) {
  //     snack(rootLocalizations()?.geoSiteOrGeoIPFileNotFound,
  //         duration: const Duration(seconds: 60));
  //     try {
  //       await geoDataHelper.downloadAndProcessGeo();
  //       rootScaffoldMessengerKey.currentState?.removeCurrentSnackBar();
  //     } catch (e) {
  //       logger.e('downloadAndProcessGeo error', error: e);
  //       snack(rootLocalizations()?.failedToDownloadGeoData(e.toString()));
  //     }
  //   }
  //   return await _xApiClient.geoIP(request);
  // }

  //TODO:
  Future<ResponseStream<MonitorServerResponse>> monitorServer(
    SshServer server,
  ) async {
    final config = await _sshServerToServerSshConfig(server);
    return _xApiClient.monitorServer(
      MonitorServerRequest(interval: 5, sshConfig: config),
    );
  }

  Future<VproxyStatusResponse> vproxyStatus(SshServer server) async {
    await _completer.future;
    final config = await _sshServerToServerSshConfig(server);
    return await _xApiClient.vproxyStatus(
      VproxyStatusRequest(sshConfig: config),
    );
  }

  Future<ServerConfig> serverConfig(SshServer server) async {
    await _completer.future;
    final config = await _sshServerToServerSshConfig(server);
    return (await _xApiClient.serverConfig(
      ServerConfigRequest(sshConfig: config),
    )).config;
  }

  Future<String> serverConfigJson(SshServer server) async {
    await _completer.future;
    final sshConfig = await _sshServerToServerSshConfig(server);
    return (await _xApiClient.serverConfigJson(
      ServerConfigRequest(sshConfig: sshConfig),
    )).configJson;
  }

  Future<void> updateServerConfig(SshServer server, ServerConfig config) async {
    await _completer.future;
    final sshConfig = await _sshServerToServerSshConfig(server);
    await _xApiClient.updateServerConfig(
      UpdateServerConfigRequest(sshConfig: sshConfig, config: config),
    );
  }

  Future<void> updateServerConfigJson(
    SshServer server,
    String configJson,
  ) async {
    await _completer.future;
    final sshConfig = await _sshServerToServerSshConfig(server);
    await _xApiClient.updateServerConfigJson(
      UpdateServerConfigJsonRequest(
        sshConfig: sshConfig,
        configJson: configJson,
      ),
    );
  }

  Future<List<OutboundHandlerConfig>> convertInboundToOutbound(
    SshServer server, {
    ProxyInboundConfig? inbound,
    MultiProxyInboundConfig? multiInbound,
  }) async {
    await _completer.future;
    final response = await _xApiClient.inboundConfigToOutboundConfig(
      InboundConfigToOutboundConfigRequest(
        serverAddress: server.address,
        serverName: server.name,
        inbound: inbound,
        multiInbound: multiInbound,
      ),
    );
    return response.outboundConfigs;
  }

  Future<List<OutboundHandlerConfig>> inboundConfigToOutboundConfig(
    String serverName,
    String serverAddress,
    ProxyInboundConfig? inbound,
    MultiProxyInboundConfig? multiInbound,
  ) async {
    await _completer.future;
    final response = await _xApiClient.inboundConfigToOutboundConfig(
      InboundConfigToOutboundConfigRequest(
        serverName: serverName,
        serverAddress: serverAddress,
        inbound: inbound,
        multiInbound: multiInbound,
      ),
    );
    return response.outboundConfigs;
  }

  Future<void> vx(
    SshServer server, {
    bool? start,
    bool? stop,
    bool? restart,
    bool? update,
    bool? uninstall,
  }) async {
    await _completer.future;
    final config = await _sshServerToServerSshConfig(server);
    await _xApiClient.vX(
      VXRequest(
        sshConfig: config,
        start: start,
        stop: stop,
        restart: restart,
        update: update,
        uninstall: uninstall,
      ),
    );
  }

  Future<ServerSshConfig> _sshServerToServerSshConfig(SshServer server) async {
    final serverSecureStorageJson = await _storage.read(key: server.storageKey);
    if (serverSecureStorageJson == null) {
      throw Exception('Auth secret not found');
    }
    final serverSecureStorage = SshServerSecureStorage.fromJson(
      jsonDecode(serverSecureStorageJson),
    );
    String? passphrase = serverSecureStorage.passphrase;
    List<int>? sshKey;
    if (server.authMethod == AuthMethod.sshKey) {
      if (serverSecureStorage.sshKey != null) {
        sshKey = utf8.encode(serverSecureStorage.sshKey!);
      } else if (serverSecureStorage.sshKeyPath != null) {
        sshKey = await File(serverSecureStorage.sshKeyPath!).readAsBytes();
      } else {
        assert(
          serverSecureStorage.globalSshKeyName != null &&
              serverSecureStorage.globalSshKeyName!.isNotEmpty,
        );
        final commonSshKeySecureStorageJson = await _storage.read(
          key: 'common_ssh_key_${serverSecureStorage.globalSshKeyName}',
        );
        if (commonSshKeySecureStorageJson == null) {
          throw Exception('Common ssh key not found');
        }
        final commonSshKeySecureStorage = SshServerSecureStorage.fromJson(
          jsonDecode(commonSshKeySecureStorageJson),
        );
        passphrase = commonSshKeySecureStorage.passphrase;
        if (commonSshKeySecureStorage.sshKey != null) {
          sshKey = utf8.encode(commonSshKeySecureStorage.sshKey!);
        } else if (commonSshKeySecureStorage.sshKeyPath != null) {
          sshKey = await File(
            commonSshKeySecureStorage.sshKeyPath!,
          ).readAsBytes();
        } else {
          throw Exception('invalid common ssh key');
        }
      }
    }
    List<int>? serverPubKey;
    if (serverSecureStorage.pubKey != null &&
        serverSecureStorage.pubKey!.isNotEmpty) {
      serverPubKey = base64Decode(serverSecureStorage.pubKey!);
    } else {
      final response = await _xApiClient.getServerPublicKey(
        GetServerPublicKeyRequest(
          sshConfig: ServerSshConfig(
            address: server.address,
            port: serverSecureStorage.port,
            username: serverSecureStorage.user,
            sudoPassword: serverSecureStorage.password,
            sshKey: sshKey,
            sshKeyPassphrase: passphrase,
          ),
        ),
      );
      serverSecureStorage.pubKey = base64Encode(response.publicKey);
      _storage.write(
        key: server.storageKey,
        value: jsonEncode(serverSecureStorage.toJson()),
      );
      serverPubKey = response.publicKey;
    }

    return ServerSshConfig(
      address: server.address,
      port: serverSecureStorage.port,
      username: serverSecureStorage.user,
      sudoPassword: serverSecureStorage.password,
      sshKey: sshKey,
      sshKeyPassphrase: passphrase,
      serverPubKey: serverPubKey,
    );
  }

  Future<UpdateSubscriptionResponse> updateSubscriptions(
    UpdateSubscriptionRequest request,
  ) async {
    await _completer.future;

    return await _xApiClient.updateSubscription(request);
    // // all other handlers
    // final handlers = await outboundRepo.getHandlers(usableNotEqual: 1);
    // req.handlers.clear();
    // req.handlers.addAll(handlers.map((e) => e.toConfig()));
    // return await _xApiClient.updateSubscription(req);
  }

  Future<FetchSubscriptionContentResponse> fetchSubscriptionContent(
    FetchSubscriptionContentRequest request,
  ) async {
    await _completer.future;
    return await _xApiClient.fetchSubscriptionContent(request);
  }

  //TODO: simplify more for category-games:cn
  Future<void> processGeoFiles() async {
    await _completer.future;
    final geositePath = await getGeositePath();
    final geoIpPath = await getGeoIPPath();
    await _xApiClient.processGeoFiles(
      ProcessGeoFilesRequest(
        geoipPath: geoIpPath,
        geositePath: geositePath,
        dstGeoipPath: await getSimplifiedGeoIPPath(),
        dstGeositePath: await getSimplifiedGeositePath(),
        geositeCodes: simplifiedGeoSiteCodes,
        geoipCodes: simplifiedGeoIpCodes,
      ),
    );
  }

  Future<DecodeResponse> decode(
    String data, {
    Map<String, String> shareLinkQueryExtra = const {},
  }) async {
    await _completer.future;
    final req = DecodeRequest(data: data);
    req.shareLinkQueryExtra.addAll(shareLinkQueryExtra);
    return await _xApiClient.decode(req);
  }

  Future<DeployResponse> deploy({
    required SshServer server,
    Uint8List? xrayConfig,
    Uint8List? hysteriaConfig,
    ServerConfig? serverConfig,
    Map<String, Uint8List>? files,
    bool? disableOSFirewall,
  }) async {
    await _completer.future;
    final req = DeployRequest(
      sshConfig: await _sshServerToServerSshConfig(server),
      xrayConfig: xrayConfig,
      hysteriaConfig: hysteriaConfig,
      vxConfig: serverConfig,
      disableFirewall: disableOSFirewall,
    );
    req.files.addAll(files ?? {});
    return await _xApiClient.deploy(req);
  }

  Future<GenerateCertResponse> generateCert(String domain) async {
    await _completer.future;
    final response = await _xApiClient.generateCert(
      GenerateCertRequest(domain: domain),
    );
    return response;
  }

  Future<String?> extractCertDomain(String cert) async {
    try {
      await _completer.future;
      final response = await _xApiClient.getCertDomain(
        GetCertDomainRequest(cert: utf8.encode(cert)),
      );
      return response.domain;
    } catch (e) {
      logger.e('extractCertDomain error', error: e);
      return null;
    }
  }

  Future<void> shutdownServer(SshServer server) async {
    await _completer.future;
    final req = ServerActionRequest(
      sshConfig: await _sshServerToServerSshConfig(server),
      action: ServerActionRequest_Action.ACTION_SHUTDOWN,
    );
    await _xApiClient.serverAction(req);
  }

  Future<void> restartServer(SshServer server) async {
    await _completer.future;
    final req = ServerActionRequest(
      sshConfig: await _sshServerToServerSshConfig(server),
      action: ServerActionRequest_Action.ACTION_RESTART,
    );
    await _xApiClient.serverAction(req);
  }

  Future<void> uploadLog(UploadLogRequest req) async {
    await _completer.future;
    await _xApiClient.uploadLog(req);
  }

  Future<bool> defaultNICHasGlobalV6() async {
    await _completer.future;
    final response = await _xApiClient.defaultNICHasGlobalV6(
      DefaultNICHasGlobalV6Request(),
    );
    logger.i('defaultNICHasGlobalV6: ${response.hasGlobalV6}');

    return response.hasGlobalV6;
  }

  Future<ParseClashRuleFileResponse> parseClashRuleFile(
    List<int> content,
  ) async {
    await _completer.future;
    return await _xApiClient.parseClashRuleFile(
      ParseClashRuleFileRequest(content: content),
    );
  }

  Future<List<CIDR>> parseGeoIPConfig(GeoIPConfig config) async {
    await _completer.future;
    return (await _xApiClient.parseGeoIPConfig(
      ParseGeoIPConfigRequest(config: config),
    )).cidrs;
  }

  Future<List<Domain>> parseGeositeConfig(GeositeConfig config) async {
    await _completer.future;
    return (await _xApiClient.parseGeositeConfig(
      ParseGeositeConfigRequest(config: config),
    )).domains;
  }

  Future<(String, String)> generateX25519KeyPair() async {
    await _completer.future;
    final response = await _xApiClient.generateX25519KeyPair(
      GenerateX25519KeyPairRequest(),
    );
    return (response.pub, response.pri);
  }

  Future<void> setSystemProxy(SysProxyConfig config) async {
    await _completer.future;
    await _xApiClient.startMacSystemProxy(
      StartMacSystemProxyRequest(
        socksProxyAddress: '127.0.0.1',
        socksProxyPort: config.socksProxyPort,
        httpProxyAddress: '127.0.0.1',
        httpProxyPort: config.httpProxyPort,
      ),
    );
  }

  Future<void> stopSystemProxy() async {
    await _completer.future;
    await _xApiClient.stopMacSystemProxy(StopMacSystemProxyRequest());
  }

  Future<void> closeDb() async {
    // await _completer.future;
    // await _xApiClient.closeDb(CloseDbRequest());
  }

  Future<void> openDb() async {
    // await _completer.future;
    // await _xApiClient.openDb(OpenDbRequest(path: await getDbPath(_pref)));
  }

  Future<ToUrlResponse> toUrl(List<OutboundHandlerConfig> configs) async {
    await _completer.future;
    final response = await _xApiClient.toUrl(
      ToUrlRequest(outboundConfogs: configs),
    );
    return response;
  }

  Future<GenerateECHResponse> generateECHResponse(String domain) async {
    await _completer.future;
    return await _xApiClient.generateECH(GenerateECHRequest(domain: domain));
  }

  Future<void> setLog(LoggerConfig logConfig) async {
    await _completer.future;
    await _xApiClient.setLog(logConfig);
  }
}

Future<bool> isIOSSimulator() async {
  if (Platform.isIOS) {
    final deviceInfo = DeviceInfoPlugin();
    final iosInfo = await deviceInfo.iosInfo;
    return !iosInfo.isPhysicalDevice; // true if simulator, false if real device
  }
  return false;
}

const simplifiedGeoSiteCodes = [
  'cn',
  'apple-cn',
  'tld-cn',
  'private',
  'category-games',
  'gfw',
];
const simplifiedGeoIpCodes = [
  'cn',
  'private',
  'telegram',
  'google',
  'facebook',
  'twitter',
  "tor",
];
