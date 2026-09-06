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

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vx/data/database.dart';
import 'package:vx/utils/db_recovery.dart';
import 'package:vx/utils/recover_and_open.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory tempRoot;
  late String resourceDir;
  late String cacheDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp('vx_recover_open_');
    resourceDir = p.join(tempRoot.path, 'resource');
    cacheDir = p.join(tempRoot.path, 'cache');
    await Directory(resourceDir).create(recursive: true);
    await Directory(cacheDir).create(recursive: true);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  test('wipe then open creates a usable Drift database in place', () async {
    final oldPath = p.join(resourceDir, 'x_database.sqlite');
    await File(oldPath).writeAsBytes(List<int>.filled(2048, 0xDE));
    await File('$oldPath-wal').writeAsString('stale-wal');

    final pref = await SharedPreferences.getInstance();
    final opened = await recoverAndOpenDatabase(
      pref: pref,
      oldPath: oldPath,
      currentDbName: 'x_database.sqlite',
      resourceDir: resourceDir,
      cacheDir: cacheDir,
      integrityReport: 'disk image is malformed',
      rotateFileName: false,
      openDatabase: _openTestDb,
    );

    try {
      expect(opened.result.kind, DbRecoveryKind.wiped);
      expect(opened.result.newDbName, 'x_database.sqlite');
      expect(opened.result.newDbPath, oldPath);
      expect(opened.result.message, contains('disk image is malformed'));
      expect(pref.getString('dbName'), isNull);

      final groups = await opened.db.select(opened.db.outboundHandlerGroups).get();
      expect(groups.map((g) => g.name), contains('default'));
    } finally {
      await opened.db.close();
    }
  });

  test('VACUUM salvage then open keeps subscriptions and the same path', () async {
    final oldPath = p.join(resourceDir, 'x_database.sqlite');
    await _seedDriftDb(oldPath, subscriptionName: 'keep-me');

    final pref = await SharedPreferences.getInstance();
    final opened = await recoverAndOpenDatabase(
      pref: pref,
      oldPath: oldPath,
      currentDbName: 'x_database.sqlite',
      resourceDir: resourceDir,
      cacheDir: cacheDir,
      integrityReport: 'quick_check failed',
      rotateFileName: false,
      openDatabase: _openTestDb,
    );

    try {
      expect(opened.result.kind, DbRecoveryKind.vacuumSalvaged);
      expect(opened.result.newDbPath, oldPath);
      expect(pref.getString('dbName'), isNull);

      final subs = await opened.db.select(opened.db.subscriptions).get();
      expect(subs.map((s) => s.name), contains('keep-me'));
    } finally {
      await opened.db.close();
    }
  });

  test('Windows rotation persists dbName and opens the new file', () async {
    final oldPath = p.join(resourceDir, 'x_database.sqlite');
    await _seedDriftDb(oldPath, subscriptionName: 'rotated');

    final pref = await SharedPreferences.getInstance();
    final opened = await recoverAndOpenDatabase(
      pref: pref,
      oldPath: oldPath,
      currentDbName: 'x_database.sqlite',
      resourceDir: resourceDir,
      cacheDir: cacheDir,
      integrityReport: 'corrupt',
      rotateFileName: true,
      openDatabase: _openTestDb,
    );

    try {
      expect(opened.result.kind, DbRecoveryKind.vacuumSalvaged);
      expect(opened.result.newDbName, '1.sqlite');
      expect(opened.result.newDbPath, p.join(resourceDir, '1.sqlite'));
      expect(pref.getString('dbName'), '1.sqlite');
      expect(await File(oldPath).exists(), isFalse);
      expect(await File(opened.result.newDbPath).exists(), isTrue);

      final subs = await opened.db.select(opened.db.subscriptions).get();
      expect(subs.map((s) => s.name), contains('rotated'));
    } finally {
      await opened.db.close();
    }
  });
}

AppDatabase _openTestDb(String path, QueryInterceptor? interceptor) {
  return AppDatabase(path: path, executor: NativeDatabase(File(path)));
}

Future<void> _seedDriftDb(String path, {required String subscriptionName}) async {
  final db = _openTestDb(path, null);
  try {
    await db.customSelect('SELECT 1').get();
    await db
        .into(db.subscriptions)
        .insert(
          SubscriptionsCompanion.insert(
            name: subscriptionName,
            link: 'https://example.test/$subscriptionName',
            lastUpdate: 0,
            lastSuccessUpdate: 0,
          ),
        );
  } finally {
    await db.close();
  }
}
