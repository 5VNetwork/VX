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

import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

const defaultRealmRendezvousHost = 'realm.leeveck.site';
const publicRealmRendezvousHost = 'realm.hy2.io';
const publicRealmRendezvousPassword = 'public';

Future<String> defaultRealmDeviceName() async {
  final info = await DeviceInfoPlugin().deviceInfo;
  return switch (info) {
    AndroidDeviceInfo() => '${info.brand} ${info.model}'.trim(),
    IosDeviceInfo() => info.name,
    WindowsDeviceInfo() => info.computerName,
    MacOsDeviceInfo() => info.computerName,
    LinuxDeviceInfo() => info.prettyName,
    _ => 'VX device',
  };
}

class ParsedRealmAddr {
  const ParsedRealmAddr({
    required this.insecure,
    required this.password,
    required this.host,
    required this.realmId,
    this.port,
    // Optional connect-params embedded in the URL for sharing with clients.
    this.auth,
    this.sni,
    this.allowInsecureTls = false,
    this.sha256Hex,
  });

  /// Scheme-derived: true when the rendezvous transport is realm+http.
  final bool insecure;

  /// Rendezvous server auth token (the `userInfo` part of the URL).
  final String password;
  final String host;
  final String realmId;
  final String? port;

  // ---- Connect params (Hysteria2 server info) ----

  /// Hysteria2 auth password on the server inbound.
  final String? auth;

  /// TLS SNI override.
  final String? sni;

  /// Whether the client should skip TLS certificate verification.
  final bool allowInsecureTls;

  /// Hex-encoded SHA-256 fingerprint for certificate pinning.
  final String? sha256Hex;
}

ParsedRealmAddr? parseRealmAddr(String raw) {
  if (raw.isEmpty) {
    return null;
  }
  final uri = Uri.tryParse(raw);
  if (uri == null || uri.host.isEmpty) {
    return null;
  }
  final scheme = uri.scheme;

  // Accept both the legacy realm:// format and the official hysteria2+realm://
  // scheme produced by the Go URI pipeline.
  const oldSchemes = {'realm', 'realm+http'};
  const newSchemes = {'hysteria2+realm', 'hysteria2+realm+http'};
  if (!oldSchemes.contains(scheme) && !newSchemes.contains(scheme)) {
    return null;
  }

  final password = uri.userInfo;
  if (password.isEmpty) {
    return null;
  }
  var realmId = uri.path;
  if (realmId.startsWith('/')) {
    realmId = realmId.substring(1);
  }
  if (realmId.isEmpty || realmId.contains('/')) {
    return null;
  }

  final insecureRendezvous =
      scheme == 'realm+http' || scheme == 'hysteria2+realm+http';

  final q = uri.queryParameters;
  return ParsedRealmAddr(
    insecure: insecureRendezvous,
    password: password,
    host: uri.host,
    realmId: realmId,
    port: uri.hasPort ? uri.port.toString() : null,
    auth: q['auth'],
    sni: q['sni'],
    // "insecure" param = TLS insecure (not rendezvous transport insecure).
    allowInsecureTls: q['insecure'] == '1',
    // Accept both official "pinSHA256" (new) and legacy "sha256" (old).
    sha256Hex: q['pinSHA256'] ?? q['sha256'],
  );
}

String buildRealmAddr({
  required String password,
  required String realmId,
  String host = defaultRealmRendezvousHost,
  bool insecure = false,
  int? port,
  // Optional connect params embedded for client auto-configuration.
  String? auth,
  String? sni,
  bool allowInsecureTls = false,
  String? sha256Hex,
}) {
  final scheme = insecure ? 'realm+http' : 'realm';
  final authority = port == null ? host : '$host:$port';
  final encodedPassword = Uri.encodeComponent(password);
  final encodedRealmId = Uri.encodeComponent(realmId);
  final base = '$scheme://$encodedPassword@$authority/$encodedRealmId';

  final params = <String, String>{};
  if (auth != null && auth.isNotEmpty) params['auth'] = auth;
  if (sni != null && sni.isNotEmpty) params['sni'] = sni;
  if (allowInsecureTls) params['insecure'] = '1';
  if (sha256Hex != null && sha256Hex.isNotEmpty) params['sha256'] = sha256Hex;

  if (params.isEmpty) return base;
  final queryString = params.entries
      .map(
        (e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
      )
      .join('&');
  return '$base?$queryString';
}

String realmSlugFromDeviceId(String deviceId) {
  return deviceId.replaceAll('-', '');
}

String generateRealmUrl({
  required String deviceId,
  String? existingUrl,
  bool? insecure,
  String? host,
  String? rendezvousPassword,
}) {
  final parsed = existingUrl != null
      ? parseRealmAddr(existingUrl.trim())
      : null;
  final resolvedHost = host ?? parsed?.host ?? defaultRealmRendezvousHost;
  final password = switch (resolvedHost) {
    publicRealmRendezvousHost => publicRealmRendezvousPassword,
    defaultRealmRendezvousHost when rendezvousPassword != null =>
      rendezvousPassword,
    defaultRealmRendezvousHost => throw ArgumentError(
      'rendezvousPassword is required for $defaultRealmRendezvousHost',
    ),
    _ => const Uuid().v4().replaceAll('-', ''),
  };
  return buildRealmAddr(
    password: password,
    realmId: parsed?.realmId.isNotEmpty == true
        ? parsed!.realmId
        : realmSlugFromDeviceId(deviceId),
    host: resolvedHost,
    insecure: insecure ?? parsed?.insecure ?? false,
    port: parsed?.port != null ? int.tryParse(parsed!.port!) : null,
  );
}
