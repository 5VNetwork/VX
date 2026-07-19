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

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:vx/app/blocs/proxy_selector/proxy_selector_bloc.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/data/database.dart';
import 'package:vx/data/database_provider.dart';
import 'package:vx/data/sync.dart';
import 'package:vx/main.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/file.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/path.dart';
import 'package:vx/utils/xapi_client.dart';

//TODO: reduce duplicate code
class BackupSerevice extends ChangeNotifier {
  BackupSerevice({
    required AuthBloc authProvider,
    required SharedPreferences prefHelper,
    required FlutterSecureStorage storage,
    required DatabaseProvider databaseProvider,
    required this.xController,
    required this.xApiClient,
    required SyncService syncService,
  }) : _authProvider = authProvider,
       _storage = storage,
       _prefHelper = prefHelper,
       databaseProvider = databaseProvider,
       _syncService = syncService;
  final AuthBloc _authProvider;
  final SharedPreferences _prefHelper;
  final FlutterSecureStorage _storage;
  final XApiClient xApiClient;
  final XController xController;
  final DatabaseProvider databaseProvider;
  final SyncService _syncService;

  bool get canUpload => _authProvider.state.user?.pro ?? false;
  String get _userId => _authProvider.state.user?.id ?? '';
  bool uploading = false;
  bool restoring = false;

  // Periodic sync fields
  Timer? _periodicBackupTimer;
  final Duration _periodicSyncInterval = const Duration(minutes: 5);

  void startPeriodicBackup() {
    _periodicBackupTimer = Timer.periodic(_periodicSyncInterval, (timer) {
      uploadBackup();
    });
  }

  void stopPeriodicBackup() {
    _periodicBackupTimer?.cancel();
    _periodicBackupTimer = null;
  }

  /// Create a local backup of the current database at [destinationPath].
  ///
  /// [destinationPath] should be a full file path (e.g. selected by user).
  Future<void> saveLocalBackup(String destinationPath) async {
    uploading = true;
    notifyListeners();

    final dst = await dbVacuumDest();

    try {
      if (await File(dst).exists()) {
        await File(dst).delete();
      }

      // Create a compact, standalone copy of the current database
      await databaseProvider.database.customStatement('VACUUM INTO ?', [dst]);

      File fileToSave = File(dst);

      final destFile = File(destinationPath);
      if (!await destFile.parent.exists()) {
        await destFile.parent.create(recursive: true);
      }

      await fileToSave.copy(destinationPath);
    } catch (e) {
      logger.e('Failed to save local backup', error: e);
      rethrow;
    } finally {
      uploading = false;
      notifyListeners();

      // Clean up temporary files
      if (await File(dst).exists()) {
        await File(dst).delete();
      }
    }
  }

  Future<String?> uploadBackup() async {
    final userId = _userId;
    if (userId.isEmpty) {
      return null;
    }

    uploading = true;
    notifyListeners();

    final dst = await dbVacuumDest();
    File? encryptedFile;

    try {
      if (await File(dst).exists()) {
        await File(dst).delete();
      }

      await databaseProvider.database.customStatement('VACUUM INTO ?', [dst]);

      // Get backup password from secure storage
      final password = await _storage.read(key: 'backupPassword');

      File fileToUpload = File(dst);

      // Encrypt the database file if password is set
      if (password != null && password.isNotEmpty) {
        encryptedFile = await encryptFile(File(dst), password);
        fileToUpload = encryptedFile;
        logger.i('Database encrypted for backup');
      } else {
        logger.w('No backup password set, uploading unencrypted database');
      }

      final fileName = '${DateTime.now().toIso8601String()}.db';
      await supabase.storage
          .from('backup')
          .upload('$userId/$fileName', fileToUpload);

      // Clean up old backups asynchronously
      unawaited(
        Future(() async {
          final existingFiles = await supabase.storage
              .from('backup')
              .list(path: userId);
          if (existingFiles.isNotEmpty) {
            existingFiles.removeWhere((element) => element.name == fileName);
            await supabase.storage
                .from('backup')
                .remove(existingFiles.map((e) => '$userId/${e.name}').toList());
          }
        }),
      );

      return fileName;
    } catch (e) {
      logger.e('Failed to upload backup', error: e);
      rethrow;
    } finally {
      uploading = false;
      notifyListeners();

      // Clean up temporary files
      if (await File(dst).exists()) {
        await File(dst).delete();
      }
      if (encryptedFile != null && await encryptedFile.exists()) {
        await encryptedFile.delete();
      }
    }
  }

  Future<String?> getLatestBackup() async {
    final userId = _userId;
    if (userId.isEmpty) {
      return null;
    }
    final existingFiles = await supabase.storage
        .from('backup')
        .list(path: userId);
    if (existingFiles.isEmpty) {
      return null;
    }
    final backupFile = existingFiles.first;
    return backupFile.name;
  }

  Future<void> deleteBackup() async {
    final userId = _userId;
    if (userId.isEmpty) {
      return;
    }
    final existingFiles = await supabase.storage
        .from('backup')
        .list(path: userId);
    if (existingFiles.isEmpty) {
      return;
    }
    await supabase.storage
        .from('backup')
        .remove(existingFiles.map((e) => '$userId/${e.name}').toList());
  }

  Future<void> restoreBackup({String? path}) async {
    final userId = _userId;
    if (userId.isEmpty) {
      return;
    }

    restoring = true;
    notifyListeners();

    List<File> filesToDelete = [];

    try {
      path ??= await getLatestBackup();
      if (path == null) {
        throw Exception('No backup found');
      }

      // Download the backup file
      final storageResponse = await supabase.storage
          .from('backup')
          .download('$userId/$path');
      final tmpLocation = await tempFilePath();
      final tmpFile = await File(tmpLocation).writeAsBytes(storageResponse);
      filesToDelete.add(tmpFile);

      File dbFileToRestore = tmpFile;

      // Try to decrypt the file if password is set
      final password = await _storage.read(key: 'backupPassword');
      if (password != null && password.isNotEmpty) {
        try {
          final decryptedFile = await decryptFile(tmpFile, password);
          filesToDelete.add(decryptedFile);
          dbFileToRestore = decryptedFile;
          logger.i('Backup decrypted successfully');
        } catch (e) {
          logger.e('Failed to decrypt backup', error: e);
          throw Exception(
            'Failed to decrypt backup. Please check your password.',
          );
        }
      } else {
        logger.w('No backup password set, assuming unencrypted backup');
      }

      // Open the database and vacuum it
      final backupDb = sqlite3.open(dbFileToRestore.path);
      final tmpDb = '$tmpLocation.db';
      backupDb
        ..execute('VACUUM INTO ?', [tmpDb])
        ..dispose();

      // Then replace the existing database file with it.
      final tempDbFile = File(tmpDb);
      filesToDelete.add(tempDbFile);

      await xController.waitForConnectedIfConnecting();
      if (xController.status == XStatus.connected) {
        await xController.stop();
      }
      await databaseProvider.database.close(); // close the current database
      await xApiClient.closeDb();

      late String newDbPath;
      if (Platform.isWindows) {
        // copy the new database file to the standard location
        final newDbName = _prefHelper.dbName == 'x_database.sqlite'
            ? '1.sqlite'
            : '${int.parse(_prefHelper.dbName.split('.')[0]) + 1}.sqlite';
        newDbPath = join(resourceDirectory.path, newDbName);
        logger.d(newDbPath);
      } else {
        newDbPath = await getDbPath(_prefHelper);
      }

      await tempDbFile.copy(newDbPath);

      if (Platform.isWindows) {
        _prefHelper.setDbName(newDbPath.split('\\').last);
      }

      databaseProvider.setDatabase(
        AppDatabase(path: newDbPath)..syncService = _syncService,
      );
      await xApiClient.openDb();
    } catch (e) {
      rethrow;
    } finally {
      restoring = false;
      notifyListeners();
      unawaited(
        Future(() async {
          // remove old db
          // get all files ended with .sqlite
          final currentDbPath = await getDbPath(_prefHelper);
          // TODO: breaks if the directory path contains a dot.
          final currentDbWalPath = '${currentDbPath.split('.')[0]}.sqlite-wal';
          final currentDbShmPath = '${currentDbPath.split('.')[0]}.sqlite-shm';
          final sqliteFiles = resourceDirectory
              .listSync()
              .where((e) {
                return e.path.endsWith('.sqlite') && e.path != currentDbPath ||
                    (e.path.endsWith('.sqlite-wal') &&
                        e.path != currentDbWalPath) ||
                    (e.path.endsWith('.sqlite-shm') &&
                        e.path != currentDbShmPath);
              })
              .map((e) => File(e.path));
          filesToDelete.addAll(sqliteFiles);
          // delete the temporary database file
          for (final file in filesToDelete) {
            try {
              file.delete();
            } catch (e) {
              logger.e('Failed to delete file', error: e);
            }
          }
        }),
      );
    }
  }

  /// Restore from a local backup file at [backupPath].
  ///
  /// The file format is the same as cloud backups: optionally encrypted,
  /// then VACUUMed into a clean SQLite file before replacing the current DB.
  Future<void> restoreFromLocalBackup(String backupPath) async {
    restoring = true;
    notifyListeners();

    final filesToDelete = <File>[];

    try {
      final sourceFile = File(backupPath);
      if (!await sourceFile.exists()) {
        throw Exception('Backup file not found: $backupPath');
      }

      // Work on a temporary copy so the original file is never modified
      final tmpLocation = await tempFilePath();
      final tmpFile = await File(
        tmpLocation,
      ).writeAsBytes(await sourceFile.readAsBytes());
      filesToDelete.add(tmpFile);

      File dbFileToRestore = tmpFile;
      // Open the database and vacuum it into a clean file
      final backupDb = sqlite3.open(dbFileToRestore.path);
      final tmpDb = '$tmpLocation.db';
      backupDb
        ..execute('VACUUM INTO ?', [tmpDb])
        ..dispose();

      // Then replace the existing database file with it.
      final tempDbFile = File(tmpDb);
      filesToDelete.add(tempDbFile);

      await xController.waitForConnectedIfConnecting();
      if (xController.status == XStatus.connected) {
        await xController.stop();
      }
      await databaseProvider.database.close(); // close the current database
      await xApiClient.closeDb();

      late String newDbPath;
      if (Platform.isWindows) {
        // copy the new database file to the standard location
        final newDbName = _prefHelper.dbName == 'x_database.sqlite'
            ? '1.sqlite'
            : '${int.parse(_prefHelper.dbName.split('.')[0]) + 1}.sqlite';
        newDbPath = join(resourceDirectory.path, newDbName);
        logger.d(newDbPath);
      } else {
        newDbPath = await getDbPath(_prefHelper);
      }

      await tempDbFile.copy(newDbPath);

      if (Platform.isWindows) {
        _prefHelper.setDbName(newDbPath.split('\\').last);
      }

      databaseProvider.setDatabase(
        AppDatabase(path: newDbPath)..syncService = _syncService,
      );
      await xApiClient.openDb();
    } catch (e) {
      rethrow;
    } finally {
      restoring = false;
      notifyListeners();
      unawaited(
        Future(() async {
          // remove old db
          // get all files ended with .sqlite
          final currentDbPath = await getDbPath(_prefHelper);
          final currentDbWalPath = '${currentDbPath.split('.')[0]}.sqlite-wal';
          final currentDbShmPath = '${currentDbPath.split('.')[0]}.sqlite-shm';
          final sqliteFiles = resourceDirectory
              .listSync()
              .where((e) {
                return e.path.endsWith('.sqlite') && e.path != currentDbPath ||
                    (e.path.endsWith('.sqlite-wal') &&
                        e.path != currentDbWalPath) ||
                    (e.path.endsWith('.sqlite-shm') &&
                        e.path != currentDbShmPath);
              })
              .map((e) => File(e.path));
          filesToDelete.addAll(sqliteFiles);
          // delete the temporary database file
          for (final file in filesToDelete) {
            try {
              file.delete();
            } catch (e) {
              logger.e('Failed to delete file', error: e);
            }
          }
        }),
      );
    }
  }
}
