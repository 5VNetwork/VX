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

class _VmessClient extends StatefulWidget {
  const _VmessClient({required this.config});

  final VmessClientConfig config;

  @override
  State<_VmessClient> createState() => _VmessClientState();
}

class _VmessClientState extends State<_VmessClient> {
  final _uuid = TextEditingController();
  final _alterId = TextEditingController();

  @override
  void initState() {
    super.initState();
    _uuid.text = widget.config.id;
    _alterId.text = widget.config.alterId.toString();
  }

  @override
  void dispose() {
    _uuid.dispose();
    _alterId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _uuid,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.empty;
            }
            widget.config.id = value;
            return null;
          },
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.password,
          ).applyDefaults(Theme.of(context).inputDecorationTheme),
        ),
        boxH10,
        Row(
          children: [
            TextFormField(
              controller: _alterId,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'AlterId cannot be empty';
                }
                int? i = int.tryParse(value);
                if (i == null || i < 0) {
                  return 'AlterId must be a non-negative integer';
                }
                widget.config.alterId = i;
                return null;
              },
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                constraints: BoxConstraints(maxWidth: 100),
                labelText: 'AlterId',
              ).applyDefaults(Theme.of(context).inputDecorationTheme),
            ),
            boxW10,
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: DropdownMenu<SecurityType>(
                  requestFocusOnTap: false,
                  initialSelection: widget.config.security,
                  label: const Text('Security'),
                  onSelected: (SecurityType? s) {
                    if (s != null) {
                      widget.config.security = s;
                    }
                  },
                  dropdownMenuEntries: SecurityType.values
                      .map<DropdownMenuEntry<SecurityType>>((SecurityType s) {
                        return DropdownMenuEntry<SecurityType>(
                          label: s.name,
                          value: s,
                        );
                      })
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrojanClient extends StatefulWidget {
  const _TrojanClient({required this.config});

  final TrojanClientConfig config;

  @override
  State<_TrojanClient> createState() => _TrojanClientState();
}

class _TrojanClientState extends State<_TrojanClient> {
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _password.text = widget.config.password;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _password,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password cannot be empty';
            }
            widget.config.password = value;
            return null;
          },
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.password,
          ),
        ),
        const Gap(10),
        SwitchListTile(
          title: const Text('Vision'),
          subtitle: Text(AppLocalizations.of(context)!.visionDesc),
          value: widget.config.vision,
          onChanged: (value) {
            setState(() {
              widget.config.vision = value;
            });
          },
        ),
      ],
    );
  }
}

class _AnytlsClient extends StatefulWidget {
  const _AnytlsClient({required this.config});

  final AnytlsClientConfig config;

  @override
  State<_AnytlsClient> createState() => _AnytlsClientState();
}

class _AnytlsClientState extends State<_AnytlsClient> {
  final _password = TextEditingController();
  final _idleSessionCheckInterval = TextEditingController();
  final _idleSessionTimeout = TextEditingController();
  final _minIdleSession = TextEditingController();

  @override
  void initState() {
    super.initState();
    _password.text = widget.config.password;
    if (widget.config.idleSessionCheckInterval == 0) {
      widget.config.idleSessionCheckInterval = 30;
    }
    if (widget.config.idleSessionTimeout == 0) {
      widget.config.idleSessionTimeout = 30;
    }
    if (widget.config.minIdleSession == 0) {
      widget.config.minIdleSession = 5;
    }
    _idleSessionCheckInterval.text = widget.config.idleSessionCheckInterval
        .toString();
    _idleSessionTimeout.text = widget.config.idleSessionTimeout.toString();
    _minIdleSession.text = widget.config.minIdleSession.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _password,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.fieldRequired;
            }
            widget.config.password = value;
            return null;
          },
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.password,
          ),
        ),
        boxH10,
        TextFormField(
          controller: _idleSessionCheckInterval,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            widget.config.idleSessionCheckInterval = int.parse(value ?? '0');
            return null;
          },
          decoration: const InputDecoration(
            labelText: 'Idle Session Check Interval',
          ),
        ),
        boxH10,
        TextFormField(
          controller: _idleSessionTimeout,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            widget.config.idleSessionTimeout = int.parse(value ?? '0');
            return null;
          },
          decoration: const InputDecoration(labelText: 'Idle Session Timeout'),
        ),
        boxH10,
        TextFormField(
          controller: _minIdleSession,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            widget.config.minIdleSession = int.parse(value ?? '0');
            return null;
          },
          decoration: const InputDecoration(labelText: 'Min Idle Session'),
        ),
      ],
    );
  }
}

class _VlessClient extends StatefulWidget {
  const _VlessClient({required this.config});

  final VlessClientConfig config;

  @override
  State<_VlessClient> createState() => _VlessClientState();
}

class _VlessClientState extends State<_VlessClient> {
  final _uuid = TextEditingController();

  @override
  void initState() {
    super.initState();
    _uuid.text = widget.config.id;
  }

  @override
  void dispose() {
    _uuid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _uuid,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.empty;
            }
            widget.config.id = value;
            return null;
          },
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.password,
          ).applyDefaults(Theme.of(context).inputDecorationTheme),
        ),
        boxH10,
        DropdownMenu<VlessFlow>(
          requestFocusOnTap: false,
          initialSelection: VlessFlow.fromString(widget.config.flow),
          label: const Text('Flow'),
          onSelected: (VlessFlow? s) {
            if (s != null) {
              widget.config.flow = s.toString();
            }
          },
          dropdownMenuEntries: VlessFlow.values
              .map<DropdownMenuEntry<VlessFlow>>((VlessFlow s) {
                return DropdownMenuEntry<VlessFlow>(
                  label: s.toString(),
                  value: s,
                );
              })
              .toList(),
        ),
      ],
    );
  }
}

enum VlessFlow {
  xtlsRprxVision,
  xtlsRprxVisionUdp443,
  none;

  static VlessFlow? fromString(String s) {
    switch (s) {
      case '':
        return VlessFlow.none;
      case 'xtls-rprx-vision':
        return VlessFlow.xtlsRprxVision;
      case 'xtls-rprx-vision-udp443':
        return VlessFlow.xtlsRprxVisionUdp443;
      default:
        throw ArgumentError('Invalid VlessFlow: $s');
    }
  }

  @override
  String toString() {
    switch (this) {
      case VlessFlow.xtlsRprxVision:
        return 'xtls-rprx-vision';
      case VlessFlow.xtlsRprxVisionUdp443:
        return 'xtls-rprx-vision-udp443';
      case VlessFlow.none:
        return '';
    }
  }
}

class _ShadowsocksClient extends StatefulWidget {
  const _ShadowsocksClient({required this.config});

  final ShadowsocksClientConfig config;

  @override
  State<_ShadowsocksClient> createState() => _ShadowsocksClientState();
}

class _ShadowsocksClientState extends State<_ShadowsocksClient> {
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _password.text = widget.config.password;
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _password,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.password,
          ),
          validator: (value) {
            widget.config.password = value ?? '';
            return null;
          },
        ),
        boxH10,
        DropdownMenu<ShadowsocksCipherType>(
          requestFocusOnTap: false,
          initialSelection: widget.config.cipherType,
          label: const Text('Cipher'),
          onSelected: (ShadowsocksCipherType? s) {
            if (s != null) {
              widget.config.cipherType = s;
            }
          },
          dropdownMenuEntries: ShadowsocksCipherType.values
              .map<DropdownMenuEntry<ShadowsocksCipherType>>((
                ShadowsocksCipherType s,
              ) {
                return DropdownMenuEntry<ShadowsocksCipherType>(
                  label: s.toString(),
                  value: s,
                );
              })
              .toList(),
        ),
      ],
    );
  }
}

class _Shadowsocks2022Client extends StatefulWidget {
  const _Shadowsocks2022Client({required this.config});

  final Shadowsocks2022ClientConfig config;

  @override
  State<_Shadowsocks2022Client> createState() => _Shadowsocks2022ClientState();
}

class _Shadowsocks2022ClientState extends State<_Shadowsocks2022Client> {
  final _keyController = TextEditingController();
  static const List<String> _methods = [
    '2022-blake3-aes-128-gcm',
    '2022-blake3-aes-256-gcm',
    '2022-blake3-chacha20-poly1305',
  ];
  late String _method;

  @override
  void initState() {
    super.initState();
    _keyController.text = widget.config.key;
    _method = widget.config.method.isNotEmpty
        ? widget.config.method
        : _methods.first;
        
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownMenu<String>(
          requestFocusOnTap: false,
          initialSelection: _method,
          label: const Text('Method'),
          onSelected: (String? m) {
            if (m != null) {
              setState(() {
                _method = m;
                widget.config.method = m;
              });
            }
          },
          dropdownMenuEntries: _methods
              .map<DropdownMenuEntry<String>>(
                (m) => DropdownMenuEntry<String>(label: m, value: m),
              )
              .toList(),
        ),
        boxH10,
        TextFormField(
          controller: _keyController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.password,
            helperText: 'PSK / password (BLAKE3-derived if not base64)',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.fieldRequired;
            }
            widget.config.key = value;
            return null;
          },
        ),
      ],
    );
  }
}

class _SocksClient extends StatefulWidget {
  const _SocksClient({required this.config});

  final SocksClientConfig config;

  @override
  State<_SocksClient> createState() => _SocksClientState();
}

class _SocksClientState extends State<_SocksClient> {
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _username.text = widget.config.name;
    _password.text = widget.config.password;
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _username,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.accountName,
          ),
          validator: (value) {
            widget.config.name = value ?? '';
            return null;
          },
        ),
        boxH10,
        TextFormField(
          controller: _password,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.password,
          ),
          validator: (value) {
            widget.config.password = value ?? '';
            return null;
          },
        ),
      ],
    );
  }
}

QuicConfig getDefaultQuicConfig() {
  return QuicConfig(
    // initialConnectionReceiveWindow: 8,
    // maxConnectionReceiveWindow: 8,
    // initialStreamReceiveWindow: 20,
    // maxStreamReceiveWindow: 20,
    initialConnectionReceiveWindowBytes: Platform.isIOS
        ? Int64(200 * 1024)
        : Int64(20 * 1024 * 1024),
    maxConnectionReceiveWindowBytes: Int64(20 * 1024 * 1024),
    initialStreamReceiveWindowBytes: Platform.isIOS
        ? Int64(80 * 1024)
        : Int64(8 * 1024 * 1024),
    maxStreamReceiveWindowBytes: Int64(8 * 1024 * 1024),
    maxIdleTimeout: 30,
    keepAlivePeriod: 10,
    disablePathMtuDiscovery: false,
  );
}

Hysteria2ServerConfig getDefaultHysteriaServerConfig() {
  return Hysteria2ServerConfig(
    quic: getDefaultQuicConfig(),
    bandwidth: BandwidthConfig(),
    obfs: ObfsConfig(),
    tlsConfig: TlsConfig(),
  );
}

Hysteria2ClientConfig _getDefaultHysteriaConfig() {
  return Hysteria2ClientConfig(
    quic: getDefaultQuicConfig(),
    fastOpen: true,
    bandwidth: BandwidthConfig(),
    obfs: ObfsConfig(),
    tlsConfig: TlsConfig(),
  );
}

// It modifies the config
class VmessServer extends StatefulWidget {
  const VmessServer({super.key, required this.config});

  final VmessServerConfig config;

  @override
  State<VmessServer> createState() => _VmessServerState();
}

class _VmessServerState extends State<VmessServer> {
  bool _secureEncryptionOnly = false;

  @override
  void initState() {
    super.initState();
    _secureEncryptionOnly = widget.config.secureEncryptionOnly;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Secure Encryption Only',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Switch(
          value: _secureEncryptionOnly,
          onChanged: (value) {
            setState(() {
              _secureEncryptionOnly = value;
              widget.config.secureEncryptionOnly = value;
            });
          },
        ),
      ],
    );
  }
}

class _Secrets extends StatefulWidget {
  const _Secrets({required this.secrets});
  final List<String> secrets;
  @override
  State<_Secrets> createState() => __SecretsState();
}

class __SecretsState extends State<_Secrets> {
  final List<TextEditingController> _secretControllers = [];
  final TextEditingController _newSecretController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _secretControllers.addAll(
      widget.secrets.map((e) => TextEditingController(text: e)),
    );
    for (var i = 0; i < widget.secrets.length; i++) {
      _secretControllers.add(TextEditingController(text: widget.secrets[i]));
    }
  }

  @override
  void dispose() {
    _newSecretController.dispose();
    for (var e in _secretControllers) {
      e.dispose();
    }
    super.dispose();
  }

  void _addSecret() {
    setState(() {
      final newSecretController = TextEditingController(
        text: _newSecretController.text,
      );
      _newSecretController.text = '';
      widget.secrets.add(newSecretController.text);
      _secretControllers.add(newSecretController);
    });
  }

  void _removeSecret(int index) {
    setState(() {
      final secretController = _secretControllers.removeAt(index);
      secretController.dispose();
      widget.secrets.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...widget.secrets.asMap().entries.map((entry) {
          final index = entry.key;
          final secretController = _secretControllers[index];
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: secretController,
                  decoration: const InputDecoration(labelText: 'Secret'),
                ),
              ),
              boxW10,
              IconButton.filledTonal(
                icon: const Icon(Icons.delete),
                onPressed: () => _removeSecret(index),
              ),
            ],
          );
        }),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _newSecretController,
                decoration: const InputDecoration(labelText: 'Secret'),
              ),
            ),
            boxW10,
            IconButton.filledTonal(
              icon: const Icon(Icons.add),
              onPressed: _addSecret,
            ),
          ],
        ),
      ],
    );
  }
}

/// It modifies the config
class TrojanServer extends StatefulWidget {
  const TrojanServer({super.key, required this.config});

  final TrojanServerConfig config;

  @override
  State<TrojanServer> createState() => _TrojanServerState();
}

class _TrojanServerState extends State<TrojanServer> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Vision'),
          value: widget.config.vision,
          onChanged: (value) {
            setState(() {
              widget.config.vision = value;
            });
          },
        ),
      ],
    );
  }
}

class AnyTlsServer extends StatelessWidget {
  const AnyTlsServer({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

class DokodemoServer extends StatefulWidget {
  const DokodemoServer({super.key, required this.config});

  final DokodemoConfig config;

  @override
  State<DokodemoServer> createState() => _DokodemoServerState();
}

class _DokodemoServerState extends State<DokodemoServer> {
  final _addressController = TextEditingController();
  final _portController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.config.address;
    if (widget.config.hasPort()) {
      _portController.text = widget.config.port.toString();
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _addressController,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!isValidIp(value) && !isDomain(value)) {
                return AppLocalizations.of(context)!.invalidIp;
              }
            }
            widget.config.address = value ?? '';
            return null;
          },
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.address,
            hintText: '127.0.0.1',
          ).applyDefaults(Theme.of(context).inputDecorationTheme),
        ),
        boxH10,
        TextFormField(
          controller: _portController,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.fieldRequired;
            }
            final port = int.tryParse(value);
            if (port == null || port < 1 || port > 65535) {
              return AppLocalizations.of(context)!.invalidPort;
            }
            widget.config.port = port;
            return null;
          },
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.port,
            hintText: '4431',
          ).applyDefaults(Theme.of(context).inputDecorationTheme),
        ),
        const Gap(10),
        Row(
          children: [
            ChoiceChip(
              label: const Text('TCP'),
              selected: widget.config.networks.contains(Network.TCP),
              onSelected: (value) {
                setState(() {
                  if (value) {
                    widget.config.networks.add(Network.TCP);
                  } else {
                    widget.config.networks.remove(Network.TCP);
                  }
                });
              },
            ),
            const Gap(5),
            ChoiceChip(
              label: const Text('UDP'),
              selected: widget.config.networks.contains(Network.UDP),
              onSelected: (value) {
                if (value) {
                  setState(() {
                    widget.config.networks.add(Network.UDP);
                  });
                } else {
                  setState(() {
                    widget.config.networks.remove(Network.UDP);
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class ShadowsocksServer extends StatefulWidget {
  const ShadowsocksServer({super.key, required this.config});

  final ShadowsocksServerConfig config;

  @override
  State<ShadowsocksServer> createState() => _ShadowsocksServerState();
}

class _ShadowsocksServerState extends State<ShadowsocksServer> {
  late ShadowsocksCipherType _cipherType;
  bool _ivCheck = false;

  @override
  void initState() {
    super.initState();
    _cipherType = widget.config.cipherType;
    _ivCheck = widget.config.ivCheck;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownMenu<ShadowsocksCipherType>(
          requestFocusOnTap: false,
          initialSelection: _cipherType,
          label: const Text('Cipher'),
          onSelected: (ShadowsocksCipherType? s) {
            if (s != null) {
              setState(() {
                _cipherType = s;
                widget.config.cipherType = s;
              });
            }
          },
          dropdownMenuEntries: ShadowsocksCipherType.values
              .map<DropdownMenuEntry<ShadowsocksCipherType>>((
                ShadowsocksCipherType s,
              ) {
                return DropdownMenuEntry<ShadowsocksCipherType>(
                  label: s.toString(),
                  value: s,
                );
              })
              .toList(),
        ),
        boxH10,
        Row(
          children: [
            Text('IV Check', style: Theme.of(context).textTheme.titleMedium),
            Switch(
              value: _ivCheck,
              onChanged: (value) {
                setState(() {
                  _ivCheck = value;
                  widget.config.ivCheck = value;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}

class Shadowsocks2022Server extends StatefulWidget {
  const Shadowsocks2022Server({super.key, required this.config});

  final Shadowsocks2022ServerConfig config;

  @override
  State<Shadowsocks2022Server> createState() => _Shadowsocks2022ServerState();
}

class _Shadowsocks2022ServerState extends State<Shadowsocks2022Server> {
  static const List<String> _methods = [
    '2022-blake3-aes-128-gcm',
    '2022-blake3-aes-256-gcm',
    '2022-blake3-chacha20-poly1305',
  ];

  late String _method;
  bool _tcp = true;
  bool _udp = false;

  @override
  void initState() {
    super.initState();
    _method = widget.config.method.isNotEmpty
        ? widget.config.method
        : _methods.first;
    _tcp = widget.config.networks.contains(Network.TCP);
    _udp = widget.config.networks.contains(Network.UDP);
    if (widget.config.method.isEmpty) {
      widget.config.method = _methods.first;
    }
  }

  void _setNetwork(bool tcp, bool udp) {
    setState(() {
      _tcp = tcp;
      _udp = udp;
      widget.config.networks.clear();
      if (_tcp) {
        widget.config.networks.add(Network.TCP);
      }
      if (_udp) {
        widget.config.networks.add(Network.UDP);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownMenu<String>(
          requestFocusOnTap: false,
          initialSelection: _method,
          label: const Text('Method'),
          onSelected: (String? m) {
            if (m != null) {
              setState(() {
                _method = m;
                widget.config.method = m;
              });
            }
          },
          dropdownMenuEntries: _methods
              .map<DropdownMenuEntry<String>>(
                (m) => DropdownMenuEntry<String>(label: m, value: m),
              )
              .toList(),
        ),
        boxH10,
        Row(
          children: [
            ChoiceChip(
              label: const Text('TCP'),
              selected: _tcp,
              onSelected: (v) => _setNetwork(v, _udp),
            ),
            const Gap(5),
            ChoiceChip(
              label: const Text('UDP'),
              selected: _udp,
              onSelected: (v) => _setNetwork(_tcp, v),
            ),
          ],
        ),
      ],
    );
  }
}

class VlessServer extends StatefulWidget {
  const VlessServer({super.key, required this.config});
  final VlessServerConfig config;

  @override
  State<VlessServer> createState() => _VlessServerState();
}

class _VlessServerState extends State<VlessServer> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

class SocksServer extends StatefulWidget {
  const SocksServer({super.key, required this.config});

  final SocksServerConfig config;

  @override
  State<SocksServer> createState() => _SocksServerState();
}

class _SocksServerState extends State<SocksServer> {
  final _addressController = TextEditingController();
  late AuthType _authType;
  bool _udpEnabled = false;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.config.address;
    _authType = widget.config.authType;
    _udpEnabled = widget.config.udpEnabled;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownMenu<AuthType>(
          requestFocusOnTap: false,
          initialSelection: _authType,
          label: const Text('Auth Type'),
          onSelected: (AuthType? s) {
            if (s != null) {
              setState(() {
                _authType = s;
                widget.config.authType = s;
              });
            }
          },
          dropdownMenuEntries: AuthType.values.map<DropdownMenuEntry<AuthType>>(
            (AuthType s) {
              return DropdownMenuEntry<AuthType>(label: s.name, value: s);
            },
          ).toList(),
        ),
        boxH10,
        TextFormField(
          controller: _addressController,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!isValidIp(value)) {
                return AppLocalizations.of(context)!.invalidIp;
              }
            }
            return null;
          },
          onChanged: (value) {
            widget.config.address = value;
          },
          decoration: const InputDecoration(
            labelText: 'Socks UDP Associate BND.ADDR',
          ),
        ),
        boxH10,
        Row(
          children: [
            Text('UDP Enabled', style: Theme.of(context).textTheme.titleMedium),
            Switch(
              value: _udpEnabled,
              onChanged: (value) {
                setState(() {
                  _udpEnabled = value;
                  widget.config.udpEnabled = value;
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}

class HysteriaClient extends StatefulWidget {
  const HysteriaClient({super.key, required this.config});
  final Hysteria2ClientConfig config;

  @override
  State<HysteriaClient> createState() => _HysteriaClientState();
}

class _HysteriaClientState extends State<HysteriaClient> {
  late TextEditingController _authController;
  late bool _realmEnabled;

  @override
  void initState() {
    super.initState();
    _authController = TextEditingController(text: widget.config.auth);
    _realmEnabled = hysteriaRealmEnabled(widget.config.realm);
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        TextFormField(
          controller: _authController,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.password,
          ),
          validator: (value) {
            if (value != null) {
              widget.config.auth = value;
            }
            return null;
          },
        ),
        const Gap(10),
        Hysteria(
          quicConfig: widget.config.quic,
          tlsConfig: widget.config.tlsConfig,
          obfsConfig: widget.config.obfs,
          bandwidthConfig: widget.config.bandwidth,
        ),
        const Gap(10),
        Row(
          children: [
            Text('Fast Open', style: Theme.of(context).textTheme.titleMedium),
            Switch(
              value: widget.config.fastOpen,
              onChanged: (value) {
                setState(() {
                  widget.config.fastOpen = value;
                });
              },
            ),
          ],
        ),
        boxH10,
        TextDivider(text: l10n.realmSection),
        boxH10,
        Row(
          children: [
            Text(l10n.realmSection, style: Theme.of(context).textTheme.titleMedium),
            Switch(
              value: _realmEnabled,
              onChanged: (value) {
                setState(() {
                  _realmEnabled = value;
                  if (!value) {
                    clearRealmConfig(widget.config.ensureRealm());
                  }
                });
              },
            ),
          ],
        ),
        if (_realmEnabled) ...[
          boxH10,
          HysteriaRealmConfig(
            config: widget.config.ensureRealm(),
          ),
        ],
      ],
    );
  }
}

/// the constructor parameters will be modified directly.
class Hysteria extends StatefulWidget {
  const Hysteria({
    super.key,
    required this.quicConfig,
    required this.tlsConfig,
    required this.obfsConfig,
    required this.bandwidthConfig,
    this.server = false,
  });
  final QuicConfig quicConfig;
  final TlsConfig tlsConfig;
  final BandwidthConfig bandwidthConfig;
  final ObfsConfig obfsConfig;
  final bool server;
  @override
  State<Hysteria> createState() => _HysteriaState();
}

class _HysteriaState extends State<Hysteria> {
  late TextEditingController _initialStreamReceiveWindowController;
  late TextEditingController _maxStreamReceiveWindowController;
  late TextEditingController _initialConnectionReceiveWindowController;
  late TextEditingController _maxConnectionReceiveWindowController;
  late TextEditingController _maxIdleTimeoutController;
  late TextEditingController _keepAlivePeriodController;
  late TextEditingController _disablePathMtuDiscoveryController;
  late TextEditingController _maxTxController;
  late TextEditingController _maxRxController;
  late TextEditingController _salamanderPasswordController;

  @override
  void initState() {
    super.initState();
    _initialStreamReceiveWindowController = TextEditingController();
    if (widget.quicConfig.initialStreamReceiveWindow != 0) {
      _initialStreamReceiveWindowController.text =
          (widget.quicConfig.initialStreamReceiveWindow * 1024 * 1024)
              .toString();
    } else {
      _initialStreamReceiveWindowController.text = widget
          .quicConfig
          .initialStreamReceiveWindowBytes
          .toString();
    }
    _maxStreamReceiveWindowController = TextEditingController();
    if (widget.quicConfig.maxStreamReceiveWindow != 0) {
      _maxStreamReceiveWindowController.text =
          (widget.quicConfig.maxStreamReceiveWindow * 1024 * 1024).toString();
    } else {
      _maxStreamReceiveWindowController.text = widget
          .quicConfig
          .maxStreamReceiveWindowBytes
          .toString();
    }
    _initialConnectionReceiveWindowController = TextEditingController();
    if (widget.quicConfig.initialConnectionReceiveWindow != 0) {
      _initialConnectionReceiveWindowController.text =
          (widget.quicConfig.initialConnectionReceiveWindow * 1024 * 1024)
              .toString();
    } else {
      _initialConnectionReceiveWindowController.text = widget
          .quicConfig
          .initialConnectionReceiveWindowBytes
          .toString();
    }
    _maxConnectionReceiveWindowController = TextEditingController();
    if (widget.quicConfig.maxConnectionReceiveWindow != 0) {
      _maxConnectionReceiveWindowController.text =
          (widget.quicConfig.maxConnectionReceiveWindow * 1024 * 1024)
              .toString();
    } else {
      _maxConnectionReceiveWindowController.text = widget
          .quicConfig
          .maxConnectionReceiveWindowBytes
          .toString();
    }
    _maxIdleTimeoutController = TextEditingController(
      text: widget.quicConfig.maxIdleTimeout.toString(),
    );
    _keepAlivePeriodController = TextEditingController(
      text: widget.quicConfig.keepAlivePeriod.toString(),
    );
    _disablePathMtuDiscoveryController = TextEditingController(
      text: widget.quicConfig.disablePathMtuDiscovery.toString(),
    );
    _maxTxController = TextEditingController(
      text: widget.bandwidthConfig.maxTx == 0
          ? null
          : widget.bandwidthConfig.maxTx.toString(),
    );
    _maxRxController = TextEditingController(
      text: widget.bandwidthConfig.maxRx == 0
          ? null
          : widget.bandwidthConfig.maxRx.toString(),
    );
    _salamanderPasswordController = TextEditingController(
      text: widget.obfsConfig.salamander.password,
    );
  }

  @override
  void dispose() {
    _initialStreamReceiveWindowController.dispose();
    _maxStreamReceiveWindowController.dispose();
    _initialConnectionReceiveWindowController.dispose();
    _maxConnectionReceiveWindowController.dispose();
    _maxIdleTimeoutController.dispose();
    _keepAlivePeriodController.dispose();
    _disablePathMtuDiscoveryController.dispose();
    _maxTxController.dispose();
    _maxRxController.dispose();
    _salamanderPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _initialStreamReceiveWindowController,
                decoration: const InputDecoration(
                  labelText: 'Initial Stream Receive Window',
                  suffixText: 'Byte',
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  print('value: $value');
                  if (value.isNotEmpty) {
                    widget.quicConfig.initialStreamReceiveWindowBytes = Int64(
                      int.parse(value),
                    );
                    widget.quicConfig.initialStreamReceiveWindow = 0;
                  } else {
                    widget.quicConfig.initialStreamReceiveWindowBytes = Int64(
                      0,
                    );
                    widget.quicConfig.initialStreamReceiveWindow = 0;
                  }
                },
              ),
            ),
            const Gap(5),
            Expanded(
              child: TextFormField(
                controller: _maxStreamReceiveWindowController,
                decoration: const InputDecoration(
                  labelText: 'Max Stream Receive Window',
                  suffixText: 'Byte',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    widget.quicConfig.maxStreamReceiveWindowBytes = Int64(
                      int.parse(value),
                    );
                    widget.quicConfig.maxStreamReceiveWindow = 0;
                  } else {
                    widget.quicConfig.maxStreamReceiveWindowBytes = Int64(0);
                    widget.quicConfig.maxStreamReceiveWindow = 0;
                  }
                },
              ),
            ),
          ],
        ),
        const Gap(10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _initialConnectionReceiveWindowController,
                decoration: const InputDecoration(
                  labelText: 'Initial Connection Receive Window',
                  suffixText: 'Byte',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    widget.quicConfig.initialConnectionReceiveWindowBytes =
                        Int64(int.parse(value));
                    widget.quicConfig.initialConnectionReceiveWindow = 0;
                  } else {
                    widget.quicConfig.initialConnectionReceiveWindowBytes =
                        Int64(0);
                    widget.quicConfig.initialConnectionReceiveWindow = 0;
                  }
                },
              ),
            ),
            const Gap(5),
            Expanded(
              child: TextFormField(
                controller: _maxConnectionReceiveWindowController,
                decoration: const InputDecoration(
                  labelText: 'Max Connection Receive Window',
                  suffixText: 'Byte',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    widget.quicConfig.maxConnectionReceiveWindowBytes = Int64(
                      int.parse(value),
                    );
                    widget.quicConfig.maxConnectionReceiveWindow = 0;
                  } else {
                    widget.quicConfig.maxConnectionReceiveWindowBytes = Int64(
                      0,
                    );
                    widget.quicConfig.maxConnectionReceiveWindow = 0;
                  }
                },
              ),
            ),
          ],
        ),
        const Gap(10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _maxIdleTimeoutController,
                decoration: const InputDecoration(
                  labelText: 'Max Idle Timeout',
                  suffixText: 's',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                // onChanged: (value) {
                //   if (value.isNotEmpty) {
                //     widget.quicConfig.maxIdleTimeout = int.parse(value);
                //   } else {
                //     widget.quicConfig.maxIdleTimeout = 0;
                //   }
                // },
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final i = int.parse(value);
                    if (i < 4 || i > 120) {
                      return '需在[4, 120]之间';
                    }
                    widget.quicConfig.maxIdleTimeout = i;
                  } else {
                    widget.quicConfig.maxIdleTimeout = 0;
                  }
                  return null;
                },
              ),
            ),
            const Gap(5),
            Expanded(
              child: TextFormField(
                controller: _keepAlivePeriodController,
                decoration: const InputDecoration(
                  labelText: 'Keep Alive Period',
                  suffixText: 's',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    widget.quicConfig.keepAlivePeriod = int.parse(value);
                  } else {
                    widget.quicConfig.keepAlivePeriod = 0;
                  }
                },
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final v = int.parse(value);
                    if (v < 2 || v > 60) {
                      return AppLocalizations.of(
                        context,
                      )!.keepAlivePeriodMustBeBetween2And60;
                    }
                    widget.quicConfig.keepAlivePeriod = v;
                  } else {
                    widget.quicConfig.keepAlivePeriod = 0;
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const Gap(10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _maxTxController,
                decoration: const InputDecoration(
                  labelText: 'Tx',
                  suffixText: 'MB',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final i = int.tryParse(value);
                    if (i != null) {
                      widget.bandwidthConfig.maxTx = i;
                    } else {
                      return 'Invalid number';
                    }
                  } else {
                    widget.bandwidthConfig.maxTx = 0;
                  }
                  return null;
                },
              ),
            ),
            const Gap(5),
            Expanded(
              child: TextFormField(
                controller: _maxRxController,
                decoration: const InputDecoration(
                  labelText: 'Rx',
                  suffixText: 'MB',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final i = int.tryParse(value);
                    if (i != null) {
                      widget.bandwidthConfig.maxRx = i;
                    } else {
                      return 'Invalid number';
                    }
                  } else {
                    widget.bandwidthConfig.maxRx = 0;
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const Gap(10),
        TextFormField(
          controller: _salamanderPasswordController,
          decoration: const InputDecoration(labelText: 'Salamander Password'),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              widget.obfsConfig.salamander = SalamanderConfig(password: value);
            } else {
              widget.obfsConfig.clear();
            }
            return null;
          },
        ),
        const Gap(10),
        Row(
          children: [
            Text(
              'Disable Path MTU Discovery',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Switch(
              value: widget.quicConfig.disablePathMtuDiscovery,
              onChanged: (value) {
                setState(() {
                  widget.quicConfig.disablePathMtuDiscovery = value;
                });
              },
            ),
          ],
        ),
        const Gap(10),
        ExpansionTile(
          title: Text(
            'TLS',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
          collapsedBackgroundColor:
              Theme.of(context).colorScheme.surfaceContainerLow,
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          childrenPadding: const EdgeInsets.all(10),
          children: [
            _TransportSecurityTls(
              config: widget.tlsConfig,
              showAlpn: false,
              server: widget.server,
            ),
          ],
        ),
      ],
    );
  }
}

class HysteriaServer extends StatefulWidget {
  const HysteriaServer({
    super.key,
    required this.config,
  });
  final Hysteria2ServerConfig config;

  @override
  State<HysteriaServer> createState() => _HysteriaServerState();
}

class _HysteriaServerState extends State<HysteriaServer> {
  late bool _realmEnabled;

  @override
  void initState() {
    super.initState();
    _realmEnabled = hysteriaRealmEnabled(widget.config.realm);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Hysteria(
          quicConfig: widget.config.quic,
          tlsConfig: widget.config.tlsConfig,
          obfsConfig: widget.config.obfs,
          bandwidthConfig: widget.config.bandwidth,
          server: true,
        ),
        boxH10,
        Row(
          children: [
            Text(
              l10n.ignoreClientBandwidth,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Switch(
              value: widget.config.ignoreClientBandwidth,
              onChanged: (value) {
                setState(() {
                  widget.config.ignoreClientBandwidth = value;
                });
              },
            ),
          ],
        ),
        boxH10,
        TextDivider(text: l10n.realmSection),
        boxH10,
        Row(
          children: [
            Text(l10n.realmSection, style: Theme.of(context).textTheme.titleMedium),
            Switch(
              value: _realmEnabled,
              onChanged: (value) {
                setState(() {
                  _realmEnabled = value;
                  if (!value) {
                    clearRealmConfig(widget.config.ensureRealm());
                  }
                });
              },
            ),
          ],
        ),
        if (_realmEnabled) ...[
          boxH10,
          HysteriaRealmConfig(
            config: widget.config.ensureRealm(),
            server: true,
          ),
        ],
      ],
    );
  }
}

class _HttpClient extends StatefulWidget {
  const _HttpClient({required this.config});
  final HttpClientConfig config;

  @override
  State<_HttpClient> createState() => __HttpClientState();
}

class __HttpClientState extends State<_HttpClient> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!widget.config.hasAccount()) {
      widget.config.account = Account();
    }
    _usernameController.text = widget.config.account.username;
    _passwordController.text = widget.config.account.password;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _usernameController,
          decoration: const InputDecoration(labelText: 'Username'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.fieldRequired;
            }
            widget.config.account.username = value;
            return null;
          },
        ),
        boxH10,
        TextFormField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Password'),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.fieldRequired;
            }
            widget.config.account.password = value;
            return null;
          },
        ),
      ],
    );
  }
}

class _WireguardPeerEditors {
  _WireguardPeerEditors({
    required this.publicKey,
    required this.preSharedKey,
    required this.endpoint,
    required this.keepAlive,
    required this.allowedIps,
  });

  factory _WireguardPeerEditors.empty() {
    return _WireguardPeerEditors(
      publicKey: TextEditingController(),
      preSharedKey: TextEditingController(),
      endpoint: TextEditingController(),
      keepAlive: TextEditingController(),
      allowedIps: TextEditingController(),
    );
  }

  factory _WireguardPeerEditors.fromPeer(PeerConfig p) {
    return _WireguardPeerEditors(
      publicKey: TextEditingController(text: p.publicKey),
      preSharedKey: TextEditingController(text: p.preSharedKey),
      endpoint: TextEditingController(text: p.endpoint),
      keepAlive: TextEditingController(
        text: p.keepAlive != 0 ? '${p.keepAlive}' : '',
      ),
      allowedIps: TextEditingController(text: p.allowedIps.join('\n')),
    );
  }

  final TextEditingController publicKey;
  final TextEditingController preSharedKey;
  final TextEditingController endpoint;
  final TextEditingController keepAlive;
  final TextEditingController allowedIps;

  void dispose() {
    publicKey.dispose();
    preSharedKey.dispose();
    endpoint.dispose();
    keepAlive.dispose();
    allowedIps.dispose();
  }

  void copyTo(PeerConfig p) {
    p.publicKey = publicKey.text.trim();
    if (preSharedKey.text.trim().isEmpty) {
      p.clearPreSharedKey();
    } else {
      p.preSharedKey = preSharedKey.text.trim();
    }
    p.endpoint = endpoint.text.trim();
    final ka = int.tryParse(keepAlive.text.trim());
    if (ka == null || ka <= 0) {
      p.clearKeepAlive();
    } else {
      p.keepAlive = ka;
    }
    p.allowedIps.clear();
    for (final line in allowedIps.text.split(RegExp(r'[\n,]+'))) {
      final s = line.trim();
      if (s.isNotEmpty) {
        p.allowedIps.add(s);
      }
    }
  }
}

class _WireguardClient extends StatefulWidget {
  const _WireguardClient({required this.config});

  final DeviceConfig config;

  @override
  State<_WireguardClient> createState() => _WireguardClientState();
}

class _WireguardClientState extends State<_WireguardClient> {
  late final TextEditingController _secretKey;
  late final TextEditingController _localAddresses;
  late final TextEditingController _mtu;
  late final TextEditingController _numWorkers;
  late final TextEditingController _reserved;
  late List<_WireguardPeerEditors> _peerEditors;

  @override
  void initState() {
    super.initState();
    final c = widget.config;
    if (c.peers.isEmpty) {
      c.peers.add(PeerConfig());
    }
    _secretKey = TextEditingController(text: c.secretKey);
    _localAddresses = TextEditingController(text: c.endpoint.join('\n'));
    _mtu = TextEditingController(
      text: c.hasMtu() && c.mtu != 0 ? '${c.mtu}' : '',
    );
    _numWorkers = TextEditingController(
      text: c.hasNumWorkers() && c.numWorkers != 0 ? '${c.numWorkers}' : '',
    );
    _reserved = TextEditingController(
      text: c.hasReserved() && c.reserved.isNotEmpty
          ? c.reserved.map((b) => b.toString()).join(',')
          : '',
    );
    _peerEditors = c.peers
        .map((p) => _WireguardPeerEditors.fromPeer(p))
        .toList();
  }

  @override
  void dispose() {
    _secretKey.dispose();
    _localAddresses.dispose();
    _mtu.dispose();
    _numWorkers.dispose();
    _reserved.dispose();
    for (final e in _peerEditors) {
      e.dispose();
    }
    super.dispose();
  }

  void _addPeer() {
    setState(() {
      widget.config.peers.add(PeerConfig());
      _peerEditors.add(_WireguardPeerEditors.empty());
    });
  }

  void _removePeer(int index) {
    if (widget.config.peers.length <= 1) {
      return;
    }
    setState(() {
      _peerEditors[index].dispose();
      _peerEditors.removeAt(index);
      widget.config.peers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _secretKey,
          decoration: const InputDecoration(
            labelText: 'Private key',
            helperText: 'Base64 or 64-char hex',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return AppLocalizations.of(context)!.fieldRequired;
            }
            widget.config.secretKey = value.trim();
            return null;
          },
        ),
        boxH10,
        TextFormField(
          controller: _localAddresses,
          minLines: 2,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Interface addresses',
            helperText: 'One per line, e.g. 10.0.0.2/32',
          ),
          validator: (value) {
            widget.config.endpoint.clear();
            final lines = value?.split(RegExp(r'\r?\n')) ?? [];
            var any = false;
            for (final line in lines) {
              final s = line.trim();
              if (s.isNotEmpty) {
                widget.config.endpoint.add(s);
                any = true;
              }
            }
            if (!any) {
              return AppLocalizations.of(context)!.fieldRequired;
            }
            return null;
          },
        ),
        boxH10,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _mtu,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'MTU',
                  helperText: 'Leave empty for default (1420)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    widget.config.clearMtu();
                    return null;
                  }
                  final i = int.tryParse(value);
                  if (i == null || i < 576 || i > 65535) {
                    return 'Invalid MTU';
                  }
                  widget.config.mtu = i;
                  return null;
                },
              ),
            ),
            boxW10,
            Expanded(
              child: TextFormField(
                controller: _numWorkers,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Workers'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    widget.config.clearNumWorkers();
                    return null;
                  }
                  final i = int.tryParse(value);
                  if (i == null || i < 1) {
                    return 'Invalid';
                  }
                  widget.config.numWorkers = i;
                  return null;
                },
              ),
            ),
          ],
        ),
        boxH10,
        TextFormField(
          controller: _reserved,
          decoration: const InputDecoration(
            labelText: 'Reserved bytes',
            helperText: 'Optional, three 0–255 values: e.g. 0,0,0',
          ),
          validator: (value) {
            final t = value?.trim() ?? '';
            if (t.isEmpty) {
              widget.config.clearReserved();
              return null;
            }
            final parts = t.split(',');
            if (parts.length != 3) {
              return 'Need exactly three comma-separated bytes';
            }
            final bytes = <int>[];
            for (final p in parts) {
              final n = int.tryParse(p.trim());
              if (n == null || n < 0 || n > 255) {
                return 'Each value must be 0–255';
              }
              bytes.add(n);
            }
            widget.config.reserved = bytes;
            return null;
          },
        ),
        boxH10,
        SwitchListTile(
          title: const Text('No kernel TUN'),
          subtitle: Text(
            'Use userspace TUN (gVisor) instead of OS TUN',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          value: widget.config.noKernelTun,
          onChanged: (v) {
            setState(() {
              widget.config.noKernelTun = v;
            });
          },
        ),
        const Gap(8),
        Row(
          children: [
            Text('Peers', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: _addPeer,
              icon: const Icon(Icons.add),
              label: const Text('Add peer'),
            ),
          ],
        ),
        ..._peerEditors.asMap().entries.map((entry) {
          final i = entry.key;
          final ed = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FormContainer(
              children: [
                Row(
                  children: [
                    Text(
                      'Peer ${i + 1}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    if (_peerEditors.length > 1)
                      IconButton(
                        tooltip: 'Remove peer',
                        onPressed: () => _removePeer(i),
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
                boxH10,
                TextFormField(
                  controller: ed.publicKey,
                  decoration: const InputDecoration(
                    labelText: 'Public key',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context)!.fieldRequired;
                    }
                    ed.copyTo(widget.config.peers[i]);
                    return null;
                  },
                ),
                boxH10,
                TextFormField(
                  controller: ed.preSharedKey,
                  decoration: const InputDecoration(
                    labelText: 'Pre-shared key',
                    helperText: 'Optional',
                  ),
                  onChanged: (_) => ed.copyTo(widget.config.peers[i]),
                ),
                boxH10,
                TextFormField(
                  controller: ed.endpoint,
                  decoration: const InputDecoration(
                    labelText: 'Endpoint',
                    helperText: 'host:port',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context)!.fieldRequired;
                    }
                    ed.copyTo(widget.config.peers[i]);
                    return null;
                  },
                ),
                boxH10,
                TextFormField(
                  controller: ed.keepAlive,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Persistent keepalive (seconds)',
                    helperText: 'Optional',
                  ),
                  onChanged: (_) => ed.copyTo(widget.config.peers[i]),
                ),
                boxH10,
                TextFormField(
                  controller: ed.allowedIps,
                  minLines: 2,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Allowed IPs',
                    helperText: 'One per line or comma-separated',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context)!.fieldRequired;
                    }
                    ed.copyTo(widget.config.peers[i]);
                    return null;
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
