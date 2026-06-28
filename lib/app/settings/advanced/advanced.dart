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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/vx/tun/tun.pb.dart';
import 'package:vx/app/routing/repo.dart';
import 'package:vx/app/settings/advanced/system_proxy.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/data/database.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:vx/app/settings/advanced/proxy_share.dart';
import 'package:vx/app/settings/advanced/hysteria_realm.dart';
import 'package:vx/pref_helper.dart';

class AdvancedScreen extends StatelessWidget {
  const AdvancedScreen({super.key, this.showAppBar = true});
  final bool showAppBar;

  static void _showTunDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        VoidCallback? applyTun;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(l10n.tunIpv6Settings),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: double.maxFinite,
                  child: TunSetting(
                    onRegisterApply: (apply) {
                      applyTun = apply;
                      setDialogState(() {});
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: applyTun == null
                      ? null
                      : () {
                          applyTun!();
                          Navigator.of(ctx).pop();
                        },
                  child: Text(l10n.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? AppBar(title: Text(AppLocalizations.of(context)!.advanced))
          : null,
      body: Padding(
        padding: const EdgeInsets.only(top: 8, right: 8),
        child: ListView(
          children: [
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: Text(
                AppLocalizations.of(context)!.proxyShare,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              trailing: const Icon(Icons.keyboard_arrow_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (ctx) {
                      return ProxyShareSettingScreen(fullscreen: showAppBar);
                    },
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: Text(
                AppLocalizations.of(context)!.hysteriaRealm,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              trailing: const Icon(Icons.keyboard_arrow_right_rounded),
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (ctx) {
                      return HysteriaRealmSettingScreen(
                        fullscreen: showAppBar,
                      );
                    },
                  ),
                );
              },
            ),
            const Divider(),
            const SniffSetting(),
            const Divider(),
            const FallbackSetting(),
            const Divider(),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              title: Text(
                AppLocalizations.of(context)!.tunIpv6Settings,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              trailing: const Icon(Icons.keyboard_arrow_right_rounded),
              onTap: () => _showTunDialog(context),
            ),
            const Divider(),
            const SystemProxySetting(),
            const Divider(),
            const RejectQuicHysteriaSetting(),
            const Divider(),
            const DialerSetting(),
            const Divider(),
            const PolicyTimeoutSetting(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class SniffSetting extends StatefulWidget {
  const SniffSetting({super.key});

  @override
  State<SniffSetting> createState() => _SniffSettingState();
}

class _SniffSettingState extends State<SniffSetting> {
  bool _sniffing = false;

  @override
  void initState() {
    super.initState();
    _sniffing = context.read<SharedPreferences>().sniff;
  }

  void _toggleSniffing(bool value) {
    context.read<SharedPreferences>().setSniff(value);
    setState(() {
      _sniffing = value;
    });
    context.read<XController>().restart();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.sniff,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Switch(value: _sniffing, onChanged: _toggleSniffing),
            ],
          ),
        ],
      ),
    );
  }
}

class FallbackSetting extends StatefulWidget {
  const FallbackSetting({super.key});

  @override
  State<FallbackSetting> createState() => _FallbackSettingState();
}

class _FallbackSettingState extends State<FallbackSetting> {
  bool _changeIpv6ToDomain = false;
  bool _automaticallyAddFallbackDomain = false;
  late final TextEditingController _fallbackTimeoutController;

  @override
  void initState() {
    super.initState();
    final pref = context.read<SharedPreferences>();
    _changeIpv6ToDomain = pref.changeIpv6ToDomain;
    _automaticallyAddFallbackDomain = pref.automaticallyAddFallbackDomain;
    _fallbackTimeoutController = TextEditingController(
      text: '${pref.fallbackTimeout}',
    );
  }

  @override
  void dispose() {
    _fallbackTimeoutController.dispose();
    super.dispose();
  }

  void _toggleAutomaticallyAddFallbackDomain(bool value) async {
    setState(() {
      _automaticallyAddFallbackDomain = value;
    });
    context.read<SharedPreferences>().setAutomaticallyAddFallbackDomain(value);
    // update database
    final setRepo = context.read<SetRepo>();
    if (await setRepo.getAtomicDomainSet('Fallback') == null) {
      setRepo.addAtomicDomainSet(
        AtomicDomainSet(name: 'Fallback', useBloomFilter: false),
      );
    }
    context.read<XController>().restart();
  }

  void _toggleChangeIpv6ToDomain(bool value) {
    context.read<SharedPreferences>().setChangeIpv6ToDomain(value);
    setState(() {
      _changeIpv6ToDomain = value;
    });
    context.read<XController>().restart();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.changeIpv6ToDomain,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Switch(
                value: _changeIpv6ToDomain,
                onChanged: _toggleChangeIpv6ToDomain,
              ),
            ],
          ),
          const Gap(5),
          Text(
            AppLocalizations.of(context)!.changeIpv6ToDomainDesc,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.automaticallyAddFallbackDomain,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Switch(
                value: _automaticallyAddFallbackDomain,
                onChanged: _toggleAutomaticallyAddFallbackDomain,
              ),
            ],
          ),
          const Gap(5),
          Text(
            AppLocalizations.of(context)!.automaticallyAddFallbackDomainDesc,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(16),
          TextField(
            controller: _fallbackTimeoutController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.fallbackTimeout,
              helperText: AppLocalizations.of(context)!.fallbackTimeoutDesc,
              helperMaxLines: 5,
              suffixText: AppLocalizations.of(context)!.seconds,
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              context.read<SharedPreferences>().setFallbackTimeout(
                int.parse(value),
              );
            },
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );
  }
}

/// Widget for TUN-related settings: tun IPv4/IPv6 (tun46Setting),
/// reject IPv6, and reject QUIC (all map to [TunConfig] fields).
/// When [onRegisterApply] is non-null (e.g. in a dialog), nothing is written
/// until the parent invokes the registered callback (typically from a dialog
/// Save action).
class TunSetting extends StatefulWidget {
  const TunSetting({super.key, this.onRegisterApply});

  /// Receives [apply], which persists all fields and restarts the controller.
  final void Function(VoidCallback apply)? onRegisterApply;

  @override
  State<TunSetting> createState() => _TunSettingState();
}

class _TunSettingState extends State<TunSetting> {
  bool _rejectIpv6 = false;
  TunConfig_TUN46Setting _tun46Setting = TunConfig_TUN46Setting.DYNAMIC;
  late final TextEditingController _cidr4Controller;
  late final TextEditingController _cidr6Controller;
  late final TextEditingController _dns4Controller;
  late final TextEditingController _dns6Controller;
  late final TextEditingController _routes4Controller;
  late final TextEditingController _routes6Controller;
  late final TextEditingController _mtuController;

  @override
  void initState() {
    super.initState();
    final pref = context.read<SharedPreferences>();
    _rejectIpv6 = pref.rejectIpv6;
    _tun46Setting = pref.tun46Setting;
    _cidr4Controller = TextEditingController(text: pref.tunCidr4);
    _cidr6Controller = TextEditingController(text: pref.tunCidr6);
    _dns4Controller = TextEditingController(text: pref.tunDns4);
    _dns6Controller = TextEditingController(text: pref.tunDns6);
    _routes4Controller = TextEditingController(text: pref.tunRoutes4);
    _routes6Controller = TextEditingController(text: pref.tunRoutes6);
    _mtuController = TextEditingController(text: '${pref.tunMtu}');
    if (widget.onRegisterApply != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onRegisterApply!(_applyAll);
      });
    }
  }

  @override
  void dispose() {
    _cidr4Controller.dispose();
    _cidr6Controller.dispose();
    _dns4Controller.dispose();
    _dns6Controller.dispose();
    _routes4Controller.dispose();
    _routes6Controller.dispose();
    _mtuController.dispose();
    super.dispose();
  }

  bool get _inDialog => widget.onRegisterApply != null;

  void _applyAll() {
    final pref = context.read<SharedPreferences>();
    pref.setTunCidr4(
      _cidr4Controller.text.isEmpty ? null : _cidr4Controller.text,
    );
    pref.setTunCidr6(
      _cidr6Controller.text.isEmpty ? null : _cidr6Controller.text,
    );
    pref.setTunDns4(_dns4Controller.text.isEmpty ? null : _dns4Controller.text);
    pref.setTunDns6(_dns6Controller.text.isEmpty ? null : _dns6Controller.text);
    pref.setTunRoutes4(
      _routes4Controller.text.isEmpty ? null : _routes4Controller.text,
    );
    pref.setTunRoutes6(
      _routes6Controller.text.isEmpty ? null : _routes6Controller.text,
    );
    final mtuStr = _mtuController.text.trim();
    final mtu = mtuStr.isEmpty ? null : int.tryParse(mtuStr);
    pref.setTunMtu(mtu != null && mtu > 0 ? mtu : null);
    pref.setTun46Setting(_tun46Setting);
    pref.setRejectIpv6(_rejectIpv6);
    context.read<XController>().restart();
  }

  void _saveCidr4(String value) {
    context.read<SharedPreferences>().setTunCidr4(value.isEmpty ? null : value);
    context.read<XController>().restart();
  }

  void _saveCidr6(String value) {
    context.read<SharedPreferences>().setTunCidr6(value.isEmpty ? null : value);
    context.read<XController>().restart();
  }

  void _saveDns4(String value) {
    context.read<SharedPreferences>().setTunDns4(value.isEmpty ? null : value);
    context.read<XController>().restart();
  }

  void _saveDns6(String value) {
    context.read<SharedPreferences>().setTunDns6(value.isEmpty ? null : value);
    context.read<XController>().restart();
  }

  void _saveRoutes4(String value) {
    context.read<SharedPreferences>().setTunRoutes4(
      value.isEmpty ? null : value,
    );
    context.read<XController>().restart();
  }

  void _saveRoutes6(String value) {
    context.read<SharedPreferences>().setTunRoutes6(
      value.isEmpty ? null : value,
    );
    context.read<XController>().restart();
  }

  void _saveMtu(String value) {
    final v = value.trim();
    final parsed = v.isEmpty ? null : int.tryParse(v);
    context.read<SharedPreferences>().setTunMtu(
      parsed != null && parsed > 0 ? parsed : null,
    );
    context.read<XController>().restart();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.tunIpv6Settings,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Gap(10),
        DropdownMenu<TunConfig_TUN46Setting>(
          initialSelection: _tun46Setting,
          requestFocusOnTap: false,
          dropdownMenuEntries: [
            DropdownMenuEntry(
              value: TunConfig_TUN46Setting.FOUR_ONLY,
              label: l10n.tun46SettingIpv4Only,
            ),
            DropdownMenuEntry(
              value: TunConfig_TUN46Setting.BOTH,
              label: l10n.tun46SettingIpv4AndIpv6,
            ),
            DropdownMenuEntry(
              value: TunConfig_TUN46Setting.DYNAMIC,
              label: l10n.dependsOnDefaultNic,
            ),
          ],
          onSelected: (value) {
            if (value != null) setState(() => _tun46Setting = value);
          },
        ),
        const Gap(10),
        if (_tun46Setting == TunConfig_TUN46Setting.DYNAMIC)
          Text(
            l10n.dependsOnDefaultNicDesc,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else if (_tun46Setting == TunConfig_TUN46Setting.FOUR_ONLY)
          Text(
            l10n.tunIpv4Desc,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        const Gap(16),
        TextField(
          controller: _cidr4Controller,
          decoration: InputDecoration(
            labelText: l10n.tunCidr4,
            hintText: l10n.tunCidr4Hint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          textInputAction: TextInputAction.next,
          onSubmitted: _inDialog ? null : _saveCidr4,
          onEditingComplete: _inDialog
              ? null
              : () => _saveCidr4(_cidr4Controller.text),
        ),
        const Gap(10),
        TextField(
          controller: _cidr6Controller,
          decoration: InputDecoration(
            labelText: l10n.tunCidr6,
            hintText: l10n.tunCidr6Hint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          textInputAction: TextInputAction.next,
          onSubmitted: _inDialog ? null : _saveCidr6,
          onEditingComplete: _inDialog
              ? null
              : () => _saveCidr6(_cidr6Controller.text),
        ),
        const Gap(10),
        TextField(
          controller: _dns4Controller,
          decoration: InputDecoration(
            labelText: l10n.tunDns4,
            hintText: l10n.tunDns4Hint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          textInputAction: TextInputAction.next,
          onSubmitted: _inDialog ? null : _saveDns4,
          onEditingComplete: _inDialog
              ? null
              : () => _saveDns4(_dns4Controller.text),
        ),
        const Gap(10),
        TextField(
          controller: _dns6Controller,
          decoration: InputDecoration(
            labelText: l10n.tunDns6,
            hintText: l10n.tunDns6Hint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          textInputAction: TextInputAction.next,
          onSubmitted: _inDialog ? null : _saveDns6,
          onEditingComplete: _inDialog
              ? null
              : () => _saveDns6(_dns6Controller.text),
        ),
        const Gap(10),
        TextField(
          controller: _routes4Controller,
          decoration: InputDecoration(
            labelText: l10n.tunRoutes4,
            hintText: l10n.tunRoutes4Hint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          textInputAction: TextInputAction.next,
          onSubmitted: _inDialog ? null : _saveRoutes4,
          onEditingComplete: _inDialog
              ? null
              : () => _saveRoutes4(_routes4Controller.text),
        ),
        const Gap(10),
        TextField(
          controller: _routes6Controller,
          decoration: InputDecoration(
            labelText: l10n.tunRoutes6,
            hintText: l10n.tunRoutes6Hint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          textInputAction: TextInputAction.next,
          onSubmitted: _inDialog ? null : _saveRoutes6,
          onEditingComplete: _inDialog
              ? null
              : () => _saveRoutes6(_routes6Controller.text),
        ),
        const Gap(10),
        TextField(
          controller: _mtuController,
          decoration: InputDecoration(
            labelText: l10n.tunMtu,
            hintText: l10n.tunMtuHint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          onSubmitted: _inDialog ? null : _saveMtu,
          onEditingComplete: _inDialog
              ? null
              : () => _saveMtu(_mtuController.text),
        ),
        const Gap(16),
        SwitchListTile(
          title: Text(
            l10n.tunRejectIpv6,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          subtitle: Text(
            l10n.tunRejectIpv6Desc,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          value: _rejectIpv6,
          onChanged: (value) {
            if (_inDialog) {
              setState(() => _rejectIpv6 = value);
            } else {
              context.read<SharedPreferences>().setRejectIpv6(value);
              setState(() => _rejectIpv6 = value);
              context.read<XController>().restart();
            }
          },
        ),
      ],
    );
  }
}

class TunIpv6Settings extends StatefulWidget {
  const TunIpv6Settings({super.key});

  @override
  State<TunIpv6Settings> createState() => _TunIpv6SettingsState();
}

class _TunIpv6SettingsState extends State<TunIpv6Settings> {
  TunConfig_TUN46Setting _tun46Setting = TunConfig_TUN46Setting.DYNAMIC;

  @override
  void initState() {
    super.initState();
    _tun46Setting = context.read<SharedPreferences>().tun46Setting;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.tunIpv6Settings,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const Gap(10),
        DropdownMenu<TunConfig_TUN46Setting>(
          initialSelection: _tun46Setting,
          requestFocusOnTap: false,
          dropdownMenuEntries: [
            DropdownMenuEntry(
              value: TunConfig_TUN46Setting.FOUR_ONLY,
              label: AppLocalizations.of(context)!.tun46SettingIpv4Only,
            ),
            DropdownMenuEntry(
              value: TunConfig_TUN46Setting.BOTH,
              label: AppLocalizations.of(context)!.tun46SettingIpv4AndIpv6,
            ),
            DropdownMenuEntry(
              value: TunConfig_TUN46Setting.DYNAMIC,
              label: AppLocalizations.of(context)!.dependsOnDefaultNic,
            ),
          ],
          onSelected: (value) {
            context.read<SharedPreferences>().setTun46Setting(
              value ?? TunConfig_TUN46Setting.DYNAMIC,
            );
            setState(() {
              _tun46Setting = value ?? TunConfig_TUN46Setting.DYNAMIC;
            });
            context.read<XController>().restart();
          },
        ),
        const Gap(10),
        if (_tun46Setting == TunConfig_TUN46Setting.DYNAMIC)
          Text(
            AppLocalizations.of(context)!.dependsOnDefaultNicDesc,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else if (_tun46Setting == TunConfig_TUN46Setting.FOUR_ONLY)
          Text(
            AppLocalizations.of(context)!.tunIpv4Desc,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class RejectQuicHysteriaSetting extends StatefulWidget {
  const RejectQuicHysteriaSetting({super.key});

  @override
  State<RejectQuicHysteriaSetting> createState() =>
      _RejectQuicHysteriaSettingState();
}

class _RejectQuicHysteriaSettingState extends State<RejectQuicHysteriaSetting> {
  bool _rejectQuicHysteria = false;

  @override
  void initState() {
    super.initState();
    _rejectQuicHysteria = context.read<SharedPreferences>().rejectQuicHysteria;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.hysteriaRejectQuic,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const Gap(10),
          Switch(
            value: _rejectQuicHysteria,
            onChanged: (value) {
              context.read<SharedPreferences>().setRejectQuicHysteria(value);
              setState(() {
                _rejectQuicHysteria = value;
              });
              context.read<XController>().restart();
            },
          ),
        ],
      ),
    );
  }
}

class DialerSetting extends StatefulWidget {
  const DialerSetting({super.key});

  @override
  State<DialerSetting> createState() => _DialerSettingState();
}

class _DialerSettingState extends State<DialerSetting> {
  late final SharedPreferences _pref;
  late final TextEditingController _directDialingTimeoutController;
  late final TextEditingController _globalDialTimeoutController;

  @override
  void initState() {
    super.initState();
    _pref = context.read<SharedPreferences>();
    _directDialingTimeoutController = TextEditingController(
      text: '${_pref.directDialingTimeout}',
    );
    _globalDialTimeoutController = TextEditingController(
      text: '${_pref.globalDialTimeout}',
    );
  }

  @override
  void dispose() {
    _directDialingTimeoutController.dispose();
    _globalDialTimeoutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Gap(10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _directDialingTimeoutController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.directDialingTimeout,
              helperText: AppLocalizations.of(
                context,
              )!.directDialingTimeoutHint,
              helperMaxLines: 5,
              border: const OutlineInputBorder(),
              suffixText: 's',
            ),
            onChanged: (value) {
              _pref.setDirectDialingTimeout(int.parse(value));
            },
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
        const Gap(10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _globalDialTimeoutController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.globalDialTimeout,
              helperText: AppLocalizations.of(context)!.globalDialTimeoutHint,
              suffixText: 's',
              helperMaxLines: 5,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              if (value.isEmpty) {
                _pref.setGlobalDialTimeout(0);
                return;
              }
              _pref.setGlobalDialTimeout(int.parse(value));
            },
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      ],
    );
  }
}

class PolicyTimeoutSetting extends StatefulWidget {
  const PolicyTimeoutSetting({super.key});

  @override
  State<PolicyTimeoutSetting> createState() => _PolicyTimeoutSettingState();
}

class _PolicyTimeoutSettingState extends State<PolicyTimeoutSetting> {
  late final SharedPreferences _pref;
  late final TextEditingController _handshakeTimeoutController;
  late final TextEditingController _connectionIdleTimeoutController;
  late final TextEditingController _udpIdleTimeoutController;
  late final TextEditingController _upLinkOnlyTimeoutController;
  late final TextEditingController _downLinkOnlyTimeoutController;

  @override
  void initState() {
    super.initState();
    _pref = context.read<SharedPreferences>();
    _handshakeTimeoutController = TextEditingController(
      text: '${_pref.policyHandshakeTimeout}',
    );
    _connectionIdleTimeoutController = TextEditingController(
      text: '${_pref.policyConnectionIdleTimeout}',
    );
    _udpIdleTimeoutController = TextEditingController(
      text: '${_pref.policyUdpIdleTimeout}',
    );
    _upLinkOnlyTimeoutController = TextEditingController(
      text: '${_pref.policyUpLinkOnlyTimeout}',
    );
    _downLinkOnlyTimeoutController = TextEditingController(
      text: '${_pref.policyDownLinkOnlyTimeout}',
    );
  }

  @override
  void dispose() {
    _handshakeTimeoutController.dispose();
    _connectionIdleTimeoutController.dispose();
    _udpIdleTimeoutController.dispose();
    _upLinkOnlyTimeoutController.dispose();
    _downLinkOnlyTimeoutController.dispose();
    super.dispose();
  }

  Widget _buildTimeoutField({
    required TextEditingController controller,
    required String label,
    required String helperText,
    required void Function(int timeout) onSave,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          helperMaxLines: 3,
          suffixText: 's',
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          if (value.isEmpty) {
            onSave(0);
            return;
          }
          onSave(int.parse(value));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.policyTimeout,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const Gap(10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            l10n.policyTimeoutNoTimeoutHint,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Gap(10),
        _buildTimeoutField(
          controller: _connectionIdleTimeoutController,
          label: l10n.policyTcpIdleTimeout,
          helperText: l10n.policyTcpIdleTimeoutDesc,
          onSave: _pref.setPolicyConnectionIdleTimeout,
        ),
        const Gap(10),
        _buildTimeoutField(
          controller: _udpIdleTimeoutController,
          label: l10n.policyUdpIdleTimeout,
          helperText: l10n.policyUdpIdleTimeoutDesc,
          onSave: _pref.setPolicyUdpIdleTimeout,
        ),
        const Gap(10),
        _buildTimeoutField(
          controller: _upLinkOnlyTimeoutController,
          label: l10n.policyUpLinkOnlyTimeout,
          helperText: l10n.policyUpLinkOnlyTimeoutDesc,
          onSave: _pref.setPolicyUpLinkOnlyTimeout,
        ),
        const Gap(10),
        _buildTimeoutField(
          controller: _downLinkOnlyTimeoutController,
          label: l10n.policyDownLinkOnlyTimeout,
          helperText: l10n.policyDownLinkOnlyTimeoutDesc,
          onSave: _pref.setPolicyDownLinkOnlyTimeout,
        ),
      ],
    );
  }
}
