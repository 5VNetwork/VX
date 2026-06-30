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

class ProxySelectorState extends Equatable {
  const ProxySelectorState({
    this.routeMode,
    this.showProxySelector,
    this.proxySelectorMode = ProxySelectorMode.auto,
    this.manualNodeSetting = const ManualNodeSetting(),
    this.autoNodeSetting,
  });
  // either a RouteMode or a String which is the name of a RouteConfig
  final String? routeMode;
  final bool? showProxySelector;
  final ProxySelectorMode proxySelectorMode;
  final ManualNodeSetting manualNodeSetting;
  final SelectorConfig? autoNodeSetting;

  bool get enableManualSelect =>
      (showProxySelector ?? false) &&
      proxySelectorMode == ProxySelectorMode.manual;

  @override
  List<Object?> get props => [
    routeMode,
    proxySelectorMode,
    manualNodeSetting,
    autoNodeSetting,
    showProxySelector,
  ];

  // copy with
  ProxySelectorState copyWith({
    String? routeMode,
    bool? showProxySelector,
    bool? proxySelectorEnabled,
    ProxySelectorMode? outboundMode,
    ManualNodeSetting? manualNodeSetting,
    SelectorConfig? autoNodeSetting,
  }) {
    return ProxySelectorState(
      routeMode: routeMode ?? this.routeMode,
      showProxySelector: showProxySelector ?? this.showProxySelector,
      proxySelectorMode: outboundMode ?? proxySelectorMode,
      manualNodeSetting: manualNodeSetting ?? this.manualNodeSetting,
      autoNodeSetting: autoNodeSetting ?? this.autoNodeSetting,
    );
  }
}

class ManualNodeSetting extends Equatable {
  const ManualNodeSetting({
    this.nodeMode = ProxySelectorManualNodeSelectionMode.single,
    this.balanceStrategy = SelectorConfig_BalanceStrategy.RANDOM,
    this.landHandlers = const [],
  });
  final ProxySelectorManualNodeSelectionMode nodeMode;
  final SelectorConfig_BalanceStrategy balanceStrategy;
  final List<Int64> landHandlers;
  @override
  List<Object?> get props => [nodeMode, balanceStrategy, landHandlers];

  ManualNodeSetting copyWith({
    ProxySelectorManualNodeSelectionMode? nodeMode,
    SelectorConfig_BalanceStrategy? balanceStrategy,
    List<Int64>? landHandlers,
  }) {
    return ManualNodeSetting(
      nodeMode: nodeMode ?? this.nodeMode,
      balanceStrategy: balanceStrategy ?? this.balanceStrategy,
      landHandlers: landHandlers ?? this.landHandlers,
    );
  }
}

class AutoNodeSetting extends Equatable {
  const AutoNodeSetting({
    this.selectingStrategy = SelectorConfig_SelectingStrategy.MOST_THROUGHPUT,
    this.balanceStrategy = SelectorConfig_BalanceStrategy.RANDOM,
  });
  final SelectorConfig_SelectingStrategy selectingStrategy;
  final SelectorConfig_BalanceStrategy balanceStrategy;

  @override
  List<Object?> get props => [selectingStrategy, balanceStrategy];

  AutoNodeSetting copyWith({
    SelectorConfig_SelectingStrategy? selectingStrategy,
    SelectorConfig_BalanceStrategy? balanceStrategy,
  }) {
    return AutoNodeSetting(
      selectingStrategy: selectingStrategy ?? this.selectingStrategy,
      balanceStrategy: balanceStrategy ?? this.balanceStrategy,
    );
  }
}

enum XStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  reconnecting,
  unknown,
  preparing;

  static XStatus fromTmStatus(TmStatus status) {
    switch (status) {
      case TmStatus.disconnected:
        return XStatus.disconnected;
      case TmStatus.connecting:
        return XStatus.connecting;
      case TmStatus.connected:
        return XStatus.connected;
      case TmStatus.disconnecting:
        return XStatus.disconnecting;
      case TmStatus.reconnecting:
        return XStatus.reconnecting;
      case TmStatus.unknown:
        return XStatus.unknown;
    }
  }

  String localizedString(BuildContext context) {
    switch (this) {
      case XStatus.disconnected:
        return AppLocalizations.of(context)!.disconnected;
      case XStatus.connecting:
        return AppLocalizations.of(context)!.connecting;
      case XStatus.connected:
        return AppLocalizations.of(context)!.connected;
      case XStatus.disconnecting:
        return AppLocalizations.of(context)!.disconnecting;
      case XStatus.reconnecting:
        return AppLocalizations.of(context)!.reconnecting;
      case XStatus.unknown:
        return AppLocalizations.of(context)!.unknown;
      case XStatus.preparing:
        return AppLocalizations.of(context)!.preparing;
    }
  }
}

enum InboundMode {
  tun(),
  systemProxy(),
  wfp();

  const InboundMode();

  String toLocalString(BuildContext ctx) {
    switch (this) {
      case InboundMode.wfp:
        return 'WFP';
      case InboundMode.systemProxy:
        return AppLocalizations.of(ctx)!.systemProxy;
      case InboundMode.tun:
        return 'TUN';
    }
  }
}

enum ProxySelectorMode {
  @JsonValue('auto')
  auto(),
  @JsonValue('manual')
  manual();

  const ProxySelectorMode();

  String toLocalString(BuildContext ctx) {
    switch (this) {
      case ProxySelectorMode.auto:
        return AppLocalizations.of(ctx)!.auto;
      case ProxySelectorMode.manual:
        return AppLocalizations.of(ctx)!.mannual;
    }
  }
}
