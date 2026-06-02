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
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vx/common/common.dart';
import 'package:vx/main.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/logger.dart';

final macPkg = Platform.isMacOS && appFlavor == 'pkg';

/// dir to hold geosite, geoip, wintun.dll, unix socket
Future<Directory> resourceDir() async {
  if (Platform.isWindows || Platform.isAndroid || Platform.isLinux) {
    return await getApplicationSupportDirectory();
  }

  if (Platform.isMacOS || Platform.isIOS) {
    final appGroupPath = await darwinHostApi!.appGroupPath();
    final dir = Directory(join(appGroupPath, "Library", "Application Support"));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  throw UnimplementedError("Unsupported platform");
}

Future<String> getDbPath(SharedPreferences pref) async {
  final dbName = pref.dbName;
  return join(resourceDirectory.path, dbName);
}

Future<String> dbVacuumDest() async {
  return join(await getCacheDir(), "x_database_backup.db");
}

Future<String> tempFilePath() async {
  return join(
    await getCacheDir(),
    DateTime.now().microsecondsSinceEpoch.toString(),
  );
}

Directory getFlutterLogDir() {
  final dir = Directory(join(resourceDirectory.path, "flutter_logs"));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

Directory getTunnelLogDir() {
  final dir = Directory(join(resourceDirectory.path, "tunnel_logs"));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

Future<Directory> getDebugTunnelLogDir() async {
  final dir = Directory(join((await resourceDir()).path, "debug_tunnel_logs"));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

Future<Directory> getDebugFlutterLogDir() async {
  final dir = Directory(join((await resourceDir()).path, "debug_flutter_logs"));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

/// logs
Future<String> getCacheDir() async {
  if (Platform.isMacOS || Platform.isIOS) {
    final appGroupPath = await darwinHostApi!.appGroupPath();
    final dir = Directory(join(appGroupPath, "Library", "Caches"));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir.path;
  }
  // if (Platform.isIOS) {
  //   final appGroupPath = await platformHostApi.appGroupPath();
  //   return appGroupPath;
  // }
  if (Platform.isWindows || Platform.isAndroid || Platform.isLinux) {
    return (await getApplicationCacheDirectory()).path;
  }
  throw UnimplementedError("Unsupported platform");
}

Future<String> getGeositePath() async {
  String path;
  final geositeFile = File(join((await resourceDir()).path, 'geosite.dat'));
  path = geositeFile.path;
  return path;
}

Future<String> getSimplifiedGeositePath() async {
  String path;
  final geositeFile = File(
    join((await resourceDir()).path, 'geosite_simplified.dat'),
  );
  path = geositeFile.path;
  return path;
}

Future<String> getGeoIPPath() async {
  String path;
  final geoIPFile = File(join((resourceDirectory).path, 'geoip.dat'));
  path = geoIPFile.path;
  return path;
}

Future<String> getSimplifiedGeoIPPath() async {
  String path;
  final geoIPFile = File(
    join((resourceDirectory).path, 'geoip_simplified.dat'),
  );
  path = geoIPFile.path;
  return path;
}

Future<String> getWintunDir() async {
  return join((await resourceDir()).path, 'wintun', 'bin');
}

Future<String> configFilePath() async {
  return join((await resourceDir()).path, 'config');
}

String getDllPath() {
  // if (kReleaseMode) {
  final String localLibPath = join(
    'data',
    'flutter_assets',
    'packages',
    'tm_windows',
    'assets',
    'x.dll',
  );
  String pathToLib = join(
    Directory(Platform.resolvedExecutable).parent.path,
    localLibPath,
  );
  logger.d('pathToLib: $pathToLib');
  return pathToLib;
  // } else {
  // return join(Directory.current.parent.path, 'tm-plugin', 'tm_windows',
  // 'assets', 'x.dll');
  // }
}

String getServicePath() {
  return join((resourceDirectory).path, 'vx_service.exe');
}

String getServiceExeZipPath() {
  final String localExePath = join(
    'data',
    'flutter_assets',
    'packages',
    'tm_windows',
    'assets',
    'vx_service.zip',
  );
  String pathToExe = join(
    Directory(Platform.resolvedExecutable).parent.path,
    localExePath,
  );
  logger.d('pathToExe: $pathToExe');
  return pathToExe;
}

String getSoPath() {
  final String localLibPath = join(
    'data',
    'flutter_assets',
    'packages',
    'tm_linux',
    'assets',
    'x.so',
  );
  String pathToLib = join(
    Directory(Platform.resolvedExecutable).parent.path,
    localLibPath,
  );
  logger.d('pathToLib: $pathToLib');
  return pathToLib;
}

Future<Directory> getClashRulesDir() async {
  final dir = Directory(join((await resourceDir()).path, 'clash_rules'));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

Future<Directory> getGeoDir() async {
  final dir = Directory(join((await resourceDir()).path, 'geo'));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  return dir;
}

Future<String> getClashRulesPath(String url, {bool isPkg = false}) async {
  final dir = isPkg
      ? Directory('/tmp/com.5vnetwork.x/geo')
      : await getClashRulesDir();
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  // hash the url
  final hash = sha256.convert(utf8.encode(url)).toString();
  return join(dir.path, hash);
}

Future<String> getGeoUrlPath(String url) async {
  final dir = isPkg ? Directory('/tmp/com.5vnetwork.x/geo') : await getGeoDir();
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  // hash the url
  final hash = sha256.convert(utf8.encode(url)).toString();
  return join(dir.path, hash);
}
