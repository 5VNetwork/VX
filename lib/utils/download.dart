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
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:flutter_common/util/download.dart';
import 'package:http/http.dart' as http;
import 'package:tm/protos/app/api/api.pbgrpc.dart';
import 'package:tm/protos/vx/outbound/outbound.pb.dart';
import 'package:vx/app/outbound/outbound_repo.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/path.dart';
import 'package:vx/utils/xapi_client.dart';

/// Download something and record traffic usage
class Downloader {
  final OutboundRepo outboundRepo;
  final XApiClient xApiClient;
  Downloader(this.outboundRepo, this.xApiClient);

  /// download from multiple urls, return the first successful one
  Future<void> downloadMulti(List<String> urls, String dest) async {
    for (var url in urls) {
      try {
        return await download(url, dest);
      } catch (e) {
        logger.d("download failed: $e");
      }
    }
    throw Exception("all download failed");
  }

  Future<void> downloadProxyFirst(String url, String dest) async {
    logger.d("downloading $url to $dest with proxy");
    try {
      final handlers = await outboundRepo.getHandlers(
        usable: true,
        orderBySpeed1MBDesc: true,
      );
      if (handlers.isNotEmpty) {
        final configs = handlersToHandlerConfig(handlers);
        await xApiClient.download(
          DownloadRequest(
            url: url,
            handlers: configs.sublist(0, min(5, configs.length)),
            dest: dest,
          ),
        );
        logger.d("downloaded $url to $dest with proxy");
        return;
      }
    } catch (e, s) {
      logger.d("proxy download failed: $e", stackTrace: s);
    }

    return await directDownloadToFile(url, dest);
  }

  Future<void> download(String url, String dest) async {
    await _download(url, dest);
  }

  Future<void> downloadZip(
    String url,
    String dest, {
    bool cleanDest = true,
  }) async {
    final tmpPath = '${await tempFilePath()}.zip';
    await downloadProxyFirst(url, tmpPath);

    if (cleanDest && Directory(dest).existsSync()) {
      Directory(dest).deleteSync(recursive: true);
    }

    // unzip the file to dest. If dest already exists, there will be no error.
    // existing files that are also in the zip will be replaced
    // if dest does not exist, it will be created
    await extractFileToDisk(tmpPath, dest);
    File(tmpPath).deleteSync();
  }

  /// try direct download first, if failed, try to use outbound handlers
  Future<void> _download(String url, String dest) async {
    try {
      await directDownloadToFile(url, dest);
      return;
    } catch (e, s) {
      logger.d("plain download failed: $e", stackTrace: s);
    }

    List<HandlerConfig> configs = handlersToHandlerConfig(
      await outboundRepo.getHandlers(usable: true, orderBySpeed1MBDesc: true),
    );
    if (configs.length >= 5) {
      configs = configs.sublist(0, 5);
    }
    await xApiClient.download(
      DownloadRequest(url: url, handlers: configs, dest: dest),
    );
  }

  Future<Uint8List> downloadMemory(String url) async {
    try {
      return await directDownloadMemory(url);
    } catch (e) {
      logger.e("plain download failed: $e");
    }

    final configs = handlersToHandlerConfig(
      await outboundRepo.getHandlers(usable: true),
    );
    final rsp = await xApiClient.download(
      DownloadRequest(url: url, handlers: configs),
    );
    return Uint8List.fromList(rsp.data);
  }
}
