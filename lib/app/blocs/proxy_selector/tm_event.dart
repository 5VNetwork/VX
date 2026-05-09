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

part of 'proxy_selector_bloc.dart';

sealed class ProxySelectorEvent extends Equatable {
  const ProxySelectorEvent();

  @override
  List<Object> get props => [];

  @override
  bool get stringify => true;
}

class XBlocInitialEvent extends ProxySelectorEvent {}

class AuthUserChangedEvent extends ProxySelectorEvent {
  const AuthUserChangedEvent(this.unlockPro);
  final bool unlockPro;

  @override
  List<Object> get props => [unlockPro];
}

class RoutingModeSelectionChangeEvent extends ProxySelectorEvent {
  const RoutingModeSelectionChangeEvent(this.routeMode);
  final CustomRouteMode routeMode;
}

class CustomRouteModeChangeEvent extends ProxySelectorEvent {
  const CustomRouteModeChangeEvent(this.routeMode);
  final CustomRouteMode routeMode;
}

class CustomRouteModeDeleteEvent extends ProxySelectorEvent {
  const CustomRouteModeDeleteEvent(this.routeMode);
  final CustomRouteMode routeMode;
}

class InboundModeChangeEvent extends ProxySelectorEvent {
  const InboundModeChangeEvent(this.mode);
  final InboundMode mode;
}

class ProxySelectorModeChangeEvent extends ProxySelectorEvent {
  const ProxySelectorModeChangeEvent(this.mode);
  final ProxySelectorMode mode;

  @override
  List<Object> get props => [mode];
}

class ManualSelectionModeChangeEvent extends ProxySelectorEvent {
  const ManualSelectionModeChangeEvent(this.mode);
  final ProxySelectorManualNodeSelectionMode mode;
}

class ManualNodeBalanceStrategyChangeEvent extends ProxySelectorEvent {
  const ManualNodeBalanceStrategyChangeEvent(this.strategy);
  final SelectorConfig_BalanceStrategy strategy;
}

class ManualModeLandHandlersChangeEvent extends ProxySelectorEvent {
  const ManualModeLandHandlersChangeEvent();
}

class AutoNodeSelectorConfigChangeEvent extends ProxySelectorEvent {
  const AutoNodeSelectorConfigChangeEvent({
    this.selectorStrategyOrLandHandlers = false,
    this.balancingStragegy = false,
    this.filterLandHandlers = false,
  });

  final bool selectorStrategyOrLandHandlers;
  final bool balancingStragegy;
  final bool filterLandHandlers;
}

class TestParametersChangeEvent extends ProxySelectorEvent {
  const TestParametersChangeEvent({required this.config});
  final SelectorConfig config;
}
