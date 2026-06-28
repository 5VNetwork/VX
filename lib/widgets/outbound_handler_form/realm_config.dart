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

class HysteriaRealmConfig extends StatefulWidget {
  const HysteriaRealmConfig({
    super.key,
    required this.config,
    this.server = false,
  });

  final RealmConfig config;
  final bool server;

  @override
  State<HysteriaRealmConfig> createState() => _HysteriaRealmConfigState();
}

class _HysteriaRealmConfigState extends State<HysteriaRealmConfig> {
  late bool _insecure;
  late bool _portMappingEnabled;
  late TextEditingController _realmUrlController;
  late TextEditingController _localPortController;
  late TextEditingController _stunServersController;
  late TextEditingController _stunTimeoutController;
  late TextEditingController _punchTimeoutController;
  late TextEditingController _heartbeatController;
  late TextEditingController _portMapTimeoutController;
  late TextEditingController _portMapLifetimeController;
  String _ipMode = 'dual';
  bool _advancedExpanded = false;

  @override
  void initState() {
    super.initState();
    final parsed = parseRealmAddr(widget.config.realmAddr);
    _insecure = widget.config.insecure || (parsed?.insecure ?? false);
    _portMappingEnabled =
        widget.config.hasPortMapping() && widget.config.portMapping.enabled;
    _realmUrlController = TextEditingController(text: widget.config.realmAddr);
    _localPortController = TextEditingController(
      text: widget.config.localPort == 0
          ? ''
          : widget.config.localPort.toString(),
    );
    _stunServersController = TextEditingController(
      text: widget.config.stunServers.join(','),
    );
    _stunTimeoutController = TextEditingController(
      text: widget.config.stunTimeout == 0
          ? ''
          : widget.config.stunTimeout.toString(),
    );
    _punchTimeoutController = TextEditingController(
      text: widget.config.punchTimeout == 0
          ? ''
          : widget.config.punchTimeout.toString(),
    );
    _heartbeatController = TextEditingController(
      text: widget.config.heartbeatInterval == 0
          ? ''
          : widget.config.heartbeatInterval.toString(),
    );
    _portMapTimeoutController = TextEditingController(
      text:
          widget.config.hasPortMapping() &&
              widget.config.portMapping.timeout != 0
          ? widget.config.portMapping.timeout.toString()
          : '',
    );
    _portMapLifetimeController = TextEditingController(
      text:
          widget.config.hasPortMapping() &&
              widget.config.portMapping.lifetime != 0
          ? widget.config.portMapping.lifetime.toString()
          : '',
    );
    _ipMode = widget.config.ipMode.isEmpty ? 'dual' : widget.config.ipMode;
    _realmUrlController.addListener(_applyConfig);
    _localPortController.addListener(_applyConfig);
    _stunServersController.addListener(_applyConfig);
    _stunTimeoutController.addListener(_applyConfig);
    _punchTimeoutController.addListener(_applyConfig);
    _heartbeatController.addListener(_applyConfig);
    _portMapTimeoutController.addListener(_applyConfig);
    _portMapLifetimeController.addListener(_applyConfig);
  }

  void _unbindConfigControllers() {
    _realmUrlController.removeListener(_applyConfig);
    _localPortController.removeListener(_applyConfig);
    _stunServersController.removeListener(_applyConfig);
    _stunTimeoutController.removeListener(_applyConfig);
    _punchTimeoutController.removeListener(_applyConfig);
    _heartbeatController.removeListener(_applyConfig);
    _portMapTimeoutController.removeListener(_applyConfig);
    _portMapLifetimeController.removeListener(_applyConfig);
  }

  @override
  void dispose() {
    _unbindConfigControllers();
    _realmUrlController.dispose();
    _localPortController.dispose();
    _stunServersController.dispose();
    _stunTimeoutController.dispose();
    _punchTimeoutController.dispose();
    _heartbeatController.dispose();
    _portMapTimeoutController.dispose();
    _portMapLifetimeController.dispose();
    super.dispose();
  }

  void _applyConfig() {
    final url = _realmUrlController.text.trim();
    widget.config.realmAddr = url;
    widget.config.localPort =
        int.tryParse(_localPortController.text.trim()) ?? 0;

    widget.config.stunServers.clear();
    for (final part in _stunServersController.text.split(RegExp(r'[,\n]+'))) {
      final s = part.trim();
      if (s.isNotEmpty) {
        widget.config.stunServers.add(s);
      }
    }

    widget.config.stunTimeout = int.tryParse(_stunTimeoutController.text) ?? 0;
    widget.config.punchTimeout =
        int.tryParse(_punchTimeoutController.text) ?? 0;
    widget.config.heartbeatInterval =
        int.tryParse(_heartbeatController.text) ?? 0;
    widget.config.ipMode = _ipMode;

    if (_portMappingEnabled) {
      widget.config.portMapping = RealmPortMappingConfig(
        enabled: true,
        timeout: int.tryParse(_portMapTimeoutController.text) ?? 0,
        lifetime: int.tryParse(_portMapLifetimeController.text) ?? 0,
      );
    } else {
      widget.config.clearPortMapping();
    }
  }

  Future<void> _generateRealmUrl(String host, {required bool proOnly}) async {
    if (proOnly && context.read<AuthBloc>().state.user?.isProUser != true) {
      showProPromotionDialog(context);
      return;
    }
    final deviceId = context.read<SharedPreferences>().uniqueDeviceId;
    String? rendezvousPassword;
    if (host == defaultRealmRendezvousHost) {
      try {
        rendezvousPassword = await fetchRealmSecret();
      } catch (e) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        return;
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _realmUrlController.text = generateRealmUrl(
        deviceId: deviceId,
        existingUrl: _realmUrlController.text,
        insecure: _insecure,
        host: host,
        rendezvousPassword: rendezvousPassword,
      );
    });
  }

  void _setInsecure(bool value) {
    setState(() {
      _insecure = value;
      _applyConfig();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _realmUrlController,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n.realmUrl,
            hintText: l10n.realmUrlHint,
            helper: widget.server
                ? Align(
                    alignment: Alignment.centerRight,
                    child: MenuAnchor(
                      menuChildren: [
                        MenuItemButton(
                          onPressed: () => _generateRealmUrl(
                            publicRealmRendezvousHost,
                            proOnly: false,
                          ),
                          child: Text(publicRealmRendezvousHost),
                        ),
                        MenuItemButton(
                          onPressed:
                              context.read<AuthBloc>().state.user?.isProUser !=
                                  true
                              ? null
                              : () => _generateRealmUrl(
                                  defaultRealmRendezvousHost,
                                  proOnly: true,
                                ),
                          child: AppendProIcon(
                            child: Text(defaultRealmRendezvousHost),
                          ),
                        ),
                      ],
                      builder: (context, controller, child) => TextButton(
                        onPressed: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                        child: Text(l10n.generateRealmUrl),
                      ),
                    ),
                  )
                : null,
          ),
        ),
        boxH10,
        TextFormField(
          controller: _localPortController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: l10n.realmLocalPort,
            helperText: l10n.realmLocalPortHelper,
          ),
        ),
        boxH10,
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.insecureRendezvous),
          subtitle: Text(l10n.insecureRendezvousDesc),
          value: _insecure,
          onChanged: _setInsecure,
        ),
        boxH10,
        ExpansionPanelList(
          elevation: 0,
          expandedHeaderPadding: EdgeInsets.zero,
          expansionCallback: (_, __) {
            setState(() {
              _advancedExpanded = !_advancedExpanded;
            });
          },
          children: [
            ExpansionPanel(
              isExpanded: _advancedExpanded,
              canTapOnHeader: true,
              headerBuilder: (context, isExpanded) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: Text(
                      l10n.advanced,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                );
              },
              body: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _stunServersController,
                      decoration: InputDecoration(
                        labelText: l10n.stunServers,
                        hintText: l10n.stunServersHint,
                      ),
                    ),
                    boxH10,
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stunTimeoutController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: l10n.stunTimeoutSeconds,
                            ),
                          ),
                        ),
                        const Gap(5),
                        Expanded(
                          child: TextFormField(
                            controller: _punchTimeoutController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: l10n.punchTimeoutSeconds,
                            ),
                          ),
                        ),
                      ],
                    ),
                    boxH10,
                    TextFormField(
                      controller: _heartbeatController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: l10n.heartbeatIntervalSeconds,
                      ),
                    ),
                    boxH10,
                    DropdownMenu<String>(
                      initialSelection: _ipMode,
                      label: Text(l10n.ipMode),
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'dual', label: 'dual'),
                        DropdownMenuEntry(value: 'v4', label: 'v4'),
                        DropdownMenuEntry(value: 'v6', label: 'v6'),
                      ],
                      onSelected: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _ipMode = value;
                          _applyConfig();
                        });
                      },
                    ),
                    boxH10,
                    Row(
                      children: [
                        Text(
                          l10n.portMappingUpnp,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Switch(
                          value: _portMappingEnabled,
                          onChanged: (value) {
                            setState(() {
                              _portMappingEnabled = value;
                              _applyConfig();
                            });
                          },
                        ),
                      ],
                    ),
                    if (_portMappingEnabled) ...[
                      boxH10,
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _portMapTimeoutController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: l10n.mappingTimeoutSeconds,
                              ),
                            ),
                          ),
                          const Gap(5),
                          Expanded(
                            child: TextFormField(
                              controller: _portMapLifetimeController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: l10n.mappingLifetimeSeconds,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

void clearRealmConfig(RealmConfig config) {
  config.clearRealmAddr();
  config.localPort = 0;
  config.insecure = false;
  config.stunServers.clear();
  config.stunTimeout = 0;
  config.punchTimeout = 0;
  config.heartbeatInterval = 0;
  config.ipMode = '';
  config.clearPortMapping();
}

bool hysteriaRealmEnabled(RealmConfig? config) {
  return config != null && config.realmAddr.isNotEmpty;
}
