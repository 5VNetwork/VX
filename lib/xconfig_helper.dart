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

import 'package:drift/drift.dart';
import 'package:installed_apps/index.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/vx/common/geo/geo.pb.dart';
import 'package:tm/protos/vx/common/net/net.pb.dart';
import 'package:tm/protos/vx/dispatcher/dispatcher.pb.dart';
import 'package:tm/protos/vx/transport/dlhelper.pb.dart';
import 'package:tm/protos/vx/dns/dns.pb.dart';
import 'package:tm/protos/vx/geo/geo.pb.dart';
import 'package:tm/protos/vx/grpc/grpc_service.pb.dart';
import 'package:tm/protos/vx/inbound/inbound.pb.dart';
import 'package:tm/protos/vx/log/logger.pb.dart' as l;
import 'package:tm/protos/vx/client.pb.dart' as core;
import 'package:tm/protos/vx/proxy/freedom/freedom.pb.dart';
import 'package:tm/protos/vx/proxy/http/http.pb.dart';
import 'package:tm/protos/vx/proxy/socks/socks.pb.dart';
import 'package:tm/protos/vx/outbound/outbound.pb.dart' as o;
import 'package:tm/protos/vx/policy.pb.dart';
import 'package:tm/protos/vx/router/router.pb.dart';
import 'package:tm/protos/vx/sysproxy/sysproxy.pb.dart';
import 'package:tm/protos/vx/transport/transport.pb.dart';
import 'package:tm/protos/vx/dialerfactory/dialerfactory.pb.dart';
import 'package:tm/protos/vx/tun/tun.pb.dart';
import 'package:tm/protos/vx/subscription/subscription.pb.dart';
import 'package:tm/protos/vx/fallbackmon/fallbackmon.pb.dart';
import 'package:tm/protos/vx/grpc/grpc_server.pb.dart';
import 'package:vx/app/control.dart';
import 'package:vx/app/outbound/outbound_repo.dart';
import 'package:vx/app/routing/default.dart';
import 'package:vx/app/routing/routing_page.dart';
import 'package:vx/app/routing/selector_widget.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/common/common.dart';
import 'package:vx/data/realm_server_config.dart';
import 'package:vx/data/database_provider.dart';
import 'package:vx/main.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/download.dart';
import 'package:vx/utils/geodata.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/path.dart';
import 'package:vx/app/blocs/proxy_selector/proxy_selector_bloc.dart';
import 'package:vx/common/file.dart';
import 'package:flutter_common/util/net.dart';
import 'package:vx/common/net.dart';
import 'package:vx/utils/permission.dart';
import 'package:vx/utils/wintun.dart';
import 'package:vx/utils/xapi_client.dart';
import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart';

class ConfigException implements Exception {
  ConfigException(this.message);
  final String message;
}

/// Helper to generate configs of X.
/// To store latest config in app group container for macos
class XConfigHelper {
  XConfigHelper({
    required OutboundRepo outboundRepo,
    required SharedPreferences psr,
    required Downloader downloader,
    required GeoDataHelper geoDataHelper,
    required XApiClient xApiClient,
    required DatabaseProvider databaseProvider,
  }) : _outboundRepo = outboundRepo,
       _persistentStateRepo = psr,
       _downloader = downloader,
       _geoDataHelper = geoDataHelper,
       _xApiClient = xApiClient,
       _databaseProvider = databaseProvider;
  // final _outboundHandlerGroupBox = store.box<OHTag>();
  final OutboundRepo _outboundRepo;
  final SharedPreferences _persistentStateRepo;
  final Downloader _downloader;
  final GeoDataHelper _geoDataHelper;
  final XApiClient _xApiClient;
  final DatabaseProvider _databaseProvider;

  /// Return outbound handlers to use
  ///
  /// All enabled outbound handlers will be returned if outbound mode is auto
  /// Only selected outbound handlers will be returned if outbound mode is manual
  // Future<List<OutboundHandler>> getProxyOutboundHandler() async {
  //   if (_persistentStateRepo.outboundMode == OutboundMode.auto) {
  //     return _outboundRepo.getHandlers(enabled: true);
  //   } else {
  //     return _outboundRepo.getHandlers(selected: true);
  //   }
  // }

  Future<core.TmConfig> getConfig({
    Uint8List? certBytes,
    (String, int)? dbSecretAndPort,
  }) async {
    final inboundConfig = await _getInboundConfig();
    final dnsConfig = await _getDnsConfig();
    final (routerConfig, geoConfig) = await getRouterGeoConfig(dnsConfig);

    // TODO: I assume a server supports ipv4
    final config = core.TmConfig(
      inboundManager: inboundConfig,
      outbound: await _getOutboundConfig(routerConfig),
      tun: await _getTunConfig(routerConfig),
      wfp: await _getWfpConfig(),
      dns: dnsConfig,
      policy: _getPolicyConfig(),
      router: routerConfig,
      selectors: await getSelectorsConfig(routerConfig),
      log: await _getLoggerConfig(),
      geo: geoConfig,
      grpc: await _getGrpcConfig(certBytes: certBytes),
      dispatcher: _getDispatcherConfig(),
      subscription: isPkg ? null : await _getSubscriptionConfig(),
      dbPath: isPkg ? null : await getDbPath(_persistentStateRepo),
      serviceSecret: dbSecretAndPort?.$1,
      servicePort: dbSecretAndPort?.$2,
      defaultNicMonitor: true,
      sysProxy: _getSysProxyConfig(inboundConfig),
      grpcService: GrpcServiceConfig(
        updateLatency: _persistentStateRepo.pingMode == PingMode.Real,
      ),
      fallbackMon: _persistentStateRepo.automaticallyAddFallbackDomain
          ? FallbackMonConfig(domainSetName: 'Fallback')
          : null,
      userLog: l.UserLoggerConfig(
        enable: _persistentStateRepo.enableLog,
        logAppId: _persistentStateRepo.showApp,
        logSessionEnd: _persistentStateRepo.showSessionOngoing,
        logRealtimeUsage: _persistentStateRepo.showRealtimeUsage,
      ),
      dialerFactory: DialerFactoryConfig(
        dialTimeout: _persistentStateRepo.globalDialTimeout,
        shouldBindDevice: _persistentStateRepo.inboundMode == InboundMode.tun,
        resolveDomain: true,
      ),
    );
    // redirect std err
    if (!isProduction() ||
        _persistentStateRepo.shareLog ||
        _persistentStateRepo.enableDebugLog) {
      final dir = _persistentStateRepo.enableDebugLog
          ? await getDebugTunnelLogDir()
          : getTunnelLogDir();
      config.redirectStdErr = join((dir).path, await getLogFileName());
      // config.redirectStdErr = '/var/root/Library/Group Containers/K4FDLB3LLD.com.5vnetwork.x.system/Library/Application Support/v.log';
    }
    return config;
  }

  Future<String> getLogFileName() async {
    return "${(await PackageInfo.fromPlatform()).version}-${DateTime.now().toString().replaceAll(':', '_')}.txt";
  }

  Future<o.OutboundConfig> _getOutboundConfig(RouterConfig routerConfig) async {
    final config = o.OutboundConfig(
      hysteriaRejectQuic: _persistentStateRepo.rejectQuicHysteria,
      handlerLinkStats: true,
      handlerMeter: true,
      totalCounter: true,
      handlers: [
        o.HandlerConfig(
          outbound: o.OutboundHandlerConfig(
            tag: 'direct',
            protocol: Any.pack(FreedomConfig()),
            domainStrategy: o.DomainStrategy.Speed,
            transport: TransportConfig(
              socket: SocketConfig(
                dialTimeout: _persistentStateRepo.directDialingTimeout,
              ),
            ),
          ),
        ),
      ],
    );
    for (final rule in routerConfig.rules) {
      if (rule.outboundTag.isNotEmpty &&
          rule.outboundTag != directHandlerTag &&
          rule.outboundTag != _dnsTag) {
        final handler = await _outboundRepo.getHandlerById(
          int.parse(rule.outboundTag),
        );
        if (handler != null) {
          config.handlers.add(handler.toConfig());
        }
      }
      for (final fallback in rule.fallbacks) {
        if (fallback.outboundTag.isNotEmpty &&
            fallback.outboundTag != directHandlerTag &&
            fallback.outboundTag != _dnsTag) {
          final handler = await _outboundRepo.getHandlerById(
            int.parse(fallback.outboundTag),
          );
          if (handler != null) {
            config.handlers.add(handler.toConfig());
          }
        }
      }
    }
    return config;
  }

  Future<Directory> _configFileDir() async {
    return resourceDir();
  }

  /// returns the latest config, if isMacOS or isIOS store it in app group container.
  /// TODO: store using saveToPreferences
  /// should be called whenever config is changed
  Future<core.TmConfig> getAndOrStoreConfig({
    Uint8List? certBytes,
    (String, int)? dbSecretAndPort,
  }) async {
    final config = await getConfig(
      certBytes: certBytes,
      dbSecretAndPort: dbSecretAndPort,
    );

    if (!isPkg) {
      final configBytes = config.writeToBuffer();
      _configFileDir()
          .then((dir) {
            return atomicWriteToFile(dir, 'config', configBytes);
          })
          .catchError((e) {
            logger.e('storeConfig', error: e);
          });
    }

    return config;
  }

  DispatcherConfig _getDispatcherConfig() {
    final config = DispatcherConfig(
      ipv6UseDomain: _persistentStateRepo.changeIpv6ToDomain,
      sniff: _persistentStateRepo.sniff,
      fallbackTimeout: _persistentStateRepo.fallbackTimeout,
      sessionStats: true,
    );
    return config;
  }

  Future<SubscriptionConfig> _getSubscriptionConfig() async {
    final config = SubscriptionConfig(
      interval: _persistentStateRepo.updateInterval,
      periodicUpdate: _persistentStateRepo.autoUpdate,
    );
    return config;
  }

  static const tunName = 'VXTun';

  Future<WfpConfig?> _getWfpConfig() async {
    if (!Platform.isWindows ||
        _persistentStateRepo.inboundMode != InboundMode.wfp) {
      return null;
    }
    return WfpConfig(tcpPort: 12345, udpPort: 54321);
  }

  Future<TunConfig?> _getTunConfig(RouterConfig routerConfig) async {
    if (_persistentStateRepo.inboundMode != InboundMode.tun) {
      return null;
    }
    final mtu = _persistentStateRepo.tunMtu;

    // if (Platform.isWindows) {
    //   try {
    //     await makeWinTunAvailable(_downloader);
    //   } catch (e) {
    //     throw ConfigException('Wintun.dll download failed: $e');
    //   }
    // }

    final List<String> blackListApps = [];
    if (Platform.isAndroid) {
      bool directAppSetUsed = false;
      for (final rule in routerConfig.rules) {
        if (rule.appTags.contains(directAppSetName) ||
            rule.allTags.contains(directAppSetName)) {
          directAppSetUsed = true;
          break;
        }
      }
      if (directAppSetUsed) {
        // blackListApps.add(androidPackageNme);
        final apps = await _databaseProvider.database
            .select(_databaseProvider.database.apps)
            .get();
        final futures = <Future>[];
        for (final app in apps) {
          if (app.appSetName == directAppSetName &&
              app.appId.type == AppId_Type.Exact) {
            futures.add(
              InstalledApps.isAppInstalled(app.appId.value).then((installed) {
                if (installed != null && installed) {
                  blackListApps.add(app.appId.value);
                } else {
                  logger.d(
                    "App ${app.appId.value} is not installed, not adding to blacklist",
                  );
                }
              }),
            );
          }
        }
        await Future.wait(futures);
      }
    }

    return TunConfig(
      tag: 'tun',
      mode: Platform.isWindows || Platform.isAndroid || Platform.isLinux
          ? Mode.MODE_SYSTEM
          : Mode.MODE_GVISOR,
      tun46Setting: _persistentStateRepo.tun46Setting,
      rejectIpv6: _persistentStateRepo.rejectIpv6,
      device: TunDeviceConfig(
        name: tunName,
        mtu: mtu,
        dns4: [_persistentStateRepo.tunDns4],
        cidr4: _persistentStateRepo.tunCidr4,
        routes4: _persistentStateRepo.tunRoutes4List,
        cidr6: _persistentStateRepo.tunCidr6,
        dns6: [_persistentStateRepo.tunDns6],
        routes6: _persistentStateRepo.tunRoutes6List,
        path: await getWintunDir(),
        blackListApps: blackListApps,
      ),
    );
  }

  Future<InboundManagerConfig> _getInboundConfig() async {
    final inboundConfig = InboundManagerConfig();
    if (_persistentStateRepo.inboundMode == InboundMode.systemProxy) {
      int socksPort = _persistentStateRepo.dynamicSystemProxyPorts
          ? (await getUnusedPort())
          : _persistentStateRepo.socksPort;
      int httpPort = _persistentStateRepo.dynamicSystemProxyPorts
          ? (await getUnusedPort())
          : _persistentStateRepo.httpPort;
      inboundConfig.handlers.addAll([
        ProxyInboundConfig(
          address: '127.0.0.1',
          port: socksPort,
          tag: 'socks',
          protocol: Any.pack(SocksServerConfig(udpEnabled: true)),
        ),
        ProxyInboundConfig(
          address: '127.0.0.1',
          port: httpPort,
          tag: 'http',
          protocol: Any.pack(HttpServerConfig()),
        ),
      ]);
    }
    if (_persistentStateRepo.proxyShare) {
      inboundConfig.handlers.addAll([
        ProxyInboundConfig(
          address: _persistentStateRepo.proxyShareListenAddress,
          port: _persistentStateRepo.proxyShareListenPort,
          tag: 'proxyShare',
          protocols: [
            Any.pack(
              SocksServerConfig(
                address: _persistentStateRepo.socksUdpAssociateAddress,
                udpEnabled: true,
              ),
            ),
            Any.pack(HttpServerConfig()),
          ],
        ),
      ]);
    }
    final realmInbound = buildRealmServerInbound(
      loadLocalRealmServerConfig(
        _persistentStateRepo,
        _persistentStateRepo.uniqueDeviceId,
      ),
    );
    if (realmInbound != null) {
      inboundConfig.handlers.add(realmInbound);
    }

    return inboundConfig;
  }

  static const _dnsTag = 'dns';
  static const _tunTag = 'tun';
  static final selectorNotOkayException = ConfigException(
    'Free users can only use manual single node mode',
  );

  Future<SelectorsConfig> getSelectorsConfig(RouterConfig routerConfig) async {
    // if (!_authBloc.state.pro) {
    //   assert(
    //     _persistentStateRepo.proxySelectorMode == ProxySelectorMode.manual &&
    //         _persistentStateRepo.proxySelectorManualMode ==
    //             ProxySelectorManualNodeSelectionMode.single &&
    //         _persistentStateRepo.proxySelectorManualLandHandlers.isEmpty,
    //   );
    //   final proxySelector = SelectorConfig(
    //     strategy: SelectorConfig_SelectingStrategy.ALL,
    //     tag: defaultProxySelectorTag,
    //     balanceStrategy: SelectorConfig_BalanceStrategy.RANDOM,
    //     filter: SelectorConfig_Filter(selected: true),
    //   );
    //   if ((await _outboundRepo.getHandlers(selected: true)).isEmpty) {
    //     snack(rootLocalizations()?.noSelectedNode);
    //   }
    //   return SelectorsConfig(selectors: [proxySelector]);
    // }

    final selectors = <SelectorConfig>[];

    Future<void> addSelector(String selectorTag) async {
      SelectorConfig? config;
      // if the selector is the default proxy selector and the proxy selector mode is manual
      if (selectorTag == defaultProxySelectorTag &&
          _persistentStateRepo.proxySelectorMode == ProxySelectorMode.manual) {
        config = _persistentStateRepo.manualSelectorConfig;
        selectors.add(config);
      } else {
        config = await _databaseProvider.database.getSelectorConfig(
          selectorTag,
        );
        if (config != null) {
          selectors.add(config);
        }
      }
      // check if all land handlers in the selector are available
      if (config != null) {
        final landHandlers = config.landHandlers;
        for (final landHandler in landHandlers) {
          final handler = await _outboundRepo.getHandlerById(
            landHandler.toInt(),
          );
          if (handler == null) {
            throw ConfigException(
              '${rootLocalizations()?.selectorContainsDeletedLandHandler(config.toLocalString(rootNavigationKey.currentContext))}',
            );
          }
        }
      }
    }

    for (final rule in routerConfig.rules) {
      // if any rule uses the selector and it has not been added to the selectors, add it
      if (rule.selectorTag.isNotEmpty &&
          !selectors.any((e) => e.tag == rule.selectorTag)) {
        await addSelector(rule.selectorTag);
      }
      for (final fallback in rule.fallbacks) {
        if (fallback.selectorTag.isNotEmpty &&
            !selectors.any((e) => e.tag == fallback.selectorTag)) {
          await addSelector(fallback.selectorTag);
        }
      }
    }

    return SelectorsConfig(selectors: selectors);
  }

  static final fakednsPools = [
    FakeDnsServer_PoolConfig(cidr: '198.18.0.0/15', lruSize: 65535),
    FakeDnsServer_PoolConfig(cidr: 'fc00::/18', lruSize: 65535),
  ];

  /// When any domain of outbound tag is not resolved by the first two clients,
  /// the dns request will go proxy, and the proxy outbound might do a dns lookup again,
  /// the new lookup request will be handled again by the proxy outbound, which is a loop
  Future<DnsConfig> _getDnsConfig() async {
    final routeMode = _persistentStateRepo.routingMode;

    late final DnsConfig config;
    config = DnsConfig(
      dnsHijack: DnsHijackConfig(enableFakeDns: _persistentStateRepo.fakeDns),
      requestDomainResolver: Resolver(dnsServers: ['Hijack']),
      records: await (_databaseProvider.database.select(
        _databaseProvider.database.dnsRecords,
      )).get().then((value) => value.map((e) => e.dnsRecord).toList()),
      serialDnsServers: [],
      concurrentDnsServers: [],
    );

    final customRouteMode = await _databaseProvider
        .database
        .managers
        .customRouteModes
        .filter((e) => e.name.equals(routeMode))
        .getSingle();
    config.dnsHijack.dnsRules.addAll(customRouteMode.dnsRules.rules);
    for (final rule in customRouteMode.dnsRules.rules) {
      // the dns server is not in the config, add it
      if (!config.dnsServers.any((e) => e.name == rule.dnsServerName)) {
        final dnsServer = await _databaseProvider.database.managers.dnsServers
            .filter((e) => e.name.equals(rule.dnsServerName))
            .getSingleOrNull();
        if (dnsServer == null) {
          throw ConfigException('DNS server ${rule.dnsServerName} not found');
        }
        if (dnsServer.dnsServer != null) {
          config.dnsServers.add(dnsServer.dnsServer!);
        } else if (dnsServer.concurrentDnsServer != null) {
          config.concurrentDnsServers.add(dnsServer.concurrentDnsServer!);
        } else if (dnsServer.serialDnsServer != null) {
          config.serialDnsServers.add(dnsServer.serialDnsServer!);
        }
      }
    }

    // internal dns servers
    config.internalResolver = Resolver(
      dnsServers: [...customRouteMode.internalDnsServers],
    );
    for (final server in customRouteMode.internalDnsServers) {
      if (!config.dnsServers.any((e) => e.name == server)) {
        final dnsServer = await _databaseProvider.database.managers.dnsServers
            .filter((e) => e.name.equals(server))
            .getSingleOrNull();
        if (dnsServer == null) {
          throw ConfigException('DNS server $server not found');
        }
        if (dnsServer.dnsServer != null) {
          config.dnsServers.add(dnsServer.dnsServer!);
        } else if (dnsServer.concurrentDnsServer != null) {
          config.concurrentDnsServers.add(dnsServer.concurrentDnsServer!);
        } else if (dnsServer.serialDnsServer != null) {
          config.serialDnsServers.add(dnsServer.serialDnsServer!);
        }
      }
    }

    Future<void> ensureDnsServerByName(String serverName) async {
      if (config.dnsServers.any((e) => e.name == serverName)) {
        return;
      }
      final dnsServer = await _databaseProvider.database.managers.dnsServers
          .filter((e) => e.name.equals(serverName))
          .getSingleOrNull();
      if (dnsServer == null) {
        throw ConfigException('DNS server $serverName not found');
      }
      if (dnsServer.dnsServer != null) {
        config.dnsServers.add(dnsServer.dnsServer!);
      }
    }

    for (final concurrent in config.concurrentDnsServers) {
      for (final name in concurrent.dnsServers) {
        await ensureDnsServerByName(name);
      }
    }
    for (final serial in config.serialDnsServers) {
      for (final name in serial.dnsServers) {
        await ensureDnsServerByName(name);
      }
    }
    final dnsRecords = await (_databaseProvider.database.select(
      _databaseProvider.database.dnsRecords,
    )).get();
    config.records.addAll(dnsRecords.map((e) => e.dnsRecord));
    return config;
  }

  Future<(RouterConfig, GeoConfig)> getRouterGeoConfig(
    DnsConfig dnsConfig,
  ) async {
    late final RouterConfig routerConfig;
    late final GeoConfig geoConfig;

    final mode = _persistentStateRepo.routingMode;
    // switch (mode) {
    //   case DefaultRouteMode.black:
    //     routerConfig = RouterConfig(rules: [
    //       _dnsRule,
    //       _dnsReject,
    //       ...(mode as DefaultRouteMode).displayRouterRules()
    //     ]);
    //     proxyDnsDomainSet = GreatDomainSetConfig(
    //       name: internalProxySetName,
    //       inNames: [blackListProxy],
    //     );
    //   case DefaultRouteMode.white:
    //     routerConfig = RouterConfig(rules: [
    //       _dnsRule,
    //       _dnsReject,
    //       ...(mode as DefaultRouteMode).displayRouterRules()
    //     ]);
    //     proxyDnsDomainSet = GreatDomainSetConfig(
    //       name: internalProxySetName,
    //       inNames: [whiteListProxy],
    //     );
    //   case DefaultRouteMode.proxyAll:
    //     routerConfig = RouterConfig(rules: [
    //       _dnsRule,
    //       _dnsReject,
    //       ...(mode as DefaultRouteMode).displayRouterRules()
    //     ]);
    //     proxyDnsDomainSet = GreatDomainSetConfig(
    //       name: internalProxySetName,
    //       inNames: [proxyAllProxy],
    //     );
    //   case String s:
    if (mode == null) {
      throw ConfigException(
        rootLocalizations()?.pleaseSelectARoutingMode ?? '请选择一个路由模式',
      );
    }
    // if (!_authBloc.state.pro &&
    //     rootNavigationKey.currentContext != null &&
    //     !isDefaultRouteMode(mode, rootNavigationKey.currentContext!)) {
    //   throw ConfigException(
    //     rootLocalizations()?.freeUserCannotUseCustomRoutingMode ??
    //         '免费用户无法使用自定义路由模式。请选择一个默认路由模式。您可以在路由界面添加默认路由模式。',
    //   );
    // }
    final ruleConfig = await _databaseProvider
        .database
        .managers
        .customRouteModes
        .filter((e) => e.name.equals(mode))
        .getSingle();
    routerConfig = RouterConfig(
      rules: [
        RuleConfig(
          ruleName: 'default-dns go dns handler',
          inboundTags: [_tunTag],
          dstCidrs: [
            '${_persistentStateRepo.tunDns4}/32',
            '${_persistentStateRepo.tunDns6}/128',
          ],
          dstPortRanges: [PortRange(from: 53, to: 53)],
          outboundTag: _dnsTag,
        ),
        RuleConfig(
          ruleName: 'reject default dns over tls',
          dstCidrs: [
            '${_persistentStateRepo.tunDns4}/32',
            '${_persistentStateRepo.tunDns6}/128',
          ],
          dstPortRanges: [PortRange(from: 853, to: 853)],
        ),
        ...ruleConfig.routerConfig.rules,
      ],
    );
    //   default:
    //     throw ConfigException('未知的路由模式 $mode');
    // }

    // if (!_authBloc.state.pro) {
    //   final geoConfig = await getGeoConfig0();
    //   geoConfig.greatDomainSets.add(proxyDnsDomainSet!);
    //   await _addNodeSet(geoConfig);
    //   if (isPkg) {
    //     await pkgConvertGeoConfig(geoConfig);
    //   }
    //   return (routerConfig, geoConfig);
    // }

    final geositePath = await getSimplifiedGeositePath();
    final geoIPPath = await getSimplifiedGeoIPPath();
    // if simplified geoip or geosite is not found, write assets geo data to to them
    if (!File(geositePath).existsSync() || !File(geoIPPath).existsSync()) {
      await writeStaticGeo();
    }
    final greatDomainSets = <GreatDomainSetConfig>[];
    final greatIpSets = <GreatIPSetConfig>[];
    final atomicDomainSets = <AtomicDomainSetConfig>[];
    final atomicIpSets = <AtomicIPSetConfig>[];
    final appSets = <AppSetConfig>[];
    bool useStandartGeoSite = false;
    bool useStandartGeoIP = false;
    final clashUrlsSet = <String>{};
    final geoUrlsSet = <String>{};

    /// given a set name, return all atomic domain sets and great domain sets
    Future<(List<AtomicDomainSetConfig>?, List<GreatDomainSetConfig>?)>
    getDomainSets(String setName, {bool notFoundThrow = true}) async {
      if (greatDomainSets.any((e) => e.name == setName) ||
          atomicDomainSets.any((e) => e.name == setName)) {
        return (null, null);
      }
      final atomicSet = await ((_databaseProvider.database.select(
        _databaseProvider.database.atomicDomainSets,
      ))..where((s) => s.name.equals(setName))).getSingleOrNull();
      if (atomicSet != null) {
        final geositeConfig = atomicSet.geositeConfig;
        if (geositeConfig != null && geositeConfig.codes.isNotEmpty) {
          if (atomicSet.geoUrl == null || atomicSet.geoUrl!.isEmpty) {
            useStandartGeoSite = geositeConfig.codes.any(
              (e) => !simplifiedGeoSiteCodes.contains(e),
            );
            if (useStandartGeoSite) {
              geositeConfig.filepath = await getGeositePath();
            } else {
              geositeConfig.filepath = await getSimplifiedGeositePath();
            }
          } else {
            geoUrlsSet.add(atomicSet.geoUrl!);
            geositeConfig.filepath = await getGeoUrlPath(atomicSet.geoUrl!);
          }
        }
        final config = AtomicDomainSetConfig(
          name: setName,
          geosite: geositeConfig,
          inverse: atomicSet.inverse,
          useBloomFilter: atomicSet.useBloomFilter && Platform.isIOS,
        );
        for (final url in atomicSet.clashRuleUrls ?? []) {
          clashUrlsSet.add(url);
          config.clashFiles.add(await getClashRulesPath(url));
        }
        final domains = await (_databaseProvider.database.select(
          _databaseProvider.database.geoDomains,
        )..where((t) => t.domainSetName.equals(setName))).get();
        config.domains.addAll(domains.map((e) => e.geoDomain));
        return ([config], <GreatDomainSetConfig>[]);
      }
      // great domain set
      final retAtomic = <AtomicDomainSetConfig>[];
      final retGreat = <GreatDomainSetConfig>[];
      final greatSet =
          await ((_databaseProvider.database.select(
                _databaseProvider.database.greatDomainSets,
              ))..where(
                (s) => s.name.equals(setName) | s.oppositeName.equals(setName),
              ))
              .getSingleOrNull();
      if (greatSet != null) {
        retGreat.add(greatSet.set);
        for (final setName in [
          ...greatSet.set.inNames,
          ...greatSet.set.exNames,
        ]) {
          final (atomic, great) = await getDomainSets(setName);
          retAtomic.addAll(atomic ?? []);
          retGreat.addAll(great ?? []);
        }
        return (retAtomic, retGreat);
      } else {
        if (notFoundThrow) {
          throw ConfigException('Domain set $setName not found');
        }
        return (null, null);
      }
    }

    Future<void> prepareDomainSet(
      String setName, {
      bool notFoundThrow = true,
    }) async {
      final (atomic, great) = await getDomainSets(
        setName,
        notFoundThrow: notFoundThrow,
      );
      atomicDomainSets.addAll(atomic ?? []);
      greatDomainSets.addAll(great ?? []);
    }

    Future<void> addAtomicIpSet(
      String setName, {
      bool notFoundThrow = true,
    }) async {
      final atomicSet = await ((_databaseProvider.database.select(
        _databaseProvider.database.atomicIpSets,
      ))..where((s) => s.name.equals(setName))).getSingleOrNull();
      if (atomicSet != null) {
        final geoipConfig = atomicSet.geoIpConfig;
        if (geoipConfig != null && geoipConfig.codes.isNotEmpty) {
          if (atomicSet.geoUrl == null || atomicSet.geoUrl!.isEmpty) {
            useStandartGeoIP = geoipConfig.codes.any(
              (e) => !simplifiedGeoIpCodes.contains(e),
            );
            if (useStandartGeoIP) {
              geoipConfig.filepath = await getGeoIPPath();
            } else {
              geoipConfig.filepath = await getSimplifiedGeoIPPath();
            }
          } else {
            geoUrlsSet.add(atomicSet.geoUrl!);
            geoipConfig.filepath = await getGeoUrlPath(atomicSet.geoUrl!);
          }
        }
        final config = AtomicIPSetConfig(
          name: setName,
          inverse: atomicSet.inverse,
          geoip: geoipConfig,
        );
        for (final url in atomicSet.clashRuleUrls ?? []) {
          clashUrlsSet.add(url);
          config.clashFiles.add(await getClashRulesPath(url));
        }

        final cidrs = await (_databaseProvider.database.select(
          _databaseProvider.database.cidrs,
        )..where((t) => t.ipSetName.equals(setName))).get();
        config.cidrs.addAll(cidrs.map((e) => e.cidr));
        atomicIpSets.add(config);
      } else {
        // the set is not found, throw error
        if (notFoundThrow) {
          throw ConfigException('IP set $setName not found');
        }
      }
    }

    Future<void> prepareIpSet(
      String dstIpTag, {
      bool notFoundThrow = true,
    }) async {
      if (greatIpSets.any((e) => e.name == dstIpTag) ||
          atomicIpSets.any((e) => e.name == dstIpTag)) {
        return;
      }
      final greatSet =
          await ((_databaseProvider.database.select(
                _databaseProvider.database.greatIpSets,
              ))..where(
                (s) =>
                    s.name.equals(dstIpTag) | s.oppositeName.equals(dstIpTag),
              ))
              .getSingleOrNull();
      if (greatSet != null) {
        greatIpSets.add(greatSet.greatIpSetConfig);
        for (final setName in [
          ...greatSet.greatIpSetConfig.inNames,
          ...greatSet.greatIpSetConfig.exNames,
        ]) {
          await addAtomicIpSet(setName);
        }
      } else {
        await addAtomicIpSet(dstIpTag, notFoundThrow: notFoundThrow);
      }
    }

    Future<void> prepareAppSet(
      String appTag, {
      bool notFoundThrow = true,
    }) async {
      if (appSets.any((e) => e.name == appTag)) {
        return;
      }
      final appSet = await ((_databaseProvider.database.select(
        _databaseProvider.database.appSets,
      ))..where((s) => s.name.equals(appTag))).getSingleOrNull();
      if (appSet == null) {
        if (notFoundThrow) {
          throw ConfigException('App set $appTag not found');
        }
        return;
      }
      final apps = await (_databaseProvider.database.select(
        _databaseProvider.database.apps,
      )..where((s) => s.appSetName.equals(appTag))).get();
      final appSetConfig = AppSetConfig(
        name: appTag,
        appIds: apps.map((e) => e.appId),
      );
      for (final url in appSet.clashRuleUrls ?? []) {
        clashUrlsSet.add(url);
        appSetConfig.clashFiles.add(await getClashRulesPath(url));
      }
      appSets.add(appSetConfig);
    }

    // set referenced in allTags are not required to be present.
    // set refencenced in domainTag, appTag, dstIpTag are required to be present.
    // any set referenced by a great set is required to be present.
    for (final rule in routerConfig.rules) {
      for (final dstIpTag in rule.dstIpTags) {
        await prepareIpSet(dstIpTag);
      }
      for (final dstIpTag in rule.allTags) {
        await prepareIpSet(dstIpTag, notFoundThrow: false);
      }
      for (final fallback in rule.fallbacks) {
        for (final dstIpTag in fallback.dstIpTags) {
          await prepareIpSet(dstIpTag);
        }
        for (final domainTag in fallback.domainTags) {
          await prepareDomainSet(domainTag);
        }
      }
      // domain tags
      for (final domainTag in rule.domainTags) {
        await prepareDomainSet(domainTag);
      }
      for (final domainTag in rule.allTags) {
        await prepareDomainSet(domainTag, notFoundThrow: false);
      }
      // app tags
      for (final appTag in rule.appTags) {
        await prepareAppSet(appTag);
      }
      for (final appTag in rule.allTags) {
        await prepareAppSet(appTag, notFoundThrow: false);
      }
    }

    // dns rules
    for (final dnsRule in dnsConfig.dnsHijack.dnsRules) {
      for (final domainTag in dnsRule.domainTags) {
        await prepareDomainSet(domainTag);
      }
    }
    // dns servers
    for (final dnsServer in dnsConfig.dnsServers) {
      for (final ipTag in dnsServer.ipTags) {
        await prepareIpSet(ipTag);
      }
    }

    geoConfig = GeoConfig(
      atomicDomainSets: atomicDomainSets,
      greatDomainSets: greatDomainSets,
      atomicIpSets: atomicIpSets,
      greatIpSets: greatIpSets,
      appSets: appSets,
    );
    await _addNodeSet(geoConfig);

    final futures = <Future>[];
    if (useStandartGeoSite || useStandartGeoIP) {
      final geoSitePath = await getGeositePath();
      final geoIPPath = await getGeoIPPath();
      final geoSiteFile = File(geoSitePath);
      final geoIPFile = File(geoIPPath);
      if (!geoSiteFile.existsSync() || !geoIPFile.existsSync()) {
        futures.add(_geoDataHelper.downloadAndProcessGeo());
      }
    }
    for (final url in clashUrlsSet) {
      final path = await getClashRulesPath(url);
      final file = File(path);
      if (!file.existsSync()) {
        futures.add(_downloader.downloadProxyFirst(url, path));
      }
    }
    for (final url in geoUrlsSet) {
      final path = await getGeoUrlPath(url);
      final file = File(path);
      if (!file.existsSync()) {
        futures.add(_downloader.downloadProxyFirst(url, path));
      }
    }
    if (futures.isNotEmpty) {
      snack(
        rootLocalizations()?.geoSiteOrGeoIPFileNotFound,
        duration: const Duration(seconds: 100),
      );
      try {
        await Future.wait(futures);
      } catch (e) {
        throw ConfigException('Failed to download geo files: $e');
      } finally {
        rootScaffoldMessengerKey.currentState?.removeCurrentSnackBar();
      }
    }

    if (isPkg) {
      await pkgConvertGeoConfig(_xApiClient, geoConfig);
    }

    return (routerConfig, geoConfig);
  }

  Future<void> _addNodeSet(GeoConfig geoConfig) async {
    final (nodeDomainSet, nodeIpSet) = await getNodeSet();
    geoConfig.atomicDomainSets.add(nodeDomainSet);
    geoConfig.atomicIpSets.add(nodeIpSet);
  }

  // add node to node set
  Future<(AtomicDomainSetConfig, AtomicIPSetConfig)> getNodeSet() async {
    final allHandlers = await _outboundRepo.getAllHandlers();

    final domains = <Domain>[];
    final cidrs = <CIDR>[];
    for (final handler in allHandlers) {
      if (isDomain(handler.address) && handler.address.isNotEmpty) {
        domains.add(Domain(type: Domain_Type.Full, value: handler.address));
      } else if (isValidIp(handler.address) && handler.address.isNotEmpty) {
        cidrs.add(ipToCidr(handler.address));
      }
      if (isDomain(handler.sni) && handler.sni.isNotEmpty) {
        domains.add(Domain(type: Domain_Type.Full, value: handler.sni));
      }
    }

    // outbound domain and outbound ip should go direct
    return (
      AtomicDomainSetConfig(name: node, domains: domains),
      AtomicIPSetConfig(name: node, cidrs: cidrs),
    );
  }

  /// TODO: optimize
  static Future<void> pkgConvertGeoConfig(
    XApiClient xApiClient,
    GeoConfig geoConfig,
  ) async {
    // final futures = <Future>[];
    for (final atomicDomainSet in geoConfig.atomicDomainSets) {
      if (atomicDomainSet.hasGeosite()) {
        await xApiClient.parseGeositeConfig(atomicDomainSet.geosite).then((
          domains,
        ) {
          atomicDomainSet.clearGeosite();
          atomicDomainSet.domains.addAll(domains);
        });
        // futures.add();
      }
      for (final clashFilePath in atomicDomainSet.clashFiles) {
        await xApiClient
            .parseClashRuleFile(File(clashFilePath).readAsBytesSync())
            .then((result) {
              atomicDomainSet.domains.addAll(result.domains);
            });
        // futures.add();
      }
      atomicDomainSet.clashFiles.clear();
    }
    for (final atomicIpSet in geoConfig.atomicIpSets) {
      if (atomicIpSet.hasGeoip()) {
        await xApiClient.parseGeoIPConfig(atomicIpSet.geoip).then((cidrs) {
          atomicIpSet.clearGeoip();
          atomicIpSet.cidrs.addAll(cidrs);
        });
        // futures.add();
      }
      for (final clashFilePath in atomicIpSet.clashFiles) {
        await xApiClient
            .parseClashRuleFile(File(clashFilePath).readAsBytesSync())
            .then((result) {
              atomicIpSet.cidrs.addAll(result.cidrs);
            });
        // futures.add();
      }
      atomicIpSet.clashFiles.clear();
    }
    for (final appSet in geoConfig.appSets) {
      for (final clashFilePath in appSet.clashFiles) {
        await xApiClient
            .parseClashRuleFile(File(clashFilePath).readAsBytesSync())
            .then((result) {
              appSet.appIds.addAll(result.appIds);
            });
        // futures.add();
      }
      appSet.clashFiles.clear();
    }
    // await Future.wait(futures);
  }

  // There should be no same name in great_domain_sets and atomic_domain_sets.
  // Same for great_ip_sets and atomic_ip_sets.
  // Future<GeoConfig> getGeoConfig0() async {
  //   final mode = _persistentStateRepo.routingMode;
  //   final geositePath = await getSimplifiedGeositePath();
  //   final geoIPPath = await getSimplifiedGeoIPPath();

  //   late final GeoConfig config;

  //   // if simplified geoip or geosite is not found, write assets geo data to to them
  //   if (!File(geositePath).existsSync() || !File(geoIPPath).existsSync()) {
  //     await writeStaticGeo();
  //   }
  //   switch (mode) {
  //     case DefaultRouteMode.black:
  //       config = GeoConfig(atomicDomainSets: [
  //         AtomicDomainSetConfig(
  //             name: gfw,
  //             geosite: GeositeConfig(codes: ['gfw'], filepath: geositePath)),
  //       ], greatDomainSets: [
  //         GreatDomainSetConfig(
  //             name: blackListProxy,
  //             oppositeName: blackListDirect,
  //             inNames: [gfw, customProxy],
  //             exNames: [customDirect])
  //       ], atomicIpSets: [
  //         AtomicIPSetConfig(
  //             name: gfw,
  //             geoip: GeoIPConfig(
  //                 codes: ['telegram', 'google', 'facebook', 'twitter', "tor"],
  //                 filepath: geoIPPath)),
  //       ], greatIpSets: [
  //         GreatIPSetConfig(
  //             name: blackListProxy,
  //             inNames: [gfw, customProxy],
  //             exNames: [customDirect]),
  //       ]);
  //     case DefaultRouteMode.white:
  //       config = GeoConfig(atomicDomainSets: [
  //         AtomicDomainSetConfig(
  //             name: gfw,
  //             geosite: GeositeConfig(codes: ['gfw'], filepath: geositePath)),
  //         AtomicDomainSetConfig(
  //             name: cn,
  //             useBloomFilter: Platform.isIOS ? true : false,
  //             geosite: GeositeConfig(
  //                 codes: ['cn', 'apple-cn', 'tld-cn'], filepath: geositePath)),
  //         AtomicDomainSetConfig(
  //             name: private,
  //             geosite:
  //                 GeositeConfig(codes: ['private'], filepath: geositePath)),
  //         AtomicDomainSetConfig(
  //             name: cnGames,
  //             geosite: GeositeConfig(
  //                 codes: ['category-games'],
  //                 filepath: geositePath,
  //                 attributes: ['cn']))
  //       ], greatDomainSets: [
  //         GreatDomainSetConfig(
  //           name: whiteListDirect,
  //           oppositeName: whiteListProxy,
  //           inNames: [private, cn, cnGames, customDirect],
  //           exNames: [customProxy, if (Platform.isIOS) gfwWithoutCustomDirect],
  //         ),
  //         if (Platform.isIOS)
  //           GreatDomainSetConfig(
  //             name: gfwWithoutCustomDirect,
  //             inNames: [gfw],
  //             exNames: [customDirect],
  //           )
  //       ], atomicIpSets: [
  //         AtomicIPSetConfig(
  //             name: cn, geoip: GeoIPConfig(codes: ['cn'], filepath: geoIPPath)),
  //         AtomicIPSetConfig(
  //             name: private,
  //             geoip: GeoIPConfig(codes: ['private'], filepath: geoIPPath)),
  //       ], greatIpSets: [
  //         GreatIPSetConfig(
  //             name: whiteListDirect,
  //             // oppositeName: whiteListGreatDomainSetOppositeName,
  //             inNames: [cn, private, customDirect],
  //             exNames: [customProxy]),
  //       ]);
  //     case DefaultRouteMode.proxyAll:
  //       config = GeoConfig(atomicDomainSets: [
  //         AtomicDomainSetConfig(
  //             name: private,
  //             geosite: GeositeConfig(codes: ['private'], filepath: geositePath))
  //       ], greatDomainSets: [
  //         GreatDomainSetConfig(
  //             name: proxyAllDirect,
  //             oppositeName: proxyAllProxy,
  //             inNames: [private, customDirect],
  //             exNames: [customProxy]),
  //       ], atomicIpSets: [
  //         AtomicIPSetConfig(
  //             name: private,
  //             geoip: GeoIPConfig(codes: ['private'], filepath: geoIPPath))
  //       ], greatIpSets: [
  //         GreatIPSetConfig(
  //             name: proxyAllDirect,
  //             // oppositeName: proxyAllGreatDomainSetOppositeName,
  //             inNames: [private, customDirect],
  //             exNames: [customProxy]),
  //       ]);
  //   }

  //   // final customDirectDomains = await (_databaseProvider.database.select(_databaseProvider.database.geoDomains)
  //   //       ..where((t) => t.domainSetName.equals(customDirect)))
  //   //     .get();
  //   // final customProxyDomains = await (_databaseProvider.database.select(_databaseProvider.database.geoDomains)
  //   //       ..where((t) => t.domainSetName.equals(customProxy)))
  //   //     .get();
  //   // final customDirectCidrs = await (_databaseProvider.database.select(_databaseProvider.database.cidrs)
  //   //       ..where((t) => t.ipSetName.equals(customDirect)))
  //   //     .get();
  //   // final customProxyCidrs = await (_databaseProvider.database.select(_databaseProvider.database.cidrs)
  //   //       ..where((t) => t.ipSetName.equals(customProxy)))
  //   //     .get();
  //   config.atomicDomainSets.add(AtomicDomainSetConfig(
  //     name: customDirect,
  //     // domains: customDirectDomains.map((e) => e.geoDomain),
  //   ));
  //   config.atomicDomainSets.add(AtomicDomainSetConfig(
  //     name: customProxy,
  //     // domains: customProxyDomains.map((e) => e.geoDomain),
  //   ));
  //   config.atomicIpSets.add(AtomicIPSetConfig(
  //     name: customDirect,
  //     // cidrs: customDirectCidrs.map((e) => e.cidr),
  //   ));
  //   config.atomicIpSets.add(AtomicIPSetConfig(
  //     name: customProxy,
  //     // cidrs: customProxyCidrs.map((e) => e.cidr),
  //   ));
  //   // app sets
  //   // final directApps = await (_databaseProvider.database.select(_databaseProvider.database.apps)
  //   //       ..where((t) => t.appSetName.equals(direct)))
  //   //     .get();
  //   // final proxyApps = await (_databaseProvider.database.select(_databaseProvider.database.apps)
  //   //       ..where((t) => t.appSetName.equals(proxy)))
  //   //     .get();
  //   config.appSets.add(AppSetConfig(
  //     name: directAppSetName,
  //     // appIds: directApps.map((e) => e.appId),
  //   ));
  //   config.appSets.add(AppSetConfig(
  //     name: proxy,
  //     // appIds: proxyApps.map((e) => e.appId),
  //   ));
  //   // final allHandlers = await _outboundRepo.getAllHandlers();
  //   // // outbound domain and outbound ip should go direct
  //   // config.atomicDomainSets.add(AtomicDomainSetConfig(
  //   //   name: outboundTag,
  //   //   domains: allHandlers
  //   //       .where((e) => isDomain(e.address) && e.address.isNotEmpty)
  //   //       .map((e) => common_geo.Domain(
  //   //             type: common_geo.Domain_Type.Full,
  //   //             value: e.address,
  //   //           )),
  //   // ));
  //   // config.atomicIpSets.add(AtomicIPSetConfig(
  //   //   name: outboundTag,
  //   //   cidrs: allHandlers
  //   //       .where((e) => isValidIp(e.address) && e.address.isNotEmpty)
  //   //       .map((e) => ipToCidr(e.address)),
  //   // ));
  //   return config;
  // }

  PolicyConfig _getPolicyConfig() {
    final c = PolicyConfig(
      handshakeTimeout: _persistentStateRepo.policyHandshakeTimeout,
      connectionIdleTimeout: _persistentStateRepo.policyConnectionIdleTimeout,
      udpIdleTimeout: _persistentStateRepo.policyUdpIdleTimeout,
      upLinkOnlyTimeout: _persistentStateRepo.policyUpLinkOnlyTimeout,
      downLinkOnlyTimeout: _persistentStateRepo.policyDownLinkOnlyTimeout,
    );
    return c;
  }

  Future<l.LoggerConfig> _getLoggerConfig() async {
    late final l.Level logLevel;
    if (!isProduction() || (_persistentStateRepo.enableDebugLog)) {
      logLevel = l.Level.DEBUG;
    } else {
      logLevel = l.Level.DISABLED;
    }
    return l.LoggerConfig(
      consoleWriter: true,
      showCaller: true,
      logLevel: logLevel,
      showColor: !Platform.isAndroid,
    );
  }

  SysProxyConfig? _getSysProxyConfig(InboundManagerConfig inboundConfig) {
    if (_persistentStateRepo.inboundMode != InboundMode.systemProxy) {
      return null;
    }
    // setting system proxy cannot be done in system extension by "networksetup"
    // they are done on flutter side
    if (isPkg || Platform.isLinux || Platform.isWindows) {
      return null;
    }
    return SysProxyConfig(
      httpProxyAddress: "127.0.0.1",
      httpProxyPort: inboundConfig.handlers
          .firstWhere((e) => e.tag == 'http')
          .port,
      socksProxyAddress: "127.0.0.1",
      socksProxyPort: inboundConfig.handlers
          .firstWhere((e) => e.tag == 'socks')
          .port,
    );
  }

  Future<GrpcConfig> _getGrpcConfig({Uint8List? certBytes}) async {
    if (useTcpForGrpc) {
      final p = await getUnusedPort();
      return GrpcConfig(address: '127.0.0.1', port: p, clientCert: certBytes);
    }
    final config = GrpcConfig(address: await grpcListenAddrUnix());
    if (Platform.isLinux) {
      final uid = await userId();
      final gid = await groupId();
      config.uid = uid;
      config.gid = gid;
    }
    return config;
  }
}

final useTcpForGrpc = Platform.isWindows || isPkg;

Future<String> grpcListenAddrUnix() async {
  late String address;
  if (Platform.isAndroid || Platform.isLinux) {
    address = join((await resourceDir()).path, 'grpc.sock');
  }
  // if use cacheDir, bind fails. probably due to long path
  if (Platform.isIOS || Platform.isMacOS) {
    address = join(await darwinHostApi!.appGroupPath(), 'grpc.sock');
  }
  return address;
}
