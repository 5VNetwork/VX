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
import 'dart:typed_data';

import 'package:vx/utils/encrypt.dart';

const realmUrlEncryptedPrefix = 'vxrealm1:';

bool isEncryptedRealmUrl(String value) =>
    value.startsWith(realmUrlEncryptedPrefix);

String encryptRealmUrl(String url, String password) {
  final encrypted = encryptToBase64(
    Uint8List.fromList(utf8.encode(url)),
    password,
  );
  return '$realmUrlEncryptedPrefix$encrypted';
}

String decryptRealmUrl(String stored, String password) {
  if (!isEncryptedRealmUrl(stored)) {
    return stored;
  }
  final encryptedBase64 = stored.substring(realmUrlEncryptedPrefix.length);
  final bytes = decryptFromBase64(encryptedBase64, password);
  return utf8.decode(bytes);
}
