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

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Table, Column, RouterConfig;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/vx/common/net/net.pb.dart';
import 'package:tm/protos/vx/geo/geo.pb.dart';
import 'package:tm/protos/vx/outbound/outbound.pb.dart';
import 'package:tm/protos/vx/proxy/hysteria/hysteria.pb.dart';
import 'package:tm/protos/vx/transport/transport.pb.dart';
import 'package:vx/app/outbound/outbounds_bloc.dart';
import 'package:vx/app/routing/default.dart';
import 'package:vx/app/routing/routing_page.dart';
import 'package:vx/app/server/add_server.dart';
import 'package:vx/app/blocs/proxy_selector/proxy_selector_bloc.dart';
import 'package:vx/common/common.dart';
import 'package:vx/common/config.dart';
import 'package:vx/common/net.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:tm/protos/vx/router/router.pb.dart';
import 'package:tm/protos/vx/common/geo/geo.pb.dart';
import 'package:tm/protos/vx/dns/dns.pb.dart' as dns;
import 'package:vx/data/database.steps.dart';
import 'package:vx/data/sync.dart';
import 'package:vx/data/sync.pb.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/main.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/path.dart';
import 'package:json_annotation/json_annotation.dart' as ja;
// import 'database.steps.dart';

part 'database.g.dart';
part 'custom_row_class.dart';

@DriftDatabase(
  tables: [
    OutboundHandlers,
    Subscriptions,
    OutboundHandlerGroups,
    OutboundHandlerGroupRelations,
    DnsRecords,
    GeoDomains,
    AtomicDomainSets,
    GreatDomainSets,
    AtomicIpSets,
    GreatIpSets,
    Apps,
    AppSets,
    Cidrs,
    SshServers,
    CommonSshKeys,
    CustomRouteModes,
    HandlerSelectors,
    SelectorHandlerRelations,
    SelectorHandlerGroupRelations,
    SelectorSubscriptionRelations,
    DnsServers,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({
    required String path,
    QueryExecutor? executor,
    QueryInterceptor? interceptor,
  }) : super(executor ?? _openConnection(path, interceptor));

  @override
  int get schemaVersion => 15;

  static QueryExecutor _openConnection(
    String path,
    QueryInterceptor? interceptor,
  ) {
    // the LazyDatabase util lets us find the right location for the file async.
    return LazyDatabase(() async {
      // put the database file, called db.sqlite here, into the documents folder
      // for your app.
      final file = File(path);

      // Also work around limitations on old Android versions
      if (Platform.isAndroid) {
        await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      }

      try {
        // Make sqlite3 pick a more suitable location for temporary files - the
        // one from the system may be inaccessible due to sandboxing.
        final cachebase = (await getCacheDir());
        // We can't access /tmp on Android, which sqlite3 would try by default.
        // Explicitly tell it about the correct temporary directory.
        sqlite3.tempDirectory = cachebase;
      } catch (e) {
        logger.e("Error setting sqlite3 temp directory", error: e);
        reportError("Error setting sqlite3 temp directory", e);
      }

      try {
        if (interceptor != null) {
          return NativeDatabase.createInBackground(
            file,
          ).interceptWith(interceptor);
        }
        return NativeDatabase.createInBackground(file);
      } catch (e) {
        logger.e("Error creating database", error: e);
        reportError("Error creating database", e);
        rethrow;
      }
    }, openImmediately: true);
  }

  Future<void> _insertDefault() async {
    // if default group not exists, create it
    await into(outboundHandlerGroups).insert(
      const OutboundHandlerGroupsCompanion(name: Value(defaultGroupName)),
      mode: InsertMode.insertOrIgnore,
    );
    // proxy selector
    await into(handlerSelectors).insert(
      HandlerSelectorsCompanion(
        name: const Value(proxy),
        config: Value(
          SelectorConfig(
            strategy: SelectorConfig_SelectingStrategy.LEAST_PING,
            balanceStrategy: SelectorConfig_BalanceStrategy.MEMORY,
            filter: SelectorConfig_Filter(all: true),
          ),
        ),
      ),
      mode: InsertMode.insertOrIgnore,
    );
    // set name
    await into(atomicDomainSets).insert(
      AtomicDomainSetsCompanion(name: Value('Fallback')),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<Set<String>> _tableColumnNames(String table) async {
    final columns = await customSelect("PRAGMA table_info('$table')").get();
    return columns.map((row) => row.data['name']).whereType<String>().toSet();
  }

  Future<Map<String, Map<String, String>>> _readSchemaFromCleanDb() async {
    final blob = await rootBundle.load('assets/clean.db');
    final tempDir = await Directory.systemTemp.createTemp('vx-clean-db-');
    final cleanDbPath = '${tempDir.path}${Platform.pathSeparator}clean.db';
    await File(cleanDbPath).writeAsBytes(
      blob.buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes),
    );

    final clean = sqlite3.open(cleanDbPath);
    try {
      final tables = clean.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
      );
      final schema = <String, Map<String, String>>{};
      for (final table in tables) {
        final tableName = table['name'] as String;
        final cols = clean.select("PRAGMA table_info('$tableName')");
        final colMap = <String, String>{};
        for (final col in cols) {
          final colName = col['name'] as String?;
          if (colName == null || colName.isEmpty) {
            continue;
          }
          colMap[colName] = ((col['type'] as String?) ?? '').trim();
        }
        schema[tableName] = colMap;
      }
      logger.d('schema: $schema');
      return schema;
    } finally {
      clean.dispose();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<void> _selfHealMissingColumnsFromCleanDb() async {
    final cleanSchema = await _readSchemaFromCleanDb();
    for (final table in allTables) {
      final tableName = table.actualTableName;
      final expectedColumns = cleanSchema[tableName];
      if (expectedColumns == null || expectedColumns.isEmpty) {
        continue;
      }
      final existingColumns = await _tableColumnNames(tableName);
      for (final entry in expectedColumns.entries) {
        if (existingColumns.contains(entry.key)) {
          continue;
        }
        final sqlType = entry.value.isEmpty ? 'BLOB' : entry.value;
        logger.w(
          'Missing column detected via clean.db, applying self-heal: '
          '$tableName.${entry.key} ($sqlType)',
        );
        await customStatement(
          'ALTER TABLE $tableName ADD COLUMN ${entry.key} $sqlType',
        );
      }
    }
  }

  Future<void> _selfHealSchema() async {
    try {
      await _selfHealMissingColumnsFromCleanDb();
    } catch (e) {
      reportError("selfHealSchema", e);
      rethrow;
    }
  }

  Future<void> repairSchemaFromCleanDb() async {
    await _selfHealSchema();
  }

  // Database Open
  //     ↓
  // Is this a NEW database?
  //     ↓ YES → onCreate() → beforeOpen() → Database Ready
  //     ↓ NO
  // Is schema version different?
  //     ↓ YES → onUpgrade() → beforeOpen() → Database Ready
  //     ↓ NO
  // beforeOpen() → Database Ready
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      // Executes when the database is opened for the first time.
      onCreate: (Migrator m) async {
        //  SqliteException(5898): while executing, disk I/O error, disk I/O error (code 5898)
        for (int i = 0; i < 3; i++) {
          try {
            await m.createAll();
            // Create triggers after tables are created
            await _createUpdateTriggers();
            break;
          } catch (e) {
            logger.e("onCreate createAll", error: e);
            if (i == 2) {
              reportError("onCreate createAll", e);
              snack(
                rootLocalizations()?.failedToCreateAllFirstLaunch(e.toString()),
              );
            }
            // sleep 100ms
            await Future.delayed(Duration(milliseconds: 100 * i));
          }
        }
      },
      // runs after migration
      beforeOpen: (details) async {
        try {
          await customStatement('PRAGMA journal_mode = WAL');
        } catch (e) {
          reportError("beforeOpen journal_mode setup", e);
        }
        try {
          await customStatement('PRAGMA busy_timeout = 5000');
        } catch (e) {
          reportError("beforeOpen busy_timeout", e);
        }

        for (int i = 0; i < 5; i++) {
          try {
            await _insertDefault();
            break;
          } catch (e) {
            logger.e('Error inserting default (attempt ${i + 1}/5)', error: e);
            if (i == 4) {
              reportError("insertDefault", e);
              snack(
                rootLocalizations()?.failedToInsertDefaultData(e.toString()),
              );
              //TODO: recreate database
              return;
            }
            // Check if it's a database lock error
            if (e.toString().contains('database is locked') ||
                e.toString().contains('SQLITE_BUSY')) {
              // Wait with exponential backoff
              const delay = Duration(milliseconds: 200); // 200ms
              logger.d(
                'Database locked, waiting ${delay.inMilliseconds}ms before retry',
              );
              await Future.delayed(delay);
              continue;
            }
          }
        }

        try {
          await customStatement('PRAGMA foreign_keys = ON');
        } catch (e) {
          reportError("beforeOpen enable foreign keys", e);
        }

        if (kDebugMode) {
          // This check pulls in a fair amount of code that's not needed
          // anywhere else, so we recommend only doing it in debug builds.
          await validateDatabaseSchema();
        }

        // Ensure triggers exist (in case of upgrade from old version)
        await _createUpdateTriggers();
      },
      onUpgrade: (m, from, to) async {
        logger.d('onUpgrade from ${from} to ${to}');
        try {
          await customStatement('PRAGMA foreign_keys = OFF');
          await transaction(() async {
            await m.runMigrationSteps(
              from: from,
              to: to,
              steps: migrationSteps(
                from14To15: (m, schema) async {
                  await m.addColumn(
                    schema.subscriptions,
                    schema.subscriptions.shareLinkQueryExtra,
                  );
                },
                from13To14: (m, schema) async {
                  // alterTable copies all target columns; add new ones on disk first.
                  await m.addColumn(
                    schema.dnsServers,
                    schema.dnsServers.concurrentDnsServer,
                  );
                  await m.addColumn(
                    schema.dnsServers,
                    schema.dnsServers.serialDnsServer,
                  );
                  await m.alterTable(TableMigration(schema.dnsServers));
                },
                from12To13: (m, schema) async {
                  logger.d('from12To13');
                  await m.addColumn(schema.apps, schema.apps.name);
                },
                from11To12: (m, schema) async {
                  await m.addColumn(
                    schema.atomicDomainSets,
                    schema.atomicDomainSets.inverse,
                  );
                },
                from10To11: (m, schema) async {
                  final allHandlers = await managers.outboundHandlers.get();
                  for (final handler in allHandlers) {
                    final config = handler.config;
                    if (config.hasOutbound() &&
                        oldTypeUrlToNewTypeUrl.containsKey(
                          config.outbound.protocol.typeUrl,
                        )) {
                      config.outbound.protocol.typeUrl =
                          oldTypeUrlToNewTypeUrl[config
                              .outbound
                              .protocol
                              .typeUrl]!;
                    } else {
                      for (final config in config.chain.handlers) {
                        if (oldTypeUrlToNewTypeUrl.containsKey(
                          config.protocol.typeUrl,
                        )) {
                          config.protocol.typeUrl =
                              oldTypeUrlToNewTypeUrl[config.protocol.typeUrl]!;
                        }
                      }
                    }
                    await ((update(
                      outboundHandlers,
                    ))..where((e) => e.id.equals(handler.id))).write(
                      OutboundHandlersCompanion(config: Value(config)),
                    );
                  }
                },
                from9To10: (m, schema) async {
                  await m.addColumn(
                    schema.greatIpSets,
                    schema.greatIpSets.oppositeName,
                  );
                },
                from1To2: (m, schema) async {
                  await m.addColumn(schema.apps, schema.apps.icon);
                  await m.createTable(schema.commonSshKeys);
                  await m.dropColumn(schema.sshServers, 'port');
                  await m.dropColumn(schema.sshServers, 'user');
                  await m.dropColumn(schema.sshServers, 'password');
                  await m.dropColumn(schema.sshServers, 'passphrase');
                  await m.dropColumn(schema.sshServers, 'pub_key');
                },
                from2To3: (m, schema) async {
                  const customDirect = '自定义直连';
                  const customProxy = '自定义代理';

                  // create tables
                  await m.createTable(schema.outboundHandlerGroups);
                  await m.createTable(schema.outboundHandlerGroupRelations);
                  await m.createTable(schema.atomicDomainSets);
                  await m.createTable(schema.greatDomainSets);
                  await m.createTable(schema.atomicIpSets);
                  await m.createTable(schema.greatIpSets);
                  await m.createTable(schema.appSets);
                  await m.createTable(schema.customRouteModes);
                  await m.createTable(schema.handlerSelectors);
                  // Save existing data before table recreation
                  try {
                    // outboundHandlers
                    final oldData = await customSelect(
                      'SELECT * FROM outbound_handlers',
                    ).get();
                    logger.d(
                      'Saving ${oldData.length} outbound handlers before migration',
                    );
                    await m.deleteTable(
                      schema.outboundHandlers.actualTableName,
                    );
                    await m.createTable(schema.outboundHandlers);
                    // Restore outboundHandlers data with schema transformation
                    for (final row in oldData) {
                      // Create new companion with transformed data
                      final newCompanion = OutboundHandlersCompanion(
                        id: Value(row.data['id'] as int),
                        config: Value(
                          HandlerConfig(
                            outbound: OutboundHandlerConfig.fromBuffer(
                              row.data['config'] as Uint8List,
                            ),
                          ),
                        ),
                        subId: Value(row.data['sub_id'] as int?),
                        // New columns get default values
                      );
                      await into(outboundHandlers).insert(newCompanion);
                    }
                  } catch (e) {
                    logger.e('Error migrating outboundHandlers', error: e);
                    rethrow;
                  }

                  // subscriptions
                  await m.alterTable(TableMigration(schema.subscriptions));

                  try {
                    // geoDomains
                    final oldData = await customSelect(
                      'SELECT * FROM geo_domains',
                    ).get();
                    logger.d(
                      'Saving ${oldData.length} geo domains before migration',
                    );
                    await m.deleteTable(schema.geoDomains.actualTableName);
                    await m.createTable(schema.geoDomains);
                    // Restore geoDomains data
                    for (final row in oldData) {
                      await into(geoDomains).insert(
                        GeoDomainsCompanion(
                          domainSetName: Value(
                            (row.data['go_proxy'] as int) == 1
                                ? customProxy
                                : customDirect,
                          ),
                          geoDomain: Value(
                            Domain.fromBuffer(row.data['geo_domain']),
                          ),
                        ),
                      );
                    }
                    logger.d('Restored ${oldData.length} geo domains');
                  } catch (e) {
                    logger.e('Error migrating geoDomains', error: e);
                    rethrow;
                  }

                  try {
                    // apps
                    final oldData = await customSelect(
                      'SELECT * FROM apps',
                    ).get();
                    logger.d('Saving ${oldData.length} apps before migration');
                    await m.deleteTable(schema.apps.actualTableName);
                    await m.createTable(schema.apps);
                    // Restore apps data
                    for (final row in oldData) {
                      await into(apps).insert(
                        AppsCompanion(
                          appSetName: Value(
                            (row.data['proxy'] as int) == 1
                                ? proxy
                                : directAppSetName,
                          ),
                          appId: Value(AppId.fromBuffer(row.data['app_id'])),
                        ),
                      );
                    }
                    logger.d('Restored ${oldData.length} apps');
                  } catch (e) {
                    logger.e('Error migrating apps', error: e);
                    rethrow;
                  }

                  try {
                    // cidrs
                    final oldData = await customSelect(
                      'SELECT * FROM cidrs',
                    ).get();
                    logger.d('Saving ${oldData.length} cidrs before migration');
                    await m.deleteTable(schema.cidrs.actualTableName);
                    await m.createTable(schema.cidrs);
                    // Restore cidrs data
                    for (final row in oldData) {
                      await into(cidrs).insert(
                        CidrsCompanion(
                          cidr: Value(CIDR.fromBuffer(row.data['cidr'])),
                          ipSetName: Value(
                            (row.data['proxy'] as int) == 1
                                ? customProxy
                                : customDirect,
                          ),
                        ),
                      );
                    }
                    logger.d('Restored ${oldData.length} cidrs');
                  } catch (e) {
                    logger.e('Error migrating cidrs', error: e);
                    rethrow;
                  }
                },
                from3To4: (m, schema) async {
                  await m.createTable(schema.selectorHandlerGroupRelations);
                  await m.createTable(schema.selectorHandlerRelations);
                  await m.createTable(schema.selectorSubscriptionRelations);
                },
                from4To5: (m, schema) async {
                  const dnsServerProxy = 'Proxy DNS Server';
                  const dnsServerDirect = 'Direct DNS Server';
                  await m.addColumn(
                    schema.greatDomainSets,
                    schema.greatDomainSets.oppositeName,
                  );
                  // select all greatDomainSets and populate oppositeName column
                  final gds = await select(greatDomainSets).get();
                  for (final row in gds) {
                    await (update(
                      greatDomainSets,
                    )..where((e) => e.name.equals(row.name))).write(
                      GreatDomainSetsCompanion(
                        oppositeName: Value(row.set.oppositeName),
                      ),
                    );
                  }
                  // select all rows in customRouteModes
                  final oldData = await customSelect(
                    'SELECT * FROM custom_route_modes',
                  ).get();
                  await m.dropColumn(
                    schema.customRouteModes,
                    'domain_sets_proxy_dns',
                  );
                  await m.addColumn(
                    schema.customRouteModes,
                    schema.customRouteModes.dnsRules,
                  );
                  for (final row in oldData) {
                    final domainSetsProxyDns =
                        row.data['domain_sets_proxy_dns'] as String;
                    final domainTags =
                        jsonDecode(domainSetsProxyDns) as List<dynamic>;
                    final domainTagsString = domainTags
                        .map((e) => e.toString())
                        .toList();
                    if (domainTagsString.isNotEmpty) {
                      await (update(
                        customRouteModes,
                      )..where((e) => e.id.equals(row.data['id']))).write(
                        CustomRouteModesCompanion(
                          dnsRules: Value(
                            dns.DnsRules(
                              rules: [
                                dns.DnsRuleConfig(
                                  ruleName: '代理域名(proxy domains) A/AAAA',
                                  dnsServerName: dnsServerFake,
                                  includedTypes: [
                                    dns.DnsType.DnsType_A,
                                    dns.DnsType.DnsType_AAAA,
                                  ],
                                  domainTags: domainTagsString,
                                ),
                                dns.DnsRuleConfig(
                                  ruleName: '代理域名(proxy domains)',
                                  dnsServerName: dnsServerProxy,
                                  domainTags: domainTagsString,
                                ),
                                dns.DnsRuleConfig(
                                  ruleName: '直连域名(direct domains)',
                                  dnsServerName: dnsServerDirect,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  }
                  await m.createTable(schema.dnsServers);
                },
                from5To6: (m, schema) async {
                  await m.addColumn(
                    schema.outboundHandlerGroups,
                    schema.outboundHandlerGroups.placeOnTop,
                  );
                  await m.addColumn(
                    schema.subscriptions,
                    schema.subscriptions.placeOnTop,
                  );
                  await m.addColumn(
                    schema.atomicDomainSets,
                    schema.atomicDomainSets.clashRuleUrls,
                  );
                  await m.addColumn(
                    schema.appSets,
                    schema.appSets.clashRuleUrls,
                  );
                  await m.addColumn(
                    schema.atomicIpSets,
                    schema.atomicIpSets.clashRuleUrls,
                  );
                },
                from6To7: (m, schema) async {
                  // outboundHandlers id column no longer auto increment
                  await m.alterTable(
                    TableMigration(
                      schema.outboundHandlers,
                      newColumns: [schema.outboundHandlers.updatedAt],
                    ),
                  );
                  // outboundHandlerGroups
                  await m.addColumn(
                    schema.outboundHandlerGroups,
                    schema.outboundHandlerGroups.updatedAt,
                  );
                  // subscriptions. id column no longer auto increment
                  await m.alterTable(
                    TableMigration(
                      schema.subscriptions,
                      newColumns: [schema.subscriptions.updatedAt],
                    ),
                  );
                  // atomicDomainSets
                  await m.addColumn(
                    schema.atomicDomainSets,
                    schema.atomicDomainSets.updatedAt,
                  );
                  // greatDomainSets
                  await m.addColumn(
                    schema.greatDomainSets,
                    schema.greatDomainSets.updatedAt,
                  );
                  // appSets
                  await m.addColumn(schema.appSets, schema.appSets.updatedAt);
                  // atomicIpSets
                  await m.addColumn(
                    schema.atomicIpSets,
                    schema.atomicIpSets.updatedAt,
                  );
                  // greatIpSets
                  await m.addColumn(
                    schema.greatIpSets,
                    schema.greatIpSets.updatedAt,
                  );
                  // dnsServers
                  await m.alterTable(
                    TableMigration(
                      schema.dnsServers,
                      columnTransformer: {
                        schema.dnsServers.id: const CustomExpression(
                          '(abs(random()) % 9223372036854775807)',
                        ),
                      },
                      newColumns: [schema.dnsServers.updatedAt],
                    ),
                  );
                  // sshServers
                  await m.addColumn(
                    schema.sshServers,
                    schema.sshServers.updatedAt,
                  );
                  // customRouteModes
                  await m.alterTable(
                    TableMigration(
                      schema.customRouteModes,
                      newColumns: [schema.customRouteModes.updatedAt],
                    ),
                  );
                  // handlerSelectors
                  await m.addColumn(
                    schema.handlerSelectors,
                    schema.handlerSelectors.updatedAt,
                  );
                  // selectorHandlerRelations
                  await m.alterTable(
                    TableMigration(
                      schema.selectorHandlerRelations,
                      columnTransformer: {
                        schema.selectorHandlerRelations.id:
                            const CustomExpression(
                              '(abs(random()) % 9223372036854775807)',
                            ),
                      },
                    ),
                  );
                  // selectorSubscriptionRelations
                  await m.alterTable(
                    TableMigration(
                      schema.selectorSubscriptionRelations,
                      columnTransformer: {
                        schema.selectorSubscriptionRelations.id:
                            const CustomExpression(
                              '(abs(random()) % 9223372036854775807)',
                            ),
                      },
                    ),
                  );
                  // selectorHandlerGroupRelations
                  await m.alterTable(
                    TableMigration(
                      schema.selectorHandlerGroupRelations,
                      columnTransformer: {
                        schema.selectorHandlerGroupRelations.id:
                            const CustomExpression(
                              '(abs(random()) % 9223372036854775807)',
                            ),
                      },
                    ),
                  );
                },
                from7To8: (m, schema) async {
                  await m.addColumn(
                    schema.atomicDomainSets,
                    schema.atomicDomainSets.geoUrl,
                  );
                  await m.addColumn(
                    schema.atomicIpSets,
                    schema.atomicIpSets.geoUrl,
                  );
                },
                from8To9: (m, schema) async {
                  // m.addColumn(
                  //   schema.internalDnsServers,
                  //   schema.internalDnsServers.geoUrl,
                  // );
                  await m.alterTable(
                    TableMigration(
                      schema.customRouteModes,
                      columnTransformer: {
                        schema.customRouteModes.internalDnsServers: Constant(
                          jsonEncode([internalDnsDirect, internalDnsProxy]),
                        ),
                      },
                      newColumns: [schema.customRouteModes.internalDnsServers],
                    ),
                  );
                  // add internal dns servers to dnsServers
                  await into(dnsServers).insert(
                    DnsServersCompanion(
                      name: Value(internalDnsDirect),
                      dnsServer: Value(
                        dns.DnsServerConfig(
                          name: internalDnsDirect,
                          plainDnsServer: dns.PlainDnsServer(
                            addresses: [
                              '1.1.1.1:53',
                              ...(countryDnsServers[getUserCountryFromLocale()] ??
                                  []),
                            ],
                            useDefaultDns: true,
                          ),
                        ),
                      ),
                    ),
                  );
                  await into(dnsServers).insert(
                    DnsServersCompanion(
                      name: Value(internalDnsProxy),
                      dnsServer: Value(
                        dns.DnsServerConfig(
                          name: internalDnsProxy,
                          plainDnsServer: dns.PlainDnsServer(
                            addresses: ['1.1.1.1:53'],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          });

          // Assert that the schema is valid after migrations
          if (kDebugMode) {
            final wrongForeignKeys = await customSelect(
              'PRAGMA foreign_key_check',
            ).get();
            assert(
              wrongForeignKeys.isEmpty,
              '${wrongForeignKeys.map((e) => e.data)}',
            );
          }
        } catch (e) {
          reportError("onUpgrade: $from -> $to", e);
          rethrow;
        }
      },
    );
  }

  Future<void> deleteEverything() async {
    await customStatement('PRAGMA foreign_keys = OFF');
    try {
      await transaction(() async {
        for (final table in allTables) {
          await delete(table).go();
        }
      });
    } finally {
      await customStatement('PRAGMA foreign_keys = OFF');
    }
  }

  Future<void> _createUpdateTriggers() async {
    final idTables = [
      'subscriptions',
      'outbound_handlers',
      'outbound_handler_groups',
      // 'dns_records',
      'atomic_domain_sets',
      'great_domain_sets',
      'atomic_ip_sets',
      'great_ip_sets',
      'app_sets',
      'ssh_servers',
      'common_ssh_keys',
      'custom_route_modes',
      'handler_selectors',
      'dns_servers',
    ];

    for (final table in idTables) {
      // Prevent updates when old updated_at is later than new updated_at
      // This protects against stale data overwriting newer records (useful for sync)
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS prevent_stale_update_$table
        BEFORE UPDATE ON $table
        FOR EACH ROW
        WHEN NEW.updated_at IS NOT NULL 
             AND OLD.updated_at IS NOT NULL 
             AND OLD.updated_at > NEW.updated_at
        BEGIN
          SELECT RAISE(IGNORE);
        END;
      ''');
    }
  }

  Future<SelectorConfig> selectorToConfig(HandlerSelector selector) async {
    final config = selector.config.deepCopy();
    config.tag = selector.name;
    config.filter = selector.config.filter.all
        ? SelectorConfig_Filter(all: true)
        : SelectorConfig_Filter(
            prefixes: selector.config.filter.prefixes,
            subStrings: selector.config.filter.subStrings,
            countryCodes: selector.config.filter.countryCodes,
            handlerIds:
                (await (select(selectorHandlerRelations)
                          ..where((s) => s.selectorName.equals(selector.name)))
                        .get())
                    .map((e) => Int64(e.handlerId))
                    .toList(),
            groupTags:
                (await (select(selectorHandlerGroupRelations)
                          ..where((s) => s.selectorName.equals(selector.name)))
                        .get())
                    .map((e) => e.groupName)
                    .toList(),
            subIds:
                (await (select(selectorSubscriptionRelations)
                          ..where((s) => s.selectorName.equals(selector.name)))
                        .get())
                    .map((e) => Int64(e.subscriptionId))
                    .toList(),
          );
    return config;
  }

  Future<SelectorConfig?> getSelectorConfig(String name) async {
    final selector = await (select(
      handlerSelectors,
    )..where((s) => s.name.equals(name))).getSingleOrNull();
    if (selector != null) {
      return selectorToConfig(selector);
    }
    return null;
  }

  TableInfo<Table, Object?>? getTableByName(String tableName) {
    for (final table in allTables) {
      if (table.actualTableName == tableName) {
        return table;
      }
    }
    return null;
  }

  SyncService? syncService;
  Future<Row> updateById<T extends TableInfo<Table, Row>, Row>(
    T table,
    int id,
    Insertable<Row> data,
  ) async {
    final columnsByName = table.columnsByName;
    final stmt = update(table)
      ..where((tbl) {
        final idColumn = columnsByName['id'];

        if (idColumn == null) {
          throw ArgumentError.value(
            this,
            'this',
            'Must be a table with an id column',
          );
        }

        if (idColumn.type != DriftSqlType.int) {
          throw ArgumentError('Column `id` is not an integer');
        }

        return idColumn.equals(id);
      });

    if (columnsByName.containsKey('updated_at') &&
        table.actualTableName != 'outbound_handlers') {
      data = (data as dynamic).copyWith(updatedAt: Value(DateTime.now()));
    }
    final rows = await stmt.writeReturning(data);
    if (syncService?.enable ?? false) {
      syncService!.sqlOperation(
        SqlOperation(
          type: SQLType.UPDATE,
          table: table.actualTableName,
          rows: [jsonEncode((rows.single as dynamic).toJson())],
        ),
      );
    }
    return rows.single;
  }

  Future<Row> updateName<T extends TableInfo<Table, Row>, Row>(
    T table,
    String name,
    Insertable<Row> data,
  ) async {
    final columnsByName = table.columnsByName;
    final stmt = update(table)
      ..where((tbl) {
        final idColumn = columnsByName['name'];

        if (idColumn == null) {
          throw ArgumentError.value(
            this,
            'this',
            'Must be a table with an name column',
          );
        }

        if (idColumn.type != DriftSqlType.string) {
          throw ArgumentError('Column `name` is not a string');
        }

        return idColumn.equals(name);
      });
    if (columnsByName.containsKey('updated_at')) {
      data = (data as dynamic).copyWith(updatedAt: Value(DateTime.now()));
    }
    final rows = await stmt.writeReturning(data);
    if (syncService?.enable ?? false) {
      syncService!.sqlOperation(
        SqlOperation(
          type: SQLType.UPDATE,
          table: table.actualTableName,
          rows: [jsonEncode((rows.single as dynamic).toJson())],
        ),
      );
    }
    return rows.single;
  }

  Future<void> transactionInsert<T extends TableInfo<Table, Row>, Row>(
    T table,
    List<Insertable<Row>> datas,
  ) async {
    final rows = <Row>[];
    await transaction(() async {
      for (var data in datas) {
        final row = await into(table).insertReturning(data);
        rows.add(row);
      }
    });
    if (syncService?.enable ?? false) {
      syncService!.sqlOperation(
        SqlOperation(
          type: SQLType.INSERT,
          table: table.actualTableName,
          rows: rows.map((e) => jsonEncode((e as dynamic).toJson())).toList(),
        ),
      );
    }
  }

  Future<Row> insertReturning<T extends TableInfo<Table, Row>, Row>(
    T table,
    Insertable<Row> data, {
    InsertMode? mode,
  }) async {
    final stmt = into(table);
    final row = await stmt.insertReturning(data, mode: mode);
    if (syncService?.enable ?? false) {
      syncService!.sqlOperation(
        SqlOperation(
          type: SQLType.INSERT,
          table: table.actualTableName,
          rows: [jsonEncode((row as dynamic).toJson())],
        ),
      );
    }
    return row;
  }

  Future<void> deleteById<T extends TableInfo<Table, Row>, Row>(
    T table,
    List<int> ids,
  ) async {
    final columnsByName = table.columnsByName;
    for (var id in ids) {
      final stmt = delete(table)
        ..where((tbl) {
          final idColumn = columnsByName['id'];
          if (idColumn == null) {
            throw ArgumentError.value(
              this,
              'this',
              'Must be a table with an id column',
            );
          }
          if (idColumn.type != DriftSqlType.int) {
            throw ArgumentError('Column `id` is not an integer');
          }
          return idColumn.equals(id);
        });
      await stmt.go();
    }
    if (syncService?.enable ?? false) {
      syncService!.sqlOperation(
        SqlOperation(
          type: SQLType.DELETE,
          table: table.actualTableName,
          ids: ids.map((e) => Int64(e)).toList(),
        ),
      );
    }
  }

  Future<void> deleteByName<T extends TableInfo<Table, Row>, Row>(
    T table,
    String name,
  ) async {
    final columnsByName = table.columnsByName;
    final stmt = delete(table)
      ..where((tbl) {
        final idColumn = columnsByName['name'];
        if (idColumn == null) {
          throw ArgumentError.value(
            this,
            'this',
            'Must be a table with an name column',
          );
        }
        if (idColumn.type != DriftSqlType.string) {
          throw ArgumentError('Column `name` is not a string');
        }
        return idColumn.equals(name);
      });
    await stmt.go();
    if (syncService?.enable ?? false) {
      syncService!.sqlOperation(
        SqlOperation(
          type: SQLType.DELETE,
          table: table.actualTableName,
          names: [name],
        ),
      );
    }
  }
}

// class SyncAppDatabase extends AppDatabase {
//   SyncAppDatabase(
//       {required super.path,
//       QueryExecutor? executor,
//       super.interceptor,
//       required this.syncService})
//       : super(
//             executor:
//                 executor ?? AppDatabase._openConnection(path, interceptor));
//   SyncService syncService;

//   @override
//   Future<Row> updateById<T extends TableInfo<Table, Row>, Row>(
//       T table, int id, Insertable<Row> data) async {
//     final row = await super.updateById(table, id, data);
//     if (syncService.enable) {
//       syncService.sqlOperation(SqlOperation(
//         type: SQLType.UPDATE,
//         table: table.actualTableName,
//         rows: [jsonEncode((row as dynamic).toJson())],
//       ));
//     }
//     return row;
//   }

//   @override
//   Future<Row> updateName<T extends TableInfo<Table, Row>, Row>(
//       T table, String name, Insertable<Row> data) async {
//     final row = await super.updateName(table, name, data);
//     if (syncService.enable) {
//       syncService.sqlOperation(SqlOperation(
//         type: SQLType.UPDATE,
//         table: table.actualTableName,
//         rows: [jsonEncode((row as dynamic).toJson())],
//       ));
//     }
//     return row;
//   }

//   @override
//   Future<void> transactionInsert<T extends TableInfo<Table, Row>, Row>(
//       T table, List<Insertable<Row>> datas) async {
//     final rows = <Row>[];
//     await transaction(() async {
//       for (var data in datas) {
//         final row = await into(table).insertReturning(data);
//         rows.add(row);
//       }
//     });
//     if (syncService.enable) {
//       syncService.sqlOperation(SqlOperation(
//         type: SQLType.INSERT,
//         table: table.actualTableName,
//         rows: rows.map((e) => jsonEncode((e as dynamic).toJson())).toList(),
//       ));
//     }
//   }

//   @override
//   Future<Row> insertReturning<T extends TableInfo<Table, Row>, Row>(
//     T table,
//     Insertable<Row> data, {
//     InsertMode? mode,
//   }) async {
//     final row = await super.insertReturning(table, data, mode: mode);
//     if (syncService.enable) {
//       syncService.sqlOperation(SqlOperation(
//         type: SQLType.INSERT,
//         table: table.actualTableName,
//         rows: [jsonEncode((row as dynamic).toJson())],
//       ));
//     }
//     return row;
//   }

//   @override
//   Future<void> deleteById<T extends TableInfo<Table, Row>, Row>(
//       T table, List<int> ids) async {
//     await super.deleteById(table, ids);
//     if (syncService.enable) {
//       syncService.sqlOperation(SqlOperation(
//         type: SQLType.DELETE,
//         table: table.actualTableName,
//         ids: ids.map((e) => Int64(e)).toList(),
//       ));
//     }
//   }

//   @override
//   Future<void> deleteByName<T extends TableInfo<Table, Row>, Row>(
//       T table, String name) async {
//     await super.deleteByName(table, name);
//     if (syncService.enable) {
//       syncService.sqlOperation(SqlOperation(
//         type: SQLType.DELETE,
//         table: table.actualTableName,
//         names: [name],
//       ));
//     }
//   }
// }

@UseRowClass(OutboundHandler)
class OutboundHandlers extends Table with TableMixin {
  IntColumn get id => integer()();
  BoolColumn get selected => boolean().clientDefault(() => false)();
  TextColumn get countryCode => text().clientDefault(() => '')();
  TextColumn get sni => text().clientDefault(() => '')();
  // speed in Mbps
  RealColumn get speed => real().withDefault(const Constant(0))();
  IntColumn get speedTestTime => integer().withDefault(const Constant(0))();
  // ping in ms
  IntColumn get ping => integer().withDefault(const Constant(0))();
  IntColumn get pingTestTime => integer().withDefault(const Constant(0))();
  // 0: dont know. This value is the result of the latest test.
  IntColumn get ok => integer().withDefault(const Constant(0))();
  TextColumn get serverIp => text().clientDefault(() => '')();
  BlobColumn get config => blob().map(const OutboundConverter())();
  IntColumn get support6 => integer().withDefault(const Constant(0))();
  IntColumn get support6TestTime => integer().withDefault(const Constant(0))();
  IntColumn get subId => integer()
      .references(Subscriptions, #id, onDelete: KeyAction.cascade)
      .nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class OutboundConverter extends TypeConverter<HandlerConfig, Uint8List> {
  const OutboundConverter();

  @override
  HandlerConfig fromSql(Uint8List fromSql) {
    final config = HandlerConfig.fromBuffer(fromSql);
    return config;
  }

  @override
  Uint8List toSql(HandlerConfig fromDart) => fromDart.writeToBuffer();
}

class PortListConverter extends TypeConverter<PortList, Uint8List> {
  const PortListConverter();

  @override
  PortList fromSql(Uint8List fromSql) => PortList.fromBuffer(fromSql);

  @override
  Uint8List toSql(PortList fromDart) => fromDart.writeToBuffer();
}

@UseRowClass(OutboundHandlerGroup)
class OutboundHandlerGroups extends Table with TableMixin {
  TextColumn get name => text()();
  BoolColumn get placeOnTop => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {name};
}

class OutboundHandlerGroupRelations extends Table {
  TextColumn get groupName => text().references(
    OutboundHandlerGroups,
    #name,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get handlerId => integer().references(
    OutboundHandlers,
    #id,
    onDelete: KeyAction.cascade,
  )();
  @override
  Set<Column<Object>> get primaryKey => {groupName, handlerId};
}

class Subscriptions extends Table with TableMixin {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get link => text().unique()();
  // GB
  RealColumn get remainingData => real().nullable()();
  // miliseconds
  IntColumn get endTime => integer().nullable()();
  TextColumn get website => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  // miliseconds
  IntColumn get lastUpdate => integer()();
  // miliseconds
  IntColumn get lastSuccessUpdate => integer()();
  BoolColumn get placeOnTop => boolean().withDefault(const Constant(false))();

  /// Merged into each share link line before decode (e.g. vless://...). Format: tx=10&foo=bar
  TextColumn get shareLinkQueryExtra =>
      text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DnsRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  BlobColumn get dnsRecord => blob().map(const DnsRecordConverter())();
}

class DnsRecordConverter extends TypeConverter<dns.Record, Uint8List> {
  const DnsRecordConverter();

  @override
  dns.Record fromSql(Uint8List fromSql) => dns.Record.fromBuffer(fromSql);

  @override
  Uint8List toSql(dns.Record fromDart) => fromDart.writeToBuffer();
}

@UseRowClass(AtomicDomainSet)
class AtomicDomainSets extends Table with TableMixin {
  TextColumn get name => text()();
  BlobColumn get geositeConfig =>
      blob().nullable().map(const GeositeConfigConverter())();
  BoolColumn get useBloomFilter =>
      boolean().withDefault(const Constant(false))();
  TextColumn get clashRuleUrls =>
      text().nullable().map(const StringListConverter())();
  TextColumn get geoUrl => text().nullable()();
  BoolColumn get inverse => boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {name};
}

@UseRowClass(GreatDomainSet)
class GreatDomainSets extends Table with TableMixin {
  TextColumn get name => text()();
  TextColumn get oppositeName => text().nullable()();
  BlobColumn get set => blob().map(const GreatDomainSetConverter())();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

class GreatDomainSetConverter
    extends TypeConverter<GreatDomainSetConfig, Uint8List> {
  const GreatDomainSetConverter();

  @override
  GreatDomainSetConfig fromSql(Uint8List fromSql) =>
      GreatDomainSetConfig.fromBuffer(fromSql);

  @override
  Uint8List toSql(GreatDomainSetConfig fromDart) => fromDart.writeToBuffer();
}

class GeositeConfigConverter extends TypeConverter<GeositeConfig, Uint8List> {
  const GeositeConfigConverter();

  @override
  GeositeConfig fromSql(Uint8List fromSql) => GeositeConfig.fromBuffer(fromSql);

  @override
  Uint8List toSql(GeositeConfig fromDart) => fromDart.writeToBuffer();
}

@UseRowClass(GeoDomain)
class GeoDomains extends Table {
  IntColumn get id => integer().autoIncrement()();
  // BoolColumn get goProxy => boolean()();
  BlobColumn get geoDomain => blob().map(const GeoDomainConverter())();
  TextColumn get domainSetName => text().references(
    AtomicDomainSets,
    #name,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();
  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
    {geoDomain, domainSetName},
  ];
}

class GeoDomainConverter extends TypeConverter<Domain, Uint8List> {
  const GeoDomainConverter();

  @override
  Domain fromSql(Uint8List fromSql) => Domain.fromBuffer(fromSql);

  @override
  Uint8List toSql(Domain fromDart) => fromDart.writeToBuffer();
}

@UseRowClass(App)
class Apps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get appSetName => text().references(
    AppSets,
    #name,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();
  BlobColumn get appId => blob().map(const AppIdConverter())();
  BlobColumn get icon => blob().nullable()();
  TextColumn get name => text().nullable()();

  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
    {appId, appSetName},
  ];
}

@UseRowClass(AppSet)
class AppSets extends Table with TableMixin {
  TextColumn get name => text()();
  TextColumn get clashRuleUrls =>
      text().nullable().map(const StringListConverter())();
  @override
  Set<Column<Object>> get primaryKey => {name};
}

class AppIdConverter extends TypeConverter<AppId, Uint8List> {
  const AppIdConverter();

  @override
  AppId fromSql(Uint8List fromSql) => AppId.fromBuffer(fromSql);

  @override
  Uint8List toSql(AppId fromDart) => fromDart.writeToBuffer();
}

@UseRowClass(Cidr)
class Cidrs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get ipSetName => text().references(
    AtomicIpSets,
    #name,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();
  BlobColumn get cidr => blob().map(const CidrConverter())();

  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
    {cidr, ipSetName},
  ];
}

@UseRowClass(AtomicIpSet)
class AtomicIpSets extends Table with TableMixin {
  TextColumn get name => text()();
  BoolColumn get inverse => boolean().withDefault(const Constant(false))();
  BlobColumn get geoIpConfig =>
      blob().nullable().map(const GeoIpConfigConverter())();
  TextColumn get clashRuleUrls =>
      text().nullable().map(const StringListConverter())();
  TextColumn get geoUrl => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {name};
}

@UseRowClass(GreatIpSet)
class GreatIpSets extends Table with TableMixin {
  TextColumn get name => text()();
  BlobColumn get greatIpSetConfig => blob().map(const GreatIpSetConverter())();
  TextColumn get oppositeName => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

class GreatIpSetConverter extends TypeConverter<GreatIPSetConfig, Uint8List> {
  const GreatIpSetConverter();

  @override
  GreatIPSetConfig fromSql(Uint8List fromSql) =>
      GreatIPSetConfig.fromBuffer(fromSql);

  @override
  Uint8List toSql(GreatIPSetConfig fromDart) => fromDart.writeToBuffer();
}

class GeoIpConfigConverter extends TypeConverter<GeoIPConfig, Uint8List> {
  const GeoIpConfigConverter();

  @override
  GeoIPConfig fromSql(Uint8List fromSql) => GeoIPConfig.fromBuffer(fromSql);

  @override
  Uint8List toSql(GeoIPConfig fromDart) => fromDart.writeToBuffer();
}

class CidrConverter extends TypeConverter<CIDR, Uint8List> {
  const CidrConverter();

  @override
  CIDR fromSql(Uint8List fromSql) => CIDR.fromBuffer(fromSql);

  @override
  Uint8List toSql(CIDR fromDart) => fromDart.writeToBuffer();
}

class SshServers extends Table with TableMixin {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  TextColumn get storageKey => text()();
  TextColumn get country => text().nullable()();
  IntColumn get authMethod => intEnum<AuthMethod>()();
}

class CommonSshKeys extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get remark => text().nullable()();
}

@UseRowClass(CustomRouteMode)
class CustomRouteModes extends Table with TableMixin {
  IntColumn get id => integer()();
  TextColumn get name => text().unique()();
  BlobColumn get routerConfig => blob().map(const RouterConfigConverter())();
  // TextColumn get domainSetsProxyDns =>
  //     text().map(const StringListConverter())();
  BlobColumn get dnsRules => blob()
      .withDefault(Constant(dns.DnsRules().writeToBuffer()))
      .map(const DnsRulesConverter())();
  TextColumn get internalDnsServers =>
      text()
      // .withDefault(Constant(jsonEncode([internalDnsDirect, internalDnsProxy])))
      .map(const StringListConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DnsRulesConverter extends TypeConverter<dns.DnsRules, Uint8List> {
  const DnsRulesConverter();

  @override
  dns.DnsRules fromSql(Uint8List fromSql) => dns.DnsRules.fromBuffer(fromSql);

  @override
  Uint8List toSql(dns.DnsRules fromDart) => fromDart.writeToBuffer();
}

class CustomRouteMode {
  CustomRouteMode({
    this.id = 0,
    required this.name,
    required this.routerConfig,
    required this.dnsRules,
    required this.internalDnsServers,
  });
  int id;
  final String name;
  final RouterConfig routerConfig;
  final dns.DnsRules dnsRules;
  final List<String> internalDnsServers;

  bool get hasDefaultProxySelector {
    for (var rule in routerConfig.rules) {
      if (rule.selectorTag == defaultProxySelectorTag) {
        return true;
      }
    }
    return false;
  }

  List<String> getSelectorTags() {
    final ret = <String>[];
    for (var rule in routerConfig.rules) {
      if (rule.selectorTag.isNotEmpty) {
        ret.add(rule.selectorTag);
      }
    }
    return ret;
  }

  CustomRouteModesCompanion toCompanion(bool nullToAbsent) {
    print('internalDnsServers: $internalDnsServers');
    return CustomRouteModesCompanion(
      id: Value(id),
      name: Value(name),
      routerConfig: Value(routerConfig),
      dnsRules: Value(dnsRules),
      internalDnsServers: Value(internalDnsServers),
    );
  }

  Map<String, dynamic> toJson() {
    final serializer = driftRuntimeOptions.defaultSerializer;

    return {
      'id': id,
      'name': name,
      'routerConfig': routerConfig.writeToJson(),
      'dnsRules': dnsRules.writeToJson(),
      'internalDnsServers': serializer.toJson<List<String>>(internalDnsServers),
    };
  }

  factory CustomRouteMode.fromJson(Map<String, dynamic> json) {
    return CustomRouteMode(
      id: json['id'],
      name: json['name'],
      routerConfig: RouterConfig.fromJson(json['routerConfig']),
      dnsRules: dns.DnsRules.fromJson(json['dnsRules']),
      internalDnsServers: json['internalDnsServers'] != null
          ? (json['internalDnsServers'] as List<dynamic>).cast<String>()
          : [],
    );
  }
}

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();
  @override
  List<String> fromSql(String fromSql) {
    final ret = jsonDecode(fromSql) as List<dynamic>;
    return ret.map((e) => e.toString()).toList();
  }

  @override
  String toSql(List<String> fromDart) => jsonEncode(fromDart);
}

class RouterConfigConverter extends TypeConverter<RouterConfig, Uint8List> {
  const RouterConfigConverter();

  @override
  RouterConfig fromSql(Uint8List fromSql) => RouterConfig.fromBuffer(fromSql);

  @override
  Uint8List toSql(RouterConfig fromDart) => fromDart.writeToBuffer();
}

@UseRowClass(HandlerSelector)
class HandlerSelectors extends Table with TableMixin {
  TextColumn get name => text()();
  BlobColumn get config => blob().map(const SelectorConfigConverter())();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

class SelectorConfigConverter extends TypeConverter<SelectorConfig, Uint8List> {
  const SelectorConfigConverter();

  @override
  SelectorConfig fromSql(Uint8List fromSql) =>
      SelectorConfig.fromBuffer(fromSql);
  @override
  Uint8List toSql(SelectorConfig fromDart) => fromDart.writeToBuffer();
}

class SelectorHandlerRelations extends Table {
  IntColumn get id => integer()();
  TextColumn get selectorName =>
      text().references(HandlerSelectors, #name, onDelete: KeyAction.cascade)();
  IntColumn get handlerId => integer().references(
    OutboundHandlers,
    #id,
    onDelete: KeyAction.cascade,
  )();
  @override
  Set<Column<Object>> get primaryKey => {id};
  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
    {selectorName, handlerId},
  ];
}

class SelectorHandlerGroupRelations extends Table {
  IntColumn get id => integer()();
  TextColumn get selectorName =>
      text().references(HandlerSelectors, #name, onDelete: KeyAction.cascade)();
  TextColumn get groupName => text().references(
    OutboundHandlerGroups,
    #name,
    onDelete: KeyAction.cascade,
  )();
  @override
  Set<Column<Object>> get primaryKey => {id};
  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
    {selectorName, groupName},
  ];
}

class SelectorSubscriptionRelations extends Table {
  IntColumn get id => integer()();
  TextColumn get selectorName =>
      text().references(HandlerSelectors, #name, onDelete: KeyAction.cascade)();
  IntColumn get subscriptionId =>
      integer().references(Subscriptions, #id, onDelete: KeyAction.cascade)();
  @override
  Set<Column<Object>> get primaryKey => {id};
  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
    {selectorName, subscriptionId},
  ];
}

@UseRowClass(DnsServer)
class DnsServers extends Table with TableMixin {
  IntColumn get id => integer()();
  TextColumn get name => text().unique()();
  BlobColumn get dnsServer =>
      blob().map(const DnsServerConverter()).nullable()();
  BlobColumn get concurrentDnsServer =>
      blob().map(const ConcurrentDnsServerConverter()).nullable()();
  BlobColumn get serialDnsServer =>
      blob().map(const SerialDnsServerConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class DnsServerConverter extends TypeConverter<dns.DnsServerConfig, Uint8List> {
  const DnsServerConverter();

  @override
  dns.DnsServerConfig fromSql(Uint8List fromSql) =>
      dns.DnsServerConfig.fromBuffer(fromSql);

  @override
  Uint8List toSql(dns.DnsServerConfig fromDart) => fromDart.writeToBuffer();
}

class ConcurrentDnsServerConverter
    extends TypeConverter<dns.ConcurrentDnsServer, Uint8List> {
  const ConcurrentDnsServerConverter();

  @override
  dns.ConcurrentDnsServer fromSql(Uint8List fromSql) =>
      dns.ConcurrentDnsServer.fromBuffer(fromSql);

  @override
  Uint8List toSql(dns.ConcurrentDnsServer fromDart) => fromDart.writeToBuffer();
}

class SerialDnsServerConverter
    extends TypeConverter<dns.SerialDnsServer, Uint8List> {
  const SerialDnsServerConverter();

  @override
  dns.SerialDnsServer fromSql(Uint8List fromSql) =>
      dns.SerialDnsServer.fromBuffer(fromSql);

  @override
  Uint8List toSql(dns.SerialDnsServer fromDart) => fromDart.writeToBuffer();
}

abstract class ToJson {
  Map<String, dynamic> toJson({ValueSerializer? serializer});
}

mixin TableMixin on Table {
  // Column for created at timestamp
  late final updatedAt = dateTime().nullable().clientDefault(
    () => DateTime.now(),
  )();
}

Future<void> insertDefault(
  BuildContext context,
  SharedPreferences pref,
  AppDatabase database,
) async {
  final al = AppLocalizations.of(context)!;
  final xbloc = context.read<ProxySelectorBloc>();

  try {
    if (!pref.databaseInitialized) {
      final country = getUserCountryFromLocale();
      final defaultModes = <DefaultRouteMode>[];
      if (country == 'CN') {
        defaultModes.addAll([DefaultRouteMode.black, DefaultRouteMode.white]);
      } else if (country == 'RU') {
        defaultModes.addAll([
          DefaultRouteMode.ruBlocked,
          DefaultRouteMode.ruBlockedAll,
        ]);
      }
      defaultModes.add(DefaultRouteMode.proxyAll);
      for (var mode in defaultModes) {
        await insertDefaultRouteMode(al, mode, database);
      }
      if (pref.routingMode == null) {
        pref.setRoutingMode(al.proxyAll);
        final mode = await ((database.select(
          database.customRouteModes,
        ))..where((tbl) => tbl.name.equals(al.proxyAll))).getSingle();
        xbloc.add(RoutingModeSelectionChangeEvent(mode));
      }
      pref.setDatabaseInitialized(true);
    }
    // check if custom direct, custom proxy set, direct app set and proxy app set exists
    // domain set
    final customDirect = await (database.select(
      database.atomicDomainSets,
    )..where((tbl) => tbl.name.equals(al.customDirect))).getSingleOrNull();
    if (customDirect == null) {
      await database
          .into(database.atomicDomainSets)
          .insert(
            AtomicDomainSetsCompanion(name: Value(al.customDirect)),
            mode: InsertMode.insertOrIgnore,
          );
    }
    final customProxy = await (database.select(
      database.atomicDomainSets,
    )..where((tbl) => tbl.name.equals(al.customProxy))).getSingleOrNull();
    if (customProxy == null) {
      await database
          .into(database.atomicDomainSets)
          .insert(
            AtomicDomainSetsCompanion(name: Value(al.customProxy)),
            mode: InsertMode.insertOrIgnore,
          );
    }
    //  ip set
    final customDirectIpSet = await (database.select(
      database.atomicIpSets,
    )..where((tbl) => tbl.name.equals(al.customDirect))).getSingleOrNull();
    if (customDirectIpSet == null) {
      await database
          .into(database.atomicIpSets)
          .insert(
            AtomicIpSetsCompanion(name: Value(al.customDirect)),
            mode: InsertMode.insertOrIgnore,
          );
    }
    final customProxyIpSet = await (database.select(
      database.atomicIpSets,
    )..where((tbl) => tbl.name.equals(al.customProxy))).getSingleOrNull();
    if (customProxyIpSet == null) {
      await database
          .into(database.atomicIpSets)
          .insert(
            AtomicIpSetsCompanion(name: Value(al.customProxy)),
            mode: InsertMode.insertOrIgnore,
          );
    }
    // app set
    final directAppSet = await (database.select(
      database.appSets,
    )..where((tbl) => tbl.name.equals(al.direct))).getSingleOrNull();
    if (directAppSet == null) {
      await database
          .into(database.appSets)
          .insert(
            AppSetsCompanion(name: Value(al.direct)),
            mode: InsertMode.insertOrIgnore,
          );
    }
    final proxyAppSet = await (database.select(
      database.appSets,
    )..where((tbl) => tbl.name.equals(al.proxy))).getSingleOrNull();
    if (proxyAppSet == null) {
      await database
          .into(database.appSets)
          .insert(
            AppSetsCompanion(name: Value(al.proxy)),
            mode: InsertMode.insertOrIgnore,
          );
    }
  } catch (e, stackTrace) {
    logger.e("Error inserting default data", error: e, stackTrace: stackTrace);
    fatalMessageDialog(al.insertDefaultError(e.toString()));
  }
}

Future<void> insertDefaultRouteMode(
  AppLocalizations al,
  DefaultRouteMode mode,
  AppDatabase database, {
  bool setsOnly = false,
}) async {
  await database.transaction(() async {
    if (!setsOnly) {
      // router config
      await database
          .into(database.customRouteModes)
          .insert(
            CustomRouteModesCompanion(
              name: Value(mode.toLocalString(al)),
              routerConfig: Value(
                RouterConfig(rules: mode.displayRouterRules(al: al)),
              ),
              dnsRules: Value(dns.DnsRules(rules: mode.dnsRules(al: al))),
              internalDnsServers: Value(mode.internalDnsServers(al: al)),
            ),
            mode: InsertMode.insertOrReplace,
          );
      // dns servers
      for (var server in mode.getDnsServerConfigs(al: al)) {
        await database
            .into(database.dnsServers)
            .insert(
              DnsServersCompanion(
                name: Value(server.name),
                dnsServer: Value(server),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    }
    // small domain sets
    for (var set in mode.getAtomicDomainSets(al: al)) {
      await database
          .into(database.atomicDomainSets)
          .insert(set.toCompanion(true), mode: InsertMode.insertOrIgnore);
    }
    // small ip sets
    for (var set in mode.getAtomicIpSets(al: al)) {
      await database
          .into(database.atomicIpSets)
          .insert(set.toCompanion(true), mode: InsertMode.insertOrIgnore);
    }
    // great domain sets
    for (var set in mode.getGreatDomainSets(al: al)) {
      await database
          .into(database.greatDomainSets)
          .insert(set.toCompanion(true), mode: InsertMode.insertOrIgnore);
    }
    // great ip sets
    for (var set in mode.getGreatIpSets(al: al)) {
      await database
          .into(database.greatIpSets)
          .insert(set.toCompanion(true), mode: InsertMode.insertOrIgnore);
    }
    await database
        .into(database.atomicDomainSets)
        .insert(
          AtomicDomainSetsCompanion(name: Value(al.customDirect)),
          mode: InsertMode.insertOrIgnore,
        );
    await database
        .into(database.atomicDomainSets)
        .insert(
          AtomicDomainSetsCompanion(name: Value(al.customProxy)),
          mode: InsertMode.insertOrIgnore,
        );
    await database
        .into(database.appSets)
        .insert(
          AppSetsCompanion(name: Value(al.direct)),
          mode: InsertMode.insertOrIgnore,
        );
    await database
        .into(database.appSets)
        .insert(
          AppSetsCompanion(name: Value(al.proxy)),
          mode: InsertMode.insertOrIgnore,
        );
  });
}
