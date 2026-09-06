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

import 'dart:developer' as developer;
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

enum DbRecoveryKind {
  /// Readable pages were salvaged with VACUUM INTO.
  vacuumSalvaged,

  /// Unrecoverable; caller should open a fresh empty DB at [newDbPath].
  wiped,
}

class DbRecoveryResult {
  const DbRecoveryResult({
    required this.kind,
    required this.newDbPath,
    required this.newDbName,
    required this.message,
  });

  final DbRecoveryKind kind;
  final String newDbPath;
  final String newDbName;
  final String message;
}

bool looksLikeCorruptDbError(Object e) {
  final s = e.toString();
  return s.contains('malformed') ||
      s.contains('corrupt') ||
      s.contains('SqliteException(11)') ||
      s.contains('SQLITE_CORRUPT') ||
      s.contains('SQLITE_NOTADB');
}

String nextDbName(String current) {
  if (current == 'x_database.sqlite') {
    return '1.sqlite';
  }
  final stem = current.split('.').first;
  final n = int.tryParse(stem);
  if (n != null) {
    return '${n + 1}.sqlite';
  }
  return '${DateTime.now().millisecondsSinceEpoch}.sqlite';
}

/// Returns a human-readable report when quick_check fails, otherwise null.
String? quickCheckSqliteFile(String dbPath) {
  try {
    final db = sqlite3.open(dbPath);
    try {
      final rows = db.select('PRAGMA quick_check');
      final messages = rows
          .map((r) => r.values.first?.toString() ?? '')
          .toList();
      if (messages.length == 1 && messages.first == 'ok') {
        return null;
      }
      return messages.join('\n');
    } finally {
      db.dispose();
    }
  } catch (e) {
    return e.toString();
  }
}

Future<void> deleteCorruptDatabaseFiles(String dbPath) async {
  final files = [
    File(dbPath),
    File('$dbPath-wal'),
    File('$dbPath-shm'),
    File('$dbPath-journal'),
  ];
  for (final f in files) {
    if (await f.exists()) {
      developer.log('Deleting corrupt database file: ${f.path}');
      try {
        await f.delete();
      } catch (e) {
        developer.log('Failed to delete ${f.path}', error: e);
      }
    }
  }
}

/// Attempts VACUUM INTO a temp file under [cacheDir]. Returns the temp path
/// when the salvaged file passes quick_check.
Future<String?> tryVacuumRecover(String corruptPath, String cacheDir) async {
  if (!await File(corruptPath).exists()) {
    return null;
  }
  final tmpPath = p.join(
    cacheDir,
    'vx_db_recover_${DateTime.now().microsecondsSinceEpoch}.db',
  );
  try {
    final src = sqlite3.open(corruptPath);
    try {
      src.execute('VACUUM INTO ?', [tmpPath]);
    } finally {
      src.dispose();
    }
    if (!await File(tmpPath).exists()) {
      return null;
    }
    final report = quickCheckSqliteFile(tmpPath);
    if (report != null) {
      developer.log('VACUUM INTO produced unhealthy DB, discarding: $report');
      try {
        await File(tmpPath).delete();
      } catch (_) {}
      return null;
    }
    developer.log('VACUUM INTO recovery wrote $tmpPath');
    return tmpPath;
  } catch (e) {
    developer.log('VACUUM INTO recovery failed', error: e);
    try {
      if (await File(tmpPath).exists()) {
        await File(tmpPath).delete();
      }
    } catch (_) {}
    return null;
  }
}

String _recoveryTargetName(String currentDbName, {required bool rotateFileName}) {
  return rotateFileName ? nextDbName(currentDbName) : currentDbName;
}

String _recoveryTargetPath({
  required String oldPath,
  required String resourceDir,
  required String newDbName,
  required bool rotateFileName,
}) {
  return rotateFileName ? p.join(resourceDir, newDbName) : oldPath;
}

/// Salvage [oldPath] into a usable file, or wipe and reserve a path.
///
/// When [rotateFileName] is true (Windows), writes a new numbered file so the
/// locked original can be abandoned. Otherwise replaces [oldPath] in place so
/// the name stays `x_database.sqlite`. Does not open Drift — caller opens
/// [DbRecoveryResult.newDbPath].
Future<DbRecoveryResult> recoverCorruptDatabase({
  required String oldPath,
  required String currentDbName,
  required String resourceDir,
  required String cacheDir,
  required String integrityReport,
  bool rotateFileName = false,
}) async {
  developer.log('Attempting database recovery for $oldPath');

  final salvagedPath = await tryVacuumRecover(oldPath, cacheDir);
  if (salvagedPath != null) {
    final newDbName = _recoveryTargetName(
      currentDbName,
      rotateFileName: rotateFileName,
    );
    final newDbPath = _recoveryTargetPath(
      oldPath: oldPath,
      resourceDir: resourceDir,
      newDbName: newDbName,
      rotateFileName: rotateFileName,
    );
    if (p.equals(newDbPath, oldPath)) {
      await deleteCorruptDatabaseFiles(oldPath);
    }
    await File(salvagedPath).copy(newDbPath);
    try {
      await File(salvagedPath).delete();
    } catch (_) {}

    if (!p.equals(newDbPath, oldPath)) {
      await deleteCorruptDatabaseFiles(oldPath);
    }

    final stillBad = quickCheckSqliteFile(newDbPath);
    if (stillBad == null) {
      return DbRecoveryResult(
        kind: DbRecoveryKind.vacuumSalvaged,
        newDbPath: newDbPath,
        newDbName: newDbName,
        message:
            'Database was corrupted and has been repaired. '
            'Some recent changes may be missing.\n$integrityReport',
      );
    }
    developer.log('Recovered DB still fails quick_check:\n$stillBad');
    await deleteCorruptDatabaseFiles(newDbPath);
  }

  developer.log('Falling back to recreate empty database');
  await deleteCorruptDatabaseFiles(oldPath);
  final newDbName = _recoveryTargetName(
    currentDbName,
    rotateFileName: rotateFileName,
  );
  final newDbPath = _recoveryTargetPath(
    oldPath: oldPath,
    resourceDir: resourceDir,
    newDbName: newDbName,
    rotateFileName: rotateFileName,
  );
  return DbRecoveryResult(
    kind: DbRecoveryKind.wiped,
    newDbPath: newDbPath,
    newDbName: newDbName,
    message:
        'Database was corrupted and could not be fully repaired. '
        'Your local data has been reset.\n$integrityReport',
  );
}
