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
}
