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

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:installed_apps/index.dart';
import 'package:lru_cache/lru_cache.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/vx/userlogger/userlogger.pb.dart';
import 'package:vx/app/outbound/outbound_repo.dart';
import 'package:vx/app/routing/mode_form.dart';
import 'package:vx/app/blocs/proxy_selector/proxy_selector_bloc.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/common/circuler_buffer.dart';
import 'package:tm/tm.dart';
import 'package:flutter_common/util/net.dart';
import 'package:vx/main.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/logger.dart';
import 'package:grpc/grpc.dart';
import 'package:vx/utils/xapi_client.dart';

part 'log_event.dart';
part 'log_state.dart';

const int maxLogSize = 1000;

class LogBloc extends Bloc<LogEvent, LogState> {
  LogBloc({
    required SharedPreferences pref,
    required OutboundRepo outboundRepo,
    required XController xController,
  }) : _pref = pref,
       _outboundRepo = outboundRepo,
       _xController = xController,
       super(
         LogState(
           enableLog: pref.enableLog,
           showApp: pref.showApp,
           showHandler: pref.showHandler,
           showSessionOngoing: pref.showSessionOngoing,
           showRealtimeUsage: pref.showRealtimeUsage,
           logs: CircularBuffer<XLog>(maxSize: maxLogSize),
           filter: const LogFilter(
             showDirect: true,
             showProxy: true,
             errorOnly: false,
           ),
         ),
       ) {
    on<_NewLogEvent>(_onLogEvent);
    on<SubstringChangedEvent>(
      _onSubstringChangedEvent,
      transformer: (events, mapper) {
        return events
            .debounceTime(const Duration(milliseconds: 500))
            .switchMap(mapper);
      },
    );
    on<DirectPressedEvent>(_onDirectPressedEvent);
    on<ProxyPressedEvent>(_onProxyPressedEvent);
    on<RejectPressedEvent>(_onRejectPressedEvent);
    on<ErrorOnlyPressedEvent>(_onErrorOnlyPressedEvent);
    on<LogSwitchPressedEvent>(_onLogSwitchPressedEvent);
    on<LogBlocInitialEvent>(_onInitialEvent);
    on<AppPressedEvent>(_onAppPressedEvent);
    on<HandlerPressedEvent>(_onHandlerPressedEvent);
    on<SessionOngoingPressedEvent>(_onSessionOngoingPressedEvent);
    on<RealtimeUsagePressedEvent>(_onRealtimeUsagePressedEvent);
    _logs = state.logs;
    isIOSSimulator().then((value) {
      if (value) {
        for (var i = 0; i < 5; i++) {
          sleep(const Duration(milliseconds: 1000));
          _logs.add(
            SessionInfo(
              timestamp: DateTime.now(),
              tag: i.isEven ? 'direct' : '1234',
              handlerName: i.isEven ? 'Direct' : 'Proxy',
              selector: i.isEven ? '' : proxySelector.name,
              resolver: '1.1.1.1',
              ipToDomain: '1.1.1.1',
              inboundTag: i.isEven ? 'TUN' : 'SOCKS',
              network: i.isEven ? 'tcp' : 'udp',
              sniffProtocol: i.isEven ? 'http' : 'https',
              source: i.isEven ? '127.0.0.1:23412' : '127.0.0.1:23413',
              dst: i.isEven ? 'vx.5vnetwork.com' : 'www.google.com',
              app: '',
              routeRuleMatched: "Default Deirect",
              sessionId: i * 1000000,
            ),
          );
        }
      }
    });
    add(const LogBlocInitialEvent());
  }

  final SharedPreferences _pref;
  final Tm _tm = Tm.instance;
  ResponseStream<UserLogMessage>? _logStream;
  // all collected logs, not logs being shown. Logsbeing shown are subset of _logs.
  late final CircularBuffer<XLog> _logs;
  final LruCache<String, Uint8List> _appIconCache = LruCache(1000);
  late final OutboundRepo _outboundRepo;
  final XController _xController;

  @override
  void onTransition(Transition<LogEvent, LogState> transition) {
    return;
  }

  void _onInitialEvent(
    LogBlocInitialEvent event,
    Emitter<LogState> emit,
  ) async {
    await emit.forEach(
      Tm.instance.stateStream,
      onData: (statusChange) {
        logger.d('log tm status changed: ${statusChange.status}');
        if (!state.enableLog) {
          return state;
        }
        switch (statusChange.status) {
          case TmStatus.connecting:
            break;
          case TmStatus.connected:
            if (state.enableLog) {
              _subscribe();
            }
          case TmStatus.disconnecting:
            _disconnectLogStream();
          case TmStatus.disconnected:
            _disconnectLogStream();
          case TmStatus.reconnecting:
          case TmStatus.unknown:
            return state;
        }
        final newLog = XStatusLog(
          DateTime.now(),
          XStatus.fromTmStatus(statusChange.status),
        );
        _logs.add(newLog);

        return state.copyWith(logs: state.logs);
      },
    );
  }

  void _onAppPressedEvent(AppPressedEvent event, Emitter<LogState> emit) {
    _pref.setShowApp(event.showApp);
    emit(state.copyWith(showApp: event.showApp));
    _xController.resetUserLogging(
      state.enableLog,
      event.showApp,
      state.showSessionOngoing,
      state.showRealtimeUsage,
    );
  }

  void _onSessionOngoingPressedEvent(
    SessionOngoingPressedEvent event,
    Emitter<LogState> emit,
  ) {
    _pref.setShowSessionOngoing(event.showSessionOngoing);
    emit(state.copyWith(showSessionOngoing: event.showSessionOngoing));
    _xController.resetUserLogging(
      state.enableLog,
      state.showApp,
      event.showSessionOngoing,
      state.showRealtimeUsage,
    );
  }

  void _onRealtimeUsagePressedEvent(
    RealtimeUsagePressedEvent event,
    Emitter<LogState> emit,
  ) {
    _pref.setShowRealtimeUsage(event.showRealtimeUsage);
    emit(state.copyWith(showRealtimeUsage: event.showRealtimeUsage));
    _xController.resetUserLogging(
      state.enableLog,
      state.showApp,
      state.showSessionOngoing,
      event.showRealtimeUsage,
    );
  }

  void _onHandlerPressedEvent(
    HandlerPressedEvent event,
    Emitter<LogState> emit,
  ) {
    _pref.setShowHandler(event.showHandler);
    emit(state.copyWith(showHandler: event.showHandler));
  }

  Future<Uint8List?> _getAppIcon(String app) async {
    if (Platform.isAndroid) {
      final icon = await _appIconCache.get(app);
      if (icon != null) {
        return icon;
      }
      final appInfo = await InstalledApps.getAppInfo(app, null);
      if (appInfo != null && appInfo.icon != null) {
        _appIconCache.put(app, appInfo.icon!);
        return appInfo.icon;
      }
      return null;
    }
    return null;
  }

  Future<void> _subscribe() async {
    logger.d('subscribing to log stream');
    try {
      _logStream ??= await _xController.userLogStream();
    } catch (e) {
      logger.e('subscribe error: $e');
      snack(e.toString());
      return;
    }
    logger.d('log stream connected');
    _logStream!.listen(
      (l) {
        add(_NewLogEvent(l));
      },
      onDone: () {
        _disconnectLogStream();
        logger.d('log stream done');
      },
      onError: (e) async {
        if (e is GrpcError && e.code == StatusCode.cancelled) {
          return;
        }
        logger.e('log stream error: $e');
        _disconnectLogStream();
        await Future.delayed(const Duration(seconds: 1));
        if (_tm.state == TmStatus.connected && _pref.enableLog) {
          _subscribe();
        }
      },
    );
  }

  Future<void> _onLogEvent(_NewLogEvent event, Emitter<LogState> emit) async {
    final l = event.log;
    switch (l.whichMessage()) {
      case UserLogMessage_Message.routeMessage:
        final routeInfo = SessionInfo(
          sessionId: l.routeMessage.sid,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            l.routeMessage.timestamp.toInt() * 1000,
          ),
          //TODO
          tag: l.routeMessage.tag,
          handlerName: state.showHandler
              ? await _outboundRepo.getHandlerName(l.routeMessage.tag)
              : null,
          dst: l.routeMessage.dst,
          sniffDomain: l.routeMessage.sniffDomain,
          app: l.routeMessage.appId,
          ipToDomain: l.routeMessage.ipToDomain,
          selector: l.routeMessage.selectorTag,
          routeRuleMatched: l.routeMessage.matchedRule,
          inboundTag: l.routeMessage.inboundTag,
          network: l.routeMessage.network,
          sniffProtocol: l.routeMessage.sniffProtofol,
          source: l.routeMessage.source,
          icon:
              (l.routeMessage.appId.isEmpty ||
                  !state.showApp ||
                  !Platform.isAndroid)
              ? null
              : await _getAppIcon(l.routeMessage.appId),
        );
        // dismiss same RouteInfo
        if (state.logs.isNotEmpty) {
          final last = state.logs.last;
          if (last is SessionInfo) {
            if (last.dst == routeInfo.dst && last.tag == routeInfo.tag) {
              // logger.d('dismiss same RouteInfo: $last');
              return;
            }
          }
        }
        final newLog = _addNewLog(routeInfo);
        if (newLog != null) {
          emit(newLog);
        }
      case UserLogMessage_Message.sessionUsage:
        final indexUsage = _findSessionIndexBackwards(l.sessionUsage.sid);
        if (indexUsage != -1) {
          final e = _logs[indexUsage];
          if (e is SessionInfo) {
            final updated = e.copyWith(
              up: l.sessionUsage.up.toInt(),
              down: l.sessionUsage.down.toInt(),
            );
            _logs[indexUsage] = updated;
            if (state.showRealtimeUsage) {
              if (state.filter.showAll()) {
                emit(state.copyWith(logs: _logs));
              } else {
                final newLogs = _logs
                    .where((e) => state.filter.show(e))
                    .toList();
                emit(
                  state.copyWith(
                    logs: CircularBuffer<XLog>(
                      maxSize: maxLogSize,
                      initialList: newLogs,
                    ),
                  ),
                );
              }
            }
          }
        }
      case UserLogMessage_Message.sessionError:
        final index = _findSessionIndexBackwards(l.sessionError.sid);
        if (index != -1) {
          final e = _logs[index];
          if (e is SessionInfo) {
            final newLog = e.copyWith(
              up: l.sessionError.up,
              down: l.sessionError.down,
              resolver: l.sessionError.dns,
              error: l.sessionError.message,
              ended: true,
            );
            _logs[index] = newLog;
            if (state.filter.showAll()) {
              emit(state.copyWith(logs: _logs));
            } else {
              final newLogs = _logs.where((e) => state.filter.show(e)).toList();
              emit(
                state.copyWith(
                  logs: CircularBuffer<XLog>(
                    maxSize: maxLogSize,
                    initialList: newLogs,
                  ),
                ),
              );
            }
          }
        }
      case UserLogMessage_Message.sessionEnd:
        final indexEnd = _findSessionIndexBackwards(l.sessionEnd.sid);
        if (indexEnd != -1) {
          final e = _logs[indexEnd];
          if (e is SessionInfo) {
            final updated = e.copyWith(
              up: l.sessionEnd.up.toInt(),
              down: l.sessionEnd.down.toInt(),
              ended: true,
            );
            _logs[indexEnd] = updated;
            if (state.filter.showAll()) {
              emit(state.copyWith(logs: _logs));
            } else {
              final newLogs = _logs.where((e) => state.filter.show(e)).toList();
              emit(
                state.copyWith(
                  logs: CircularBuffer<XLog>(
                    maxSize: maxLogSize,
                    initialList: newLogs,
                  ),
                ),
              );
            }
          }
        }
      case UserLogMessage_Message.rejectMessage:
        final newLog = _addNewLog(
          RejectMessage(
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              l.rejectMessage.timestamp.toInt() * 1000,
            ),
            dst: l.rejectMessage.dst,
            domain: l.rejectMessage.domain,
            app: l.rejectMessage.appId,
            reason: l.rejectMessage.reason,
            icon:
                (l.rejectMessage.appId.isEmpty ||
                    !state.showApp ||
                    !Platform.isAndroid)
                ? null
                : await _getAppIcon(l.rejectMessage.appId),
          ),
        );
        if (newLog != null) {
          emit(newLog);
        }
      case UserLogMessage_Message.fallback:
        logger.d('fallback: ${l.fallback.tag}');
        final index = _logs.indexOfBackwardsFunction((e) {
          if (e is SessionInfo) {
            return e.sessionId == l.fallback.sid;
          }
          return false;
        });
        if (index != -1) {
          final e = _logs[index];
          if (e is SessionInfo) {
            final newLog = e.copyWith(
              fallbackTag: l.fallback.tag,
              fallbackHandlerName: await _outboundRepo.getHandlerName(
                l.fallback.tag,
              ),
            );
            _logs[index] = newLog;
            if (state.filter.showAll()) {
              emit(state.copyWith(logs: _logs));
            } else {
              final newLogs = _logs.where((e) => state.filter.show(e)).toList();
              emit(
                state.copyWith(
                  logs: CircularBuffer<XLog>(
                    maxSize: maxLogSize,
                    initialList: newLogs,
                  ),
                ),
              );
            }
          }
        }
      default:
        return;
    }
  }

  int _findSessionIndexBackwards(int sid) {
    for (var i = _logs.length - 1; i >= 0; i--) {
      final e = _logs[i];
      if (e is SessionInfo && e.sessionId == sid) {
        return i;
      }
    }
    return -1;
  }

  LogState? _addNewLog(XLog log) {
    _logs.add(log);
    if (state.filter.showAll()) {
      return state.copyWith(logs: _logs);
    } else if (state.filter.show(log)) {
      return state.copyWith(logs: state.logs..add(log));
    }
    return null;
  }

  void _onDirectPressedEvent(DirectPressedEvent event, Emitter<LogState> emit) {
    _onFilterChanged(
      state.filter.copyWith(isDirectSelected: !state.filter.showDirect),
      emit,
    );
  }

  void _onProxyPressedEvent(ProxyPressedEvent event, Emitter<LogState> emit) {
    _onFilterChanged(
      state.filter.copyWith(isProxySelected: !state.filter.showProxy),
      emit,
    );
  }

  void _onRejectPressedEvent(RejectPressedEvent event, Emitter<LogState> emit) {
    _onFilterChanged(
      state.filter.copyWith(showReject: !state.filter.showReject),
      emit,
    );
  }

  void _onErrorOnlyPressedEvent(
    ErrorOnlyPressedEvent event,
    Emitter<LogState> emit,
  ) {
    _onFilterChanged(
      state.filter.copyWith(errorOnly: !state.filter.errorOnly),
      emit,
    );
  }

  void _onFilterChanged(LogFilter filter, Emitter<LogState> emit) {
    if (filter.showAll()) {
      emit(state.copyWith(filter: filter, logs: _logs));
    } else {
      final newLogs = _logs.where((e) => filter.show(e)).toList();
      emit(
        state.copyWith(
          filter: filter,
          logs: CircularBuffer<XLog>(maxSize: maxLogSize, initialList: newLogs),
        ),
      );
    }
  }

  void _onSubstringChangedEvent(
    SubstringChangedEvent event,
    Emitter<LogState> emit,
  ) {
    _onFilterChanged(state.filter.copyWith(substring: event.substring), emit);
  }

  void _disconnectLogStream() async {
    _logStream?.cancel();
    _logStream = null;
  }

  void _onLogSwitchPressedEvent(
    LogSwitchPressedEvent event,
    Emitter<LogState> emit,
  ) async {
    _pref.enableLog = event.enableLog;
    _logs.clear();
    emit(state.copyWith(enableLog: event.enableLog, logs: _logs));
    if (_tm.state == TmStatus.connected) {
      if (event.enableLog) {
        _subscribe();
      } else {
        _disconnectLogStream();
        await _xController.resetUserLogging(false, false, false, false);
      }
    }
  }
}

sealed class XLog extends Equatable {
  @override
  List<Object?> get props => [];
}

class SessionInfo extends XLog {
  SessionInfo({
    required this.timestamp,
    required this.tag,
    required this.dst,
    required this.app,
    required this.sessionId,
    required this.selector,
    this.fallbackHandlerName,
    this.fallbackTag,
    this.handlerName,
    this.error = '',
    this.sniffDomain = '',
    this.resolver = '',
    this.ipToDomain = '',
    this.up,
    this.down,
    this.icon,
    this.routeRuleMatched,
    this.inboundTag,
    this.network,
    this.sniffProtocol,
    this.source,
    this.ended = false,
  });
  final DateTime timestamp;
  // the handler id or "direct" or "1-2-3"(handler chain)
  final String tag;
  final String? handlerName;
  final String? fallbackTag;
  final String? fallbackHandlerName;
  final String dst;
  final String app;
  final Uint8List? icon;
  final String error;
  final String sniffDomain;
  final String resolver;
  final String ipToDomain;
  final int? up;
  final int? down;
  final int sessionId;
  final String selector;
  final String? routeRuleMatched;
  final String? inboundTag;
  final String? network;
  final String? sniffProtocol;
  final String? source;
  final bool ended;

  String get displayDst {
    if (isDomain(dst)) {
      return dst;
    } else if (sniffDomain.isNotEmpty) {
      return sniffDomain;
    }
    return dst;
  }

  bool get abnormal => (error.isNotEmpty);

  Color? abnormalColor(BuildContext contect) {
    if (error.contains('XTLS rejected QUIC') ||
        error.contains('reject quic over hysteria2')) {
      return null;
    }
    return Theme.of(contect).colorScheme.error;
  }

  String get appName {
    return getAppName(app);
  }

  @override
  List<Object?> get props => [sessionId];

  SessionInfo copyWith({
    String? error,
    String? resolver,
    int? up,
    int? down,
    Uint8List? icon,
    String? ipToDomain,
    String? selector,
    String? fallbackTag,
    String? fallbackHandlerName,
    String? handlerName,
    bool? ended,
  }) {
    return SessionInfo(
      timestamp: timestamp,
      tag: tag,
      dst: dst,
      app: app,
      sessionId: sessionId,
      sniffDomain: sniffDomain,
      error: error ?? this.error,
      resolver: resolver ?? this.resolver,
      ipToDomain: ipToDomain ?? this.ipToDomain,
      up: up ?? this.up,
      down: down ?? this.down,
      selector: selector ?? this.selector,
      fallbackTag: fallbackTag ?? this.fallbackTag,
      fallbackHandlerName: fallbackHandlerName ?? this.fallbackHandlerName,
      handlerName: handlerName ?? this.handlerName,
      inboundTag: inboundTag ?? inboundTag,
      network: network ?? network,
      sniffProtocol: sniffProtocol ?? sniffProtocol,
      source: source ?? source,
      routeRuleMatched: routeRuleMatched ?? routeRuleMatched,
      icon: icon ?? this.icon,
      ended: ended ?? this.ended,
    );
  }
}

String getAppName(String app) {
  if (Platform.isMacOS) {
    return app
        .split('/')
        .firstWhere((e) {
          return e.endsWith('.app');
        }, orElse: () => '')
        .replaceFirst('.app', '');
  } else if (Platform.isWindows) {
    return app.split('\\').last.replaceFirst('.exe', '');
  } else if (Platform.isAndroid) {
    final segments = app.split('.');
    if (segments.length >= 2) {
      return segments[1];
    }
    return segments.last;
  } else if (Platform.isLinux) {
    return app.split('/').last;
  }
  return app.split('.').last;
}

class ErrorMessage extends XLog {
  ErrorMessage(this.timestamp, this.message);
  final DateTime timestamp;
  final String message;
  @override
  List<Object?> get props => [timestamp, message];
}

class RejectMessage extends XLog {
  RejectMessage({
    required this.timestamp,
    required this.dst,
    this.domain = '',
    this.app = '',
    required this.reason,
    this.icon,
  });
  final DateTime timestamp;
  final String dst;
  final String domain;
  final String app;
  final String reason;
  final Uint8List? icon;
  @override
  List<Object?> get props => [timestamp, dst, domain, app, reason];

  String get displayDst {
    if (domain.isNotEmpty) {
      return domain;
    }
    return dst;
  }

  String get appName {
    return getAppName(app);
  }
}

// class WarnMessage extends TmLog {
//   WarnMessage(this.timestamp, this.message);
//   final DateTime timestamp;
//   final String message;
// }

class XStatusLog extends XLog {
  XStatusLog(this.timestamp, this.status);
  final DateTime timestamp;
  final XStatus status;
  @override
  List<Object?> get props => [timestamp, status];
}
