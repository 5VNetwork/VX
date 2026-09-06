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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vx/data/database.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/db_recovery.dart';

class OpenedRecovery {
  const OpenedRecovery({required this.db, required this.result});

  final AppDatabase db;
  final DbRecoveryResult result;
}

/// Salvage or wipe [oldPath], persist a rotated name when asked, then open Drift.
///
/// This is the body of `_recoverCorruptDatabase` without app globals.
Future<OpenedRecovery> recoverAndOpenDatabase({
  required SharedPreferences pref,
  required String oldPath,
  required String currentDbName,
  required String resourceDir,
  required String cacheDir,
  required String integrityReport,
  required bool rotateFileName,
  QueryInterceptor? interceptor,
  AppDatabase Function(String path, QueryInterceptor? interceptor)?
  openDatabase,
}) async {
  final result = await recoverCorruptDatabase(
    oldPath: oldPath,
    currentDbName: currentDbName,
    resourceDir: resourceDir,
    cacheDir: cacheDir,
    integrityReport: integrityReport,
    rotateFileName: rotateFileName,
  );

  if (rotateFileName) {
    pref.setDbName(result.newDbName);
  }

  final db = (openDatabase ??
      (path, interceptor) =>
          AppDatabase(path: path, interceptor: interceptor))(
    result.newDbPath,
    interceptor,
  );
  await db.customSelect('SELECT 1').get();
  return OpenedRecovery(db: db, result: result);
}
