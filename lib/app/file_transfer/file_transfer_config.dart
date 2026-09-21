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

import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/vx/inbound/inbound.pb.dart';
import 'package:tm/protos/vx/proxy/hysteria/hysteria.pb.dart';
import 'package:tm/protos/vx/transport/security/tls/certificate.pb.dart';
import 'package:tm/protos/vx/transport/security/tls/tls.pb.dart';
import 'package:tm/protos/vx/user/user.pb.dart';
import 'package:uuid/uuid.dart';
import 'package:vx/common/domain.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/realm.dart';
import 'package:vx/utils/realm_secret.dart';
import 'package:vx/utils/xapi_client.dart';
import 'package:vx/widgets/outbound_handler_form/outbound_handler_form.dart';

/// Distinct from the VPN realm slug so file-transfer registration cannot
/// steal the proxy inbound on the rendezvous.
String fileTransferRealmId(String deviceId) =>
    'ft${realmSlugFromDeviceId(deviceId)}';

class _RealmEndpoint {
  const _RealmEndpoint({required this.host, this.port});

  final String host;
  final int? port;
}

_RealmEndpoint _fileTransferRealmEndpoint({
  required bool proUser,
  required ParsedRealmAddr? existing,
  String? realmHost,
  int? realmPort,
}) {
  if (realmHost != null && realmHost.isNotEmpty) {
    return _RealmEndpoint(host: realmHost, port: realmPort);
  }
  final storedProHostUnavailable =
      existing?.host == defaultRealmRendezvousHost && !proUser;
  if (existing != null && !storedProHostUnavailable) {
    final port = existing.port == null ? null : int.tryParse(existing.port!);
    return _RealmEndpoint(host: existing.host, port: port);
  }
  if (proUser) {
    return const _RealmEndpoint(host: defaultRealmRendezvousHost);
  }
  return const _RealmEndpoint(host: publicRealmRendezvousHost);
}

Future<String> _fileTransferRealmPassword({
  required String host,
  required bool newRealmId,
  required ParsedRealmAddr? existing,
}) async {
  if (host == publicRealmRendezvousHost) {
    return publicRealmRendezvousPassword;
  }
  if (host == defaultRealmRendezvousHost) {
    return fetchRealmSecret();
  }
  if (!newRealmId &&
      existing != null &&
      existing.host == host &&
      existing.password.isNotEmpty) {
    return existing.password;
  }
  return const Uuid().v4().replaceAll('-', '');
}

Future<ProxyInboundConfig> buildFileTransferInbound({
  required bool proUser,
  required XApiClient api,
  required SharedPreferences pref,
  required String deviceId,
  String? realmHost,
  int? realmPort,
  bool newRealmId = false,
}) async {
  var auth = pref.fileTransferAuth ?? '';
  if (auth.isEmpty) {
    auth = const Uuid().v4();
    pref.setFileTransferAuth(auth);
  }

  Hysteria2ServerConfig hysteria;
  final stored = pref.fileTransferHysteriaConfigBase64;
  if (stored != null && stored.isNotEmpty) {
    hysteria = Hysteria2ServerConfig.fromBuffer(base64Decode(stored));
  } else {
    hysteria = getDefaultHysteriaServerConfig();
  }
  hysteria.ignoreClientBandwidth = true;
  hysteria.bandwidth = BandwidthConfig(maxRx: 1000, maxTx: 1000);

  if (!hysteria.hasTlsConfig() || hysteria.tlsConfig.certificates.isEmpty) {
    final sni = generateRealisticDomain();
    final cert = await api.generateCert(sni);
    hysteria.tlsConfig = TlsConfig(
      serverName: sni,
      certificates: [Certificate(certificate: cert.cert, key: cert.key)],
    );
  }

  final existing = hysteria.hasRealm() && hysteria.realm.realmAddr.isNotEmpty
      ? parseRealmAddr(hysteria.realm.realmAddr)
      : null;
  final endpoint = _fileTransferRealmEndpoint(
    proUser: proUser,
    existing: existing,
    realmHost: realmHost,
    realmPort: realmPort,
  );
  final password = await _fileTransferRealmPassword(
    host: endpoint.host,
    newRealmId: newRealmId,
    existing: existing,
  );
  final realmId = newRealmId || existing == null || existing.realmId.isEmpty
      ? (newRealmId
            ? 'ft${const Uuid().v4().replaceAll('-', '')}'
            : fileTransferRealmId(deviceId))
      : existing.realmId;

  hysteria.realm = RealmConfig(
    realmAddr: buildRealmAddr(
      password: password,
      realmId: realmId,
      host: endpoint.host,
      port: endpoint.port,
    ),
    portMapping: RealmPortMappingConfig(enabled: false),
  );

  pref.setFileTransferHysteriaConfigBase64(
    base64Encode(hysteria.writeToBuffer()),
  );

  return ProxyInboundConfig(
    tag: 'fileReceive',
    users: [UserConfig(id: 'vx', secret: auth)],
    protocol: Any.pack(hysteria),
  );
}

Future<String?> resolveFileTransferShareUrl({
  required bool proUser,
  required XApiClient api,
  required SharedPreferences pref,
  required String deviceId,
  String? realmHost,
  int? realmPort,
  bool newRealmId = false,
}) async {
  final inbound = await buildFileTransferInbound(
    proUser: proUser,
    api: api,
    pref: pref,
    deviceId: deviceId,
    realmHost: realmHost,
    realmPort: realmPort,
    newRealmId: newRealmId,
  );
  final outs = await api.inboundConfigToOutboundConfig(
    'FileTransfer',
    '',
    inbound,
    null,
  );
  if (outs.isEmpty) return null;
  final out = outs.first;
  if (out.hasProtocol()) {
    final hysteria = Hysteria2ClientConfig();
    out.protocol.unpackInto(hysteria);
    hysteria.bandwidth = BandwidthConfig(maxRx: 1000, maxTx: 1000);
    out.protocol = Any.pack(hysteria);
  }
  final response = await api.toUrl([out]);
  if (response.urls.isEmpty) return null;
  return response.urls.first;
}
