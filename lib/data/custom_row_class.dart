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

part of 'database.dart';

class OutboundHandler {
  OutboundHandler({
    required this.config,
    this.id = 0,
    this.countryCode = '',
    this.selected = false,
    this.speed = 0,
    this.ping = 0,
    // this.speed1MB = 0,
    this.monitorSpeed = 0,
    this.ok = 0,
    this.tcpOK = 0,
    this.speedTesting = false,
    this.usableTesting = false,
    this.serverIp = '',
    this.cdn,
    this.speedTestTime = 0,
    this.pingTestTime = 0,
    this.support6 = 0,
    this.support6TestTime = 0,
    this.subId,
    this.updatedAt,
    this.selectedInMultipleSelect = false,
  });

  int id;
  // if selected mannually. defaults to false
  final bool selected;
  final String countryCode;
  // speed in Mbps
  final double speed;
  // ping in ms
  final int ping;
  // speed monitored by x, in Mbps
  final double monitorSpeed;

  final int ok;
  final int tcpOK;
  // which cdn the server address belongs to
  CDN? cdn;
  final String serverIp;
  @ja.JsonKey(toJson: _toJson, fromJson: _fromJson)
  final HandlerConfig config;
  String? protocol;
  final bool speedTesting;
  final bool usableTesting;
  final bool selectedInMultipleSelect;

  final int speedTestTime;
  final int pingTestTime;
  final int support6;
  final int support6TestTime;
  final DateTime? updatedAt;

  int? subId;

  static String _toJson(HandlerConfig config) {
    return config.writeToJson();
  }

  static HandlerConfig _fromJson(String json) {
    return HandlerConfig.fromJson(json);
  }

  OutboundHandler copyWith({
    int? id,
    String? countryCode,
    HandlerConfig? config,
    String? sni,
    double? speed,
    int? ping,
    double? speed1,
    double? dspeed,
    int? dping,
    int? status,
    bool? selected,
    bool? enabled,
    int? ok,
    int? tcpOK,
    bool? speedTesting,
    bool? selectInMultipleSelect,
    bool? usableTesting,
    bool? using,
    int? subId,
    DateTime? updatedAt,
  }) {
    final newHandler = OutboundHandler(
      id: id ?? this.id,
      config: config ?? this.config,
      countryCode: countryCode ?? this.countryCode,
      speed: speed ?? this.speed,
      ping: ping ?? this.ping,
      // speed1MB: speed1 ?? speed1MB,
      selectedInMultipleSelect:
          selectInMultipleSelect ?? selectedInMultipleSelect,
      monitorSpeed: dspeed ?? monitorSpeed,
      selected: selected ?? this.selected,
      ok: ok ?? this.ok,
      tcpOK: tcpOK ?? this.tcpOK,
      speedTesting: speedTesting ?? this.speedTesting,
      usableTesting: usableTesting ?? this.usableTesting,
      subId: subId ?? this.subId,
    );
    return newHandler;
  }

  factory OutboundHandler.fromJson(Map<String, dynamic> json) =>
      OutboundHandler(
        config: OutboundHandler._fromJson(json['config'] as String),
        id: (json['id'] as num?)?.toInt() ?? 0,
        countryCode: json['countryCode'] as String? ?? '',
        selected: json['selected'] as bool? ?? false,
        speed: (json['speed'] as num?)?.toDouble() ?? 0,
        ping: (json['ping'] as num?)?.toInt() ?? 0,
        monitorSpeed: (json['monitorSpeed'] as num?)?.toDouble() ?? 0,
        ok: (json['ok'] as num?)?.toInt() ?? 0,
        tcpOK: (json['tcpOK'] as num?)?.toInt() ?? 0,
        speedTesting: json['speedTesting'] as bool? ?? false,
        usableTesting: json['usableTesting'] as bool? ?? false,
        serverIp: json['serverIp'] as String? ?? '',
        speedTestTime: (json['speedTestTime'] as num?)?.toInt() ?? 0,
        pingTestTime: (json['pingTestTime'] as num?)?.toInt() ?? 0,
        support6: (json['support6'] as num?)?.toInt() ?? 0,
        support6TestTime: (json['support6TestTime'] as num?)?.toInt() ?? 0,
        subId: (json['subId'] as num?)?.toInt(),
        selectedInMultipleSelect:
            json['selectedInMultipleSelect'] as bool? ?? false,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
      )..protocol = json['protocol'] as String?;

  Map<String, dynamic> toJson({ValueSerializer? serializer}) =>
      <String, dynamic>{
        'id': id,
        'countryCode': countryCode,
        'serverIp': serverIp,
        'config': OutboundHandler._toJson(config),
        'protocol': protocol,
        'support6': support6,
        'support6TestTime': support6TestTime,
        'subId': subId,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  @override
  String get name {
    if (config.hasOutbound()) {
      return config.outbound.tag;
    } else {
      return config.chain.tag;
    }
  }

  OutboundHandlersCompanion toCompanion() {
    return OutboundHandlersCompanion(
      id: Value(id),
      selected: Value(selected),
      countryCode: Value(countryCode),
      speed: Value(speed),
      ping: Value(ping),
      sni: Value(sni),
      config: Value(config),
      ok: Value(ok),
      subId: Value(subId),
      updatedAt: Value(updatedAt),
      serverIp: Value(serverIp),
    );
  }

  factory OutboundHandler.fromConfig(HandlerConfig config) {
    return OutboundHandler(config: config);
  }

  HandlerConfig toConfig() {
    final copy = config.deepCopy();
    if (copy.hasOutbound()) {
      copy.outbound.tag = '$id';
    } else {
      copy.chain.tag = '$id';
    }
    return copy;
  }

  outboundpb.OutboundHandler toStoredHandler({List<String> groupTags = const []}) {
    return outboundpb.OutboundHandler(
      id: Int64(id),
      selected: selected,
      countryCode: countryCode,
      ok: ok,
      speed: speed,
      speedTestTime: speedTestTime,
      ping: ping,
      pingTestTime: pingTestTime,
      subId: subId == null ? null : Int64(subId!),
      config: toConfig().writeToBuffer(),
      sni: sni,
      serverIp: serverIp,
      support6: support6,
      support6TestTime: support6TestTime,
      groupTags: groupTags,
      name: name,
    );
  }

  String get address {
    if (config.hasOutbound()) {
      return config.outbound.address;
    } else {
      return config.chain.handlers.first.address;
    }
  }

  String get displayAddress {
    if (config.hasOutbound()) {
      return '${config.outbound.address}:${portString(config.outbound)}';
    } else {
      String ret = '';
      for (final handler in config.chain.handlers) {
        if (handler != config.chain.handlers.last) {
          ret += '${handler.address}→';
        } else {
          ret += handler.address;
        }
      }
      return ret;
    }
  }

  String get sni {
    if (config.hasOutbound()) {
      return config.outbound.getSNI();
    } else {
      return config.chain.handlers.first.getSNI();
    }
  }

  String displayProtocol() {
    if (protocol != null) {
      return protocol!;
    }
    protocol = config.getDisplayProtocol();
    return protocol!;
  }

  Widget get countryIcon {
    return countryCode.isNotEmpty
        ? SvgPicture(
            height: 24,
            width: 24,
            AssetBytesLoader(
              'assets/icons/flags/${countryCode.toLowerCase()}.svg.vec',
            ),
          )
        : const Icon(Icons.language);
  }
}

extension HandlerConfigExtension on HandlerConfig {
  String getDisplayProtocol() {
    if (hasChain()) {
      String ret = '';
      for (final handler in chain.handlers) {
        if (handler != chain.handlers.last) {
          ret += '${handler.getDisplayProtocol()}→';
        } else {
          ret += handler.getDisplayProtocol();
        }
      }
      return ret;
    }
    return outbound.getDisplayProtocol();
  }
}

extension TransportConfigExtension on TransportConfig {
  String? getProtocol() {
    if (hasWebsocket()) {
      return 'WS';
    } else if (hasGrpc()) {
      return 'GRPC';
    } else if (hasHttp()) {
      return 'HTTP';
    } else if (hasKcp()) {
      return 'KCP';
    } else if (hasSplithttp()) {
      return 'XHTTP';
    } else if (hasHttpupgrade()) {
      return 'HTTPUPGRADE';
    } else {
      return null;
    }
  }
}

extension OutboundHandlerConfigExtension on OutboundHandlerConfig {
  String getDisplayProtocol() {
    String ret = getProtocolTypeFromAny(protocol).label;
    final transportProtocol = transport.getProtocol();
    if (transportProtocol != null) {
      ret += '/$transportProtocol';
    }
    if (transport.hasTls()) {
      ret += '/TLS';
    } else if (transport.hasReality()) {
      ret += '/Reality';
    }
    return ret;
  }

  String getSNI() {
    if (getProtocolTypeFromAny(protocol) == ProxyProtocolLabel.hysteria2) {
      final hysteria2Config = Hysteria2ClientConfig();
      protocol.unpackInto(hysteria2Config);
      return hysteria2Config.tlsConfig.serverName;
    }
    if (transport.hasTls()) {
      return transport.tls.serverName;
    } else if (transport.hasReality()) {
      return transport.reality.serverName;
    }
    return '';
  }
}

class OutboundHandlerGroup extends NodeGroup {
  OutboundHandlerGroup({
    required this.name,
    required this.placeOnTop,
    this.updatedAt,
  });

  @override
  final String name;
  @override
  final bool placeOnTop;
  final DateTime? updatedAt;

  OutboundHandlerGroupsCompanion toCompanion() {
    return OutboundHandlerGroupsCompanion(
      name: Value(name),
      updatedAt: Value(updatedAt),
    );
  }

  factory OutboundHandlerGroup.fromJson(Map<String, dynamic> json) =>
      OutboundHandlerGroup(
        name: json['name'] as String,
        placeOnTop: json['placeOnTop'] as bool,
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
      );

  Map<String, dynamic> toJson({ValueSerializer? serializer}) =>
      <String, dynamic>{
        'name': name,
        'placeOnTop': placeOnTop,
        'updatedAt': updatedAt?.toIso8601String(),
      };
}

class GreatIpSet extends DataClass implements Insertable<GreatIpSet> {
  final String name;
  final GreatIPSetConfig greatIpSetConfig;
  final DateTime? updatedAt;
  final String? oppositeName;
  const GreatIpSet({
    required this.name,
    required this.greatIpSetConfig,
    this.updatedAt,
    this.oppositeName,
  });

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || oppositeName != null) {
      map['opposite_name'] = Variable<String>(oppositeName);
    }
    {
      map['great_ip_set_config'] = Variable<Uint8List>(
        $GreatIpSetsTable.$convertergreatIpSetConfig.toSql(greatIpSetConfig),
      );
    }
    return map;
  }

  GreatIpSetsCompanion toCompanion(bool nullToAbsent) {
    return GreatIpSetsCompanion(
      name: Value(name),
      greatIpSetConfig: Value(greatIpSetConfig),
      updatedAt: Value(updatedAt),
      oppositeName: oppositeName == null && nullToAbsent
          ? const Value.absent()
          : Value(oppositeName),
    );
  }

  factory GreatIpSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GreatIpSet(
      name: serializer.fromJson<String>(json['name']),
      greatIpSetConfig: GreatIPSetConfig.fromJson(json['greatIpSetConfig']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      oppositeName: serializer.fromJson<String?>(json['oppositeName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'greatIpSetConfig': greatIpSetConfig.writeToJson(),
      'updatedAt': updatedAt?.toIso8601String(),
      'oppositeName': serializer.toJson<String?>(oppositeName),
    };
  }
}

class AtomicIpSet extends DataClass implements Insertable<AtomicIpSet> {
  final String name;
  final bool inverse;
  final GeoIPConfig? geoIpConfig;
  final List<String>? clashRuleUrls;
  final DateTime? updatedAt;
  final String? geoUrl;
  const AtomicIpSet({
    required this.name,
    required this.inverse,
    this.geoIpConfig,
    this.clashRuleUrls,
    this.updatedAt,
    this.geoUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['name'] = Variable<String>(name);
    map['inverse'] = Variable<bool>(inverse);
    if (!nullToAbsent || geoIpConfig != null) {
      map['geo_ip_config'] = Variable<Uint8List>(
        $AtomicIpSetsTable.$convertergeoIpConfign.toSql(geoIpConfig),
      );
    }
    if (!nullToAbsent || clashRuleUrls != null) {
      map['clash_rule_urls'] = Variable<String>(
        $AtomicIpSetsTable.$converterclashRuleUrlsn.toSql(clashRuleUrls),
      );
    }
    if (!nullToAbsent || geoUrl != null) {
      map['geo_url'] = Variable<String>(geoUrl);
    }
    return map;
  }

  AtomicIpSetsCompanion toCompanion(bool nullToAbsent) {
    return AtomicIpSetsCompanion(
      name: Value(name),
      inverse: Value(inverse),
      geoIpConfig: geoIpConfig == null && nullToAbsent
          ? const Value.absent()
          : Value(geoIpConfig),
      clashRuleUrls: clashRuleUrls == null && nullToAbsent
          ? const Value.absent()
          : Value(clashRuleUrls),
      updatedAt: Value(updatedAt),
      geoUrl: geoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(geoUrl),
    );
  }

  factory AtomicIpSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    print(json);
    return AtomicIpSet(
      name: serializer.fromJson<String>(json['name']),
      inverse: serializer.fromJson<bool>(json['inverse']),
      geoIpConfig: json['geoIpConfig'] != null
          ? GeoIPConfig.fromJson(json['geoIpConfig'])
          : null,
      clashRuleUrls: json['clashRuleUrls'] != null
          ? (json['clashRuleUrls'] as List<dynamic>).cast<String>()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      geoUrl: json['geoUrl'] != null ? json['geoUrl'] as String : null,
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    final m = <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'inverse': serializer.toJson<bool>(inverse),
      'clashRuleUrls': serializer.toJson<List<String>?>(clashRuleUrls),
      'updatedAt': updatedAt?.toIso8601String(),
    };
    if (geoIpConfig != null) {
      m['geoIpConfig'] = geoIpConfig!.writeToJson();
    }
    if (geoUrl != null) {
      m['geoUrl'] = geoUrl;
    }
    return m;
  }
}

class AppSet extends DataClass implements Insertable<AppSet> {
  final String name;
  final List<String>? clashRuleUrls;
  final DateTime? updatedAt;
  const AppSet({required this.name, this.clashRuleUrls, this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || clashRuleUrls != null) {
      map['clash_rule_urls'] = Variable<String>(
        $AppSetsTable.$converterclashRuleUrlsn.toSql(clashRuleUrls),
      );
    }
    return map;
  }

  AppSetsCompanion toCompanion(bool nullToAbsent) {
    return AppSetsCompanion(
      name: Value(name),
      clashRuleUrls: clashRuleUrls == null && nullToAbsent
          ? const Value.absent()
          : Value(clashRuleUrls),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSet(
      name: serializer.fromJson<String>(json['name']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      clashRuleUrls: json['clashRuleUrls'] != null
          ? (json['clashRuleUrls'] as List<dynamic>).cast<String>()
          : null,
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'updatedAt': updatedAt?.toIso8601String(),
      'clashRuleUrls': serializer.toJson<List<String>?>(clashRuleUrls),
    };
  }
}

class DnsServer extends DataClass implements Insertable<DnsServer> {
  final int id;
  final String name;
  final dns.DnsServerConfig? dnsServer;
  final dns.ConcurrentDnsServer? concurrentDnsServer;
  final dns.SerialDnsServer? serialDnsServer;
  final DateTime? updatedAt;
  const DnsServer({
    required this.id,
    required this.name,
    this.dnsServer,
    this.concurrentDnsServer,
    this.serialDnsServer,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || dnsServer != null) {
      map['dns_server'] = Variable<Uint8List>(
        $DnsServersTable.$converterdnsServer.toSql(dnsServer!),
      );
    }
    if (!nullToAbsent || concurrentDnsServer != null) {
      map['concurrent_dns_server'] = Variable<Uint8List>(
        $DnsServersTable.$converterconcurrentDnsServer.toSql(
          concurrentDnsServer!,
        ),
      );
    }
    if (!nullToAbsent || serialDnsServer != null) {
      map['serial_dns_server'] = Variable<Uint8List>(
        $DnsServersTable.$converterserialDnsServer.toSql(serialDnsServer!),
      );
    }
    return map;
  }

  DnsServersCompanion toCompanion(bool nullToAbsent) {
    return DnsServersCompanion(
      id: Value(id),
      name: Value(name),
      updatedAt: Value(updatedAt),
      dnsServer: dnsServer == null ? const Value.absent() : Value(dnsServer!),
      concurrentDnsServer: concurrentDnsServer == null
          ? const Value.absent()
          : Value(concurrentDnsServer!),
      serialDnsServer: serialDnsServer == null
          ? const Value.absent()
          : Value(serialDnsServer!),
    );
  }

  factory DnsServer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DnsServer(
      id: serializer.fromJson<int>(json['id']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      name: serializer.fromJson<String>(json['name']),
      dnsServer: json['dnsServer'] != null
          ? dns.DnsServerConfig.fromJson(json['dnsServer'])
          : null,
      concurrentDnsServer: json['concurrentDnsServer'] != null
          ? dns.ConcurrentDnsServer.fromJson(json['concurrentDnsServer'])
          : null,
      serialDnsServer: json['serialDnsServer'] != null
          ? dns.SerialDnsServer.fromJson(json['serialDnsServer'])
          : null,
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'updatedAt': updatedAt?.toIso8601String(),
      'name': serializer.toJson<String>(name),
      'dnsServer': dnsServer?.writeToJson(),
      'concurrentDnsServer': concurrentDnsServer?.writeToJson(),
      'serialDnsServer': serialDnsServer?.writeToJson(),
    };
  }
}

class HandlerSelector extends DataClass implements Insertable<HandlerSelector> {
  final String name;
  final SelectorConfig config;
  final DateTime? updatedAt;
  const HandlerSelector({
    required this.name,
    required this.config,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['name'] = Variable<String>(name);
    {
      map['config'] = Variable<Uint8List>(
        $HandlerSelectorsTable.$converterconfig.toSql(config),
      );
    }
    return map;
  }

  HandlerSelectorsCompanion toCompanion(bool nullToAbsent) {
    return HandlerSelectorsCompanion(
      name: Value(name),
      config: Value(config),
      updatedAt: Value(updatedAt),
    );
  }

  factory HandlerSelector.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HandlerSelector(
      name: serializer.fromJson<String>(json['name']),
      config: SelectorConfig.fromJson(json['config']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'config': config.writeToJson(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class GeoDomain extends DataClass implements Insertable<GeoDomain> {
  final int id;
  final Domain geoDomain;
  final String domainSetName;
  const GeoDomain({
    required this.id,
    required this.geoDomain,
    required this.domainSetName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    {
      map['geo_domain'] = Variable<Uint8List>(
        $GeoDomainsTable.$convertergeoDomain.toSql(geoDomain),
      );
    }
    map['domain_set_name'] = Variable<String>(domainSetName);
    return map;
  }

  GeoDomainsCompanion toCompanion(bool nullToAbsent) {
    return GeoDomainsCompanion(
      id: Value(id),
      geoDomain: Value(geoDomain),
      domainSetName: Value(domainSetName),
    );
  }

  factory GeoDomain.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GeoDomain(
      id: serializer.fromJson<int>(json['id']),
      geoDomain: Domain.fromJson(json['geoDomain']),
      domainSetName: serializer.fromJson<String>(json['domainSetName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'geoDomain': geoDomain.writeToJson(),
      'domainSetName': serializer.toJson<String>(domainSetName),
    };
  }
}

class App extends DataClass implements Insertable<App> {
  final int id;
  final String appSetName;
  final AppId appId;
  final Uint8List? icon;
  final String? name;
  const App({
    required this.id,
    required this.appSetName,
    required this.appId,
    this.icon,
    this.name,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['app_set_name'] = Variable<String>(appSetName);
    {
      map['app_id'] = Variable<Uint8List>(
        $AppsTable.$converterappId.toSql(appId),
      );
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<Uint8List>(icon);
    }
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    return map;
  }

  AppsCompanion toCompanion(bool nullToAbsent) {
    return AppsCompanion(
      id: Value(id),
      appSetName: Value(appSetName),
      appId: Value(appId),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
    );
  }

  factory App.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return App(
      id: serializer.fromJson<int>(json['id']),
      appSetName: serializer.fromJson<String>(json['appSetName']),
      appId: AppId.fromJson(json['appId']),
      icon: serializer.fromJson<Uint8List?>(json['icon']),
      name: serializer.fromJson<String?>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'appSetName': serializer.toJson<String>(appSetName),
      'appId': appId.writeToJson(),
      'icon': serializer.toJson<Uint8List?>(icon),
      'name': serializer.toJson<String?>(name),
    };
  }
}

class Cidr extends DataClass implements Insertable<Cidr> {
  final int id;
  final String ipSetName;
  final CIDR cidr;
  const Cidr({required this.id, required this.ipSetName, required this.cidr});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ip_set_name'] = Variable<String>(ipSetName);
    {
      map['cidr'] = Variable<Uint8List>($CidrsTable.$convertercidr.toSql(cidr));
    }
    return map;
  }

  CidrsCompanion toCompanion(bool nullToAbsent) {
    return CidrsCompanion(
      id: Value(id),
      ipSetName: Value(ipSetName),
      cidr: Value(cidr),
    );
  }

  factory Cidr.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cidr(
      id: serializer.fromJson<int>(json['id']),
      ipSetName: serializer.fromJson<String>(json['ipSetName']),
      cidr: CIDR.fromJson(json['cidr']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ipSetName': serializer.toJson<String>(ipSetName),
      'cidr': cidr.writeToJson(),
    };
  }

  Cidr copyWith({int? id, String? ipSetName, CIDR? cidr}) => Cidr(
    id: id ?? this.id,
    ipSetName: ipSetName ?? this.ipSetName,
    cidr: cidr ?? this.cidr,
  );
  Cidr copyWithCompanion(CidrsCompanion data) {
    return Cidr(
      id: data.id.present ? data.id.value : id,
      ipSetName: data.ipSetName.present ? data.ipSetName.value : ipSetName,
      cidr: data.cidr.present ? data.cidr.value : cidr,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cidr(')
          ..write('id: $id, ')
          ..write('ipSetName: $ipSetName, ')
          ..write('cidr: $cidr')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ipSetName, cidr);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cidr &&
          other.id == id &&
          other.ipSetName == ipSetName &&
          other.cidr == cidr);
}

class AtomicDomainSet extends DataClass implements Insertable<AtomicDomainSet> {
  final String name;
  final GeositeConfig? geositeConfig;
  final bool inverse;
  final bool useBloomFilter;
  final List<String>? clashRuleUrls;
  final DateTime? updatedAt;
  final String? geoUrl;
  const AtomicDomainSet({
    required this.name,
    this.geositeConfig,
    this.inverse = false,
    required this.useBloomFilter,
    this.updatedAt,
    this.geoUrl,
    this.clashRuleUrls,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || geositeConfig != null) {
      map['geosite_config'] = Variable<Uint8List>(
        $AtomicDomainSetsTable.$convertergeositeConfign.toSql(geositeConfig),
      );
    }
    map['inverse'] = Variable<bool>(inverse);
    map['use_bloom_filter'] = Variable<bool>(useBloomFilter);
    if (!nullToAbsent || clashRuleUrls != null) {
      map['clash_rule_urls'] = Variable<String>(
        $AtomicDomainSetsTable.$converterclashRuleUrlsn.toSql(clashRuleUrls),
      );
    }
    if (!nullToAbsent || geoUrl != null) {
      map['geo_url'] = Variable<String>(geoUrl);
    }
    return map;
  }

  AtomicDomainSetsCompanion toCompanion(bool nullToAbsent) {
    return AtomicDomainSetsCompanion(
      name: Value(name),
      inverse: Value(inverse),
      geositeConfig: geositeConfig == null && nullToAbsent
          ? const Value.absent()
          : Value(geositeConfig),
      updatedAt: Value(updatedAt),
      useBloomFilter: Value(useBloomFilter),
      geoUrl: geoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(geoUrl),
      clashRuleUrls: clashRuleUrls == null && nullToAbsent
          ? const Value.absent()
          : Value(clashRuleUrls),
    );
  }

  factory AtomicDomainSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AtomicDomainSet(
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      name: serializer.fromJson<String>(json['name']),
      geositeConfig: json['geositeConfig'] != null
          ? GeositeConfig.fromJson(json['geositeConfig'])
          : null,
      useBloomFilter: serializer.fromJson<bool>(json['useBloomFilter']),
      clashRuleUrls: json['clashRuleUrls'] != null
          ? (json['clashRuleUrls'] as List<dynamic>).cast<String>()
          : null,
      geoUrl: json['geoUrl'] != null ? json['geoUrl'] as String : null,
      inverse: serializer.fromJson<bool>(json['inverse']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'updatedAt': updatedAt?.toIso8601String(),
      'name': serializer.toJson<String>(name),
      'inverse': serializer.toJson<bool>(inverse),
      'geositeConfig': geositeConfig?.writeToJson(),
      'useBloomFilter': serializer.toJson<bool>(useBloomFilter),
      'clashRuleUrls': serializer.toJson<List<String>?>(clashRuleUrls),
      'geoUrl': serializer.toJson<String?>(geoUrl),
    };
  }
}

class GreatDomainSet extends DataClass implements Insertable<GreatDomainSet> {
  final String name;
  final String? oppositeName;
  final GreatDomainSetConfig set;
  final DateTime? updatedAt;
  const GreatDomainSet({
    required this.name,
    this.oppositeName,
    required this.set,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || oppositeName != null) {
      map['opposite_name'] = Variable<String>(oppositeName);
    }
    {
      map['set'] = Variable<Uint8List>(
        $GreatDomainSetsTable.$converterset.toSql(set),
      );
    }
    return map;
  }

  GreatDomainSetsCompanion toCompanion(bool nullToAbsent) {
    return GreatDomainSetsCompanion(
      name: Value(name),
      oppositeName: oppositeName == null && nullToAbsent
          ? const Value.absent()
          : Value(oppositeName),
      updatedAt: Value(updatedAt),
      set: Value(set),
    );
  }

  factory GreatDomainSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GreatDomainSet(
      name: serializer.fromJson<String>(json['name']),
      oppositeName: serializer.fromJson<String?>(json['oppositeName']),
      set: GreatDomainSetConfig.fromJson(json['set']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'oppositeName': serializer.toJson<String?>(oppositeName),
      'set': set.writeToJson(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
