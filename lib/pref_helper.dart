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
import 'dart:developer';
import 'dart:io';
import 'dart:math';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/vx/router/router.pb.dart';
import 'package:tm/protos/vx/tun/tun.pb.dart';
import 'package:uuid/uuid.dart';
import 'package:vx/app/control.dart';
import 'package:vx/app/home/home.dart';
import 'package:vx/app/outbound/outbound_page.dart';
import 'package:vx/app/outbound/outbounds_bloc.dart';
import 'package:vx/app/routing/routing_page.dart';
import 'package:vx/app/blocs/proxy_selector/proxy_selector_bloc.dart';
import 'package:vx/common/common.dart';
import 'package:vx/utils/logger.dart';

enum PingMode { Real, Rtt }

enum Language {
  zh(Locale('zh', 'CN'), '简体中文(中国)', aiTranslated: false),
  en(Locale('en'), 'English(United States)', aiTranslated: false),
  ru(Locale('ru'), 'русский');

  final Locale locale;
  final String localText;
  final bool aiTranslated;

  static Language? fromCode(String code) {
    if (code == 'zh') return zh;
    if (code == 'en') return en;
    if (code == 'ru') return ru;
    return null;
  }

  const Language(this.locale, this.localText, {this.aiTranslated = true});
}

extension PrefHelperExtension on SharedPreferences {
  int get machineId {
    final id = getInt('machineId');
    if (id == null) {
      final newId = Random().nextInt(1023);
      setInt('machineId', newId);
      return newId;
    }
    return id;
  }

  bool get startOnBoot {
    return getBool('startOnBoot') ?? false;
  }

  void setStartOnBoot(bool enable) {
    setBool('startOnBoot', enable);
  }

  String get initialLocation {
    return getString('initialLocation') ?? '/node';
  }

  void setInitialLocation(String location) {
    setString('initialLocation', location);
  }

  bool get initialLaunch {
    return getBool('initialLaunch') ?? true;
  }

  void setInitialLaunch() {
    setBool('initialLaunch', false);
  }

  bool get welcomeShown {
    return getBool('welcomeShown') ?? false;
  }

  void setWelcomeShown(bool shown) {
    setBool('welcomeShown', shown);
  }

  bool get databaseInitialized {
    return getBool('databaseInitialized') ?? false;
  }

  void setDatabaseInitialized(bool initialized) {
    setBool('databaseInitialized', initialized);
  }

  InboundMode get inboundMode {
    final mode = getInt('inboundMode');
    if (mode == null) return InboundMode.tun;
    return InboundMode.values[mode];
  }

  void setInboundMode(InboundMode mode) {
    setInt('inboundMode', mode.index);
  }

  bool get sniff {
    return getBool('sniff') ?? true;
  }

  void setSniff(bool enable) {
    setBool('sniff', enable);
  }

  // return either a string or a RouteMode
  String? get routingMode {
    return _customRoutingMode;
  }

  void setRoutingMode(String? mode) {
    if (mode == null) {
      remove('customRoutingMode');
    } else {
      setString('customRoutingMode', mode);
    }
  }

  String? get _customRoutingMode {
    return getString('customRoutingMode');
  }

  SelectorConfig get manualSelectorConfig {
    return SelectorConfig(
      strategy: SelectorConfig_SelectingStrategy.ALL,
      tag: defaultProxySelectorTag,
      balanceStrategy:
          proxySelectorManualMode == ProxySelectorManualNodeSelectionMode.single
          ? SelectorConfig_BalanceStrategy.RANDOM
          : proxySelectorManualMultipleBalanceStrategy,
      filter: SelectorConfig_Filter(selected: true),
      landHandlers: proxySelectorManualLandHandlers,
    );
  }

  ProxySelectorMode get proxySelectorMode {
    final mode = getInt('proxySelectorMode');
    if (mode == null) return ProxySelectorMode.manual;
    return ProxySelectorMode.values[mode];
  }

  void setProxySelectorMode(ProxySelectorMode mode) {
    setInt('proxySelectorMode', mode.index);
  }

  ProxySelectorManualNodeSelectionMode get proxySelectorManualMode {
    final mode = getInt('proxySelectorManualMode');
    if (mode == null) return ProxySelectorManualNodeSelectionMode.single;
    return ProxySelectorManualNodeSelectionMode.values[mode];
  }

  void setProxySelectorManualMode(ProxySelectorManualNodeSelectionMode mode) {
    setInt('proxySelectorManualMode', mode.index);
  }

  List<Int64> get proxySelectorManualLandHandlers {
    final ids = getStringList('proxySelectorManualLandHandlers');
    if (ids == null) return [];
    return ids.map((e) => Int64(int.parse(e))).toList();
  }

  void setProxySelectorLandHandlers(List<Int64> ids) {
    setStringList(
      'proxySelectorManualLandHandlers',
      ids.map((e) => e.toString()).toList(),
    );
  }

  SelectorConfig_BalanceStrategy
  get proxySelectorManualMultipleBalanceStrategy {
    final strategy = getInt('proxySelectorManualMultipleBalanceStrategy');
    if (strategy == null) return SelectorConfig_BalanceStrategy.MEMORY;
    return SelectorConfig_BalanceStrategy.values[strategy];
  }

  void setProxySelectorManualMultipleBalanceStrategy(
    SelectorConfig_BalanceStrategy strategy,
  ) {
    setInt('proxySelectorManualMultipleBalanceStrategy', strategy.value);
  }

  // SelectorConfig get proxySelectorAutoConfig {
  //   final config = getString('proxySelectorAutoConfig');
  //   if (config == null) {
  //     return SelectorConfig(
  //       tag: defaultProxySelectorTag,
  //       filter: SelectorConfig_Filter(
  //         all: true,
  //       ),
  //       strategy: SelectorConfig_SelectingStrategy.ALL_OK,
  //       balanceStrategy: SelectorConfig_BalanceStrategy.MEMORY,
  //     );
  //   }
  //   return SelectorConfig.fromJson(config);
  // }

  // void setProxySelectorAutoConfig(SelectorConfig config) {
  //   if (config.tag != defaultProxySelectorTag) {
  //     config.tag = defaultProxySelectorTag;
  //   }
  //   print(config.tag);
  //   setString('proxySelectorAutoConfig', config.writeToJson());
  // }

  // SelectorConfig_SelectingStrategy get autoModeSelectingStrategy {
  //   final strategy = getInt('autoModeSelectingStrategy');
  //   if (strategy == null) {
  //     return SelectorConfig_SelectingStrategy.MOST_THROUGHPUT;
  //   }
  //   return SelectorConfig_SelectingStrategy.values[strategy];
  // }

  // void setAutoModeSelectingStrategy(SelectorConfig_SelectingStrategy strategy) {
  //   setInt('autoModeSelectingStrategy', strategy.value);
  // }

  // SelectorConfig_BalanceStrategy get autoModeBalanceStrategy {
  //   final strategy = getInt('autoModeBalanceStrategy');
  //   if (strategy == null) return SelectorConfig_BalanceStrategy.MEMORY;
  //   return SelectorConfig_BalanceStrategy.values[strategy];
  // }

  // void setAutoModeBalanceStrategy(SelectorConfig_BalanceStrategy strategy) {
  //   setInt('autoModeBalanceStrategy', strategy.value);
  // }

  // List<int> get autoModeFilterHandlerIds {
  //   final ids = getStringList('autoModeFilterHandlerIds');
  //   if (ids == null) return [];
  //   return ids.map((e) => int.parse(e)).toList();
  // }

  // void setAutoModeFilterHandlerIds(List<int> ids) {
  //   setStringList(
  //       'autoModeFilterHandlerIds', ids.map((e) => e.toString()).toList());
  // }

  // List<int> get autoModeFilterSubIds {
  //   final ids = getStringList('autoModeFilterSubIds');
  //   if (ids == null) return [];
  //   return ids.map((e) => int.parse(e)).toList();
  // }

  // void setAutoModeFilterSubIds(List<int> ids) {
  //   setStringList(
  //       'autoModeFilterSubIds', ids.map((e) => e.toString()).toList());
  // }

  // List<String> get autoModeFilterGroupTags {
  //   final tags = getStringList('autoModeFilterGroupTags');
  //   if (tags == null) return [];
  //   return tags;
  // }

  // void setAutoModeFilterGroupTags(List<String> tags) {
  //   setStringList('autoModeFilterGroupTags', tags);
  // }

  // enable user log
  bool get enableLog {
    return getBool('enableLog') ?? false;
  }

  set enableLog(bool enable) {
    setBool('enableLog', enable);
  }

  bool get enableDebugLog {
    return getBool('enableDebugLog') ?? false;
  }

  void setEnableDebugLog(bool enable) {
    setBool('enableDebugLog', enable);
  }

  bool get showApp {
    return getBool('showApp') ?? false;
  }

  void setShowApp(bool show) {
    setBool('showApp', show);
  }

  bool get showHandler {
    return getBool('showHandler') ?? false;
  }

  void setShowHandler(bool show) {
    setBool('showHandler', show);
  }

  bool get showSessionOngoing {
    return getBool('showSessionOngoing') ?? false;
  }

  void setShowSessionOngoing(bool show) {
    setBool('showSessionOngoing', show);
  }

  bool get showRealtimeUsage {
    return getBool('showRealtimeUsage') ?? false;
  }

  void setShowRealtimeUsage(bool show) {
    setBool('showRealtimeUsage', show);
  }

  DateTime? get lastGeoUpdate {
    final time = getInt('lastGeoUpdate');
    if (time == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(time);
  }

  void setLastGeoUpdate(DateTime time) {
    setInt('lastGeoUpdate', time.millisecondsSinceEpoch);
  }

  // fake dns
  bool get fakeDns {
    return getBool('fakeDns') ?? true;
  }

  void setFakeDns(bool enable) {
    setBool('fakeDns', enable);
  }

  bool get autoUpdate {
    return getBool('autoUpdate') ?? true;
  }

  void setAutoUpdate(bool enable) {
    setBool('autoUpdate', enable);
  }

  // minutes
  int get updateInterval {
    return getInt('updateInterval') ?? 300;
  }

  void setUpdateInterval(int interval) {
    setInt('updateInterval', interval);
  }

  /// Last time the app checked for updates (stored as milliseconds since epoch)
  int? get lastUpdateCheckTime {
    return getInt('lastUpdateCheckTime');
  }

  void setLastUpdateCheckTime(int timestamp) {
    setInt('lastUpdateCheckTime', timestamp);
  }

  String? get skipVersion {
    return getString('skipVersion');
  }

  void setSkipVersion(String version) {
    setString('skipVersion', version);
  }

  Language? get language {
    final i = getInt('language');
    if (i == null) return null;
    return Language.values[i];
  }

  void setLanguage(Language? language) {
    if (language == null) {
      remove('language');
    } else {
      setInt('language', language.index);
    }
  }

  bool get hasShownOnce {
    return getBool('hasShownOnce') ?? false;
  }

  void setHasShownOnce(bool show) {
    setBool('hasShownOnce', show);
  }

  bool get proxyShare {
    return getBool('proxyShare') ?? false;
  }

  void setProxyShare(bool enabled) {
    setBool('proxyShare', enabled);
  }

  String get proxyShareListenAddress {
    return getString('proxyShareListenAddress') ?? '0.0.0.0';
  }

  void setProxyShareListenAddress(String address) {
    setString('proxyShareListenAddress', address);
  }

  int get proxyShareListenPort {
    return getInt('proxyShareListenPort') ?? (Platform.isIOS ? 10800 : 1080);
  }

  void setProxyShareListenPort(int port) {
    setInt('proxyShareListenPort', port);
  }

  String get socksUdpAssociateAddress {
    return getString('socksUdpAccociateAddress') ?? '';
  }

  void setSocksUdpaccociateAddress(String addr) {
    setString('socksUdpAccociateAddress', addr);
  }

  double? get windowX {
    return getDouble('windowX');
  }

  void setWindowX(double x) {
    setDouble('windowX', x);
  }

  double? get windowY {
    return getDouble('windowY');
  }

  void setWindowY(double x) {
    setDouble('windowY', x);
  }

  double get windowWidth {
    return getDouble('windowWidth') ?? 800;
  }

  void setWindowWidth(double x) {
    setDouble('windowWidth', x);
  }

  double get windowHeight {
    return getDouble('windowHeight') ?? 600;
  }

  void setWindowHeight(double x) {
    setDouble('windowHeight', x);
  }

  bool get smScreenShowProtocol {
    return getBool('smScreenShowProtocol') ?? false;
  }

  void setSmScreenShowProtocol(bool show) {
    setBool('smScreenShowProtocol', show);
  }

  bool get smScreenShowOk {
    return getBool('smScreenShowOk') ?? true;
  }

  void setSmScreenShowOk(bool show) {
    setBool('smScreenShowOk', show);
  }

  bool get smScreenShowSpeed {
    return getBool('smScreenShowSpeed') ?? true;
  }

  void setSmScreenShowSpeed(bool show) {
    setBool('smScreenShowSpeed', show);
  }

  bool get smScreenShowLatency {
    return getBool('smScreenShowLatency') ?? false;
  }

  bool get smScreenShowActive {
    return getBool('smScreenShowActive') ?? true;
  }

  void setSmScreenShowActive(bool show) {
    setBool('smScreenShowActive', show);
  }

  void setSmScreenShowLatency(bool show) {
    setBool('smScreenShowLatency', show);
  }

  bool get smScreenShowAddress {
    return getBool('smScreenShowAddress') ?? false;
  }

  void setSmScreenShowAddress(bool show) {
    setBool('smScreenShowAddress', show);
  }

  String get outboundViewMode {
    return getString('outboundViewMode') ?? 'list';
  }

  void setOutboundViewMode(OutboundViewMode mode) {
    setString('outboundViewMode', mode.name);
  }

  OutboundTableSmallScreenPreference get outboundTableSmallScreenPreference {
    return OutboundTableSmallScreenPreference(
      showProtocol: smScreenShowProtocol,
      showUsable: smScreenShowOk,
      showPing: smScreenShowLatency,
      showSpeed: smScreenShowSpeed,
      showAddress: smScreenShowAddress,
      showActive: smScreenShowActive,
    );
  }

  /// Bytes to download for outbound UI speed tests (Cloudflare `__down?bytes=`).
  static const int _defaultOutboundSpeedTestBytes = 100000;
  static const int _minOutboundSpeedTestBytes = 1000;
  static const int _maxOutboundSpeedTestBytes = 100000000;

  int get outboundSpeedTestBytes {
    final v = getInt('outboundSpeedTestBytes');
    if (v == null || v < _minOutboundSpeedTestBytes) {
      return _defaultOutboundSpeedTestBytes;
    }
    if (v > _maxOutboundSpeedTestBytes) {
      return _maxOutboundSpeedTestBytes;
    }
    return v;
  }

  void setOutboundSpeedTestBytes(int bytes) {
    final clamped = bytes.clamp(
      _minOutboundSpeedTestBytes,
      _maxOutboundSpeedTestBytes,
    );
    setInt('outboundSpeedTestBytes', clamped);
  }

  bool get shareCnDirectApps {
    return getBool('shareCnDirectApps') ?? false;
  }

  void setShareCnDirectApps(bool enable) {
    setBool('shareCnDirectApps', enable);
  }

  bool get shareLog {
    if (isPkg) {
      return false;
    }
    return getBool('shareLog') ?? isProduction();
  }

  void setShareLog(bool enable) {
    setBool('shareLog', enable);
  }

  DateTime? get lastUploadTime {
    final time = getInt('lastLogUploadTime');
    if (time == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(time);
  }

  void setLastUploadTime(DateTime time) {
    setInt('lastLogUploadTime', time.millisecondsSinceEpoch);
  }

  (Col, SortOrder)? get sortCol {
    final col = getInt('sortCol');
    if (col == null) return null;
    final order = getInt('sortOrder');
    if (order == null) return null;
    if (col < 0 || col >= Col.values.length) return null;
    return (Col.values[col], order);
  }

  void setSortCol((Col, SortOrder)? col) {
    if (col == null) {
      remove('sortCol');
      remove('sortOrder');
    } else {
      setInt('sortCol', col.$1.index);
      setInt('sortOrder', col.$2);
    }
  }

  String? get nodeGroup {
    return getString('nodeGroup');
  }

  void setNodeGroup(String? group) {
    if (group == null) {
      remove('nodeGroup');
    } else {
      setString('nodeGroup', group);
    }
  }

  bool get advanceRouteMode {
    return getBool('advanceRouteMode') ?? false;
  }

  void setAdvanceRouteMode(bool enable) {
    setBool('advanceRouteMode', enable);
  }

  // bool get tunAlwaysEnableIpv6 {
  //   return getBool('tunAlwaysEnableIpv6') ?? false;
  // }

  // void setTunAlwaysEnableIpv6(bool enable) {
  //   setBool('tunAlwaysEnableIpv6', enable);
  // }

  TunConfig_TUN46Setting get tun46Setting {
    final setting = getInt('tun46Setting');
    if (setting == null) {
      return ((Platform.isWindows || Platform.isLinux)
          ? TunConfig_TUN46Setting.DYNAMIC
          : TunConfig_TUN46Setting.FOUR_ONLY);
    }
    return TunConfig_TUN46Setting.values[setting];
  }

  void setTun46Setting(TunConfig_TUN46Setting setting) {
    setInt('tun46Setting', setting.value);
  }

  bool get rejectIpv6 {
    return getBool('rejectIpv6') ?? true;
  }

  void setRejectIpv6(bool enable) {
    setBool('rejectIpv6', enable);
  }

  /// TUN device IPv4 CIDR (e.g. 172.23.27.1/24). Null or empty = use default.
  String get tunCidr4 {
    final v = getString('tunCidr4');
    return v ?? '172.23.27.1/24';
  }

  void setTunCidr4(String value) {
    setString('tunCidr4', value.trim());
  }

  /// TUN device IPv6 CIDR (e.g. fc20::1/120). Null or empty = use default.
  String get tunCidr6 {
    final v = getString('tunCidr6');
    return v ?? 'fc20::1/120';
  }

  void setTunCidr6(String value) {
    setString('tunCidr6', value.trim());
  }

  /// TUN device DNS IPv4 servers, comma-separated (e.g. 172.23.27.2). Null or empty = use default.
  String get tunDns4 {
    final v = getString('tunDns4');
    return v ?? '172.23.27.2';
  }

  void setTunDns4(String value) {
    setString('tunDns4', value.trim());
  }

  /// TUN device DNS IPv6 servers, comma-separated (e.g. fc20::2). Null or empty = use default.
  String get tunDns6 {
    final v = getString('tunDns6');
    return v ?? 'fc20::2';
  }

  void setTunDns6(String value) {
    setString('tunDns6', value.trim());
  }

  /// TUN IPv4 routes, comma-separated (e.g. 0.0.0.0/0). Null or empty = use default.
  String get tunRoutes4 {
    final v = getString('tunRoutes4');
    return (v == null) ? '0.0.0.0/0' : v;
  }

  List<String> get tunRoutes4List => tunRoutes4
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  void setTunRoutes4(String value) {
    setString('tunRoutes4', value.trim());
  }

  /// TUN IPv6 routes, comma-separated (e.g. ::/0). Null or empty = use default.
  String get tunRoutes6 {
    final v = getString('tunRoutes6');
    return (v == null) ? '::/0' : v;
  }

  List<String> get tunRoutes6List => tunRoutes6
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  void setTunRoutes6(String value) {
    setString('tunRoutes6', value.trim());
  }

  /// TUN device MTU. Null = use platform default.
  int get tunMtu {
    final v = getInt('tunMtu');
    if (v == null || v <= 0) {
      if (Platform.isMacOS || Platform.isIOS) {
        return 4064;
      } else {
        return 8000;
      }
    }
    return v;
  }

  void setTunMtu(int? value) {
    if (value == null || value <= 0) {
      remove('tunMtu');
    } else {
      setInt('tunMtu', value);
    }
  }

  ThemeMode get themeMode {
    final mode = getInt('themeMode');
    if (mode == null) return ThemeMode.system;
    return ThemeMode.values[mode];
  }

  void setThemeMode(ThemeMode mode) {
    setInt('themeMode', mode.index);
  }

  bool get windowsServiceInstalled {
    return getBool('windowsServiceInstalled') ?? false;
  }

  void setWindowsServiceInstalled(bool installed) {
    setBool('windowsServiceInstalled', installed);
  }

  bool get automaticallyAddFallbackDomain {
    return getBool('automaticallyAddFallbackDomain') ?? true;
  }

  void setAutomaticallyAddFallbackDomain(bool enable) {
    setBool('automaticallyAddFallbackDomain', enable);
  }

  bool get changeIpv6ToDomain {
    return getBool('changeIpv6ToDomain') ?? true;
  }

  void setChangeIpv6ToDomain(bool enable) {
    setBool('changeIpv6ToDomain', enable);
  }

  int get fallbackTimeout {
    return getInt('fallbackTimeout') ?? 8;
  }

  void setFallbackTimeout(int timeout) {
    setInt('fallbackTimeout', timeout);
  }

  PingMode get pingMode {
    final mode = getInt('pingMode');
    if (mode == null) return PingMode.Real;
    return PingMode.values[mode];
  }

  void setPingMode(PingMode mode) {
    setInt('pingMode', mode.index);
  }

  bool get alwaysOn {
    if (Platform.isMacOS || Platform.isAndroid || Platform.isIOS) {
      return false;
    }
    return getBool('alwaysOn') ?? false;
  }

  void setAlwaysOn(bool enable) {
    setBool('alwaysOn', enable);
  }

  /// iOS only: VPN On Demand so the packet tunnel starts after device reboot.
  bool get connectOnDemand {
    if (!Platform.isIOS) {
      return false;
    }
    return getBool('connectOnDemand') ?? false;
  }

  void setConnectOnDemand(bool enable) {
    setBool('connectOnDemand', enable);
  }

  // if a user clicks connect, set this to true.
  // if a user clicks disconnect, set this to false.
  bool get connect {
    return getBool('connect') ?? false;
  }

  void setConnect(bool enable) {
    setBool('connect', enable);
  }

  int get socksPort {
    return getInt('socksPort') ?? 10800;
  }

  void setSocksPort(int port) {
    setInt('socksPort', port);
  }

  int get httpPort {
    return getInt('httpPort') ?? 10801;
  }

  void setHttpPort(int port) {
    setInt('httpPort', port);
  }

  bool get dynamicSystemProxyPorts {
    return getBool('dynamicSystemProxyPorts') ?? false;
  }

  void setDynamicSystemProxyPorts(bool enable) {
    setBool('dynamicSystemProxyPorts', enable);
  }

  bool get rejectQuicHysteria {
    return getBool('rejectQuicHysteria') ?? true;
  }

  void setRejectQuicHysteria(bool enable) {
    setBool('rejectQuicHysteria', enable);
  }

  bool get cloudSync {
    return getBool('cloudSync') ?? true;
  }

  void setCloudSync(bool enable) {
    setBool('cloudSync', enable);
  }

  bool get syncNodeSub {
    return getBool('syncNodeSub') ?? false;
  }

  void setSyncNodeSub(bool enable) {
    setBool('syncNodeSub', enable);
  }

  bool get syncRoute {
    return getBool('syncRoute') ?? false;
  }

  void setSyncRuleDnsSet(bool enable) {
    setBool('syncRoute', enable);
  }

  void setSyncSelectorSetting(bool enable) {
    setBool('syncSelectorSetting', enable);
  }

  bool get syncSelectorSetting {
    return getBool('syncSelectorSetting') ?? false;
  }

  bool get syncServer {
    return getBool('syncServer') ?? false;
  }

  void setSyncServer(bool enable) {
    setBool('syncServer', enable);
  }

  DateTime? get deviceIdRefreshTime {
    final time = getInt('deviceIdRefreshTime');
    if (time == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(time);
  }

  void setDeviceIdUpdateTime(DateTime time) {
    setInt('deviceIdRefreshTime', time.millisecondsSinceEpoch);
  }

  String? get fcmToken {
    return getString('fcmToken');
  }

  void setFcmToken(String? token) {
    if (token == null) {
      remove('fcmToken');
    } else {
      setString('fcmToken', token);
    }
  }

  String? get realmDeviceName => getString('realmDeviceName');

  void setRealmDeviceName(String name) {
    setString('realmDeviceName', name);
  }

  String? get realmDeviceRealmUrl => getString('realmDeviceRealmUrl');

  void setRealmDeviceRealmUrl(String url) {
    setString('realmDeviceRealmUrl', url);
  }

  bool get realmServerEnabled => getBool('realmServerEnabled') ?? false;

  void setRealmServerEnabled(bool enabled) {
    setBool('realmServerEnabled', enabled);
  }

  String? get realmServerAuth => getString('realmServerAuth');

  void setRealmServerAuth(String auth) {
    setString('realmServerAuth', auth);
  }

  String? get realmServerHysteriaConfigBase64 =>
      getString('realmServerHysteriaConfigBase64');

  void setRealmServerHysteriaConfigBase64(String value) {
    setString('realmServerHysteriaConfigBase64', value);
  }

  bool get autoBackup {
    return getBool('autoBackup') ?? false;
  }

  void setAutoBackup(bool enable) {
    setBool('autoBackup', enable);
  }

  String get dbName {
    if (Platform.isWindows) {
      return getString('dbName') ?? 'x_database.sqlite';
    }
    return 'x_database.sqlite';
  }

  void setDbName(String name) {
    setString('dbName', name);
  }

  bool get storeSudoPasswordInMemory {
    return getBool('storeSudoPasswordInMemory') ?? false;
  }

  void setStoreSudoPasswordInMemory(bool enable) {
    setBool('storeSudoPasswordInMemory', enable);
  }

  bool get showRpmNotice {
    return getBool('showRpmNotice') ?? true;
  }

  void setShowRpmNotice(bool show) {
    setBool('showRpmNotice', show);
  }

  // Auto node testing settings
  bool get autoTestNodes {
    return getBool('autoTestNodes') ?? true;
  }

  void setAutoTestNodes(bool enable) {
    setBool('autoTestNodes', enable);
  }

  // Test interval in minutes (default: 60 minutes = 1 hour)
  int get nodeTestInterval {
    return getInt('nodeTestInterval') ?? 720;
  }

  void setNodeTestInterval(int minutes) {
    setInt('nodeTestInterval', minutes);
  }

  DateTime? get lastNodeTestTime {
    final time = getInt('lastNodeTestTime');
    if (time == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(time);
  }

  void setLastNodeTestTime(DateTime time) {
    setInt('lastNodeTestTime', time.millisecondsSinceEpoch);
  }

  // Geo file auto-update settings
  bool get autoUpdateGeoFiles {
    return getBool('autoUpdateGeoFiles') ?? true;
  }

  void setAutoUpdateGeoFiles(bool enable) {
    setBool('autoUpdateGeoFiles', enable);
  }

  // Update interval in days (default: 7 days)
  int get geoUpdateInterval {
    return getInt('geoUpdateInterval') ?? 7;
  }

  void setGeoUpdateInterval(int days) {
    setInt('geoUpdateInterval', days);
  }

  NodesHelperSegment get nodesHelperSegment {
    final segment = getInt('nodesHelperSegment');
    if (segment == null) return NodesHelperSegment.fastest;
    return NodesHelperSegment.values[segment];
  }

  void setNodesHelperSegment(NodesHelperSegment segment) {
    setInt('nodesHelperSegment', segment.index);
  }

  /// Up to 10 most recently used node (handler) IDs, most recent first.
  List<int> get recentlyUsedNodeIds {
    final list = getStringList('recentlyUsedNodeIds');
    if (list == null) return [];
    return list.map((e) => int.tryParse(e)).whereType<int>().toList();
  }

  /// Append a node ID to recently used (prepend in list, dedupe, keep max 10).
  void addRecentlyUsedNodeId(int id) {
    if (id <= 0) return;
    final current = recentlyUsedNodeIds;
    final updated = [id, ...current.where((e) => e != id)].take(10).toList();
    setStringList(
      'recentlyUsedNodeIds',
      updated.map((e) => e.toString()).toList(),
    );
  }

  List<String> getSelectorSubString() {
    final subString = getStringList('selectorSubString');
    if (subString == null) return [];
    return subString;
  }

  void setSelectorSubString(List<String> subString) {
    setStringList('selectorSubString', subString);
  }

  List<String> getSelectorPrefix() {
    final prefix = getStringList('selectorPrefix');
    if (prefix == null) return [];
    return prefix;
  }

  void setSelectorPrefix(List<String> prefix) {
    setStringList('selectorPrefix', prefix);
  }

  /// Home widget IDs that the user has chosen to hide. Empty = show all.
  Set<String> get hiddenHomeWidgetIds {
    final list = getStringList('hiddenHomeWidgetIds');
    if (list == null) return {};
    return list.toSet();
  }

  void setHiddenHomeWidgetIds(Set<String> ids) {
    setStringList('hiddenHomeWidgetIds', ids.toList());
  }

  /// Whether the user prefers the customizable home page layout.
  ///
  /// Defaults to `false`, which means using the standard home page.
  bool get useCustomizableHomePage {
    return getBool('useCustomizableHomePage') ?? false;
  }

  void setUseCustomizableHomePage(bool value) {
    setBool('useCustomizableHomePage', value);
  }

  HomeLayout? getHomeWidgetRows(HomeLayoutPreset preset) {
    final jsonRaw = getString('homeWidgetRows.${preset.storageKey}');
    try {
      if (jsonRaw != null && jsonRaw.isNotEmpty) {
        return HomeLayout.fromJson(jsonRaw);
      }
    } catch (e) {
      logger.e('Error parsing home widget rows: $e');
      clearHomeWidgetRows(preset);
    }
    return null;
  }

  void setHomeWidgetRows(HomeLayoutPreset preset, HomeLayout rows) {
    setString('homeWidgetRows.${preset.storageKey}', rows.toJson());
  }

  void clearHomeWidgetRows(HomeLayoutPreset preset) {
    remove('homeWidgetRows.${preset.storageKey}');
  }

  // List<Map<String, dynamic>>? get homeDashboardLayout {
  //   final raw = getString('homeDashboardLayout');
  //   if (raw == null || raw.isEmpty) return null;
  //   final layout = jsonDecode(raw);
  //   inspect(layout);
  //   if (layout is! List<Map<String, dynamic>>) return null;
  //   return layout;
  // }

  // void setHomeDashboardLayout(List<Map<String, dynamic>> layout) {
  //   setString('homeDashboardLayout', jsonEncode(layout));
  // }

  // void clearHomeDashboardLayout() {
  //   remove('homeDashboardLayout');
  // }

  String get uniqueDeviceId {
    const key = 'unique_device_id';

    // Check if we already have a stored device ID
    String? deviceId = getString(key);
    if (deviceId != null && deviceId.isNotEmpty) {
      return deviceId;
    }

    // Fallback to UUID if hardware ID is not available
    deviceId ??= const Uuid().v4();

    // Store for future use
    setString(key, deviceId);
    return deviceId;
  }

  String get uniqueDeviceIdForCnDirectApps {
    const key = 'unique_device_id_for_cn_direct_apps';

    // Check if we already have a stored device ID
    String? deviceId = getString(key);
    if (deviceId != null && deviceId.isNotEmpty) {
      return deviceId;
    }

    // Fallback to UUID if hardware ID is not available
    deviceId ??= const Uuid().v4();

    // Store for future use
    setString(key, deviceId);
    return deviceId;
  }

  int get directDialingTimeout {
    return getInt('directDialingTimeout') ?? 16;
  }

  void setDirectDialingTimeout(int timeout) {
    setInt('directDialingTimeout', timeout);
  }

  int get globalDialTimeout {
    return getInt('globalDialTimeout') ?? 16;
  }

  void setGlobalDialTimeout(int timeout) {
    setInt('globalDialTimeout', timeout);
  }

  int get policyHandshakeTimeout {
    return getInt('policyHandshakeTimeout') ?? 4;
  }

  void setPolicyHandshakeTimeout(int timeout) {
    setInt('policyHandshakeTimeout', timeout);
  }

  int get policyConnectionIdleTimeout {
    return getInt('policyConnectionIdleTimeout') ?? 60;
  }

  void setPolicyConnectionIdleTimeout(int timeout) {
    setInt('policyConnectionIdleTimeout', timeout);
  }

  int get policyUdpIdleTimeout {
    return getInt('policyUdpIdleTimeout') ?? 120;
  }

  void setPolicyUdpIdleTimeout(int timeout) {
    setInt('policyUdpIdleTimeout', timeout);
  }

  int get policyUpLinkOnlyTimeout {
    return getInt('policyUpLinkOnlyTimeout') ?? 5;
  }

  void setPolicyUpLinkOnlyTimeout(int timeout) {
    setInt('policyUpLinkOnlyTimeout', timeout);
  }

  int get policyDownLinkOnlyTimeout {
    return getInt('policyDownLinkOnlyTimeout') ?? 2;
  }

  void setPolicyDownLinkOnlyTimeout(int timeout) {
    setInt('policyDownLinkOnlyTimeout', timeout);
  }

  DateTime? get reviewFirstUseAt {
    final value = getInt('reviewFirstUseAt');
    if (value == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  void setReviewFirstUseAt(DateTime time) {
    setInt('reviewFirstUseAt', time.millisecondsSinceEpoch);
  }

  int get reviewAppOpenCount {
    return getInt('reviewAppOpenCount') ?? 0;
  }

  void setReviewAppOpenCount(int count) {
    setInt('reviewAppOpenCount', count);
  }

  DateTime? get reviewLastPromptAt {
    final value = getInt('reviewLastPromptAt');
    if (value == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(value);
  }

  void setReviewLastPromptAt(DateTime time) {
    setInt('reviewLastPromptAt', time.millisecondsSinceEpoch);
  }

  int get reviewPromptCount {
    return getInt('reviewPromptCount') ?? 0;
  }

  void setReviewPromptCount(int count) {
    setInt('reviewPromptCount', count);
  }

  bool get reviewAutoPromptDisabled {
    return getBool('reviewAutoPromptDisabled') ?? false;
  }

  void setReviewAutoPromptDisabled(bool disabled) {
    setBool('reviewAutoPromptDisabled', disabled);
  }

  String? get installedWindowsServiceVersion {
    return getString('installedWindowsServiceVersion');
  }

  void setInstalledWindowsServiceVersion(String version) {
    setString('installedWindowsServiceVersion', version);
  }
}
