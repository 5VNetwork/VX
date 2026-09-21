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

import 'package:shared_preferences/shared_preferences.dart';
import 'package:vx/main.dart' hide App;
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/realm.dart';
import 'package:vx/utils/realm_url_crypto.dart';

class RealmPeerDevice {
  const RealmPeerDevice({
    required this.deviceId,
    required this.name,
    required this.realmUrl,
  });

  final String deviceId;
  final String name;

  /// Encrypted blob from cloud, or plaintext for legacy entries.
  final String realmUrl;

  bool get isEncrypted => isEncryptedRealmUrl(realmUrl);

  String get realmAddr => realmUrl;
}

class FileTransferPeerDevice {
  const FileTransferPeerDevice({
    required this.deviceId,
    required this.name,
    required this.fileTransferUrl,
  });

  final String deviceId;
  final String name;

  /// hysteria2+realm share URL, or an encrypted blob for legacy entries.
  final String fileTransferUrl;

  bool get isEncrypted => isEncryptedRealmUrl(fileTransferUrl);
}

class RealmDeviceService {
  RealmDeviceService({required this.deviceId, required this.prefHelper});

  final String deviceId;
  final SharedPreferences prefHelper;

  Future<void> updateRealmDeviceInfo({
    required String name,
    required String realmUrl,
    String cloudEncryptionPassword = '',
  }) async {
    prefHelper.setRealmDeviceName(name);
    prefHelper.setRealmDeviceRealmUrl(realmUrl);

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return;
    }

    final urlForCloud = cloudEncryptionPassword.isNotEmpty
        ? encryptRealmUrl(realmUrl, cloudEncryptionPassword)
        : realmUrl;

    final Map<String, dynamic> m = {
      'user_id': userId,
      'device_id': deviceId,
      'name': name,
      'realm_url': urlForCloud,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (prefHelper.deviceIdRefreshTime == null) {
      final body = {
        'deviceId': deviceId,
        'fcmToken': prefHelper.fcmToken,
        'name': name,
        'realmUrl': urlForCloud,
      };
      final token = supabase.auth.currentSession?.accessToken ?? '';
      await supabase.functions.invoke(
        'insert-deviceIdToken',
        headers: {'Authorization': 'Bearer $token'},
        body: jsonEncode(body),
      );
      prefHelper.setDeviceIdUpdateTime(DateTime.now());
    } else {
      await supabase
          .from('device_id_tokens')
          .update(m)
          .eq('device_id', deviceId)
          .eq('user_id', userId);
      prefHelper.setDeviceIdUpdateTime(DateTime.now());
    }
  }

  Future<List<RealmPeerDevice>> fetchRealmPeerDevices() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return [];
    }
    final rows = await supabase
        .from('device_id_tokens')
        .select('device_id, name, realm_url')
        .eq('user_id', userId)
        .not('realm_url', 'is', null);
    return rows
        .where(
          (row) => row['device_id'] != deviceId && row['realm_url'] != null,
        )
        .map(
          (row) => RealmPeerDevice(
            deviceId: row['device_id'] as String,
            name: (row['name'] as String?) ?? row['device_id'] as String,
            realmUrl: row['realm_url'] as String,
          ),
        )
        .toList();
  }

  Future<void> updateFileTransferUrl(
    String fileTransferUrl, {
    String cloudEncryptionPassword = '',
    String? name,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null || fileTransferUrl.trim().isEmpty) {
      return;
    }

    final urlForCloud = cloudEncryptionPassword.trim().isNotEmpty
        ? encryptRealmUrl(fileTransferUrl.trim(), cloudEncryptionPassword)
        : fileTransferUrl.trim();
    if (name != null && name.trim().isNotEmpty) {
      prefHelper.setRealmDeviceName(name.trim());
    }
    final deviceName =
        prefHelper.realmDeviceName ?? await defaultRealmDeviceName();
    final Map<String, dynamic> m = {
      'name': deviceName,
      'file_transfer_url': urlForCloud,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (prefHelper.deviceIdRefreshTime == null) {
      final body = {
        'deviceId': deviceId,
        'fcmToken': prefHelper.fcmToken,
        'name': deviceName,
        'fileTransferUrl': urlForCloud,
      };
      final token = supabase.auth.currentSession?.accessToken ?? '';
      await supabase.functions.invoke(
        'insert-deviceIdToken',
        headers: {'Authorization': 'Bearer $token'},
        body: jsonEncode(body),
      );
      prefHelper.setDeviceIdUpdateTime(DateTime.now());
    } else {
      await supabase
          .from('device_id_tokens')
          .update(m)
          .eq('device_id', deviceId)
          .eq('user_id', userId);
    }
  }

  Future<void> deleteFileTransferUrl() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    await supabase
        .from('device_id_tokens')
        .update({
          'file_transfer_url': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('device_id', deviceId)
        .eq('user_id', userId);
  }

  Future<bool> hasPublishedFileTransferUrl() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return false;
    }
    final row = await supabase
        .from('device_id_tokens')
        .select('file_transfer_url')
        .eq('device_id', deviceId)
        .eq('user_id', userId)
        .maybeSingle();
    return (row?['file_transfer_url'] as String?)?.isNotEmpty == true;
  }

  Future<List<FileTransferPeerDevice>> fetchFileTransferPeerDevices() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return [];
    }
    final rows = await supabase
        .from('device_id_tokens')
        .select('device_id, name, file_transfer_url')
        .eq('user_id', userId)
        .not('file_transfer_url', 'is', null);
    return rows
        .where(
          (row) =>
              row['device_id'] != deviceId &&
              (row['file_transfer_url'] as String?)?.isNotEmpty == true,
        )
        .map(
          (row) => FileTransferPeerDevice(
            deviceId: row['device_id'] as String,
            name: (row['name'] as String?) ?? row['device_id'] as String,
            fileTransferUrl: row['file_transfer_url'] as String,
          ),
        )
        .toList();
  }
}
