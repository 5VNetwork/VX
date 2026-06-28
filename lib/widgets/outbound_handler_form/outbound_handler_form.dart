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
import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:flutter_common/util/net.dart';
import 'package:protobuf/protobuf.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/pref_helper.dart';
import 'package:tm/protos/vx/common/net/net.pb.dart';
import 'package:protobuf/well_known_types/google/protobuf/any.pb.dart';
import 'package:tm/protos/vx/inbound/inbound.pb.dart';
import 'package:tm/protos/vx/proxy/anytls/anytls.pb.dart';
import 'package:tm/protos/vx/proxy/dokodemo/dokodemo.pb.dart';
import 'package:tm/protos/vx/proxy/http/http.pb.dart';
import 'package:tm/protos/vx/proxy/hysteria/hysteria.pb.dart';
import 'package:tm/protos/vx/proxy/shadowsocks/shadowsocks.pb.dart';
import 'package:tm/protos/vx/proxy/shadowsocks2022/shadowsocks2022.pb.dart';
import 'package:tm/protos/vx/proxy/socks/socks.pb.dart';
import 'package:tm/protos/vx/proxy/trojan/trojan.pb.dart';
import 'package:tm/protos/vx/proxy/vless/vless.pb.dart';
import 'package:tm/protos/vx/proxy/vmess/vmess.pb.dart';
import 'package:tm/protos/vx/proxy/wireguard/config.pb.dart';
import 'package:tm/protos/vx/user/user.pb.dart';
import 'package:tm/protos/vx/transport/security/tls/certificate.pb.dart';
import 'package:tm/protos/vx/transport/protocols/grpc/config.pb.dart';
import 'package:tm/protos/vx/transport/protocols/http/config.pb.dart';
import 'package:tm/protos/vx/transport/protocols/httpupgrade/config.pb.dart';
import 'package:tm/protos/vx/transport/protocols/kcp/config.pb.dart';
import 'package:tm/protos/vx/transport/protocols/tcp/config.pb.dart';
import 'package:tm/protos/vx/transport/protocols/websocket/config.pb.dart';
import 'package:tm/protos/vx/transport/security/reality/config.pb.dart';
import 'package:tm/protos/vx/outbound/outbound.pb.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:tm/protos/vx/transport/transport.pb.dart';
import 'package:vx/app/routing/routing_page.dart';
import 'package:vx/common/config.dart';
import 'package:vx/utils/realm.dart';
import 'package:vx/utils/realm_secret.dart';
import 'package:vx/common/const.dart';
import 'package:vx/common/net.dart';
import 'package:vx/theme.dart';
import 'package:uuid/uuid.dart';
import 'package:tm/protos/vx/transport/headers/http/config.pb.dart'
    as http_header;
import 'package:tm/protos/vx/transport/headers/noop/config.pb.dart'
    as noop_header;
import 'package:tm/protos/vx/transport/headers/wireguard/config.pb.dart'
    as wireguard_header;
import 'package:tm/protos/vx/transport/headers/wechat/config.pb.dart'
    as wechat_header;
import 'package:tm/protos/vx/transport/headers/utp/config.pb.dart'
    as utp_header;
import 'package:tm/protos/vx/transport/headers/srtp/config.pb.dart'
    as srtp_header;
import 'package:tm/protos/vx/transport/headers/tls/config.pb.dart'
    as tls_header;
import 'package:tm/protos/vx/transport/protocols/splithttp/config.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:tm/protos/vx/transport/security/tls/tls.pb.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/xapi_client.dart';
import 'package:vx/widgets/add_button.dart';
import 'package:vx/widgets/delete_menu_anchor.dart';
import 'package:vx/widgets/form_container.dart';
import 'package:vx/widgets/form_dialog.dart';
import 'package:vx/widgets/pro_icon.dart';
import 'package:vx/widgets/pro_promotion.dart';
import 'package:vx/widgets/text_divider.dart';
part 'transport.dart';
part 'transport_header.dart';
part 'transport_protocol.dart';
part 'transport_security.dart';
part 'proxy.dart';
part 'realm_config.dart';
part 'inbound_form.dart';

/// Collect some fields of OutboundHandler.
class OutboundHandlerForm extends StatefulWidget {
  const OutboundHandlerForm({
    super.key,
    this.config,
    required this.formKey,
    this.onNameChanged,
  });
  final OutboundHandlerConfig? config;
  final GlobalKey<FormState> formKey;
  final Function(String)? onNameChanged;

  @override
  State<OutboundHandlerForm> createState() => OutboundHandlerFormState();
}

class OutboundHandlerFormState extends State<OutboundHandlerForm>
    with OutboundHandlerConfigGetter {
  ProxyProtocolLabel _selectedProtocolLabel = ProxyProtocolLabel.vmess;
  late DropdownMenu<ProxyProtocolLabel> _menu;
  VmessClientConfig _vmessConfig = VmessClientConfig(
    security: SecurityType.SecurityType_AUTO,
  );
  TrojanClientConfig _trojanConfig = TrojanClientConfig();
  VlessClientConfig _vlessConfig = VlessClientConfig(encryption: "none");
  ShadowsocksClientConfig _shadowsocksConfig = ShadowsocksClientConfig();
  Shadowsocks2022ClientConfig _shadowsocks2022Config =
      Shadowsocks2022ClientConfig(method: '2022-blake3-aes-128-gcm');
  SocksClientConfig _socksConfig = SocksClientConfig();
  AnytlsClientConfig _anytlsConfig = AnytlsClientConfig();
  Hysteria2ClientConfig _hysteriaConfig = _getDefaultHysteriaConfig();
  HttpClientConfig _httpConfig = HttpClientConfig(account: Account());
  DeviceConfig _wireguardConfig = DeviceConfig();

  TextFormField? _name;
  final _nameController = TextEditingController();
  final _serverAddress = TextEditingController();
  final _port = TextEditingController();
  final _onePortIntervalController = TextEditingController();
  final _onePortMinIntervalController = TextEditingController();
  final _onePortMaxIntervalController = TextEditingController();
  final _muxConcurrencyController = TextEditingController();
  final _muxConnectionController = TextEditingController();
  bool _enableMux = false;
  _PortSelectStrategyUi _portSelectStrategy = _PortSelectStrategyUi.random;

  bool _enableUdpOverTcp = false;
  final _transportInputGlobalKey = GlobalKey<_TransportInputState>();
  late DomainStrategy _domainStrategy;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.config?.tag ?? '';
    _serverAddress.text = widget.config?.address ?? '';
    _port.text = portString(widget.config ?? OutboundHandlerConfig());
    _port.addListener(_onPortChanged);
    if (widget.config != null) {
      switch (widget.config!.whichPortSelectStrategy()) {
        case OutboundHandlerConfig_PortSelectStrategy.one:
          _portSelectStrategy = _PortSelectStrategyUi.one;
          final one = widget.config!.one;
          if (one.interval != 0) {
            _onePortIntervalController.text = one.interval.toString();
          }
          if (one.minInterval != 0) {
            _onePortMinIntervalController.text = one.minInterval.toString();
          }
          if (one.maxInterval != 0) {
            _onePortMaxIntervalController.text = one.maxInterval.toString();
          }
          break;
        case OutboundHandlerConfig_PortSelectStrategy.random:
        case OutboundHandlerConfig_PortSelectStrategy.notSet:
          _portSelectStrategy = _PortSelectStrategyUi.random;
          break;
      }
    }
    // if (widget.handler?.config.transport != null) {
    //   _transportConfig.mergeFromMessage(widget.handler!.config.transport);
    // }
    _enableMux = widget.config?.enableMux ?? false;
    _enableUdpOverTcp = widget.config?.uot ?? false;
    _domainStrategy = widget.config?.domainStrategy ?? DomainStrategy.Speed;
    if (widget.config?.muxConfig != null) {
      _muxConcurrencyController.text =
          (widget.config!.muxConfig.maxConcurrency == 0
          ? '1'
          : widget.config!.muxConfig.maxConcurrency.toString());
      _muxConnectionController.text =
          (widget.config!.muxConfig.maxConnection == 0
          ? '16'
          : widget.config!.muxConfig.maxConnection.toString());
    } else {
      _muxConcurrencyController.text = '2';
      _muxConnectionController.text = '16';
    }
    if (widget.config?.protocol != null) {
      final any = widget.config!.protocol;
      _selectedProtocolLabel = getProtocolTypeFromAny(any);
      switch (_selectedProtocolLabel) {
        case ProxyProtocolLabel.vmess:
          _vmessConfig = any.unpackInto(_vmessConfig);
        case ProxyProtocolLabel.trojan:
          _trojanConfig = any.unpackInto(_trojanConfig);
        case ProxyProtocolLabel.vless:
          _vlessConfig = any.unpackInto(_vlessConfig);
        case ProxyProtocolLabel.shadowsocks:
          _shadowsocksConfig = any.unpackInto(_shadowsocksConfig);
        case ProxyProtocolLabel.shadowsocks2022:
          _shadowsocks2022Config = any.unpackInto(_shadowsocks2022Config);
        case ProxyProtocolLabel.socks:
          _socksConfig = any.unpackInto(_socksConfig);
        case ProxyProtocolLabel.hysteria2:
          _hysteriaConfig = any.unpackInto(_hysteriaConfig);
          // make it writable
          _hysteriaConfig.tlsConfig = _hysteriaConfig.tlsConfig.deepCopy();
        case ProxyProtocolLabel.anytls:
          _anytlsConfig = any.unpackInto(_anytlsConfig);
        case ProxyProtocolLabel.http:
          _httpConfig = any.unpackInto(_httpConfig);
        case ProxyProtocolLabel.wireguard:
          _wireguardConfig = any.unpackInto(_wireguardConfig);
        default:
          throw Exception('Unexpected protocol: $_selectedProtocolLabel');
      }
    }
  }

  @override
  OutboundHandlerConfig get outboundHandler {
    late final Any protocol;
    switch (_selectedProtocolLabel) {
      case ProxyProtocolLabel.vmess:
        protocol = Any.pack(_vmessConfig);
      case ProxyProtocolLabel.trojan:
        protocol = Any.pack(_trojanConfig);
      case ProxyProtocolLabel.vless:
        protocol = Any.pack(_vlessConfig);
      case ProxyProtocolLabel.shadowsocks:
        protocol = Any.pack(_shadowsocksConfig);
      case ProxyProtocolLabel.shadowsocks2022:
        protocol = Any.pack(_shadowsocks2022Config);
      case ProxyProtocolLabel.socks:
        protocol = Any.pack(_socksConfig);
      case ProxyProtocolLabel.hysteria2:
        protocol = Any.pack(_hysteriaConfig);
      case ProxyProtocolLabel.anytls:
        protocol = Any.pack(_anytlsConfig);
      case ProxyProtocolLabel.http:
        protocol = Any.pack(_httpConfig);
      case ProxyProtocolLabel.wireguard:
        protocol = Any.pack(_wireguardConfig);
      default:
        throw Exception('Unexpected protocol: $_selectedProtocolLabel');
      // _transportConfig.clear();
    }
    final wireguard = _selectedProtocolLabel == ProxyProtocolLabel.wireguard;
    final hasMultiplePorts = _hasMultiplePorts;
    final onePortStrategy = _portSelectStrategy == _PortSelectStrategyUi.one;
    final onePortInterval = int.tryParse(_onePortIntervalController.text) ?? 0;
    final onePortMinInterval =
        int.tryParse(_onePortMinIntervalController.text) ?? 0;
    final onePortMaxInterval =
        int.tryParse(_onePortMaxIntervalController.text) ?? 0;
    return OutboundHandlerConfig(
      tag: _nameController.text,
      address: wireguard ? '' : _serverAddress.text,
      // port: int.tryParse(_port.text),
      ports: wireguard ? null : tryParsePorts(_port.text),
      domainStrategy: _domainStrategy,
      enableMux: wireguard ? false : _enableMux,
      uot: wireguard ? false : _enableUdpOverTcp,
      transport: wireguard
          ? null
          : _transportInputGlobalKey.currentState?.transportConfig,
      protocol: protocol,
      muxConfig: (!wireguard && _enableMux)
          ? MuxConfig(
              maxConcurrency: int.parse(_muxConcurrencyController.text),
              maxConnection: int.parse(_muxConnectionController.text),
            )
          : null,
      random: (!wireguard && hasMultiplePorts && !onePortStrategy)
          ? RandomPortSelectStrategy()
          : null,
      one: (!wireguard && hasMultiplePorts && onePortStrategy)
          ? OnePortSelectStrategy(
              interval: onePortInterval,
              minInterval: onePortMinInterval,
              maxInterval: onePortMaxInterval,
            )
          : null,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _serverAddress.dispose();
    _port.removeListener(_onPortChanged);
    _muxConcurrencyController.dispose();
    _muxConnectionController.dispose();
    _port.dispose();
    _onePortIntervalController.dispose();
    _onePortMinIntervalController.dispose();
    _onePortMaxIntervalController.dispose();
    super.dispose();
  }

  void _onPortChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _hasMultiplePorts {
    final ports = tryParsePorts(_port.text.trim());
    if (ports == null) {
      return false;
    }
    var totalPortCount = 0;
    for (final range in ports) {
      totalPortCount += (range.to - range.from + 1);
      if (totalPortCount > 1) {
        return true;
      }
    }
    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _name = TextFormField(
      controller: _nameController,
      onChanged: widget.onNameChanged,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          if (value == directEN || value == 'dns') {
            return AppLocalizations.of(
              context,
            )!.outboundNameCannotBeDirectOrDns;
          }
        }
        return null;
      },
      decoration: InputDecoration(
        constraints: const BoxConstraints(maxWidth: 200),
        labelText: AppLocalizations.of(context)!.name,
      ).applyDefaults(Theme.of(context).inputDecorationTheme),
    );
    _menu = DropdownMenu<ProxyProtocolLabel>(
      textStyle: const TextStyle(color: XBlue),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: XBlue),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: XBlue, width: 1.5),
        ),
      ),
      requestFocusOnTap: false,
      initialSelection: _selectedProtocolLabel,
      label: Text(AppLocalizations.of(context)!.protocol),
      onSelected: (ProxyProtocolLabel? l) {
        if (l != null) {
          _selectedProtocolLabel = l;
          // if (l == ProxyProtocolLabel.hysteria2) {
          //   _transportConfig.clear();
          // }
        }
        setState(() {});
      },
      dropdownMenuEntries: ProxyProtocolLabel.values
          .where((p) => p != ProxyProtocolLabel.dokodemo)
          .map<DropdownMenuEntry<ProxyProtocolLabel>>((ProxyProtocolLabel p) {
            return DropdownMenuEntry<ProxyProtocolLabel>(
              label: p.label,
              value: p,
            );
          })
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _menu,
                const Gap(10),
                Expanded(child: _name!),
              ],
            ),
            boxH10,
            if (_selectedProtocolLabel != ProxyProtocolLabel.wireguard) ...[
              TextFormField(
                controller: _serverAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(
                      context,
                    )!.outboundServerAddressCannotBeEmpty;
                  }
                  _serverAddress.text = value;
                  return null;
                },
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.address,
                  hintText: AppLocalizations.of(context)!.ipOrDomain,
                ).applyDefaults(Theme.of(context).inputDecorationTheme),
              ),
              boxH10,
              TextFormField(
                controller: _port,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(
                      context,
                    )!.outboundPortCannotBeEmpty;
                  }
                  if (int.tryParse(value) != null) {
                    return null;
                  }
                  if (tryParsePorts(value) != null) {
                    return null;
                  }
                  return AppLocalizations.of(context)!.invalidPort;
                },
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.port,
                  hintText: AppLocalizations.of(
                    context,
                  )!.outboundPortHintExample,
                ).applyDefaults(Theme.of(context).inputDecorationTheme),
              ),
              const Gap(10),
              if (_hasMultiplePorts) ...[
                DropdownMenu<_PortSelectStrategyUi>(
                  initialSelection: _portSelectStrategy,
                  label: Text(
                    AppLocalizations.of(context)!.outboundPortSelectStrategy,
                  ),
                  onSelected: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _portSelectStrategy = value;
                    });
                  },
                  dropdownMenuEntries: [
                    DropdownMenuEntry(
                      value: _PortSelectStrategyUi.random,
                      label: AppLocalizations.of(
                        context,
                      )!.outboundPortStrategyRandomAllPortsSameTime,
                    ),
                    DropdownMenuEntry(
                      value: _PortSelectStrategyUi.one,
                      label: AppLocalizations.of(
                        context,
                      )!.outboundPortStrategyOneSwitchByInterval,
                    ),
                  ],
                ),
                const Gap(8),
                if (_portSelectStrategy == _PortSelectStrategyUi.one)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextFormField(
                      controller: _onePortIntervalController,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (!_hasMultiplePorts ||
                            _portSelectStrategy != _PortSelectStrategyUi.one) {
                          return null;
                        }
                        final interval = value?.trim() ?? '';
                        final min = _onePortMinIntervalController.text.trim();
                        final max = _onePortMaxIntervalController.text.trim();
                        if (interval.isEmpty && (min.isEmpty || max.isEmpty)) {
                          return AppLocalizations.of(
                            context,
                          )!.outboundSetIntervalOrMinMax;
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(
                          context,
                        )!.outboundPortSwitchIntervalSeconds,
                        helperText: AppLocalizations.of(
                          context,
                        )!.outboundPortSwitchIntervalHelper,
                      ),
                    ),
                  ),
                if (_portSelectStrategy == _PortSelectStrategyUi.one)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _onePortMinIntervalController,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (!_hasMultiplePorts ||
                                  _portSelectStrategy !=
                                      _PortSelectStrategyUi.one) {
                                return null;
                              }
                              final interval = _onePortIntervalController.text
                                  .trim();
                              if (interval.isNotEmpty) {
                                return null;
                              }
                              if ((value?.trim() ?? '').isEmpty) {
                                return AppLocalizations.of(
                                  context,
                                )!.outboundRequiredWhenIntervalEmpty;
                              }
                              final min = int.tryParse(value!.trim());
                              final max = int.tryParse(
                                _onePortMaxIntervalController.text.trim(),
                              );
                              if (min == null || max == null) {
                                return null;
                              }
                              if (min > max) {
                                return AppLocalizations.of(
                                  context,
                                )!.outboundMinIntervalMustBeLeqMax;
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              )!.outboundMinIntervalSeconds,
                            ),
                          ),
                        ),
                        const Gap(10),
                        Expanded(
                          child: TextFormField(
                            controller: _onePortMaxIntervalController,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (!_hasMultiplePorts ||
                                  _portSelectStrategy !=
                                      _PortSelectStrategyUi.one) {
                                return null;
                              }
                              final interval = _onePortIntervalController.text
                                  .trim();
                              if (interval.isNotEmpty) {
                                return null;
                              }
                              if ((value?.trim() ?? '').isEmpty) {
                                return AppLocalizations.of(
                                  context,
                                )!.outboundRequiredWhenIntervalEmpty;
                              }
                              final max = int.tryParse(value!.trim());
                              final min = int.tryParse(
                                _onePortMinIntervalController.text.trim(),
                              );
                              if (min == null || max == null) {
                                return null;
                              }
                              if (max < min) {
                                return AppLocalizations.of(
                                  context,
                                )!.outboundMaxIntervalMustBeGeqMin;
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(
                                context,
                              )!.outboundMaxIntervalSeconds,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
            DropdownMenu(
              label: Text(AppLocalizations.of(context)!.domainStrategy),
              initialSelection: _domainStrategy,
              onSelected: (value) {
                setState(() {
                  _domainStrategy = value!;
                });
              },
              dropdownMenuEntries: DomainStrategy.values
                  .map((e) => DropdownMenuEntry(label: e.toString(), value: e))
                  .toList(),
            ),
            const Gap(4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                AppLocalizations.of(context)!.domainStrategyDesc,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Gap(10),
            if (_selectedProtocolLabel != ProxyProtocolLabel.hysteria2 &&
                _selectedProtocolLabel != ProxyProtocolLabel.wireguard)
              Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      AppLocalizations.of(context)!.outboundMux,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    value: _enableMux,
                    onChanged: (v) {
                      setState(() {
                        _enableMux = v;
                      });
                    },
                  ),
                  if (_enableMux)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _muxConcurrencyController,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(
                                    context,
                                  )!.fieldRequired;
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(
                                  context,
                                )!.maxConcurrency,
                                helperText: AppLocalizations.of(
                                  context,
                                )!.maxConcurrency,
                              ),
                            ),
                          ),
                          const Gap(10),
                          Expanded(
                            child: TextFormField(
                              controller: _muxConnectionController,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(
                                    context,
                                  )!.fieldRequired;
                                }
                                return null;
                              },
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(
                                  context,
                                )!.maxConnection,
                                helperText: AppLocalizations.of(
                                  context,
                                )!.maxConnection,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_selectedProtocolLabel == ProxyProtocolLabel.vmess ||
                      _selectedProtocolLabel == ProxyProtocolLabel.socks ||
                      _selectedProtocolLabel ==
                          ProxyProtocolLabel.shadowsocks ||
                      _selectedProtocolLabel ==
                          ProxyProtocolLabel.shadowsocks2022 ||
                      _selectedProtocolLabel == ProxyProtocolLabel.vless)
                    SwitchListTile(
                      title: Text(
                        AppLocalizations.of(context)!.outboundUdpOverTcp,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context)!.uotDesc,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: _enableUdpOverTcp,
                      onChanged: (v) {
                        setState(() {
                          _enableUdpOverTcp = v;
                        });
                      },
                    ),
                  const Gap(10),
                ],
              ),
            if (_selectedProtocolLabel == ProxyProtocolLabel.vmess)
              _VmessClient(config: _vmessConfig),
            if (_selectedProtocolLabel == ProxyProtocolLabel.trojan)
              _TrojanClient(config: _trojanConfig),
            if (_selectedProtocolLabel == ProxyProtocolLabel.vless)
              _VlessClient(config: _vlessConfig),
            if (_selectedProtocolLabel == ProxyProtocolLabel.shadowsocks)
              _ShadowsocksClient(config: _shadowsocksConfig),
            if (_selectedProtocolLabel == ProxyProtocolLabel.shadowsocks2022)
              _Shadowsocks2022Client(config: _shadowsocks2022Config),
            if (_selectedProtocolLabel == ProxyProtocolLabel.socks)
              _SocksClient(config: _socksConfig),
            if (_selectedProtocolLabel == ProxyProtocolLabel.hysteria2)
              HysteriaClient(config: _hysteriaConfig),
            if (_selectedProtocolLabel == ProxyProtocolLabel.anytls)
              _AnytlsClient(config: _anytlsConfig),
            if (_selectedProtocolLabel == ProxyProtocolLabel.http)
              _HttpClient(config: _httpConfig),
            if (_selectedProtocolLabel == ProxyProtocolLabel.wireguard)
              _WireguardClient(config: _wireguardConfig),
            const Gap(10),
            if (_selectedProtocolLabel != ProxyProtocolLabel.hysteria2 &&
                _selectedProtocolLabel != ProxyProtocolLabel.wireguard)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Divider(height: 1)),
                      const Gap(10),
                      Text(
                        AppLocalizations.of(context)!.outboundStream,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Gap(10),
                      const Expanded(child: Divider(height: 1)),
                    ],
                  ),
                  const Gap(10),
                  _TransportInput(
                    key: _transportInputGlobalKey,
                    config: widget.config?.transport,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

enum TransportHeaderLabel {
  srtp('SRTP'),
  utp('UTP'),
  wechatvideo('WeChat Video'),
  dtls('DTLS'),
  wireguard('WireGuard'),
  http('HTTP'),
  tls('TLS');

  const TransportHeaderLabel(this.label);
  final String label;
}

mixin OutboundHandlerConfigGetter {
  OutboundHandlerConfig get outboundHandler;
}

mixin TransportConfigGetter {
  TransportConfig? get transportConfig;
}

enum _PortSelectStrategyUi { random, one }
