// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:tm/protos/vx/common/geo/geo.pb.dart';
import 'package:tm/protos/vx/dns/dns.pb.dart';
import 'package:tm/protos/vx/geo/geo.pb.dart';
import 'package:tm/protos/vx/outbound/outbound.pb.dart';
import 'package:tm/protos/vx/router/router.pb.dart';
import 'package:vx/app/routing/default.dart';
import 'package:vx/app/routing/routing_page.dart';
import 'package:vx/data/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vx/xconfig_helper.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;
import 'generated/schema_v5.dart' as v5;
import 'generated/schema_v13.dart' as v13;
import 'generated/schema_v14.dart' as v14;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(
              path: 'test_db.db',
              executor: schema.newConnection(),
            );
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // The following template shows how to write tests ensuring your migrations
  // preserve existing data.
  // Testing this can be useful for migrations that change existing columns
  // (e.g. by alterating their type or constraints). Migrations that only add
  // tables or columns typically don't need these advanced tests. For more
  // information, see https://drift.simonbinder.eu/migrations/tests/#verifying-data-integrity
  // TODO: This generated template shows how these tests could be written. Adopt
  // it to your own needs when testing migrations with data integrity.
  test('migration from v1 to v2 does not corrupt data', () async {
    // Add data to insert into the old database, and the expected rows after the
    // migration.
    // TODO: Fill these lists
    final oldSubscriptionsData = <v1.SubscriptionsData>[];
    final expectedNewSubscriptionsData = <v2.SubscriptionsData>[];

    final oldOutboundHandlersData = <v1.OutboundHandlersData>[];
    final expectedNewOutboundHandlersData = <v2.OutboundHandlersData>[];

    final oldDnsRecordsData = <v1.DnsRecordsData>[];
    final expectedNewDnsRecordsData = <v2.DnsRecordsData>[];

    final oldGeoDomainsData = <v1.GeoDomainsData>[];
    final expectedNewGeoDomainsData = <v2.GeoDomainsData>[];

    final oldAppsData = <v1.AppsData>[];
    final expectedNewAppsData = <v2.AppsData>[];

    final oldCidrsData = <v1.CidrsData>[];
    final expectedNewCidrsData = <v2.CidrsData>[];

    final oldSshServersData = <v1.SshServersData>[];
    final expectedNewSshServersData = <v2.SshServersData>[];

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: (executor) =>
          AppDatabase(path: 'test_db.db', executor: executor),
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.subscriptions, oldSubscriptionsData);
        batch.insertAll(oldDb.outboundHandlers, oldOutboundHandlersData);
        batch.insertAll(oldDb.dnsRecords, oldDnsRecordsData);
        batch.insertAll(oldDb.geoDomains, oldGeoDomainsData);
        batch.insertAll(oldDb.apps, oldAppsData);
        batch.insertAll(oldDb.cidrs, oldCidrsData);
        batch.insertAll(oldDb.sshServers, oldSshServersData);
      },
      validateItems: (newDb) async {
        expect(
          expectedNewSubscriptionsData,
          await newDb.select(newDb.subscriptions).get(),
        );
        expect(
          expectedNewOutboundHandlersData,
          await newDb.select(newDb.outboundHandlers).get(),
        );
        expect(
          expectedNewDnsRecordsData,
          await newDb.select(newDb.dnsRecords).get(),
        );
        expect(
          expectedNewGeoDomainsData,
          await newDb.select(newDb.geoDomains).get(),
        );
        expect(expectedNewAppsData, await newDb.select(newDb.apps).get());
        expect(expectedNewCidrsData, await newDb.select(newDb.cidrs).get());
        expect(
          expectedNewSshServersData,
          await newDb.select(newDb.sshServers).get(),
        );
      },
    );
  });

  test('upgrade from v2 to v3', () async {
    // TestWidgetsFlutterBinding.ensureInitialized();
    final schema = await verifier.schemaAt(2);

    // Add some data to the table being migrated
    final oldDb = v2.DatabaseAtV2(schema.newConnection());
    await oldDb
        .into(oldDb.outboundHandlers)
        .insert(
          v2.OutboundHandlersCompanion.insert(
            selected: false,
            enabled: true,
            countryCode: 'US',
            sni: 'example.com',
            serverIp: '192.168.1.1',
            config: OutboundHandlerConfig(tag: "old").writeToBuffer(),
          ),
        );
    await oldDb
        .into(oldDb.geoDomains)
        .insert(
          v2.GeoDomainsCompanion.insert(
            goProxy: true,
            geoDomain: Domain(value: 'domain').writeToBuffer(),
          ),
        );
    await oldDb
        .into(oldDb.cidrs)
        .insert(
          v2.CidrsCompanion.insert(
            proxy: true,
            cidr: CIDR(ip: List.from([192, 168, 1, 0])).writeToBuffer(),
          ),
        );
    await oldDb
        .into(oldDb.apps)
        .insert(
          v2.AppsCompanion.insert(
            proxy: true,
            appId: AppId(value: 'app_id').writeToBuffer(),
          ),
        );
    await oldDb.close();

    // Run the migration and verify that it adds the name column.
    final db = AppDatabase(
      path: 'test_db.db',
      executor: schema.newConnection(),
    );
    await verifier.migrateAndValidate(db, 3);
    await db.close();

    // Make sure the entry is still here
    final migratedDb = v3.DatabaseAtV3(schema.newConnection());
    final entry = await migratedDb
        .select(migratedDb.outboundHandlers)
        .getSingle();
    expect(entry.id, 1);
    final hc = HandlerConfig.fromBuffer(entry.config);
    expect(hc.outbound.tag, "old"); // default from the migration
    final geoDomain = await migratedDb
        .select(migratedDb.geoDomains)
        .getSingle();
    expect(geoDomain.id, 1);
    expect(geoDomain.geoDomain, Domain(value: 'domain').writeToBuffer());
    expect(geoDomain.domainSetName, 'Custom Proxy');
    final cidr = await migratedDb.select(migratedDb.cidrs).getSingle();
    expect(cidr.id, 1);
    expect(cidr.cidr, CIDR(ip: List.from([192, 168, 1, 0])).writeToBuffer());
    expect(cidr.ipSetName, 'Custom Proxy');
    final app = await migratedDb.select(migratedDb.apps).getSingle();
    expect(app.id, 1);
    expect(app.appId, AppId(value: 'app_id').writeToBuffer());
    await migratedDb.close();
  });

  test('upgrade from v4 to v5', () async {
    final schema = await verifier.schemaAt(4);

    // Add some data to the table being migrated
    final oldDb = v4.DatabaseAtV4(schema.newConnection());
    await oldDb
        .into(oldDb.customRouteModes)
        .insert(
          v4.CustomRouteModesCompanion.insert(
            name: 'test',
            routerConfig: RouterConfig().writeToBuffer(),
            domainSetsProxyDns: jsonEncode(['domain1', 'domain2']),
          ),
        );
    await oldDb
        .into(oldDb.greatDomainSets)
        .insert(
          v4.GreatDomainSetsCompanion.insert(
            name: 'test',
            set: GreatDomainSetConfig(
              name: 'test',
              oppositeName: 'test2',
            ).writeToBuffer(),
          ),
        );
    await oldDb.close();

    // Run the migration and verify that it adds the name column.
    final db = AppDatabase(
      path: 'test_db.db',
      executor: schema.newConnection(),
    );
    await verifier.migrateAndValidate(db, 5);
    await db.close();

    // Make sure the entry is still here
    final migratedDb = v5.DatabaseAtV5(schema.newConnection());
    final entry = await migratedDb
        .select(migratedDb.customRouteModes)
        .getSingle();
    final rules = DnsRules.fromBuffer(entry.dnsRules);
    expect(rules.rules.length, 3);
    expect(rules.rules[0].dnsServerName, dnsServerFake);
    expect(rules.rules[0].includedTypes, [
      DnsType.DnsType_A,
      DnsType.DnsType_AAAA,
    ]);
    expect(rules.rules[0].domainTags, ['domain1', 'domain2']);
    expect(rules.rules[1].dnsServerName, 'Proxy DNS Server');
    expect(rules.rules[1].domainTags, ['domain1', 'domain2']);
    expect(rules.rules[2].dnsServerName, 'Direct DNS Server');
    expect(rules.rules[2].domainTags.isEmpty, true);

    final gds = await migratedDb.select(migratedDb.greatDomainSets).getSingle();
    expect(gds.name, 'test');
    expect(gds.oppositeName, 'test2');

    await migratedDb.close();
  });

  test('upgrade from v13 to v14', () async {
    final schema = await verifier.schemaAt(13);

    // Add some data to the table being migrated
    final oldDb = v13.DatabaseAtV13(schema.newConnection());
    await oldDb
        .into(oldDb.dnsServers)
        .insert(
          v13.DnsServersCompanion.insert(
            name: 'test',
            dnsServer: DnsServerConfig().writeToBuffer(),
          ),
        );
    await oldDb.close();

    // Run the migration and verify that it adds the name column.
    final db = AppDatabase(
      path: 'test_db.db',
      executor: schema.newConnection(),
    );
    await verifier.migrateAndValidate(db, 14);
    await db.close();

    // Make sure the entry is still here
    final migratedDb = v14.DatabaseAtV14(schema.newConnection());
    final entry = await migratedDb.select(migratedDb.dnsServers).getSingle();
    expect(entry.id, 1);
    expect(entry.dnsServer, DnsServerConfig().writeToBuffer());

    await migratedDb.close();
  });
}
