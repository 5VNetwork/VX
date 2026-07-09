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

import 'package:drift/drift.dart';
import 'package:tm/protos/vx/common/geo/geo.pb.dart';
import 'package:tm/protos/vx/dns/dns.pb.dart';
import 'package:tm/protos/vx/geo/geo.pb.dart';
import 'package:tm/protos/vx/router/router.pb.dart';
import 'package:vx/data/database.dart';
import 'package:vx/data/database_provider.dart';
import 'package:vx/utils/random.dart';

abstract class SelectorRepo {
  Future<SelectorConfig?> getSelector(String selectorName);
  Future<void> addSelector(SelectorConfig selector);
  Future<void> removeSelector(String selectorName);
  Future<void> updateSelector(SelectorConfig selector);
  Future<void> addSubscriptionToSelector(
    String selectorName,
    int subscriptionId,
  );
  Future<void> removeSubscriptionFromSelector(
    String selectorName,
    int subscriptionId,
  );
  Future<void> addHandlerGroupToSelector(String selectorName, String groupName);
  Future<void> removeHandlerGroupFromSelector(
    String selectorName,
    String groupName,
  );
  Future<void> addHandlerToSelector(String selectorName, int handlerId);
  Future<void> removeHandlerFromSelector(String selectorName, int handlerId);

  Future<List<SelectorConfig>> getAllSelectors();
  Stream<List<SelectorConfig>> getSelectorsStream();
}

abstract class RouteRepo {
  Future<CustomRouteMode?> getCustomRouteMode(String name);
  Future<void> removeCustomRouteMode(int id);
  Stream<List<CustomRouteMode>> getCustomRouteModesStream();
  Future<List<CustomRouteMode>> getAllCustomRouteModes();
  Future<void> updateCustomRouteMode(
    int id, {
    RouterConfig? routerConfig,
    DnsRules? dnsRules,
    String? name,
    List<String>? internalDnsServers,
  });
  Future<CustomRouteMode?> addCustomRouteMode(CustomRouteMode mode);
}

abstract class SetRepo {
  Future<void> addGeoDomain(String domainSetName, Domain domain);
  Future<void> bulkAddGeoDomain(String domainSetName, List<Domain> domains);
  Stream<List<GeoDomain>> getGeoDomainsStream(String domainSetName);
  Future<void> removeGeoDomain(GeoDomain geoDomain);
  Future<void> removeGreatDomainSet(String domainSetName);
  Future<void> removeAtomicDomainSet(String domainSetName);
  Future<void> addGreatDomainSet(GreatDomainSetConfig greatDomainSet);
  Stream<List<GreatDomainSet>> getGreatDomainSetsStream();
  Stream<List<AtomicDomainSet>> getAtomicDomainSetsStream();
  Future<void> addAtomicDomainSet(AtomicDomainSet atomicDomainSet);
  Future<AtomicDomainSet?> getAtomicDomainSet(String name);
  Future<void> updateAtomicDomainSet(
    String name, {
    GeositeConfig? geositeConfig,
    List<String>? clashRuleUrls,
    bool? useBloomFilter,
    String? geoUrl,
    bool? inverse,
    String? newName,
  });
  Future<void> updateGreateDomainSet(
    String name, {
    GreatDomainSetConfig? greatDomainSet,
    String? newName,
  });

  Future<void> addCidr(String ipSetName, CIDR cidr);
  Future<void> bulkAddCidr(String ipSetName, List<CIDR> cidrs);
  Stream<List<Cidr>> getCidrsStream(String ipSetName);
  Future<void> removeCidr(Cidr cidr);
  Future<void> addGreatIpSet(GreatIPSetConfig greatIpSet);
  Future<void> updateGreatIpSet(
    String name, {
    GreatIPSetConfig? greatIpSet,
    String? newName,
  });
  Future<void> removeGreatIpSet(String ipSetName);
  Future<void> addAtomicIpSet(AtomicIpSet atomicIpSet);
  Future<void> updateAtomicIpSet(
    String name, {
    GeoIPConfig? geoIpConfig,
    List<String>? clashRuleUrls,
    String? geoUrl,
    bool? inverse,
    String? newName,
  });
  Future<void> removeAtomicIpSet(String ipSetName);
  Stream<List<GreatIpSet>> getGreatIpSetsStream();
  Stream<List<AtomicIpSet>> getAtomicIpSetsStream();

  Future<void> addApp(
    String appSetName,
    AppId app, {
    Uint8List? icon,
    String? name,
  });
  Future<void> addApps(List<App> apps);
  Stream<List<App>> getAppsStream(String appSetName);
  Future<List<App>> getApps(String appSetName);
  Future<void> removeApp(List<int> ids);
  Future<void> addAppSet(AppSet appSet);
  Future<void> updateAppSet(
    String name, {
    List<String>? clashRuleUrls,
    String? newName,
  });
  Future<void> removeAppSet(String appSetName);
  Stream<List<AppSet>> getAppSetsStream();
}

abstract class DnsRepo {
  Future<List<DnsServer>> getDnsServers();
  Future<DnsServer> addDnsServer(
    String dnsServerName,
    DnsServerConfig dnsServer,
  );
  Future<void> updateDnsServer(
    DnsServer ds, {
    String? dnsServerName,
    DnsServerConfig? dnsServer,
  });
  Future<void> removeDnsServer(DnsServer ds);
  Stream<List<DnsServer>> getDnsServersStream();
  Future<List<DnsServer>> getConcurrentDnsServers();
  Future<DnsServer> addConcurrentDnsServer(
    String name,
    ConcurrentDnsServer config,
  );
  Future<void> updateConcurrentDnsServer(
    DnsServer row, {
    String? name,
    ConcurrentDnsServer? config,
  });
  Future<void> removeConcurrentDnsServer(DnsServer row);
  Stream<List<DnsServer>> getConcurrentDnsServersStream();
  Future<List<DnsServer>> getSerialDnsServers();
  Future<DnsServer> addSerialDnsServer(String name, SerialDnsServer config);
  Future<void> updateSerialDnsServer(
    DnsServer row, {
    String? name,
    SerialDnsServer? config,
  });
  Future<void> removeSerialDnsServer(DnsServer row);
  Stream<List<DnsServer>> getSerialDnsServersStream();

  Future<DnsRecord> addDnsRecord(Record record);
  Future<void> updateDnsRecord(DnsRecord record, Record newRecord);
  Future<void> removeDnsRecord(DnsRecord record);
  Stream<List<DnsRecord>> getDnsRecordsStream();
}

class DbHelper implements SelectorRepo, RouteRepo, SetRepo, DnsRepo {
  DbHelper({required DatabaseProvider databaseProvider})
    : _databaseProvider = databaseProvider;

  static const String _reservedDnsServerName = 'Hijack';
  final DatabaseProvider _databaseProvider;

  void _validateDnsServerName(String name) {
    if (name.trim().toLowerCase() == _reservedDnsServerName) {
      throw ArgumentError.value(
        name,
        'name',
        'DNS server name "Hijack" is reserved',
      );
    }
  }

  Future<List<AtomicIpSet>> getAtomicIpSets() async {
    return await _databaseProvider.database.managers.atomicIpSets.get();
  }

  Future<List<AtomicDomainSet>> getAtomicDomainSets() async {
    return await _databaseProvider.database.managers.atomicDomainSets.get();
  }

  Future<List<GreatDomainSet>> getGreatDomainSets() async {
    return await _databaseProvider.database.managers.greatDomainSets.get();
  }

  Future<List<AppSet>> getAppSets() async {
    return await _databaseProvider.database.managers.appSets.get();
  }

  @override
  Stream<List<DnsServer>> getDnsServersStream() {
    return (_databaseProvider.database.select(
      _databaseProvider.database.dnsServers,
    )..where((tbl) => tbl.dnsServer.isNotNull())).watch();
  }

  @override
  Stream<List<DnsServer>> getConcurrentDnsServersStream() {
    return (_databaseProvider.database.select(
      _databaseProvider.database.dnsServers,
    )..where((tbl) => tbl.concurrentDnsServer.isNotNull())).watch();
  }

  @override
  Stream<List<DnsServer>> getSerialDnsServersStream() {
    return (_databaseProvider.database.select(
      _databaseProvider.database.dnsServers,
    )..where((tbl) => tbl.serialDnsServer.isNotNull())).watch();
  }

  @override
  Stream<List<SelectorConfig>> getSelectorsStream() {
    return _databaseProvider.database
        .select(_databaseProvider.database.handlerSelectors)
        .watch()
        .asyncMap((q) {
          return Future.wait(
            q.map((e) {
              return _databaseProvider.database.selectorToConfig(e);
            }),
          );
        });
  }

  @override
  Future<void> removeCustomRouteMode(int id) async {
    await _databaseProvider.database.deleteById(
      _databaseProvider.database.customRouteModes,
      [id],
    );
  }

  @override
  Future<CustomRouteMode?> getCustomRouteMode(String name) async {
    return await _databaseProvider.database.managers.customRouteModes
        .filter((e) => e.name(name))
        .getSingleOrNull();
  }

  @override
  Stream<List<CustomRouteMode>> getCustomRouteModesStream() {
    return _databaseProvider.database
        .select(_databaseProvider.database.customRouteModes)
        .watch();
  }

  @override
  Stream<List<GreatDomainSet>> getGreatDomainSetsStream() {
    return _databaseProvider.database
        .select(_databaseProvider.database.greatDomainSets)
        .watch();
  }

  @override
  Stream<List<AtomicDomainSet>> getAtomicDomainSetsStream() {
    return _databaseProvider.database
        .select(_databaseProvider.database.atomicDomainSets)
        .watch();
  }

  @override
  Stream<List<AppSet>> getAppSetsStream() {
    return _databaseProvider.database
        .select(_databaseProvider.database.appSets)
        .watch();
  }

  @override
  Future<void> removeSelector(String selectorName) async {
    await _databaseProvider.database.deleteByName(
      _databaseProvider.database.handlerSelectors,
      selectorName,
    );
  }

  @override
  Future<void> updateSelector(SelectorConfig selector) async {
    await _databaseProvider.database.updateName(
      _databaseProvider.database.handlerSelectors,
      selector.tag,
      HandlerSelectorsCompanion(config: Value(selector)),
    );
  }

  @override
  Future<void> addGreatIpSet(GreatIPSetConfig greatIpSet) async {
    await _databaseProvider.database.insertReturning(
      _databaseProvider.database.greatIpSets,
      GreatIpSetsCompanion(
        name: Value(greatIpSet.name),
        greatIpSetConfig: Value(greatIpSet),
        oppositeName: Value(greatIpSet.oppositeName),
      ),
    );
    // await _databaseProvider.database.managers.greatIpSets.create(
    //     (o) => o(name: greatIpSet.name, greatIpSetConfig: greatIpSet),
    //     mode: InsertMode.insert);
  }

  @override
  Future<void> updateGreatIpSet(
    String name, {
    GreatIPSetConfig? greatIpSet,
    String? newName,
  }) async {
    await _databaseProvider.database.updateName(
      _databaseProvider.database.greatIpSets,
      name,
      GreatIpSetsCompanion(
        name: newName != null ? Value(newName) : const Value.absent(),
        greatIpSetConfig: greatIpSet != null
            ? Value(greatIpSet)
            : const Value.absent(),
        oppositeName: greatIpSet != null
            ? Value(greatIpSet.oppositeName)
            : const Value.absent(),
      ),
    );
    // await _databaseProvider.database.managers.greatIpSets
    //     .filter((f) => f.name.equals(name))
    //     .update((o) => o(
    //         name: newName != null ? Value(newName) : const Value.absent(),
    //         greatIpSetConfig:
    //             greatIpSet != null ? Value(greatIpSet) : const Value.absent()));
  }

  @override
  Future<void> removeGreatIpSet(String ipSetName) async {
    await _databaseProvider.database.deleteByName(
      _databaseProvider.database.greatIpSets,
      ipSetName,
    );
    // await _databaseProvider.database.managers.greatIpSets
    //     .filter((f) => f.name.equals(ipSetName))
    //     .delete();
  }

  @override
  Future<void> addAtomicIpSet(AtomicIpSet config) async {
    await _databaseProvider.database.insertReturning(
      _databaseProvider.database.atomicIpSets,
      AtomicIpSetsCompanion(
        name: Value(config.name),
        geoIpConfig: Value(config.geoIpConfig),
        clashRuleUrls: Value(config.clashRuleUrls),
        geoUrl: Value(config.geoUrl),
        inverse: Value(config.inverse),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  @override
  Future<void> updateAtomicIpSet(
    String name, {
    GeoIPConfig? geoIpConfig,
    List<String>? clashRuleUrls,
    String? newName,
    String? geoUrl,
    bool? inverse,
  }) async {
    await _databaseProvider.database.updateName(
      _databaseProvider.database.atomicIpSets,
      name,
      AtomicIpSetsCompanion(
        name: newName != null ? Value(newName) : const Value.absent(),
        geoIpConfig: geoIpConfig != null
            ? Value(geoIpConfig)
            : const Value.absent(),
        clashRuleUrls: clashRuleUrls != null
            ? Value(clashRuleUrls)
            : const Value.absent(),
        geoUrl: geoUrl != null ? Value(geoUrl) : const Value.absent(),
        inverse: inverse != null ? Value(inverse) : const Value.absent(),
      ),
    );
  }

  @override
  Future<void> removeAtomicIpSet(String ipSetName) async {
    await _databaseProvider.database.deleteByName(
      _databaseProvider.database.atomicIpSets,
      ipSetName,
    );
    // await _databaseProvider.database.managers.atomicIpSets
    //     .filter((f) => f.name.equals(ipSetName))
    //     .delete();
  }

  @override
  Future<void> addAppSet(AppSet appSet) async {
    // final data = AppSetsCompanion(
    //   name: Value(appSet.name),
    //   clashRuleUrls: Value(appSet.clashRuleUrls),
    // );
    // await _databaseProvider.database.into(_databaseProvider.database.appSets).insertOnConflictUpdate(data);
    await _databaseProvider.database.insertReturning(
      _databaseProvider.database.appSets,
      AppSetsCompanion(
        name: Value(appSet.name),
        clashRuleUrls: Value(appSet.clashRuleUrls),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  @override
  Future<void> updateAppSet(
    String name, {
    List<String>? clashRuleUrls,
    String? newName,
  }) async {
    await _databaseProvider.database.updateName(
      _databaseProvider.database.appSets,
      name,
      AppSetsCompanion(
        name: newName != null ? Value(newName) : const Value.absent(),
        clashRuleUrls: clashRuleUrls != null
            ? Value(clashRuleUrls)
            : const Value.absent(),
      ),
    );
  }

  @override
  Future<void> removeAppSet(String appSetName) async {
    await _databaseProvider.database.deleteByName(
      _databaseProvider.database.appSets,
      appSetName,
    );
    // await _databaseProvider.database.managers.appSets
    //     .filter((f) => f.name.equals(appSetName))
    //     .delete();
  }

  @override
  Future<void> removeAtomicDomainSet(String domainSetName) async {
    await _databaseProvider.database.deleteByName(
      _databaseProvider.database.atomicDomainSets,
      domainSetName,
    );
    // await _databaseProvider.database.managers.atomicDomainSets
    //     .filter((f) => f.name.equals(domainSetName))
    //     .delete();
  }

  @override
  Future<void> removeGreatDomainSet(String domainSetName) async {
    // await _databaseProvider.database.managers.greatDomainSets
    //     .filter((f) => f.name.equals(domainSetName))
    //     .delete();
    await _databaseProvider.database.deleteByName(
      _databaseProvider.database.greatDomainSets,
      domainSetName,
    );
  }

  @override
  Future<AtomicDomainSet?> getAtomicDomainSet(String name) async {
    return await (_databaseProvider.database.select(
      _databaseProvider.database.atomicDomainSets,
    )..where((t) => t.name.equals(name))).getSingleOrNull();
  }

  @override
  Future<void> addAtomicDomainSet(AtomicDomainSet config) async {
    await _databaseProvider.database.insertReturning(
      _databaseProvider.database.atomicDomainSets,
      AtomicDomainSetsCompanion(
        name: Value(config.name),
        geositeConfig: Value(config.geositeConfig),
        clashRuleUrls: Value(config.clashRuleUrls),
        useBloomFilter: Value(config.useBloomFilter),
        geoUrl: Value(config.geoUrl),
        inverse: Value(config.inverse),
      ),
    );
    // await _databaseProvider.database.managers.atomicDomainSets.create(
    //     (o) => o(
    //         name: config.name,
    //         geositeConfig: Value(config.geositeConfig),
    //         clashRuleUrls: Value(config.clashRuleUrls),
    //         useBloomFilter: Value(config.useBloomFilter)),
    //     mode: InsertMode.insert);
  }

  @override
  Future<void> updateAtomicDomainSet(
    String name, {
    GeositeConfig? geositeConfig,
    List<String>? clashRuleUrls,
    bool? useBloomFilter,
    String? geoUrl,
    bool? inverse,
    String? newName,
  }) async {
    // await _databaseProvider.database.managers.atomicDomainSets
    //     .filter((f) => f.name.equals(name))
    //     .update((o) => o(
    //         name: newName != null ? Value(newName) : const Value.absent(),
    //         geositeConfig: geositeConfig != null
    //             ? Value(geositeConfig)
    //             : const Value.absent(),
    //         clashRuleUrls: clashRuleUrls != null
    //             ? Value(clashRuleUrls)
    //             : const Value.absent(),
    //         useBloomFilter: useBloomFilter != null
    //             ? Value(useBloomFilter)
    //             : const Value.absent()));
    await _databaseProvider.database.updateName(
      _databaseProvider.database.atomicDomainSets,
      name,
      AtomicDomainSetsCompanion(
        name: newName != null ? Value(newName) : const Value.absent(),
        geositeConfig: geositeConfig != null
            ? Value(geositeConfig)
            : const Value.absent(),
        clashRuleUrls: clashRuleUrls != null
            ? Value(clashRuleUrls)
            : const Value.absent(),
        useBloomFilter: useBloomFilter != null
            ? Value(useBloomFilter)
            : const Value.absent(),
        geoUrl: geoUrl != null ? Value(geoUrl) : const Value.absent(),
        inverse: inverse != null ? Value(inverse) : const Value.absent(),
      ),
    );
  }

  @override
  Future<void> addGreatDomainSet(GreatDomainSetConfig config) async {
    // await _databaseProvider.database.managers.greatDomainSets.create(
    //     (o) => o(
    //         name: config.name,
    //         set: config,
    //         oppositeName: Value(config.oppositeName)),
    //     mode: InsertMode.insert);
    await _databaseProvider.database.insertReturning(
      _databaseProvider.database.greatDomainSets,
      GreatDomainSetsCompanion(
        name: Value(config.name),
        set: Value(config),
        oppositeName: Value(config.oppositeName),
      ),
    );
  }

  @override
  Future<void> updateGreateDomainSet(
    String name, {
    GreatDomainSetConfig? greatDomainSet,
    String? newName,
  }) async {
    // await _databaseProvider.database.managers.greatDomainSets
    //     .filter((f) => f.name.equals(name))
    //     .update((o) => o(
    //           name: newName != null ? Value(newName) : const Value.absent(),
    //           oppositeName: greatDomainSet != null
    //               ? Value(greatDomainSet.oppositeName)
    //               : const Value.absent(),
    //           set: greatDomainSet != null
    //               ? Value(greatDomainSet)
    //               : const Value.absent(),
    //         ));
    await _databaseProvider.database.updateName(
      _databaseProvider.database.greatDomainSets,
      name,
      GreatDomainSetsCompanion(
        name: newName != null ? Value(newName) : const Value.absent(),
        oppositeName: greatDomainSet != null
            ? Value(greatDomainSet.oppositeName)
            : const Value.absent(),
        set: greatDomainSet != null
            ? Value(greatDomainSet)
            : const Value.absent(),
      ),
    );
  }

  // RouteRepo
  @override
  Future<List<CustomRouteMode>> getAllCustomRouteModes() async {
    return await _databaseProvider.database.managers.customRouteModes.get();
  }

  @override
  Future<CustomRouteMode?> addCustomRouteMode(CustomRouteMode mode) async {
    // final data = CustomRouteModesCompanion(
    //   id: Value(mode.id),
    //   name: Value(mode.name),
    //   routerConfig: Value(mode.routerConfig),
    //   dnsRules: Value(mode.dnsRules),
    // );
    // final ret = await database
    //     .into(_databaseProvider.database.customRouteModes)
    //     .insertReturningOrNull(data, mode: InsertMode.insertOrIgnore);
    final ret = await _databaseProvider.database.insertReturning(
      _databaseProvider.database.customRouteModes,
      CustomRouteModesCompanion(
        id: Value(mode.id),
        name: Value(mode.name),
        routerConfig: Value(mode.routerConfig),
        dnsRules: Value(mode.dnsRules),
        internalDnsServers: Value(mode.internalDnsServers),
      ),
    );
    return ret;
  }

  @override
  Future<void> updateCustomRouteMode(
    int id, {
    RouterConfig? routerConfig,
    DnsRules? dnsRules,
    String? name,
    List<String>? internalDnsServers,
  }) async {
    // await _databaseProvider.database.managers.customRouteModes
    //     .filter((e) => e.id(id))
    //     .update((o) => o(
    //           routerConfig: routerConfig != null
    //               ? Value(routerConfig)
    //               : const Value.absent(),
    //           dnsRules:
    //               dnsRules != null ? Value(dnsRules) : const Value.absent(),
    //           name: name != null ? Value(name) : const Value.absent(),
    //         ));
    await _databaseProvider.database.updateById(
      _databaseProvider.database.customRouteModes,
      id,
      CustomRouteModesCompanion(
        routerConfig: routerConfig != null
            ? Value(routerConfig)
            : const Value.absent(),
        dnsRules: dnsRules != null ? Value(dnsRules) : const Value.absent(),
        name: name != null ? Value(name) : const Value.absent(),
        internalDnsServers: internalDnsServers != null
            ? Value(internalDnsServers)
            : const Value.absent(),
      ),
    );
  }

  // DnsRepo
  @override
  Future<List<DnsServer>> getDnsServers() async {
    return await (_databaseProvider.database.select(
      _databaseProvider.database.dnsServers,
    )).get();
  }

  @override
  Future<List<DnsServer>> getConcurrentDnsServers() async {
    return await (_databaseProvider.database.select(
      _databaseProvider.database.dnsServers,
    )..where((tbl) => tbl.concurrentDnsServer.isNotNull())).get();
  }

  @override
  Future<List<DnsServer>> getSerialDnsServers() async {
    return await (_databaseProvider.database.select(
      _databaseProvider.database.dnsServers,
    )..where((tbl) => tbl.serialDnsServer.isNotNull())).get();
  }

  @override
  Future<void> updateDnsServer(
    DnsServer ds, {
    String? dnsServerName,
    DnsServerConfig? dnsServer,
  }) async {
    if (dnsServerName != null) {
      _validateDnsServerName(dnsServerName);
    }
    // await _databaseProvider.database.managers.dnsServers.filter((f) => f.id(ds.id)).update((o) =>
    //     o(
    //         name: dnsServerName != null
    //             ? Value(dnsServerName)
    //             : const Value.absent(),
    //         dnsServer:
    //             dnsServer != null ? Value(dnsServer) : const Value.absent()));
    await _databaseProvider.database.updateById(
      _databaseProvider.database.dnsServers,
      ds.id,
      DnsServersCompanion(
        name: dnsServerName != null
            ? Value(dnsServerName)
            : const Value.absent(),
        dnsServer: dnsServer != null ? Value(dnsServer) : const Value.absent(),
        concurrentDnsServer: const Value.absent(),
        serialDnsServer: const Value.absent(),
      ),
    );
  }

  @override
  Future<DnsServer> addDnsServer(
    String dnsServerName,
    DnsServerConfig dnsServer,
  ) async {
    _validateDnsServerName(dnsServerName);
    // final data = DnsServersCompanion(
    //   name: Value(dnsServerName),
    //   dnsServer: Value(dnsServer),
    // );
    // return await _databaseProvider.database.into(_databaseProvider.database.dnsServers).insertReturning(data);
    return await _databaseProvider.database.insertReturning(
      _databaseProvider.database.dnsServers,
      DnsServersCompanion(
        id: Value(SnowflakeId.generate()),
        name: Value(dnsServerName),
        dnsServer: Value(dnsServer),
        concurrentDnsServer: const Value.absent(),
        serialDnsServer: const Value.absent(),
      ),
    );
  }

  @override
  Future<void> removeDnsServer(DnsServer ds) async {
    // await _databaseProvider.database.managers.dnsServers.filter((f) => f.name(ds.name)).delete();
    await _databaseProvider.database.deleteByName(
      _databaseProvider.database.dnsServers,
      ds.name,
    );
  }

  @override
  Future<DnsServer> addConcurrentDnsServer(
    String name,
    ConcurrentDnsServer config,
  ) async {
    _validateDnsServerName(name);
    return await _databaseProvider.database.insertReturning(
      _databaseProvider.database.dnsServers,
      DnsServersCompanion(
        id: Value(SnowflakeId.generate()),
        name: Value(name),
        dnsServer: const Value.absent(),
        concurrentDnsServer: Value(config),
        serialDnsServer: const Value.absent(),
      ),
    );
  }

  @override
  Future<void> updateConcurrentDnsServer(
    DnsServer row, {
    String? name,
    ConcurrentDnsServer? config,
  }) async {
    if (name != null) {
      _validateDnsServerName(name);
    }
    await _databaseProvider.database.updateById(
      _databaseProvider.database.dnsServers,
      row.id,
      DnsServersCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        dnsServer: const Value.absent(),
        concurrentDnsServer: config != null
            ? Value(config)
            : const Value.absent(),
        serialDnsServer: const Value.absent(),
      ),
    );
  }

  @override
  Future<void> removeConcurrentDnsServer(DnsServer row) async {
    await _databaseProvider.database.deleteByName(
      _databaseProvider.database.dnsServers,
      row.name,
    );
  }

  @override
  Future<DnsServer> addSerialDnsServer(
    String name,
    SerialDnsServer config,
  ) async {
    _validateDnsServerName(name);
    return await _databaseProvider.database.insertReturning(
      _databaseProvider.database.dnsServers,
      DnsServersCompanion(
        id: Value(SnowflakeId.generate()),
        name: Value(name),
        dnsServer: const Value.absent(),
        concurrentDnsServer: const Value.absent(),
        serialDnsServer: Value(config),
      ),
    );
  }

  @override
  Future<void> updateSerialDnsServer(
    DnsServer row, {
    String? name,
    SerialDnsServer? config,
  }) async {
    if (name != null) {
      _validateDnsServerName(name);
    }
    await _databaseProvider.database.updateById(
      _databaseProvider.database.dnsServers,
      row.id,
      DnsServersCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        dnsServer: const Value.absent(),
        concurrentDnsServer: const Value.absent(),
        serialDnsServer: config != null ? Value(config) : const Value.absent(),
      ),
    );
  }

  @override
  Future<void> removeSerialDnsServer(DnsServer row) async {
    await _databaseProvider.database.deleteByName(
      _databaseProvider.database.dnsServers,
      row.name,
    );
  }

  @override
  Future<DnsRecord> addDnsRecord(Record record) async {
    return await _databaseProvider.database.insertReturning(
      _databaseProvider.database.dnsRecords,
      DnsRecordsCompanion.insert(dnsRecord: record),
    );
  }

  @override
  Future<void> updateDnsRecord(DnsRecord record, Record newRecord) async {
    await _databaseProvider.database.updateById(
      _databaseProvider.database.dnsRecords,
      record.id,
      DnsRecordsCompanion(dnsRecord: Value(newRecord)),
    );
  }

  @override
  Future<void> removeDnsRecord(DnsRecord record) async {
    await _databaseProvider.database.deleteById(
      _databaseProvider.database.dnsRecords,
      [record.id],
    );
  }

  @override
  Stream<List<DnsRecord>> getDnsRecordsStream() {
    return _databaseProvider.database
        .select(_databaseProvider.database.dnsRecords)
        .watch();
  }

  // GeoRepo
  @override
  Future<void> addGeoDomain(String setName, Domain d) async {
    await _databaseProvider.database.insertReturning(
      _databaseProvider.database.geoDomains,
      GeoDomainsCompanion(geoDomain: Value(d), domainSetName: Value(setName)),
    );
    // final data =
    //     GeoDomainsCompanion(geoDomain: Value(d), domainSetName: Value(setName));
    // await database
    //     .into(_databaseProvider.database.geoDomains)
    //     .insert(data, mode: InsertMode.insertOrIgnore);
    // } on DriftRemoteException catch (e) {
    //                       if (e.remoteCause is SqliteException &&
    //                           (e.remoteCause as SqliteException)
    //                                   .extendedResultCode ==
    //                               2067) {
    //                         snack(
    //                             rootLocalizations()?.addFailedUniqueConstraint);
    //                       }
    //                     } catch (e) {
  }

  @override
  Stream<List<GeoDomain>> getGeoDomainsStream(String domainSetName) {
    return (_databaseProvider.database.select(
      _databaseProvider.database.geoDomains,
    )..where((t) => t.domainSetName.equals(domainSetName))).watch();
  }

  @override
  Future<void> bulkAddGeoDomain(
    String domainSetName,
    List<Domain> domains,
  ) async {
    await _databaseProvider.database.transactionInsert(
      _databaseProvider.database.geoDomains,
      domains
          .map(
            (e) => GeoDomainsCompanion(
              geoDomain: Value(e),
              domainSetName: Value(domainSetName),
            ),
          )
          .toList(),
    );
    // await _databaseProvider.database.managers.geoDomains.bulkCreate((o) => [
    //       ...domains.map((e) => o(
    //             geoDomain: e,
    //             domainSetName: domainSetName,
    //           )),
    //     ]);
  }

  @override
  Future<void> removeGeoDomain(GeoDomain geoDomain) async {
    // await (_databaseProvider.database.delete(_databaseProvider.database.geoDomains)
    //       ..where((t) => t.id.equals(geoDomain.id)))
    //     .go();
    await _databaseProvider.database.deleteById(
      _databaseProvider.database.geoDomains,
      [geoDomain.id],
    );
  }

  @override
  Future<void> addCidr(String ipSetName, CIDR cidr) async {
    // final data = CidrsCompanion(
    //   cidr: Value(cidr),
    //   ipSetName: Value(ipSetName),
    // );
    // await database
    //     .into(_databaseProvider.database.cidrs)
    //     .insert(data, mode: InsertMode.insertOrIgnore);
    await _databaseProvider.database.insertReturning(
      _databaseProvider.database.cidrs,
      CidrsCompanion(cidr: Value(cidr), ipSetName: Value(ipSetName)),
    );
  }

  @override
  Future<void> bulkAddCidr(String ipSetName, List<CIDR> cidrs) async {
    // await _databaseProvider.database.transaction(() async {
    //   for (var cidr in cidrs) {
    //     final data = CidrsCompanion(
    //       ipSetName: Value(ipSetName),
    //       cidr: Value(cidr),
    //     );
    //     await database
    //         .into(_databaseProvider.database.cidrs)
    //         .insert(data, mode: InsertMode.insertOrIgnore);
    //   }
    // });
    await _databaseProvider.database.transactionInsert(
      _databaseProvider.database.cidrs,
      cidrs
          .map(
            (e) => CidrsCompanion(ipSetName: Value(ipSetName), cidr: Value(e)),
          )
          .toList(),
    );
  }

  @override
  Future<void> removeCidr(Cidr cidr) async {
    // await (_databaseProvider.database.delete(_databaseProvider.database.cidrs)..where((t) => t.id.equals(cidr.id)))
    //     .go();
    await _databaseProvider.database.deleteById(
      _databaseProvider.database.cidrs,
      [cidr.id],
    );
  }

  @override
  Stream<List<Cidr>> getCidrsStream(String ipSetName) {
    return (_databaseProvider.database.select(
      _databaseProvider.database.cidrs,
    )..where((t) => t.ipSetName.equals(ipSetName))).watch();
  }

  @override
  Future<void> addApp(
    String appSetName,
    AppId app, {
    Uint8List? icon,
    String? name,
  }) async {
    // only keyword type is synced
    if (app.type == AppId_Type.Keyword) {
      await _databaseProvider.database.insertReturning(
        _databaseProvider.database.apps,
        AppsCompanion(
          appId: Value(app),
          appSetName: Value(appSetName),
          icon: icon != null ? Value(icon) : const Value.absent(),
          name: name != null ? Value(name) : const Value.absent(),
        ),
      );
    } else {
      final data = AppsCompanion(
        appId: Value(app),
        appSetName: Value(appSetName),
        icon: icon != null ? Value(icon) : const Value.absent(),
        name: name != null ? Value(name) : const Value.absent(),
      );
      await _databaseProvider.database
          .into(_databaseProvider.database.apps)
          .insert(data, mode: InsertMode.insertOrIgnore);
    }
  }

  @override
  Future<void> addApps(List<App> apps) async {
    // await _databaseProvider.database.managers.apps.bulkCreate((o) => [
    //       ...apps.map((e) => o(
    //             appSetName: e.appSetName,
    //             appId: e.appId,
    //             icon: e.icon != null ? Value(e.icon!) : const Value.absent(),
    //           )),
    //     ]);
    await _databaseProvider.database.transactionInsert(
      _databaseProvider.database.apps,
      apps
          .map(
            (e) => AppsCompanion(
              appSetName: Value(e.appSetName),
              appId: Value(e.appId),
              icon: e.icon != null ? Value(e.icon!) : const Value.absent(),
              name: e.name != null ? Value(e.name!) : const Value.absent(),
            ),
          )
          .toList(),
    );
  }

  @override
  Stream<List<App>> getAppsStream(String appSetName) {
    return (_databaseProvider.database.select(
      _databaseProvider.database.apps,
    )..where((t) => t.appSetName.equals(appSetName))).watch().map((query) {
      return query.toList();
    });
  }

  @override
  Future<List<App>> getApps(String appSetName) async {
    return await (_databaseProvider.database.select(
      _databaseProvider.database.apps,
    )..where((t) => t.appSetName.equals(appSetName))).get();
  }

  @override
  Future<void> removeApp(List<int> ids) async {
    // await (_databaseProvider.database.delete(_databaseProvider.database.apps)..where((t) => t.id.equals(id))).go();
    await _databaseProvider.database.deleteById(
      _databaseProvider.database.apps,
      ids,
    );
  }

  // SelectorRepo
  @override
  Future<List<SelectorConfig>> getAllSelectors() async {
    final selectors = await _databaseProvider.database.managers.handlerSelectors
        .get();
    final configs = <SelectorConfig>[];
    for (var selector in selectors) {
      configs.add(await _databaseProvider.database.selectorToConfig(selector));
    }
    return configs;
  }

  @override
  Future<void> addSubscriptionToSelector(
    String selectorName,
    int subscriptionId,
  ) async {
    await _databaseProvider.database.insertReturning(
      _databaseProvider.database.selectorSubscriptionRelations,
      SelectorSubscriptionRelationsCompanion(
        id: Value(SnowflakeId.generate()),
        selectorName: Value(selectorName),
        subscriptionId: Value(subscriptionId),
      ),
    );
  }

  @override
  Future<void> removeSubscriptionFromSelector(
    String selectorName,
    int subscriptionId,
  ) async {
    final relation =
        await ((_databaseProvider.database.select(
              _databaseProvider.database.selectorSubscriptionRelations,
            ))..where(
              (f) =>
                  f.selectorName.equals(selectorName) &
                  f.subscriptionId.equals(subscriptionId),
            ))
            .getSingleOrNull();
    if (relation != null) {
      await _databaseProvider.database.deleteById(
        _databaseProvider.database.selectorSubscriptionRelations,
        [relation.id],
      );
    }
    // await (_databaseProvider.database.delete(_databaseProvider.database.selectorSubscriptionRelations)
    //       ..where((f) =>
    //           f.selectorName.equals(selectorName) &
    //           f.subscriptionId.equals(subscriptionId)))
    //     .go();
  }

  @override
  Future<void> addHandlerGroupToSelector(
    String selectorName,
    String groupName,
  ) async {
    // await database
    //     .into(_databaseProvider.database.selectorHandlerGroupRelations)
    //     .insert(SelectorHandlerGroupRelationsCompanion(
    //       selectorName: Value(selectorName),
    //       groupName: Value(groupName),
    //     ));
    await _databaseProvider.database.insertReturning(
      _databaseProvider.database.selectorHandlerGroupRelations,
      SelectorHandlerGroupRelationsCompanion(
        id: Value(SnowflakeId.generate()),
        selectorName: Value(selectorName),
        groupName: Value(groupName),
      ),
    );
  }

  @override
  Future<void> removeHandlerGroupFromSelector(
    String selectorName,
    String groupName,
  ) async {
    final relation =
        await ((_databaseProvider.database.select(
              _databaseProvider.database.selectorHandlerGroupRelations,
            ))..where(
              (f) =>
                  f.selectorName.equals(selectorName) &
                  f.groupName.equals(groupName),
            ))
            .getSingleOrNull();
    if (relation != null) {
      await _databaseProvider.database.deleteById(
        _databaseProvider.database.selectorHandlerGroupRelations,
        [relation.id],
      );
    }
    // await (_databaseProvider.database.delete(_databaseProvider.database.selectorHandlerGroupRelations)
    //       ..where((f) =>
    //           f.selectorName.equals(selectorName) &
    //           f.groupName.equals(groupName)))
    //     .go();
  }

  @override
  Future<void> addHandlerToSelector(String selectorName, int handlerId) async {
    await _databaseProvider.database.insertReturning(
      _databaseProvider.database.selectorHandlerRelations,
      SelectorHandlerRelationsCompanion(
        id: Value(SnowflakeId.generate()),
        selectorName: Value(selectorName),
        handlerId: Value(handlerId),
      ),
    );
    // await database
    //     .into(_databaseProvider.database.selectorHandlerRelations)
    //     .insert(SelectorHandlerRelationsCompanion(
    //       selectorName: Value(selectorName),
    //       handlerId: Value(handlerId),
    //     ));
  }

  @override
  Future<void> removeHandlerFromSelector(
    String selectorName,
    int handlerId,
  ) async {
    // await (_databaseProvider.database.delete(_databaseProvider.database.selectorHandlerRelations)
    //       ..where((f) =>
    //           f.selectorName.equals(selectorName) &
    //           f.handlerId.equals(handlerId)))
    //     .go();
    final relation =
        await ((_databaseProvider.database.select(
              _databaseProvider.database.selectorHandlerRelations,
            ))..where(
              (f) =>
                  f.selectorName.equals(selectorName) &
                  f.handlerId.equals(handlerId),
            ))
            .getSingleOrNull();
    if (relation != null) {
      await _databaseProvider.database.deleteById(
        _databaseProvider.database.selectorHandlerRelations,
        [relation.id],
      );
    }
  }

  @override
  Future<SelectorConfig?> getSelector(String selectorName) async {
    return await _databaseProvider.database.getSelectorConfig(selectorName);
  }

  @override
  Future<void> addSelector(SelectorConfig selector) async {
    await _databaseProvider.database.insertReturning(
      _databaseProvider.database.handlerSelectors,
      HandlerSelectorsCompanion(
        name: Value(selector.tag),
        config: Value(selector),
      ),
    );
  }

  @override
  Stream<List<GreatIpSet>> getGreatIpSetsStream() {
    return _databaseProvider.database
        .select(_databaseProvider.database.greatIpSets)
        .watch();
  }

  @override
  Stream<List<AtomicIpSet>> getAtomicIpSetsStream() {
    return _databaseProvider.database
        .select(_databaseProvider.database.atomicIpSets)
        .watch();
  }
}
