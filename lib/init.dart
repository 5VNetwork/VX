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

part of 'main.dart';

Future<AppDatabase?> _initDatabase(
  SharedPreferences pref, {
  QueryInterceptor? interceptor,
}) async {
  AppDatabase? db;
  try {
    final path = await getDbPath(pref);
    db = AppDatabase(path: path, interceptor: interceptor);
    await db.customSelect('SELECT 1').get();

    if (Platform.isAndroid) {
      final corruption = await _quickCheckReport(db);
      if (corruption != null) {
        logger.e('Database corruption detected:\n$corruption');
        reportError('database corruption detected', corruption);
        await db.close();
        db = null;
        return await _recoverCorruptDatabase(
          pref,
          interceptor: interceptor,
          integrityReport: corruption,
        );
      }
    }

    return db;
  } catch (e) {
    logger.e('Error initializing database', error: e);
    reportError('init database', e);

    if (db != null) {
      try {
        await db.close();
      } catch (closeErr) {
        logger.e('Error closing corrupt database', error: closeErr);
      }
    }

    if (looksLikeCorruptDbError(e)) {
      try {
        return await _recoverCorruptDatabase(
          pref,
          interceptor: interceptor,
          integrityReport: e.toString(),
        );
      } catch (e2) {
        logger.e('Error recovering database', error: e2);
        reportError('recover database', e2);
      }
    }

    fatalErrorMessage = 'Failed to initialize database: $e';
  }

  return null;
}

/// Drift wrapper around [quickCheckSqliteFile].
Future<String?> _quickCheckReport(AppDatabase db) async {
  try {
    final rows = await db.customSelect('PRAGMA quick_check').get();
    final messages = rows
        .map((r) => r.data.values.first?.toString() ?? '')
        .toList();
    if (messages.length == 1 && messages.first == 'ok') {
      return null;
    }
    return messages.join('\n');
  } catch (e) {
    return e.toString();
  }
}

Future<AppDatabase?> _recoverCorruptDatabase(
  SharedPreferences pref, {
  QueryInterceptor? interceptor,
  required String integrityReport,
}) async {
  final opened = await recoverAndOpenDatabase(
    pref: pref,
    oldPath: await getDbPath(pref),
    currentDbName: pref.dbName,
    resourceDir: resourceDirectory.path,
    cacheDir: cacheDirectory,
    integrityReport: integrityReport,
    rotateFileName: Platform.isWindows,
    interceptor: interceptor,
  );

  databaseRecoveryMessage = opened.result.message;
  if (opened.result.kind == DbRecoveryKind.vacuumSalvaged) {
    reportError('database vacuum recovery succeeded', integrityReport);
  } else {
    reportError('database wipe recovery', integrityReport);
  }
  return opened.db;
}
