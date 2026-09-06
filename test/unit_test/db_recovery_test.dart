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
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:vx/utils/db_recovery.dart';

void main() {
  late Directory tempRoot;
  late String resourceDir;
  late String cacheDir;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('vx_db_recovery_');
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

  group('looksLikeCorruptDbError', () {
    test('matches known corruption strings', () {
      expect(looksLikeCorruptDbError('database disk image is malformed'), isTrue);
      expect(looksLikeCorruptDbError(Exception('SqliteException(11)')), isTrue);
      expect(looksLikeCorruptDbError('SQLITE_CORRUPT: database disk image is malformed'), isTrue);
      expect(looksLikeCorruptDbError('SQLITE_NOTADB'), isTrue);
      expect(looksLikeCorruptDbError('corrupt page'), isTrue);
    });

    test('ignores unrelated errors', () {
      expect(looksLikeCorruptDbError('database is locked'), isFalse);
      expect(looksLikeCorruptDbError('no such table'), isFalse);
      expect(looksLikeCorruptDbError(Exception('network failed')), isFalse);
    });
  });

  group('nextDbName', () {
    test('promotes default name to 1.sqlite', () {
      expect(nextDbName('x_database.sqlite'), '1.sqlite');
    });

    test('increments numeric names', () {
      expect(nextDbName('1.sqlite'), '2.sqlite');
      expect(nextDbName('42.sqlite'), '43.sqlite');
    });

    test('falls back to timestamp for unknown names', () {
      final name = nextDbName('weird_name.db');
      expect(name.endsWith('.sqlite'), isTrue);
      expect(int.tryParse(name.split('.').first), isNotNull);
    });
  });

  group('quickCheckSqliteFile', () {
    test('returns null for a healthy database', () {
      final dbPath = p.join(resourceDir, 'healthy.sqlite');
      _createSampleDb(dbPath, rows: {'alpha', 'beta'});
      expect(quickCheckSqliteFile(dbPath), isNull);
    });

    test('returns a report for garbage bytes', () async {
      final dbPath = p.join(resourceDir, 'garbage.sqlite');
      await File(dbPath).writeAsBytes(List<int>.filled(4096, 0x41));
      final report = quickCheckSqliteFile(dbPath);
      expect(report, isNotNull);
      expect(report, isNotEmpty);
    });

    test('returns a report after page corruption', () {
      final dbPath = p.join(resourceDir, 'paged.sqlite');
      _createSampleDb(dbPath, rows: {'keep-me'});
      _corruptMiddlePage(dbPath);
      final report = quickCheckSqliteFile(dbPath);
      expect(report, isNotNull);
    });
  });

  group('deleteCorruptDatabaseFiles', () {
    test('removes main file and wal/shm/journal sidecars', () async {
      final dbPath = p.join(resourceDir, 'victim.sqlite');
      await File(dbPath).writeAsString('main');
      await File('$dbPath-wal').writeAsString('wal');
      await File('$dbPath-shm').writeAsString('shm');
      await File('$dbPath-journal').writeAsString('journal');

      await deleteCorruptDatabaseFiles(dbPath);

      expect(await File(dbPath).exists(), isFalse);
      expect(await File('$dbPath-wal').exists(), isFalse);
      expect(await File('$dbPath-shm').exists(), isFalse);
      expect(await File('$dbPath-journal').exists(), isFalse);
    });
  });

  group('tryVacuumRecover', () {
    test('salvages a healthy database and preserves rows', () async {
      final dbPath = p.join(resourceDir, 'source.sqlite');
      _createSampleDb(dbPath, rows: {'one', 'two', 'three'});

      final recovered = await tryVacuumRecover(dbPath, cacheDir);
      expect(recovered, isNotNull);
      expect(await File(recovered!).exists(), isTrue);
      expect(quickCheckSqliteFile(recovered), isNull);
      expect(_readNames(recovered), unorderedEquals(['one', 'two', 'three']));

      await File(recovered).delete();
    });

    test('returns null for non-existent path', () async {
      final recovered = await tryVacuumRecover(
        p.join(resourceDir, 'missing.sqlite'),
        cacheDir,
      );
      expect(recovered, isNull);
    });

    test('returns null for unreadable garbage file', () async {
      final dbPath = p.join(resourceDir, 'trash.sqlite');
      await File(dbPath).writeAsBytes(Uint8List.fromList(List.filled(128, 7)));

      final recovered = await tryVacuumRecover(dbPath, cacheDir);
      expect(recovered, isNull);
      // Temp salvage file must not be left behind.
      final leftovers = Directory(cacheDir)
          .listSync()
          .whereType<File>()
          .where((f) => p.basename(f.path).startsWith('vx_db_recover_'));
      expect(leftovers, isEmpty);
    });
  });

  group('recoverCorruptDatabase', () {
    test('VACUUM salvage path keeps data and rotates db name', () async {
      final oldPath = p.join(resourceDir, 'x_database.sqlite');
      _createSampleDb(oldPath, rows: {'subscription-a', 'node-b'});

      final result = await recoverCorruptDatabase(
        oldPath: oldPath,
        currentDbName: 'x_database.sqlite',
        resourceDir: resourceDir,
        cacheDir: cacheDir,
        integrityReport: 'simulated corruption',
        rotateFileName: true,
      );

      expect(result.kind, DbRecoveryKind.vacuumSalvaged);
      expect(result.newDbName, '1.sqlite');
      expect(result.newDbPath, p.join(resourceDir, '1.sqlite'));
      expect(await File(oldPath).exists(), isFalse);
      expect(await File(result.newDbPath).exists(), isTrue);
      expect(quickCheckSqliteFile(result.newDbPath), isNull);
      expect(
        _readNames(result.newDbPath),
        unorderedEquals(['subscription-a', 'node-b']),
      );
      expect(result.message, contains('has been repaired'));
      expect(result.message, contains('simulated corruption'));
    });

    test('wipe path when file is unsalvageable', () async {
      final oldPath = p.join(resourceDir, '2.sqlite');
      await File(oldPath).writeAsBytes(List<int>.filled(2048, 0xDE));
      await File('$oldPath-wal').writeAsString('stale-wal');

      final result = await recoverCorruptDatabase(
        oldPath: oldPath,
        currentDbName: '2.sqlite',
        resourceDir: resourceDir,
        cacheDir: cacheDir,
        integrityReport: 'disk image is malformed',
        rotateFileName: true,
      );

      expect(result.kind, DbRecoveryKind.wiped);
      expect(result.newDbName, '3.sqlite');
      expect(result.newDbPath, p.join(resourceDir, '3.sqlite'));
      // Wipe path only reserves the new path; it does not create the empty file.
      expect(await File(result.newDbPath).exists(), isFalse);
      expect(await File(oldPath).exists(), isFalse);
      expect(await File('$oldPath-wal').exists(), isFalse);
      expect(result.message, contains('could not be fully repaired'));
      expect(result.message, contains('disk image is malformed'));
    });

    test('increments numeric db names across salvage', () async {
      final oldPath = p.join(resourceDir, '7.sqlite');
      _createSampleDb(oldPath, rows: {'row'});

      final result = await recoverCorruptDatabase(
        oldPath: oldPath,
        currentDbName: '7.sqlite',
        resourceDir: resourceDir,
        cacheDir: cacheDir,
        integrityReport: 'report',
        rotateFileName: true,
      );

      expect(result.newDbName, '8.sqlite');
    });

    test('VACUUM salvage replaces the same path when not rotating', () async {
      final oldPath = p.join(resourceDir, 'x_database.sqlite');
      _createSampleDb(oldPath, rows: {'subscription-a', 'node-b'});
      await File('$oldPath-wal').writeAsString('stale-wal');

      final result = await recoverCorruptDatabase(
        oldPath: oldPath,
        currentDbName: 'x_database.sqlite',
        resourceDir: resourceDir,
        cacheDir: cacheDir,
        integrityReport: 'simulated corruption',
      );

      expect(result.kind, DbRecoveryKind.vacuumSalvaged);
      expect(result.newDbName, 'x_database.sqlite');
      expect(result.newDbPath, oldPath);
      expect(await File(oldPath).exists(), isTrue);
      expect(await File('$oldPath-wal').exists(), isFalse);
      expect(quickCheckSqliteFile(oldPath), isNull);
      expect(
        _readNames(oldPath),
        unorderedEquals(['subscription-a', 'node-b']),
      );
    });

    test('wipe reuses the same path when not rotating', () async {
      final oldPath = p.join(resourceDir, 'x_database.sqlite');
      await File(oldPath).writeAsBytes(List<int>.filled(2048, 0xDE));
      await File('$oldPath-wal').writeAsString('stale-wal');

      final result = await recoverCorruptDatabase(
        oldPath: oldPath,
        currentDbName: 'x_database.sqlite',
        resourceDir: resourceDir,
        cacheDir: cacheDir,
        integrityReport: 'disk image is malformed',
      );

      expect(result.kind, DbRecoveryKind.wiped);
      expect(result.newDbName, 'x_database.sqlite');
      expect(result.newDbPath, oldPath);
      expect(await File(oldPath).exists(), isFalse);
      expect(await File('$oldPath-wal').exists(), isFalse);
    });
  });
}

void _createSampleDb(String dbPath, {required Set<String> rows}) {
  final db = sqlite3.open(dbPath);
  try {
    db.execute('CREATE TABLE sample (name TEXT PRIMARY KEY)');
    final insert = db.prepare('INSERT INTO sample (name) VALUES (?)');
    try {
      for (final name in rows) {
        insert.execute([name]);
      }
    } finally {
      insert.dispose();
    }
  } finally {
    db.dispose();
  }
}

Set<String> _readNames(String dbPath) {
  final db = sqlite3.open(dbPath);
  try {
    return db
        .select('SELECT name FROM sample')
        .map((r) => r['name'] as String)
        .toSet();
  } finally {
    db.dispose();
  }
}

/// Overwrite the second SQLite page with garbage while keeping the header.
void _corruptMiddlePage(String dbPath) {
  final file = File(dbPath);
  final bytes = file.readAsBytesSync();
  // Default page size is 4096; page 1 starts at offset 4096.
  if (bytes.length < 8192) {
    // Pad so there is a second page to corrupt.
    final padded = Uint8List(8192);
    padded.setRange(0, bytes.length, bytes);
    file.writeAsBytesSync(padded);
  }
  final mutable = file.readAsBytesSync();
  for (var i = 4096; i < 8192 && i < mutable.length; i++) {
    mutable[i] = 0xFF;
  }
  file.writeAsBytesSync(mutable);
}
