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

import 'package:flutter/foundation.dart';
import 'package:grpc/grpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/app/api/api.pb.dart';
import 'package:vx/app/file_transfer/file_transfer_config.dart';
import 'package:vx/app/file_transfer/file_transfer_paths.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/xapi_client.dart';

class FileTransferController extends ChangeNotifier {
  FileTransferController({
    required XApiClient api,
    required SharedPreferences pref,
  }) : _api = api,
       _pref = pref;

  final XApiClient _api;
  final SharedPreferences _pref;

  ResponseStream<FileTransferEvent>? _receiveStream;
  StreamSubscription<FileTransferEvent>? _receiveSub;
  ResponseStream<FileTransferEvent>? _sendStream;
  StreamSubscription<FileTransferEvent>? _sendSub;

  FileTransferEvent? receiveEvent;
  FileTransferEvent? sendEvent;
  bool receiveBusy = false;
  bool sendBusy = false;
  String? receiveError;
  String? sendError;

  bool get isReceiving =>
      receiveBusy ||
      receiveEvent?.state == FileTransferEvent_State.STATE_STARTING ||
      receiveEvent?.state == FileTransferEvent_State.STATE_WAITING ||
      receiveEvent?.state == FileTransferEvent_State.STATE_TRANSFERRING;

  bool get isSending =>
      sendBusy ||
      sendEvent?.state == FileTransferEvent_State.STATE_CONNECTING ||
      sendEvent?.state == FileTransferEvent_State.STATE_TRANSFERRING;

  bool get isReceiveTransferring =>
      isReceiving &&
      receiveEvent?.state == FileTransferEvent_State.STATE_TRANSFERRING;

  String get shareUrl {
    final live = receiveEvent?.shareUrl ?? '';
    if (live.isNotEmpty) return live;
    return _pref.fileTransferShareUrl ?? '';
  }

  bool _resolvingShareUrl = false;
  Future<void>? _shareUrlOp;

  Future<void> _enqueueShareUrl(Future<void> Function() action) {
    final previous = _shareUrlOp ?? Future<void>.value();
    final next = previous.then(
      (_) => action(),
      onError: (Object _, StackTrace _) => action(),
    );
    _shareUrlOp = next;
    return next;
  }

  Future<void> ensureShareUrl({required bool proUser}) {
    return _enqueueShareUrl(() async {
      if (_resolvingShareUrl) return;
      _resolvingShareUrl = true;
      try {
        final url = await resolveFileTransferShareUrl(
          proUser: proUser,
          api: _api,
          pref: _pref,
          deviceId: _pref.uniqueDeviceId,
        );
        if (url == null || url.isEmpty) return;
        if (url != _pref.fileTransferShareUrl) {
          _pref.setFileTransferShareUrl(url);
          notifyListeners();
        }
      } catch (e, st) {
        logger.e('ensureShareUrl failed', error: e, stackTrace: st);
      } finally {
        _resolvingShareUrl = false;
      }
    });
  }

  /// Builds a new share address on [realmHost] and restarts receive when it is running.
  Future<void> regenerateShareUrl({
    required bool proUser,
    required String realmHost,
    int? realmPort,
  }) {
    return _enqueueShareUrl(() async {
      final wasReceiving = isReceiving;
      final url = await resolveFileTransferShareUrl(
        proUser: proUser,
        api: _api,
        pref: _pref,
        deviceId: _pref.uniqueDeviceId,
        realmHost: realmHost,
        realmPort: realmPort,
        newRealmId: true,
      );
      if (url == null || url.isEmpty) {
        throw Exception('empty share url');
      }
      _pref.setFileTransferShareUrl(url);
      if (receiveEvent != null) {
        final updated = receiveEvent!.deepCopy();
        updated.shareUrl = url;
        receiveEvent = updated;
      }
      notifyListeners();
      if (wasReceiving) {
        await stopReceive();
        await startReceive(proUser: proUser);
      }
    });
  }

  bool pageOpen = false;
  bool _miniDismissed = false;

  bool get showMiniBar {
    if (pageOpen || _miniDismissed) return false;
    if (isSending) return true;
    if (!isReceiving) return false;
    final state = receiveEvent?.state;
    return state != FileTransferEvent_State.STATE_COMPLETED &&
        state != FileTransferEvent_State.STATE_FAILED &&
        state != FileTransferEvent_State.STATE_CANCELLED;
  }

  FileTransferEvent? get miniEvent {
    if (isSending && sendEvent != null) return sendEvent;
    if (isReceiving && receiveEvent != null) return receiveEvent;
    return sendEvent ?? receiveEvent;
  }

  bool get miniIsSend {
    if (isSending) return true;
    if (isReceiving) return false;
    return sendEvent != null &&
        (sendEvent!.state == FileTransferEvent_State.STATE_COMPLETED ||
            sendEvent!.state == FileTransferEvent_State.STATE_FAILED);
  }

  void setPageOpen(bool open) {
    if (pageOpen == open) return;
    pageOpen = open;
    if (open) _miniDismissed = false;
    notifyListeners();
  }

  void dismissMiniBar() {
    _miniDismissed = true;
    notifyListeners();
  }

  Future<void> startReceive({required bool proUser}) async {
    if (isReceiving) return;
    await stopReceive();
    receiveError = null;
    receiveBusy = true;
    _miniDismissed = false;
    receiveEvent = FileTransferEvent(
      state: FileTransferEvent_State.STATE_STARTING,
    );
    notifyListeners();
    try {
      final saveDir = await resolvedFileTransferSaveDir(_pref);
      final inbound = await buildFileTransferInbound(
        proUser: proUser,
        api: _api,
        pref: _pref,
        deviceId: _pref.uniqueDeviceId,
      );
      final stream = await _api.startFileReceive(
        StartFileReceiveRequest(saveDir: saveDir, inbound: inbound),
      );
      _receiveStream = stream;
      _receiveSub = stream.listen(
        (event) {
          receiveEvent = event;
          receiveError = event.error.isEmpty ? null : event.error;
          if (event.shareUrl.isNotEmpty) {
            _pref.setFileTransferShareUrl(event.shareUrl);
          }
          notifyListeners();
        },
        onError: (e, st) {
          logger.e('file receive stream error', error: e, stackTrace: st);
          receiveError = e.toString();
          receiveEvent = FileTransferEvent(
            state: FileTransferEvent_State.STATE_FAILED,
            error: receiveError,
          );
          receiveBusy = false;
          notifyListeners();
        },
        onDone: () {
          receiveBusy = false;
          notifyListeners();
        },
      );
    } catch (e, st) {
      logger.e('startReceive failed', error: e, stackTrace: st);
      receiveError = e.toString();
      receiveEvent = FileTransferEvent(
        state: FileTransferEvent_State.STATE_FAILED,
        error: receiveError,
      );
      receiveBusy = false;
      notifyListeners();
    }
  }

  Future<void> stopReceive() async {
    await _receiveSub?.cancel();
    _receiveSub = null;
    try {
      await _receiveStream?.cancel();
    } catch (_) {}
    _receiveStream = null;
    receiveBusy = false;
    if (receiveEvent != null &&
        receiveEvent!.state != FileTransferEvent_State.STATE_COMPLETED &&
        receiveEvent!.state != FileTransferEvent_State.STATE_FAILED) {
      receiveEvent = FileTransferEvent(
        state: FileTransferEvent_State.STATE_CANCELLED,
        shareUrl: receiveEvent?.shareUrl,
      );
    }
    notifyListeners();
  }

  Future<void> startSend({
    required String realmUrl,
    required String filePath,
  }) async {
    sendError = null;
    sendBusy = true;
    _miniDismissed = false;
    sendEvent = FileTransferEvent(
      state: FileTransferEvent_State.STATE_CONNECTING,
    );
    notifyListeners();
    try {
      await stopSend(reset: false);
      final stream = await _api.startFileSend(
        StartFileSendRequest(realmUrl: realmUrl.trim(), filePath: filePath),
      );
      _sendStream = stream;
      _sendSub = stream.listen(
        (event) {
          sendEvent = event;
          sendError = event.error.isEmpty ? null : event.error;
          if (event.state == FileTransferEvent_State.STATE_COMPLETED ||
              event.state == FileTransferEvent_State.STATE_FAILED ||
              event.state == FileTransferEvent_State.STATE_CANCELLED) {
            sendBusy = false;
          }
          notifyListeners();
        },
        onError: (e, st) {
          logger.e('file send stream error', error: e, stackTrace: st);
          sendError = e.toString();
          sendEvent = FileTransferEvent(
            state: FileTransferEvent_State.STATE_FAILED,
            error: sendError,
          );
          sendBusy = false;
          notifyListeners();
        },
        onDone: () {
          sendBusy = false;
          notifyListeners();
        },
      );
    } catch (e, st) {
      logger.e('startSend failed', error: e, stackTrace: st);
      sendError = e.toString();
      sendEvent = FileTransferEvent(
        state: FileTransferEvent_State.STATE_FAILED,
        error: sendError,
      );
      sendBusy = false;
      notifyListeners();
    }
  }

  Future<void> stopSend({bool reset = true}) async {
    await _sendSub?.cancel();
    _sendSub = null;
    try {
      await _sendStream?.cancel();
    } catch (_) {}
    _sendStream = null;
    sendBusy = false;
    if (reset &&
        sendEvent != null &&
        sendEvent!.state != FileTransferEvent_State.STATE_COMPLETED &&
        sendEvent!.state != FileTransferEvent_State.STATE_FAILED) {
      sendEvent = FileTransferEvent(
        state: FileTransferEvent_State.STATE_CANCELLED,
      );
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(stopReceive());
    unawaited(stopSend());
    super.dispose();
  }
}
