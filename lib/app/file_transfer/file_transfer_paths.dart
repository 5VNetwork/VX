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

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vx/pref_helper.dart';

Future<String> defaultFileTransferSaveDir() async {
  if (Platform.isAndroid) {
    return '/storage/emulated/0/Download';
  }
  if (Platform.isIOS) {
    return (await getApplicationDocumentsDirectory()).path;
  }
  return (await getDownloadsDirectory())?.path ??
      (await getApplicationDocumentsDirectory()).path;
}

Future<String> resolvedFileTransferSaveDir(SharedPreferences pref) async {
  final stored = pref.fileTransferSaveDir;
  if (stored != null && stored.isNotEmpty) {
    return stored;
  }
  return defaultFileTransferSaveDir();
}
