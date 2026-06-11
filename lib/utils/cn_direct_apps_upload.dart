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

import 'package:crypto/crypto.dart';
import 'package:vx/common/common.dart';
import 'package:vx/main.dart' show supabase;
import 'package:vx/utils/logger.dart';

/// Uploads the user's direct-app set snapshot for CN routing crowdsourcing.
class CnDirectAppsUpload {
  static Future<void> uploadSnapshot({
    required String deviceId,
    required Map<String, String?> appsByPackage,
  }) async {
    final apps = appsByPackage.entries
        .map(
          (e) => {
            'packageName': e.key,
            if (e.value != null && e.value!.isNotEmpty) 'appName': e.value,
          },
        )
        .toList();

    if (cnDirectAppsKey.isEmpty) {
      logger.d('CN direct apps upload skipped: key not configured');
      return;
    }

    final pseudonymousDeviceId = sha256
        .convert(utf8.encode('$cnDirectAppsKey\0$deviceId'))
        .toString();

    try {
      await supabase.functions.invoke(
        'submit-cn-direct-apps',
        body: {
          'deviceId': pseudonymousDeviceId,
          'apps': apps,
        },
        headers: {'X-Cn-Direct-Apps-Secret': cnDirectAppsKey},
      );
      logger.d('CN direct apps snapshot uploaded (${apps.length} apps)');
    } catch (e, st) {
      logger.w('CN direct apps upload failed', error: e, stackTrace: st);
    }
  }
}
