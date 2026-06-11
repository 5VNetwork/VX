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
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

final desktopPlatforms =
    Platform.isMacOS || Platform.isWindows || Platform.isLinux;

const androidPackageNme = appFlavor == 'staging'
    ? 'com5vnetwork.vproxy.staging'
    : 'com5vnetwork.vproxy';
const darwinBundleId = 'com.5vnetwork.x';
const dartBackendUrl = false
    ? 'http://127.0.0.1:8080/verifypurchase'
    : 'https://iap.5vnetwork.com/verifypurchase';
const logKey = String.fromEnvironment('LOG_KEY', defaultValue: '1234567890');
const cnDirectAppsKey = String.fromEnvironment(
  'CN_DIRECT_APPS_KEY',
  defaultValue: '00000000',
);

List<int> generateUniqueNumbers(int count, {int min = 1, int max = 100}) {
  final random = Random();
  final Set<int> numbers = {};

  while (numbers.length < count) {
    numbers.add(min + random.nextInt(max - min + 1));
  }

  return numbers.toList();
}

final supabaseUrl = false
    ? 'http://192.168.31.1:10110'
    : 'https://qgewguqxyteoowbxeofi.supabase.co';
final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
final numericRegExp = RegExp(r'^\d+$');
const isWinStore = bool.fromEnvironment('STORE');
const isPkg = appFlavor == 'pkg';
final androidApkRelease =
    Platform.isAndroid && !const bool.fromEnvironment('PLAY_STORE');
final autoUpdateSupported =
    androidApkRelease ||
    (Platform.isWindows && !isWinStore) ||
    Platform.isLinux;
String getUserCountryFromLocale() {
  final locale = PlatformDispatcher.instance.locale;
  return locale.countryCode ?? 'Unknown';
}
