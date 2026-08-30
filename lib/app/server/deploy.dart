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

part of 'deployer.dart';

class DeployResult {
  final List<HandlerConfig> handlerConfigs;
  final String bbrError;
  final String firewallError;

  DeployResult({
    required this.handlerConfigs,
    required this.bbrError,
    required this.firewallError,
  });
}

abstract class QuickDeployOption {
  abstract final int id;
  final XApiClient xApiClient;
  QuickDeployOption({required this.xApiClient});

  String getTitle(BuildContext context);
  String getSummary(BuildContext context);
  String getDetails(BuildContext context);
  Widget getFormWidget(BuildContext context, {String? destination});
  Future<DeployResult> deploy(SshServer server);

  bool disableOSFirewall = true;
  void setDisableOSFirewall(bool value) {
    disableOSFirewall = value;
  }
}

class BasicQuickDeploy extends QuickDeployOption {
  final FlutterSecureStorage storage;
  BasicQuickDeploy({required this.storage, required super.xApiClient});

  @override
  final int id = 1;

  /// Shared by vless (TCP) and hysteria (UDP).
  int port = 443;

  @override
  String getTitle(BuildContext context) {
    return AppLocalizations.of(context)!.basicQuickDeployTitle;
  }

  @override
  String getSummary(BuildContext context) {
    return AppLocalizations.of(context)!.basicQuickDeploySummary;
  }

  @override
  String getDetails(BuildContext context) {
    return AppLocalizations.of(context)!.basicQuickDeployDetails;
  }

  @override
  Widget getFormWidget(
    BuildContext context, {
    String? destination,
    GlobalKey<FormState>? formKey,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '• ${AppLocalizations.of(context)!.basicQuickDeployContent1}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '• ${AppLocalizations.of(context)!.basicQuickDeployContent2}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '• ${AppLocalizations.of(context)!.basicQuickDeployContent3}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '• ${AppLocalizations.of(context)!.basicQuickDeployContent4}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const Gap(10),
        TextFormField(
          initialValue: port.toString(),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.empty;
            }
            final parsed = int.tryParse(value);
            if (parsed == null || parsed < 1 || parsed > 65535) {
              return AppLocalizations.of(context)!.invalidPort;
            }
            port = parsed;
            return null;
          },
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.port,
          ),
        ),
      ],
    );
  }

  @override
  Future<DeployResult> deploy(SshServer server) async {
    final ports = generateUniqueNumbers(10, min: 10000, max: 49152);
    final vmessPorts = ports.sublist(0, 5).join(',');
    final ssPorts = ports.sublist(5, 10).join(',');
    var xrayConfig = await rootBundle.loadString('assets/configs/1_xray.json');
    var hysteriaConfig = await rootBundle.loadString(
      'assets/configs/1_hysteria.yaml',
    );
    final uuid = const Uuid().v4();

    final secureStorage = await server.secureStorage(storage);

    xrayConfig = xrayConfig.replaceAll('__VMESS_PORT__', vmessPorts);
    xrayConfig = xrayConfig.replaceAll('__SS_PORT__', ssPorts);
    xrayConfig = xrayConfig.replaceAll('__TLS_PORT__', port.toString());
    xrayConfig = xrayConfig.replaceAll('__UUID__', uuid);
    hysteriaConfig = hysteriaConfig.replaceAll('__TLS_PORT__', port.toString());
    hysteriaConfig = hysteriaConfig.replaceAll('__UUID__', uuid);
    final certPath = secureStorage.user == 'root'
        ? '/root/vx/certs/cert.pem'
        : '/home/${secureStorage.user}/vx/certs/cert.pem';
    final keyPath = secureStorage.user == 'root'
        ? '/root/vx/certs/key.pem'
        : '/home/${secureStorage.user}/vx/certs/key.pem';
    xrayConfig = xrayConfig.replaceAll('__CERTIFICATE_PATH__', certPath);
    hysteriaConfig = hysteriaConfig.replaceAll(
      '__CERTIFICATE_PATH__',
      certPath,
    );
    xrayConfig = xrayConfig.replaceAll('__KEY_PATH__', keyPath);
    hysteriaConfig = hysteriaConfig.replaceAll('__KEY_PATH__', keyPath);

    final domain = generateRealisticDomain();
    final certResponse = await xApiClient.generateCert(domain);

    final result = await xApiClient.deploy(
      server: server,
      xrayConfig: utf8.encode(xrayConfig),
      hysteriaConfig: utf8.encode(hysteriaConfig),
      disableOSFirewall: disableOSFirewall,
      files: {
        certPath: Uint8List.fromList(certResponse.cert),
        keyPath: Uint8List.fromList(certResponse.key),
      },
    );

    return DeployResult(
      handlerConfigs: [
        HandlerConfig(
          outbound: OutboundHandlerConfig(
            tag: '${server.name} vmess',
            ports: tryParsePorts(vmessPorts),
            address: server.address,
            protocol: Any.pack(VmessClientConfig(id: uuid)),
          ),
        ),
        HandlerConfig(
          outbound: OutboundHandlerConfig(
            tag: '${server.name} ss',
            ports: tryParsePorts(ssPorts),
            address: server.address,
            protocol: Any.pack(
              ShadowsocksClientConfig(
                cipherType: ShadowsocksCipherType.CHACHA20_POLY1305,
                password: uuid,
              ),
            ),
          ),
        ),
        HandlerConfig(
          outbound: OutboundHandlerConfig(
            tag: '${server.name} hysteria',
            ports: [PortRange(from: port, to: port)],
            address: server.address,
            protocol: Any.pack(
              Hysteria2ClientConfig(
                auth: uuid,
                bandwidth: BandwidthConfig(maxRx: 10, maxTx: 10),
                tlsConfig: TlsConfig(
                  allowInsecure: true,
                  serverName: domain,
                  pinnedPeerCertificateChainSha256: [certResponse.certHash],
                ),
              ),
            ),
          ),
        ),
        HandlerConfig(
          outbound: OutboundHandlerConfig(
            tag: '${server.name} vless',
            ports: [PortRange(from: port, to: port)],
            address: server.address,
            transport: TransportConfig(
              tls: TlsConfig(
                serverName: domain,
                allowInsecure: true,
                pinnedPeerCertificateChainSha256: [certResponse.certHash],
              ),
            ),
            protocol: Any.pack(
              VlessClientConfig(
                id: uuid,
                flow: 'xtls-rprx-vision',
                encryption: 'none',
              ),
            ),
          ),
        ),
      ],
      bbrError: result.bbrError,
      firewallError: result.firewallError,
    );
  }
}

enum Option2TransportProtocol { grpc, xhttp }

class MasqueradeQuickDeploy extends QuickDeployOption {
  MasqueradeQuickDeploy({required super.xApiClient});
  @override
  final int id = 2;
  @override
  String getTitle(BuildContext context) {
    return AppLocalizations.of(context)!.masqueradeQuickDeployTitle;
  }

  @override
  String getSummary(BuildContext context) {
    return AppLocalizations.of(context)!.masqueradeQuickDeploySummary;
  }

  @override
  String getDetails(BuildContext context) {
    return AppLocalizations.of(context)!.masqueradeQuickDeployDetails;
  }

  // reality target
  String? destination;

  int xhttpPort = 80;
  String? cdnDomain;

  @override
  Widget getFormWidget(BuildContext context, {String? destination}) {
    return MasquerateQuickDeploySet(deploy: this, destination: destination!);
  }

  // TODO: use ss for cdn since it is not encrypted
  @override
  Future<DeployResult> deploy(SshServer server) async {
    var xrayConfig = await rootBundle.loadString('assets/configs/2_xray.json');
    final uuid = const Uuid().v4();
    xrayConfig = xrayConfig.replaceAll('__UUID__', uuid);
    final port = isProduction()
        ? '443'
        : generateUniqueNumbers(10, min: 1024, max: 49152)[0].toString();
    final xhttpPath = '/${const Uuid().v4()}';
    final xhttpPathCdn = '/${const Uuid().v4()}';
    xrayConfig = xrayConfig.replaceAll('__PORT__', port);
    xrayConfig = xrayConfig.replaceAll('__SERVER_NAME__', destination!);
    // for cnd up and reality down
    final realitySecondDomain = destination!.startsWith('www')
        ? 'api.${getRootDomain(destination!)}'
        : 'www.${getRootDomain(destination!)}';
    xrayConfig = xrayConfig.replaceAll('__SERVER_NAME1__', realitySecondDomain);
    xrayConfig = xrayConfig.replaceAll('__DEST__', '${destination!}:443');
    final (publicKey, privateKey) = await xApiClient.generateX25519KeyPair();
    xrayConfig = xrayConfig.replaceAll('__PRIVATE_KEY__', privateKey);
    xrayConfig = xrayConfig.replaceAll('__XHTTP_PATH__', xhttpPath);
    xrayConfig = xrayConfig.replaceAll(
      '__XHTTP_PORT_CDN__',
      xhttpPort.toString(),
    );
    xrayConfig = xrayConfig.replaceAll('__XHTTP_PATH_CDN__', xhttpPathCdn);
    // final useGrpc = option.transportProtocol == Option2TransportProtocol.grpc;
    // if (useGrpc) {
    //   jsonMap['inbounds'][1]['streamSettings']['network'] = 'grpc';
    //   jsonMap['inbounds'][1]['streamSettings']['grpcSettings'] = {
    //     'serviceName': '',
    //   };
    // } else {
    //   jsonMap['inbounds'][1]['streamSettings']['network'] = 'xhttp';
    //   jsonMap['inbounds'][1]['streamSettings']
    //       ['xhttpSettings'] = {'path': '/', 'mode': 'auto'};
    // }
    final enableCDN = cdnDomain != null;
    // if (enableCDN) {
    // xrayConfig = xrayConfig.replaceAll('__XHTTP_LISTEN__', '0.0.0.0');
    // (jsonMap['inbounds'] as List<dynamic>).add({
    //   'tag': 'xhttp80',
    //   'listen': '0.0.0.0',
    //   'port': '80',
    //   'protocol': 'vless',
    //   'settings': {
    //     'clients': [
    //       {
    //         'id': uuid,
    //       }
    //     ],
    //     'decryption': 'none'
    //   },
    //   'streamSettings': {
    //     'network': 'xhttp',
    //     'xhttpSettings': {'path': '/', 'mode': 'auto'}
    //   }
    // });
    // } else {
    //   xrayConfig = xrayConfig.replaceAll('__XHTTP_LISTEN__', '127.0.0.1');
    // }

    final result = await xApiClient.deploy(
      server: server,
      xrayConfig: utf8.encode(xrayConfig),
      disableOSFirewall: disableOSFirewall,
    );
    final realityConfig = RealityConfig(
      fingerprint: "chrome",
      pbk: publicKey,
      serverName: destination!,
    );
    final vlessConfig = Any.pack(
      VlessClientConfig(id: uuid, encryption: 'none'),
    );
    final vmessConfig = Any.pack(VmessClientConfig(id: uuid));
    final tlsConfig = TlsConfig(serverName: cdnDomain);
    return DeployResult(
      handlerConfigs: [
        ...[
          HandlerConfig(
            outbound: OutboundHandlerConfig(
              tag: '${server.name} reality',
              port: int.parse(port),
              address: server.address,
              protocol: Any.pack(
                VlessClientConfig(
                  id: uuid,
                  encryption: 'none',
                  flow: 'xtls-rprx-vision',
                ),
              ),
              transport: TransportConfig(reality: realityConfig),
            ),
          ),
          HandlerConfig(
            outbound: OutboundHandlerConfig(
              tag: '${server.name} reality packet-up',
              port: int.parse(port),
              address: server.address,
              protocol: vlessConfig,
              transport: TransportConfig(
                splithttp: SplitHttpConfig(mode: 'packet-up', path: xhttpPath),
                reality: realityConfig,
              ),
            ),
          ),
          HandlerConfig(
            outbound: OutboundHandlerConfig(
              tag: '${server.name} reality stream-one',
              port: int.parse(port),
              address: server.address,
              protocol: vlessConfig,
              transport: TransportConfig(
                splithttp: SplitHttpConfig(mode: 'stream-one', path: xhttpPath),
                reality: realityConfig,
              ),
            ),
          ),
          HandlerConfig(
            outbound: OutboundHandlerConfig(
              tag: '${server.name} reality stream-up',
              port: int.parse(port),
              address: server.address,
              protocol: vlessConfig,
              transport: TransportConfig(
                splithttp: SplitHttpConfig(
                  mode: 'stream-up',
                  path: xhttpPath,
                  downloadSettings: DownConfig(
                    address: server.address,
                    port: int.parse(port),
                    xhttpConfig: SplitHttpConfig(path: xhttpPath),
                    reality: realityConfig,
                  ),
                ),
                reality: realityConfig,
              ),
            ),
          ),
        ],
        if (enableCDN) ...[
          HandlerConfig(
            outbound: OutboundHandlerConfig(
              tag: '${server.name} cdn packet-up',
              port: 443,
              address: cdnDomain,
              protocol: vmessConfig,
              transport: TransportConfig(
                splithttp: SplitHttpConfig(
                  mode: 'packet-up',
                  host: cdnDomain,
                  path: xhttpPathCdn,
                ),
                tls: tlsConfig,
              ),
            ),
          ),
          HandlerConfig(
            outbound: OutboundHandlerConfig(
              tag: '${server.name} cdn stream-one',
              port: 443,
              address: cdnDomain,
              protocol: vmessConfig,
              transport: TransportConfig(
                splithttp: SplitHttpConfig(
                  mode: 'stream-one',
                  host: cdnDomain,
                  path: xhttpPathCdn,
                ),
                tls: tlsConfig,
              ),
            ),
          ),
          HandlerConfig(
            outbound: OutboundHandlerConfig(
              tag: '${server.name} cdn stream-up',
              port: 443,
              address: cdnDomain,
              protocol: vmessConfig,
              transport: TransportConfig(
                splithttp: SplitHttpConfig(
                  mode: 'stream-up',
                  host: cdnDomain,
                  path: xhttpPathCdn,
                  downloadSettings: DownConfig(
                    address: cdnDomain,
                    port: 443,
                    xhttpConfig: SplitHttpConfig(
                      host: cdnDomain,
                      path: xhttpPathCdn,
                    ),
                    tls: tlsConfig,
                  ),
                ),
                tls: tlsConfig,
              ),
            ),
          ),
          HandlerConfig(
            outbound: OutboundHandlerConfig(
              tag: '${server.name} cdn上行reality下行',
              port: 443,
              address: cdnDomain,
              protocol: vmessConfig,
              transport: TransportConfig(
                splithttp: SplitHttpConfig(
                  mode: 'stream-up',
                  host: cdnDomain,
                  path: xhttpPathCdn,
                  downloadSettings: DownConfig(
                    address: server.address,
                    port: int.parse(port),
                    xhttpConfig: SplitHttpConfig(path: xhttpPathCdn),
                    reality: RealityConfig(
                      fingerprint: "chrome",
                      pbk: publicKey,
                      serverName: realitySecondDomain,
                    ),
                  ),
                ),
                tls: tlsConfig,
              ),
            ),
          ),
        ],
      ],
      bbrError: result.bbrError,
      firewallError: result.firewallError,
    );
  }
}

class MasquerateQuickDeploySet extends StatefulWidget {
  const MasquerateQuickDeploySet({
    super.key,
    required this.deploy,
    required this.destination,
  });
  final MasqueradeQuickDeploy deploy;
  final String destination;
  @override
  State<MasquerateQuickDeploySet> createState() =>
      _MasquerateQuickDeploySetState();
}

class _MasquerateQuickDeploySetState extends State<MasquerateQuickDeploySet> {
  final _destinationController = TextEditingController();
  final _cdnDomainController = TextEditingController();
  final _xhttpPortController = TextEditingController(text: '80');

  @override
  void dispose() {
    _destinationController.dispose();
    _cdnDomainController.dispose();
    _xhttpPortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('将生成以下节点：'),
        const Gap(10),
        const Text('• Reality/XHTTP/VLESS packet-up'),
        const Gap(10),
        const Text('• Reality/XHTTP/VLESS stream-one'),
        const Gap(10),
        const Text('• Reality/XHTTP/VLESS stream-up'),
        const Gap(10),
        const Text('如果提供了CDN域名，则还会生成以下节点：'),
        const Gap(10),
        const Text('• TLS/XHTTP/VMess(CDN) packet-up'),
        const Gap(10),
        const Text('• TLS/XHTTP/VMess(CDN) stream-one'),
        const Gap(10),
        const Text('• TLS/XHTTP/VMess(CDN) stream-up'),
        const Gap(10),
        const Text('• TLS/XHTTP/VMess(CDN)上行 Reality下行'),
        const Gap(10),
        TextFormField(
          controller: _destinationController,
          onChanged: (value) {
            widget.deploy.destination = value;
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入目标网站';
            }
            return null;
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: '目标网站',
          ),
        ),
        const Gap(2),
        // if (_enbale80Xhttp)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextFormField(
            controller: _xhttpPortController,
            onChanged: (value) {
              widget.deploy.xhttpPort = int.parse(value);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入';
              }
              widget.deploy.xhttpPort = int.parse(value);
              return null;
            },
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'XHTTP Port',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextFormField(
            controller: _cdnDomainController,
            onChanged: (value) {
              widget.deploy.cdnDomain = value;
            },
            decoration: const InputDecoration(
              labelText: 'CDN 域名',
              helperText:
                  '可不填。CDN的SSL/TLS加密需设置为灵活（即CDN与代理服务器间不加密）。如果XHTTP端口不是80，需要在CDN那里配置规则',
              helperMaxLines: 5,
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class AllInOneQuickDeploy extends QuickDeployOption {
  AllInOneQuickDeploy({required super.xApiClient});

  @override
  final int id = 3;
  @override
  String getTitle(BuildContext context) {
    return AppLocalizations.of(context)!.allInOneQuickDeployTitle;
  }

  @override
  String getSummary(BuildContext context) {
    return AppLocalizations.of(context)!.allInOneQuickDeploySummary;
  }

  @override
  String getDetails(BuildContext context) {
    return AppLocalizations.of(context)!.allInOneQuickDeployDetails;
  }

  int port = 443;
  String cdnDomain = '';
  String realityDomain = '';
  @override
  bool disableOSFirewall = true;
  @override
  Widget getFormWidget(BuildContext context, {String? destination}) {
    return AllInOneForm(deploy: this, destination: destination!);
  }

  @override
  Future<DeployResult> deploy(SshServer server) async {
    final websocketPath = '/${const Uuid().v4()}';
    final xhttpPath = '/${const Uuid().v4()}';
    final httpUpgradePath = '/${const Uuid().v4()}';
    final domain = generateRealisticDomain();
    final certResponse = await xApiClient.generateCert(domain);
    final (publicKey, privateKey) = await xApiClient.generateX25519KeyPair();
    final secret = const Uuid().v4();

    GenerateCertResponse? cdnCertResponse;
    if (cdnDomain.isNotEmpty) {
      cdnCertResponse = await xApiClient.generateCert(cdnDomain);
    }

    final serverConfig = ServerConfig(
      multiInbounds: [
        MultiProxyInboundConfig(
          users: [UserConfig(id: 'vx', secret: secret)],
          address: '0.0.0.0',
          tag: 'multi',
          ports: [port],
          protocols: [
            Any.pack(VmessServerConfig()),
            Any.pack(TrojanServerConfig()),
            Any.pack(AnytlsServerConfig()),
            Any.pack(
              Hysteria2ServerConfig(
                tlsConfig: TlsConfig(
                  certificates: [
                    Certificate(
                      certificate: certResponse.cert,
                      key: certResponse.key,
                    ),
                  ],
                ),
              ),
            ),
          ],
          transportProtocols: [
            MultiProxyInboundConfig_Protocol(
              path: websocketPath,
              websocket: WebsocketConfig(path: websocketPath),
            ),
            // MultiProxyInboundConfig_Protocol(
            //     path: xhttpPath,
            //     splithttp: SplitHttpConfig(
            //       path: xhttpPath,
            //       mode: 'auto',
            //     )),
            // MultiProxyInboundConfig_Protocol(
            //     path: httpUpgradePath,
            //     httpupgrade: HttpUpgradeConfig(
            //       config: WebsocketConfig(
            //         path: httpUpgradePath,
            //       ),
            //     )),
            MultiProxyInboundConfig_Protocol(
              h2: true,
              grpc: GrpcConfig(serviceName: 'vx'),
            ),
          ],
          securityConfigs: [
            MultiProxyInboundConfig_Security(
              domains: [domain, if (cdnDomain.isNotEmpty) cdnDomain],
              tls: TlsConfig(
                certificates: [
                  Certificate(
                    certificate: certResponse.cert,
                    key: certResponse.key,
                  ),
                  if (cdnCertResponse != null)
                    Certificate(
                      certificate: cdnCertResponse.cert,
                      key: cdnCertResponse.key,
                    ),
                ],
              ),
            ),
            if (realityDomain.isNotEmpty)
              MultiProxyInboundConfig_Security(
                domains: [realityDomain],
                reality: RealityConfig(
                  dest: '$realityDomain:443',
                  serverNames: [realityDomain],
                  privateKey: base64Url.decode(base64Url.normalize(privateKey)),
                  shortIds: [Uint8List(8)],
                ),
              ),
          ],
        ),
      ],
    );

    final result = await xApiClient.deploy(
      server: server,
      serverConfig: serverConfig,
      disableOSFirewall: disableOSFirewall,
    );

    final handlerConfigs = (await xApiClient.convertInboundToOutbound(
      server,
      multiInbound: serverConfig.multiInbounds.first,
    )).map((e) => HandlerConfig(outbound: e)).toList();

    if (cdnCertResponse != null) {
      handlerConfigs.add(
        HandlerConfig(
          outbound: OutboundHandlerConfig(
            tag: '${server.name} cdn',
            port: 443,
            address: cdnDomain,
            protocol: Any.pack(VmessClientConfig(id: secret)),
            transport: TransportConfig(
              websocket: WebsocketConfig(path: websocketPath),
              tls: TlsConfig(serverName: cdnDomain),
            ),
          ),
        ),
      );
    }

    return DeployResult(
      handlerConfigs: handlerConfigs,
      bbrError: result.bbrError,
      firewallError: result.firewallError,
    );
  }
}

class AllInOneForm extends StatefulWidget {
  const AllInOneForm({
    super.key,
    required this.deploy,
    required this.destination,
  });
  final AllInOneQuickDeploy deploy;
  final String destination;
  @override
  State<AllInOneForm> createState() => _AllInOneFormState();
}

class _AllInOneFormState extends State<AllInOneForm> {
  final _portController = TextEditingController(text: '443');
  final _cdnDomainController = TextEditingController();
  final _realityDomainController = TextEditingController();

  @override
  void dispose() {
    _portController.dispose();
    _cdnDomainController.dispose();
    _realityDomainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _portController,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.empty;
            }
            final port = int.tryParse(value);
            if (port == null || port < 1 || port > 65535) {
              return AppLocalizations.of(context)!.invalidPort;
            }
            widget.deploy.port = port;
            return null;
          },
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.port,
          ),
        ),
        const Gap(10),
        TextFormField(
          controller: _cdnDomainController,
          decoration: InputDecoration(
            labelText: 'CDN 域名',
            helperMaxLines: 5,
            helperText: AppLocalizations.of(context)!.allInOneCdnDesc,
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!isDomain(value)) {
                return AppLocalizations.of(context)!.invalidAddress;
              }
            }
            widget.deploy.cdnDomain = value ?? '';
            return null;
          },
        ),
        const Gap(10),
        TextFormField(
          controller: _realityDomainController,
          decoration: InputDecoration(
            labelText: 'Reality 域名',
            helperText: AppLocalizations.of(context)!.allInOneRealityDesc,
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!isDomain(value)) {
                return AppLocalizations.of(context)!.invalidAddress;
              }
            }
            widget.deploy.realityDomain = value ?? '';
            return null;
          },
        ),
      ],
    );
  }
}
