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

part of 'log_bloc.dart';

class LogEvent extends Equatable {
  const LogEvent();

  @override
  List<Object?> get props => [];
}

class LogBlocInitialEvent extends LogEvent {
  const LogBlocInitialEvent();
}

class _NewLogEvent extends LogEvent {
  const _NewLogEvent(this.log);
  final UserLogMessage log;
}

class LogSwitchPressedEvent extends LogEvent {
  const LogSwitchPressedEvent(this.enableLog);
  final bool enableLog;
}

class DirectPressedEvent extends LogEvent {
  const DirectPressedEvent();
}

class ProxyPressedEvent extends LogEvent {
  const ProxyPressedEvent();
}

class RejectPressedEvent extends LogEvent {
  const RejectPressedEvent();
}

class ErrorOnlyPressedEvent extends LogEvent {
  const ErrorOnlyPressedEvent();
}

class AppPressedEvent extends LogEvent {
  const AppPressedEvent(this.showApp);
  final bool showApp;
}

class HandlerPressedEvent extends LogEvent {
  const HandlerPressedEvent(this.showHandler);
  final bool showHandler;
}

class SessionOngoingPressedEvent extends LogEvent {
  const SessionOngoingPressedEvent(this.showSessionOngoing);
  final bool showSessionOngoing;
}

class RealtimeUsagePressedEvent extends LogEvent {
  const RealtimeUsagePressedEvent(this.showRealtimeUsage);
  final bool showRealtimeUsage;
}

class DismissSameRoutePressedEvent extends LogEvent {
  const DismissSameRoutePressedEvent(this.dismissSameRoute);
  final bool dismissSameRoute;
}

class SubstringChangedEvent extends LogEvent {
  const SubstringChangedEvent(this.substring);
  final String substring;

  @override
  List<Object?> get props => [substring];
}
