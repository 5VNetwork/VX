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

import 'package:flutter/material.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart';
import 'package:tm/protos/vx/common/net/net.pb.dart';
import 'package:tm/protos/vx/proxy/anytls/anytls.pb.dart';
import 'package:tm/protos/vx/proxy/dokodemo/dokodemo.pb.dart';
import 'package:tm/protos/vx/proxy/http/http.pb.dart';
import 'package:tm/protos/vx/proxy/shadowsocks/shadowsocks.pb.dart';
import 'package:tm/protos/vx/proxy/shadowsocks2022/shadowsocks2022.pb.dart';
import 'package:tm/protos/vx/proxy/socks/socks.pb.dart';
import 'package:tm/protos/vx/proxy/trojan/trojan.pb.dart';
import 'package:tm/protos/vx/proxy/vless/vless.pb.dart';
import 'package:tm/protos/vx/proxy/vmess/vmess.pb.dart';
import 'package:tm/protos/vx/proxy/wireguard/config.pb.dart';
import 'package:vx/theme.dart';
import 'package:vx/widgets/outbound_handler_form/outbound_handler_form.dart';

final oldTypeUrlToNewTypeUrl = {
  'type.googleapis.com/x.proxy.Shadowsocks2022ClientConfig':
      'type.googleapis.com/vx.proxy.shadowsocks2022.Shadowsocks2022ClientConfig',
  'type.googleapis.com/x.proxy.Shadowsocks2022ServerConfig':
      'type.googleapis.com/vx.proxy.shadowsocks2022.Shadowsocks2022ServerConfig',
  'type.googleapis.com/x.proxy.ShadowsocksClientConfig':
      'type.googleapis.com/vx.proxy.shadowsocks.ShadowsocksClientConfig',
  'type.googleapis.com/x.proxy.ShadowsocksServerConfig':
      'type.googleapis.com/vx.proxy.shadowsocks.ShadowsocksServerConfig',
  'type.googleapis.com/x.proxy.VmessClientConfig':
      'type.googleapis.com/vx.proxy.vmess.VmessClientConfig',
  'type.googleapis.com/x.proxy.VmessServerConfig':
      'type.googleapis.com/vx.proxy.vmess.VmessServerConfig',
  'type.googleapis.com/x.proxy.TrojanClientConfig':
      'type.googleapis.com/vx.proxy.trojan.TrojanClientConfig',
  'type.googleapis.com/x.proxy.TrojanServerConfig':
      'type.googleapis.com/vx.proxy.trojan.TrojanServerConfig',
  'type.googleapis.com/x.proxy.SocksClientConfig':
      'type.googleapis.com/vx.proxy.socks.SocksClientConfig',
  'type.googleapis.com/x.proxy.SocksServerConfig':
      'type.googleapis.com/vx.proxy.socks.SocksServerConfig',
  'type.googleapis.com/x.proxy.VlessClientConfig':
      'type.googleapis.com/vx.proxy.vless.VlessClientConfig',
  'type.googleapis.com/x.proxy.VlessServerConfig':
      'type.googleapis.com/vx.proxy.vless.VlessServerConfig',
  'type.googleapis.com/x.proxy.Hysteria2ClientConfig':
      'type.googleapis.com/vx.proxy.hysteria.Hysteria2ClientConfig',
  'type.googleapis.com/x.proxy.Hysteria2ServerConfig':
      'type.googleapis.com/vx.proxy.hysteria.Hysteria2ServerConfig',
  'type.googleapis.com/x.proxy.AnytlsClientConfig':
      'type.googleapis.com/vx.proxy.anytls.AnytlsClientConfig',
  'type.googleapis.com/x.proxy.AnytlsServerConfig':
      'type.googleapis.com/vx.proxy.anytls.AnytlsServerConfig',
  'type.googleapis.com/x.proxy.DokodemoConfig':
      'type.googleapis.com/vx.proxy.dokodemo.DokodemoConfig',
  'type.googleapis.com/x.proxy.HttpClientConfig':
      'type.googleapis.com/vx.proxy.http.HttpClientConfig',
  'type.googleapis.com/x.proxy.HttpServerConfig':
      'type.googleapis.com/vx.proxy.http.HttpServerConfig',
};

ProxyProtocolLabel getProtocolTypeFromAny(Any any) {
  // unpack the any to the specific config type
  switch (any.typeUrl) {
    case 'type.googleapis.com/x.proxy.Shadowsocks2022ClientConfig' ||
        'type.googleapis.com/x.proxy.Shadowsocks2022ServerConfig' ||
        'type.googleapis.com/vx.proxy.shadowsocks2022.Shadowsocks2022ClientConfig' ||
        'type.googleapis.com/vx.proxy.shadowsocks2022.Shadowsocks2022ServerConfig':
      return ProxyProtocolLabel.shadowsocks2022;
    case 'type.googleapis.com/x.proxy.ShadowsocksClientConfig' ||
        'type.googleapis.com/x.proxy.ShadowsocksServerConfig' ||
        'type.googleapis.com/vx.proxy.shadowsocks.ShadowsocksClientConfig' ||
        'type.googleapis.com/vx.proxy.shadowsocks.ShadowsocksServerConfig':
      return ProxyProtocolLabel.shadowsocks;
    case 'type.googleapis.com/x.proxy.VmessClientConfig' ||
        'type.googleapis.com/x.proxy.VmessServerConfig' ||
        'type.googleapis.com/vx.proxy.vmess.VmessClientConfig' ||
        'type.googleapis.com/vx.proxy.vmess.VmessServerConfig':
      return ProxyProtocolLabel.vmess;
    case 'type.googleapis.com/x.proxy.TrojanClientConfig' ||
        'type.googleapis.com/x.proxy.TrojanServerConfig' ||
        'type.googleapis.com/vx.proxy.trojan.TrojanClientConfig' ||
        'type.googleapis.com/vx.proxy.trojan.TrojanServerConfig':
      return ProxyProtocolLabel.trojan;
    case 'type.googleapis.com/x.proxy.SocksClientConfig' ||
        'type.googleapis.com/x.proxy.SocksServerConfig' ||
        'type.googleapis.com/vx.proxy.socks.SocksClientConfig' ||
        'type.googleapis.com/vx.proxy.socks.SocksServerConfig':
      return ProxyProtocolLabel.socks;
    case 'type.googleapis.com/x.proxy.VlessClientConfig' ||
        'type.googleapis.com/x.proxy.VlessServerConfig' ||
        'type.googleapis.com/vx.proxy.vless.VlessClientConfig' ||
        'type.googleapis.com/vx.proxy.vless.VlessServerConfig':
      return ProxyProtocolLabel.vless;
    case 'type.googleapis.com/x.proxy.Hysteria2ClientConfig' ||
        'type.googleapis.com/x.proxy.Hysteria2ServerConfig' ||
        'type.googleapis.com/vx.proxy.hysteria.Hysteria2ClientConfig' ||
        'type.googleapis.com/vx.proxy.hysteria.Hysteria2ServerConfig':
      return ProxyProtocolLabel.hysteria2;
    case 'type.googleapis.com/x.proxy.AnytlsClientConfig' ||
        'type.googleapis.com/x.proxy.AnytlsServerConfig' ||
        'type.googleapis.com/vx.proxy.anytls.AnytlsClientConfig' ||
        'type.googleapis.com/vx.proxy.anytls.AnytlsServerConfig':
      return ProxyProtocolLabel.anytls;
    case 'type.googleapis.com/x.proxy.DokodemoConfig' ||
        'type.googleapis.com/vx.proxy.dokodemo.DokodemoConfig':
      return ProxyProtocolLabel.dokodemo;
    case 'type.googleapis.com/x.proxy.HttpClientConfig' ||
        'type.googleapis.com/x.proxy.HttpServerConfig' ||
        'type.googleapis.com/vx.proxy.http.HttpClientConfig' ||
        'type.googleapis.com/vx.proxy.http.HttpServerConfig':
      return ProxyProtocolLabel.http;
    case 'type.googleapis.com/vx.proxy.wireguard.DeviceConfig':
      return ProxyProtocolLabel.wireguard;
    default:
      throw Exception('unknown protocol: ${any.typeUrl}');
  }
}

final greenColorTheme = ColorScheme.fromSeed(seedColor: ShimmerGreen);
final pinkColorTheme = ColorScheme.fromSeed(seedColor: XPink);
final purpleColorTheme = ColorScheme.fromSeed(seedColor: ShimmerPurple);

enum ProxyProtocolLabel {
  vmess('VMess'),
  trojan('Trojan'),
  vless('VLESS'),
  shadowsocks('Shadowsocks'),
  shadowsocks2022('Shadowsocks 2022'),
  socks('Socks'),
  hysteria2('Hysteria2'),
  anytls('AnyTLS'),
  dokodemo('Dokodemo'),
  http('HTTP'),
  wireguard('WireGuard');

  const ProxyProtocolLabel(this.label);
  final String label;

  @override
  String toString() {
    return label;
  }

  GeneratedMessage serverConfig() {
    switch (this) {
      case ProxyProtocolLabel.vmess:
        return VmessServerConfig();
      case ProxyProtocolLabel.trojan:
        return TrojanServerConfig();
      case ProxyProtocolLabel.vless:
        return VlessServerConfig();
      case ProxyProtocolLabel.shadowsocks:
        return ShadowsocksServerConfig();
      case ProxyProtocolLabel.shadowsocks2022:
        return Shadowsocks2022ServerConfig();
      case ProxyProtocolLabel.socks:
        return SocksServerConfig();
      case ProxyProtocolLabel.hysteria2:
        return getDefaultHysteriaServerConfig();
      case ProxyProtocolLabel.anytls:
        return AnytlsServerConfig();
      case ProxyProtocolLabel.dokodemo:
        return DokodemoConfig();
      case ProxyProtocolLabel.http:
        return HttpServerConfig();
      case ProxyProtocolLabel.wireguard:
        return DeviceConfig();
    }
  }
}

/// [ports] should be in format of "123,5000-6000"
/// Return a non empty list if ports is valid, otherwise return null.
List<PortRange>? tryParsePorts(String ports) {
  List<PortRange> pr = [];
  final ranges = ports.split(',');
  for (var r in ranges) {
    if (r.contains('-')) {
      final range = r.split('-');
      if (range.length != 2) {
        return null;
      }
      final from = int.tryParse(range[0]);
      final to = int.tryParse(range[1]);
      if (from == null || to == null) {
        return null;
      }
      pr.add(PortRange(from: from, to: to));
    } else {
      final port = int.tryParse(r);
      if (port == null) {
        return null;
      }
      pr.add(PortRange(from: port, to: port));
    }
  }
  if (pr.isEmpty) {
    return null;
  }
  return pr;
}
