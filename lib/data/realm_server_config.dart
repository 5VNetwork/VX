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
import 'dart:io';

import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/app/api/api.pb.dart';
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
import 'package:vx/widgets/outbound_handler_form/outbound_handler_form.dart';

const realmServerInboundTag = 'realmServer';

class LocalRealmServerConfig {
  LocalRealmServerConfig({
    required this.enabled,
    required this.auth,
    required this.hysteria,
  });

  final bool enabled;
  final String auth;
  final Hysteria2ServerConfig hysteria;

  LocalRealmServerConfig copyWith({
    bool? enabled,
    String? auth,
    Hysteria2ServerConfig? hysteria,
  }) {
    return LocalRealmServerConfig(
      enabled: enabled ?? this.enabled,
      auth: auth ?? this.auth,
      hysteria: hysteria ?? this.hysteria,
    );
  }
}

LocalRealmServerConfig loadLocalRealmServerConfig(
  SharedPreferences pref,
  String deviceId,
) {
  Hysteria2ServerConfig hysteria;
  final stored = pref.realmServerHysteriaConfigBase64;
  if (stored != null && stored.isNotEmpty) {
    hysteria = Hysteria2ServerConfig.fromBuffer(base64Decode(stored));
  } else {
    hysteria = getDefaultHysteriaServerConfig();
  }

  final realmId = realmSlugFromDeviceId(deviceId);
  final realmPassword = const Uuid().v4();
  if (!hysteria.hasRealm() || hysteria.realm.realmAddr.isEmpty) {
    hysteria.realm = RealmConfig(
      realmAddr:
          pref.realmDeviceRealmUrl ??
          buildRealmAddr(password: realmPassword, realmId: realmId),
      portMapping: RealmPortMappingConfig(enabled: false),
    );
  }

  return LocalRealmServerConfig(
    enabled: pref.realmServerEnabled,
    auth: pref.realmServerAuth ?? const Uuid().v4(),
    hysteria: hysteria,
  );
}

Future<void> saveLocalRealmServerConfig(
  SharedPreferences pref,
  LocalRealmServerConfig config,
) async {
  pref.setRealmServerAuth(config.auth);
  pref.setRealmServerHysteriaConfigBase64(
    base64Encode(config.hysteria.writeToBuffer()),
  );

  if (config.hysteria.realm.realmAddr.isNotEmpty) {
    pref.setRealmDeviceRealmUrl(config.hysteria.realm.realmAddr);
  }
}

Future<LocalRealmServerConfig> buildProRealmServerConfig({
  required String deviceId,
  required SharedPreferences pref,
  required Future<GenerateCertResponse> Function(String domain) generateCert,
}) async {
  final realmSecret = await fetchRealmSecret();
  final auth = const Uuid().v4();
  final sni = generateRealisticDomain();
  final certResponse = await generateCert(sni);

  final hysteria = getDefaultHysteriaServerConfig();
  hysteria.bandwidth = BandwidthConfig(maxRx: 30, maxTx: 30);
  hysteria.tlsConfig = TlsConfig(
    serverName: sni,
    certificates: [
      Certificate(certificate: certResponse.cert, key: certResponse.key),
    ],
  );
  hysteria.realm = RealmConfig(
    realmAddr: buildRealmAddr(
      password: realmSecret,
      realmId: realmSlugFromDeviceId(deviceId),
      host: defaultRealmRendezvousHost,
    ),
    portMapping: RealmPortMappingConfig(enabled: false),
  );

  return LocalRealmServerConfig(enabled: false, auth: auth, hysteria: hysteria);
}

Future<LocalRealmServerConfig> buildPublicRealmServerConfig({
  required String deviceId,
  required SharedPreferences pref,
  required Future<GenerateCertResponse> Function(String domain) generateCert,
}) async {
  final auth = const Uuid().v4();
  final sni = generateRealisticDomain();
  final certResponse = await generateCert(sni);

  final hysteria = getDefaultHysteriaServerConfig();
  hysteria.bandwidth = BandwidthConfig(maxRx: 30, maxTx: 30);
  hysteria.tlsConfig = TlsConfig(
    serverName: sni,
    certificates: [
      Certificate(certificate: certResponse.cert, key: certResponse.key),
    ],
  );
  hysteria.realm = RealmConfig(
    realmAddr: buildRealmAddr(
      password: publicRealmRendezvousPassword,
      realmId: realmSlugFromDeviceId(deviceId),
      host: publicRealmRendezvousHost,
    ),
    portMapping: RealmPortMappingConfig(enabled: false),
  );

  return LocalRealmServerConfig(enabled: false, auth: auth, hysteria: hysteria);
}

ProxyInboundConfig? buildRealmServerInbound(LocalRealmServerConfig config) {
  if (!config.enabled) {
    return null;
  }
  return ProxyInboundConfig(
    tag: realmServerInboundTag,
    users: [UserConfig(id: 'vx', secret: config.auth)],
    protocol: Any.pack(config.hysteria),
  );
}
