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

part of 'outbound_handler_form.dart';

// config is modified directly, some fields are saved when validating
class InboundForm extends StatefulWidget {
  const InboundForm({super.key, required this.config});
  final ProxyInboundConfig config;
  @override
  State<InboundForm> createState() => _InboundFormState();
}

const defaultUid = 'vx';

class _InboundFormState extends State<InboundForm> with FormDataGetter {
  late final ProxyInboundConfig _config;
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _portController = TextEditingController();
  final _protocolsKey = GlobalKey();
  final _transportKey = GlobalKey();
  late UserConfig _userConfig;
  @override
  Object? get formData {
    if (!_formKey.currentState!.validate()) {
      return null;
    }
    final protocols =
        ((_protocolsKey.currentState as FormDataGetter).formData as List<Any>);
    final transport =
        ((_transportKey.currentState as TransportConfigGetter).transportConfig);
    final users = [..._config.users];
    if (users.any((e) => e.id == _userConfig.id)) {
      users.removeWhere((e) => e.id == _userConfig.id);
    }
    return ProxyInboundConfig(
      tag: _nameController.text,
      address: _addressController.text,
      ports: _portController.text.split(',').map(int.parse).toList(),
      protocols: protocols,
      transport: transport,
      users: [_userConfig, ...users],
    );
  }

  @override
  initState() {
    super.initState();
    _config = widget.config.deepCopy();
    _nameController.text = widget.config.tag;
    _addressController.text = widget.config.address;
    _portController.text = widget.config.ports.join(',');
    if (widget.config.users.isNotEmpty) {
      _userConfig = widget.config.users.first;
    } else {
      _userConfig = UserConfig();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 800),
          Text(
            AppLocalizations.of(context)!.normalInboundDesc,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(),
          ),
          const Gap(10),
          TextFormField(
            controller: _nameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.fieldRequired;
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.name,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const Gap(10),
          TextFormField(
            controller: _addressController,
            validator: (value) {
              return null;
            },
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.address,
              hintText: '0.0.0.0',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const Gap(10),
          TextFormField(
            controller: _portController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.fieldRequired;
              }
              if (!isValidPorts(value)) {
                return AppLocalizations.of(context)!.invalidPort;
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.port,
              hintText: '443,4431,4432',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const Gap(10),
          _UserConfig(config: _userConfig),
          const Gap(10),
          const TextDivider(text: 'Proxy Protocol'),
          const Gap(10),
          _ProxyProtocols(
            key: _protocolsKey,
            protocols: _protocols,
          ),
          const Gap(10),
          const TextDivider(text: 'Stream'),
          const Gap(10),
          _TransportInput(
            key: _transportKey,
            config: _config.transport,
            server: true,
          ),
        ],
      ),
    );
  }

  List<Any>? get _protocols {
    return [..._config.protocols, if (_config.hasProtocol()) _config.protocol];
  }
}

class MultiInboundForm extends StatefulWidget {
  const MultiInboundForm({super.key, required this.multiConfig});

  final MultiProxyInboundConfig multiConfig;

  @override
  State<MultiInboundForm> createState() => _MultiInboundFormState();
}

class _MultiInboundFormState extends State<MultiInboundForm>
    with FormDataGetter {
  late final MultiProxyInboundConfig _multiConfig;
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _portController = TextEditingController();
  final List<bool> _isExpanded = List.filled(3, false);
  late UserConfig _userConfig;
  final _protocolsKey = GlobalKey();

  @override
  Object? get formData {
    if (!_formKey.currentState!.validate()) {
      return null;
    }

    final users = [..._multiConfig.users];
    if (users.any((e) => e.id == _userConfig.id)) {
      users.removeWhere((e) => e.id == _userConfig.id);
    }

    final protocols =
        ((_protocolsKey.currentState as FormDataGetter).formData as List<Any>);

    return MultiProxyInboundConfig(
      tag: _nameController.text,
      address: _addressController.text,
      ports: _portController.text.split(',').map(int.parse).toList(),
      users: [_userConfig, ...users],
      protocols: protocols,
      transportProtocols: _transportProtocols,
      securityConfigs: _securityProtocols,
    );
  }

  @override
  initState() {
    super.initState();
    _multiConfig = widget.multiConfig.deepCopy();
    _nameController.text = widget.multiConfig.tag;
    _addressController.text = widget.multiConfig.address;
    _portController.text = widget.multiConfig.ports.join(',');
    if (widget.multiConfig.users.isNotEmpty) {
      _userConfig = widget.multiConfig.users.first;
    } else {
      _userConfig = UserConfig();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.multiDesc,
            style: Theme.of(context).textTheme.titleSmall!.copyWith(),
          ),
          const Gap(10),
          TextFormField(
            controller: _nameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.fieldRequired;
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.name,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const Gap(10),
          TextFormField(
            controller: _addressController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.address,
              hintText: '0.0.0.0',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const Gap(10),
          TextFormField(
            controller: _portController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.fieldRequired;
              }
              if (!isValidPorts(value)) {
                return AppLocalizations.of(context)!.invalidPort;
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.port,
              hintText: '443,4431,4432',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const Gap(10),
          _UserConfig(config: _userConfig),
          const Gap(10),
          SizedBox(
            width: 800,
            child: Column(
              children: [
                Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ExpansionPanelList(
                    expansionCallback: (panelIndex, isExpanded) {
                      setState(() {
                        _isExpanded[panelIndex] = !_isExpanded[panelIndex];
                      });
                    },
                    elevation: 0,
                    materialGapSize: 1,
                    expandedHeaderPadding: const EdgeInsets.all(0),
                    children: [
                      ExpansionPanel(
                        canTapOnHeader: true,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        headerBuilder: (context, isExpanded) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Text(
                                'Proxy Protocol',
                                style: Theme.of(context).textTheme.titleMedium!,
                              ),
                            ),
                          );
                        },
                        isExpanded: _isExpanded[0],
                        body: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _ProxyProtocols(
                            key: _protocolsKey,
                            protocols: _protocols,
                          ),
                        ),
                      ),
                      ExpansionPanel(
                        canTapOnHeader: true,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        headerBuilder: (context, isExpanded) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Text(
                                'Transport Protocol',
                                style: Theme.of(context).textTheme.titleMedium!,
                              ),
                            ),
                          );
                        },
                        isExpanded: _isExpanded[1],
                        body: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _MultiTransportProtocols(
                            transportProtocols: _transportProtocols,
                          ),
                        ),
                      ),
                      ExpansionPanel(
                        canTapOnHeader: true,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerLow,
                        headerBuilder: (context, isExpanded) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Text(
                                'Security',
                                style: Theme.of(context).textTheme.titleMedium!,
                              ),
                            ),
                          );
                        },
                        isExpanded: _isExpanded[2],
                        body: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _MultiSecurityProtocols(
                            securityProtocols: _securityProtocols,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Any>? get _protocols {
    return _multiConfig.protocols;
  }

  List<MultiProxyInboundConfig_Protocol> get _transportProtocols {
    return _multiConfig.transportProtocols;
  }

  List<MultiProxyInboundConfig_Security> get _securityProtocols {
    return _multiConfig.securityConfigs;
  }
}

class _ProxyProtocols extends StatefulWidget {
  const _ProxyProtocols({super.key, required this.protocols});
  final List<Any>? protocols;
  @override
  State<_ProxyProtocols> createState() => __ProxyProtocolsState();
}

class __ProxyProtocolsState extends State<_ProxyProtocols> with FormDataGetter {
  List<(ProxyProtocolLabel, GeneratedMessage)> _protocols = [];
  late (ProxyProtocolLabel, GeneratedMessage) _selected;
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Object? get formData {
    return _protocols.map((e) {
      return Any.pack(e.$2);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    if (widget.protocols != null) {
      _protocols = widget.protocols!.map((e) {
        final label = getProtocolTypeFromAny(e);
        switch (label) {
          case ProxyProtocolLabel.vmess:
            return (label, VmessServerConfig.fromBuffer(e.value));
          case ProxyProtocolLabel.trojan:
            return (label, TrojanServerConfig.fromBuffer(e.value));
          case ProxyProtocolLabel.shadowsocks:
            return (label, ShadowsocksServerConfig.fromBuffer(e.value));
          case ProxyProtocolLabel.shadowsocks2022:
            return (label, Shadowsocks2022ServerConfig.fromBuffer(e.value));
          case ProxyProtocolLabel.socks:
            return (label, SocksServerConfig.fromBuffer(e.value));
          case ProxyProtocolLabel.hysteria2:
            final config = Hysteria2ServerConfig.fromBuffer(e.value);
            config.tlsConfig = config.tlsConfig.deepCopy();
            return (label, config);
          case ProxyProtocolLabel.anytls:
            return (label, AnytlsServerConfig.fromBuffer(e.value));
          case ProxyProtocolLabel.dokodemo:
            return (label, DokodemoConfig.fromBuffer(e.value));
          case ProxyProtocolLabel.vless:
            return (label, VlessServerConfig.fromBuffer(e.value));
          default:
            throw Exception('unsupported protocol: ${e.typeUrl}');
        }
      }).toList();
    }
    if (_protocols.isEmpty) {
      _protocols.add((
        ProxyProtocolLabel.hysteria2,
        getDefaultHysteriaServerConfig(),
      ));
    }
    _selected = _protocols.first;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children:
              _protocols.map<Widget>((e) {
                return DeleteMenuAnchor(
                  onDelete: _protocols.length > 1
                      ? (context) {
                          setState(() {
                            _protocols.remove(e);
                            if (_selected.$1 == e.$1) {
                              _selected = _protocols.first;
                            }
                          });
                        }
                      : null,
                  child: ChoiceChip(
                    label: Text(e.$1.label),
                    selected: _selected.$1 == e.$1,
                    onSelected: (value) {
                      if (!Form.of(context).validate()) {
                        return;
                      }
                      if (value) {
                        setState(() {
                          _selected = e;
                        });
                      }
                    },
                  ),
                );
              }).toList()..addAll([
                if (_protocols.length < ProxyProtocolLabel.values.length)
                  MenuAnchor(
                    menuChildren: ProxyProtocolLabel.values
                        .where((e) => !_protocols.any((f) => f.$1 == e))
                        .map((e) {
                          return MenuItemButton(
                            child: Text(e.label),
                            onPressed: () {
                              setState(() {
                                _protocols.add((e, e.serverConfig()));
                              });
                            },
                          );
                        })
                        .toList(),
                    builder: (context, controller, child) {
                      return getSmallAddButton(
                        onPressed: () {
                          controller.open();
                        },
                      );
                    },
                  ),
              ]),
        ),
        const Gap(10),
        _selectedProtocol(),
      ],
    );
  }

  Widget _selectedProtocol() {
    switch (_selected.$1) {
      case ProxyProtocolLabel.vmess:
        return VmessServer(config: _selected.$2 as VmessServerConfig);
      case ProxyProtocolLabel.trojan:
        return TrojanServer(config: _selected.$2 as TrojanServerConfig);
      case ProxyProtocolLabel.shadowsocks:
        return ShadowsocksServer(
          config: _selected.$2 as ShadowsocksServerConfig,
        );
      case ProxyProtocolLabel.shadowsocks2022:
        return Shadowsocks2022Server(
          config: _selected.$2 as Shadowsocks2022ServerConfig,
        );
      case ProxyProtocolLabel.socks:
        return SocksServer(config: _selected.$2 as SocksServerConfig);
      case ProxyProtocolLabel.hysteria2:
        return HysteriaServer(
          config: _selected.$2 as Hysteria2ServerConfig,
        );
      case ProxyProtocolLabel.anytls:
        return const AnyTlsServer();
      case ProxyProtocolLabel.dokodemo:
        return DokodemoServer(config: _selected.$2 as DokodemoConfig);
      case ProxyProtocolLabel.vless:
        return VlessServer(config: _selected.$2 as VlessServerConfig);
      default:
        return Container();
    }
  }
}

/// transportProtocols is modified directly
class _MultiTransportProtocols extends StatefulWidget {
  const _MultiTransportProtocols({required this.transportProtocols});
  final List<MultiProxyInboundConfig_Protocol> transportProtocols;

  @override
  State<_MultiTransportProtocols> createState() =>
      _MultiTransportProtocolsState();
}

class _MultiTransportProtocolsState extends State<_MultiTransportProtocols> {
  late List<MultiProxyInboundConfig_Protocol> _transportProtocols;
  int? _selected;
  GlobalKey _formKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _transportProtocols = widget.transportProtocols;
    if (_transportProtocols.isNotEmpty) {
      _selected = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: double.infinity),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children:
              _transportProtocols.asMap().entries.map<Widget>((e) {
                return DeleteMenuAnchor(
                  onDelete: (context) {
                    setState(() {
                      _transportProtocols.removeAt(e.key);
                      if (_selected == e.key) {
                        _selected = _transportProtocols.isNotEmpty ? 0 : null;
                      }
                    });
                  },
                  child: ChoiceChip(
                    label: Text(e.value.label),
                    selected: _selected == e.key,
                    onSelected: (value) {
                      if (value) {
                        setState(() {
                          final config =
                              (_formKey.currentState
                                      as TransportProtocolConfigGetter)
                                  .transportProtocolConfig;
                          switch (config) {
                            case WebsocketConfig():
                              _transportProtocols[_selected!].websocket =
                                  config;
                              break;
                            case GrpcConfig():
                              _transportProtocols[_selected!].grpc = config;
                              break;
                            case HttpConfig():
                              _transportProtocols[_selected!].http = config;
                              break;
                            case SplitHttpConfig():
                              _transportProtocols[_selected!].splithttp =
                                  config;
                              break;
                          }
                          _formKey = GlobalKey();
                          _selected = e.key;
                        });
                      }
                    },
                  ),
                );
              }).toList()..addAll([
                MenuAnchor(
                  menuChildren: MultiTransportProtocol.values.map((e) {
                    return MenuItemButton(
                      child: Text(e.name),
                      onPressed: () {
                        setState(() {
                          _transportProtocols.add(e.toProto());
                          _selected ??= 0;
                        });
                      },
                    );
                  }).toList(),
                  builder: (context, controller, child) {
                    return getSmallAddButton(
                      onPressed: () {
                        controller.open();
                      },
                    );
                  },
                ),
              ]),
        ),
        const Gap(10),
        if (_selected != null)
          _MultiTransportProtocol(
            key: ValueKey(_selected),
            globalKey: _formKey,
            protocol: _transportProtocols[_selected!],
          ),
      ],
    );
  }
}

class _MultiTransportProtocol extends StatelessWidget {
  const _MultiTransportProtocol({
    super.key,
    required this.protocol,
    required this.globalKey,
  });
  final MultiProxyInboundConfig_Protocol protocol;
  final GlobalKey globalKey;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MultiInboundTransportCondition(protocol: protocol),
        const Gap(10),
        if (protocol.hasWebsocket())
          _TransportProtocolWebsocket(
            key: globalKey,
            initialConfig: protocol.websocket,
          ),
        if (protocol.hasGrpc())
          _TransportProtocolGrpc(key: globalKey, initialConfig: protocol.grpc),
        if (protocol.hasHttpupgrade())
          _TransportProtocolHttpUpgrade(
            key: globalKey,
            initialConfig: protocol.httpupgrade,
          ),
        if (protocol.hasSplithttp())
          _TransportProtocolSplitHttp(
            key: globalKey,
            config: protocol.splithttp,
          ),
      ],
    );
  }
}

class _MultiInboundTransportCondition extends StatefulWidget {
  const _MultiInboundTransportCondition({required this.protocol});
  final MultiProxyInboundConfig_Protocol protocol;
  @override
  State<_MultiInboundTransportCondition> createState() =>
      __MultiInboundTransportConditionState();
}

class __MultiInboundTransportConditionState
    extends State<_MultiInboundTransportCondition> {
  final handshakeAddressController = TextEditingController();
  final alpnController = TextEditingController();
  final pathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    handshakeAddressController.text = widget.protocol.sni;
    alpnController.text = widget.protocol.alpn;
    pathController.text = widget.protocol.path;
  }

  @override
  void dispose() {
    handshakeAddressController.dispose();
    alpnController.dispose();
    pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: widget.protocol.always,
            title: Text(AppLocalizations.of(context)!.matchAll),
            subtitle: Text(
              AppLocalizations.of(context)!.transportConditionMatchAllDesc,
            ),
            onChanged: (value) {
              setState(() {
                widget.protocol.always = value ?? false;
                if (value == false) {
                  handshakeAddressController.clear();
                  alpnController.clear();
                  pathController.clear();
                }
              });
            },
          ),
          if (!widget.protocol.always)
            Column(
              children: [
                const Gap(10),
                TextFormField(
                  controller: handshakeAddressController,
                  decoration: const InputDecoration(labelText: 'SNI'),
                  onChanged: (value) {
                    widget.protocol.sni = value;
                  },
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!isDomain(value)) {
                        return 'Invalid SNI';
                      }
                    }
                    return null;
                  },
                ),
                const Gap(10),
                TextFormField(
                  controller: alpnController,
                  decoration: const InputDecoration(labelText: 'ALPN'),
                  onChanged: (value) {
                    widget.protocol.alpn = value;
                  },
                ),
                const Gap(10),
                TextFormField(
                  controller: pathController,
                  decoration: const InputDecoration(labelText: 'Path'),
                  onChanged: (value) {
                    widget.protocol.path = value;
                  },
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      if (!value.startsWith('/')) {
                        return 'Invalid path';
                      }
                    }
                    return null;
                  },
                ),
                const Gap(10),
                CheckboxListTile(
                  value: widget.protocol.h2,
                  title: const Text('H2'),
                  subtitle: Text(
                    AppLocalizations.of(context)!.transportConditionH2Desc,
                  ),
                  onChanged: (value) {
                    setState(() {
                      widget.protocol.h2 = value ?? false;
                    });
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

enum MultiTransportProtocol {
  websocket,
  grpc,
  http,
  httpupgrade;

  MultiProxyInboundConfig_Protocol toProto() {
    switch (this) {
      case MultiTransportProtocol.websocket:
        return MultiProxyInboundConfig_Protocol(websocket: WebsocketConfig());
      case MultiTransportProtocol.grpc:
        return MultiProxyInboundConfig_Protocol(grpc: GrpcConfig());
      case MultiTransportProtocol.http:
        return MultiProxyInboundConfig_Protocol(http: HttpConfig());
      case MultiTransportProtocol.httpupgrade:
        return MultiProxyInboundConfig_Protocol(
          httpupgrade: HttpUpgradeConfig(),
        );
    }
  }
}

enum MultiSecurityProtocol {
  tls,
  reality;

  MultiProxyInboundConfig_Security toProto() {
    switch (this) {
      case MultiSecurityProtocol.tls:
        return MultiProxyInboundConfig_Security(tls: TlsConfig(), always: true);
      case MultiSecurityProtocol.reality:
        return MultiProxyInboundConfig_Security(
          reality: RealityConfig(),
          always: true,
        );
    }
  }
}

extension MultiProxyInboundConfigProtocolExtension
    on MultiProxyInboundConfig_Protocol {
  String get label {
    if (hasWebsocket()) {
      return 'WS';
    } else if (hasGrpc()) {
      return 'GRPC';
    } else if (hasHttp()) {
      return 'HTTP';
    } else if (hasHttpupgrade()) {
      return 'HTTPUPGRADE';
    } else if (hasSplithttp()) {
      return 'SPLITHTTP';
    }
    return '';
  }
}

extension MultiProxyInboundConfigSecurityExtension
    on MultiProxyInboundConfig_Security {
  String get label {
    if (hasTls()) {
      return 'TLS';
    } else if (hasReality()) {
      return 'Reality';
    }
    return '';
  }
}

class _MultiSecurityProtocols extends StatefulWidget {
  const _MultiSecurityProtocols({required this.securityProtocols});
  final List<MultiProxyInboundConfig_Security> securityProtocols;

  @override
  State<_MultiSecurityProtocols> createState() =>
      __MultiSecurityProtocolsState();
}

class __MultiSecurityProtocolsState extends State<_MultiSecurityProtocols> {
  List<MultiProxyInboundConfig_Security> _securityProtocols = [];
  MultiProxyInboundConfig_Security? _selected;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _securityProtocols = widget.securityProtocols;
    if (_securityProtocols.isNotEmpty) {
      _selected = _securityProtocols.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: double.infinity),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children:
              _securityProtocols.map<Widget>((e) {
                return DeleteMenuAnchor(
                  onDelete: (context) {
                    setState(() {
                      _errorMessage = null;
                      _securityProtocols.remove(e);
                      if (_selected == e) {
                        _selected = _securityProtocols.isNotEmpty
                            ? _securityProtocols.first
                            : null;
                      }
                    });
                  },
                  child: ChoiceChip(
                    label: Text(e.label),
                    selected: _selected == e,
                    onSelected: (value) {
                      if (value) {
                        if (!Form.of(context).validate()) {
                          setState(() {
                            _errorMessage = AppLocalizations.of(
                              context,
                            )!.invalidFields;
                          });
                          return;
                        }
                        setState(() {
                          _errorMessage = null;
                          _selected = e;
                        });
                      }
                    },
                  ),
                );
              }).toList()..addAll([
                MenuAnchor(
                  menuChildren: MultiSecurityProtocol.values.map((e) {
                    return MenuItemButton(
                      child: Text(e.name),
                      onPressed: () {
                        setState(() {
                          _securityProtocols.add(e.toProto());
                          _selected ??= _securityProtocols.first;
                        });
                      },
                    );
                  }).toList(),
                  builder: (context, controller, child) {
                    return getSmallAddButton(
                      onPressed: () {
                        controller.open();
                      },
                    );
                  },
                ),
              ]),
        ),
        const Gap(10),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        if (_selected != null)
          _MultiSecurityProtocol(
            key: ValueKey(_selected),
            protocol: _selected!,
          ),
      ],
    );
  }
}

class _MultiSecurityProtocol extends StatelessWidget {
  const _MultiSecurityProtocol({super.key, required this.protocol});
  final MultiProxyInboundConfig_Security protocol;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MultiInboundSecurityCondition(protocol: protocol),
        const Gap(10),
        if (protocol.hasTls())
          _TransportSecurityTls(config: protocol.tls, server: true),
        if (protocol.hasReality())
          _TransportSecurityReality(config: protocol.reality, server: true),
      ],
    );
  }
}

class _MultiInboundSecurityCondition extends StatefulWidget {
  const _MultiInboundSecurityCondition({required this.protocol});
  final MultiProxyInboundConfig_Security protocol;
  @override
  State<_MultiInboundSecurityCondition> createState() =>
      __MultiInboundSecurityConditionState();
}

class __MultiInboundSecurityConditionState
    extends State<_MultiInboundSecurityCondition> {
  final domainsController = TextEditingController();
  final regularExpressionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    domainsController.text = widget.protocol.domains.join(',');
    regularExpressionController.text = widget.protocol.regularExpression;
  }

  @override
  void dispose() {
    domainsController.dispose();
    regularExpressionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: widget.protocol.always,
            title: Text(AppLocalizations.of(context)!.matchAll),
            subtitle: Text(
              AppLocalizations.of(context)!.securityConditionMatchAllDesc,
            ),
            onChanged: (value) {
              setState(() {
                widget.protocol.always = value ?? false;
                if (value == false) {
                  domainsController.clear();
                  regularExpressionController.clear();
                }
              });
            },
          ),
          if (!widget.protocol.always)
            Column(
              children: [
                const Gap(10),
                TextFormField(
                  controller: domainsController,
                  decoration: const InputDecoration(
                    labelText: 'Domains',
                    hintText: 'example.com,example.org',
                  ),
                  validator: (value) {
                    widget.protocol.domains.clear();
                    if (value != null && value.isNotEmpty) {
                      for (var domain in value.split(',')) {
                        if (!isDomain(domain)) {
                          return 'Invalid';
                        }
                      }
                      widget.protocol.domains.addAll(value.split(','));
                    }
                    return null;
                  },
                ),
                const Gap(10),
                TextFormField(
                  controller: regularExpressionController,
                  decoration: const InputDecoration(
                    labelText: 'Regular Expression',
                  ),
                  onChanged: (value) {
                    widget.protocol.regularExpression = value;
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// config is edited directly
class _UserConfig extends StatefulWidget {
  const _UserConfig({required this.config});
  final UserConfig config;
  @override
  State<_UserConfig> createState() => __UserConfigState();
}

class __UserConfigState extends State<_UserConfig> {
  final _userNameController = TextEditingController();
  final _userSecretController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userNameController.text = widget.config.id;
    _userSecretController.text = widget.config.secret;
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _userSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _userNameController,
          onChanged: (value) {
            widget.config.id = value;
          },
          decoration: InputDecoration(
            helperText: AppLocalizations.of(context)!.optional,
            labelText: AppLocalizations.of(context)!.accountName,
          ),
        ),
        const Gap(10),
        TextFormField(
          controller: _userSecretController,
          onChanged: (value) {
            widget.config.secret = value;
          },
          decoration: InputDecoration(
            helper: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  _userSecretController.text = const Uuid().v4();
                  widget.config.secret = _userSecretController.text;
                },
                child: Text(AppLocalizations.of(context)!.generatePassword),
              ),
            ),
            labelText: AppLocalizations.of(context)!.password,
          ),
        ),
      ],
    );
  }
}
