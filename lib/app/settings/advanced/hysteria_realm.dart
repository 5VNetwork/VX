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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/vx/proxy/hysteria/hysteria.pb.dart';
import 'package:uuid/uuid.dart';
import 'package:vx/app/layout_provider.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/data/realm_device.dart';
import 'package:vx/data/realm_server_config.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/main.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/qr.dart';
import 'package:vx/utils/realm.dart';
import 'package:vx/utils/xapi_client.dart';
import 'package:vx/widgets/outbound_handler_form/outbound_handler_form.dart';
import 'package:vx/widgets/text_divider.dart';

class HysteriaRealmSettingScreen extends StatefulWidget {
  const HysteriaRealmSettingScreen({super.key, this.fullscreen = true});
  final bool fullscreen;

  @override
  State<HysteriaRealmSettingScreen> createState() =>
      _HysteriaRealmSettingScreenState();
}

class _HysteriaRealmSettingScreenState
    extends State<HysteriaRealmSettingScreen> {
  late bool _enabled;
  late TextEditingController _authController;
  late TextEditingController _deviceNameController;
  late TextEditingController _cloudPasswordController;
  late Hysteria2ServerConfig _hysteria;
  late final String _deviceId;
  bool _uploading = false;
  bool _sharing = false;
  bool _configuring = false;

  @override
  void initState() {
    super.initState();
    final pref = context.read<SharedPreferences>();
    _deviceId = pref.uniqueDeviceId;
    final config = loadLocalRealmServerConfig(pref, _deviceId);
    _enabled = pref.realmServerEnabled;
    _authController = TextEditingController(text: config.auth);
    _deviceNameController = TextEditingController(
      text: pref.realmDeviceName ?? '',
    );
    _cloudPasswordController = TextEditingController();
    if (_deviceNameController.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final name = await defaultRealmDeviceName();
        if (mounted && _deviceNameController.text.isEmpty) {
          setState(() => _deviceNameController.text = name);
        }
      });
    }
    _hysteria = config.hysteria.deepCopy();
    _hysteria.tlsConfig = _hysteria.tlsConfig.deepCopy();
  }

  @override
  void dispose() {
    _authController.dispose();
    _deviceNameController.dispose();
    _cloudPasswordController.dispose();
    super.dispose();
  }

  void _persistRealmConfig() {
    final l10n = AppLocalizations.of(context)!;
    if (_enabled && _authController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.configureServerSettingsFirst)),
      );
      return;
    }
    if (_enabled && !hysteriaRealmEnabled(_hysteria.realm)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.configureRealmSettings)));
      return;
    }
    final pref = context.read<SharedPreferences>();
    saveLocalRealmServerConfig(
      pref,
      LocalRealmServerConfig(
        auth: _authController.text.trim(),
        hysteria: _hysteria,
      ),
    );

    final deviceName = _deviceNameController.text.trim();
    if (deviceName.isNotEmpty) {
      pref.setRealmDeviceName(deviceName);
    }
  }

  void _persistDeviceName() {
    final deviceName = _deviceNameController.text.trim();
    if (deviceName.isNotEmpty) {
      context.read<SharedPreferences>().setRealmDeviceName(deviceName);
    }
  }

  void _showSnackBar(SnackBar snackBar) {
    if (!mounted) {
      return;
    }
    rootScaffoldMessengerKey.currentState?.showSnackBar(snackBar);
  }

  Future<String?> _buildRealmShareUrl() async {
    if (!mounted) {
      return null;
    }
    final l10n = AppLocalizations.of(context)!;
    final xApiClient = context.read<XApiClient>();
    if (_authController.text.trim().isEmpty) {
      _showSnackBar(SnackBar(content: Text(l10n.configureServerSettingsFirst)));
      return null;
    }
    if (!hysteriaRealmEnabled(_hysteria.realm)) {
      _showSnackBar(SnackBar(content: Text(l10n.configureValidRealmUrlFirst)));
      return null;
    }

    final serverConfig = LocalRealmServerConfig(
      auth: _authController.text.trim(),
      hysteria: _hysteria,
    );
    final inboundConfig = buildRealmServerInbound(serverConfig);
    if (inboundConfig == null) {
      return null;
    }

    final realmOutbound = await xApiClient.inboundConfigToOutboundConfig(
      'RealmServer',
      '',
      inboundConfig,
      null,
    );
    if (!mounted) {
      return null;
    }
    if (realmOutbound.isEmpty) {
      _showSnackBar(SnackBar(content: Text(l10n.failedInboundToOutbound)));
      return null;
    }
    final response = await xApiClient.toUrl(realmOutbound);
    if (!mounted) {
      return null;
    }
    if (response.urls.isEmpty) {
      logger.e('Failed to convert to url. ${response.failedNodes.join('\n')}');
      _showSnackBar(
        SnackBar(
          content: Text(
            l10n.failedConvertToUrl(response.failedNodes.join('\n')),
          ),
        ),
      );
      return null;
    }
    return response.urls.first;
  }

  Future<void> _copyRealmUrl() async {
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    setState(() => _sharing = true);
    try {
      final realmUrl = await _buildRealmShareUrl();
      if (realmUrl == null || !mounted) {
        return;
      }
      await Clipboard.setData(ClipboardData(text: realmUrl));
      _showSnackBar(SnackBar(content: Text(l10n.copiedToClipboard)));
    } catch (e) {
      _showSnackBar(
        SnackBar(content: Text(l10n.realmUploadFailed(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  Future<void> _showRealmQrCode() async {
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    setState(() => _sharing = true);
    try {
      final realmUrl = await _buildRealmShareUrl();
      if (realmUrl == null || !mounted) {
        return;
      }
      shareQrCode(context, realmUrl);
    } catch (e) {
      _showSnackBar(
        SnackBar(content: Text(l10n.realmUploadFailed(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }

  Future<void> _uploadDeviceInfo() async {
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final deviceName = _deviceNameController.text.trim();
    if (deviceName.isEmpty) {
      _showSnackBar(SnackBar(content: Text(l10n.enterDeviceName)));
      return;
    }
    if (!hysteriaRealmEnabled(_hysteria.realm)) {
      _showSnackBar(SnackBar(content: Text(l10n.configureValidRealmUrlFirst)));
      return;
    }
    final cloudPassword = _cloudPasswordController.text;

    final pref = context.read<SharedPreferences>();
    final realmDevice = context.read<RealmDeviceService>();

    setState(() => _uploading = true);
    try {
      final realmUrl = await _buildRealmShareUrl();
      if (realmUrl == null || !mounted) {
        return;
      }
      pref.setRealmDeviceName(deviceName);
      await realmDevice.updateRealmDeviceInfo(
        name: deviceName,
        realmUrl: realmUrl,
        cloudEncryptionPassword: cloudPassword,
      );
      if (!mounted) {
        return;
      }
      _showSnackBar(SnackBar(content: Text(l10n.realmDeviceRegistered)));
    } catch (e) {
      _showSnackBar(
        SnackBar(content: Text(l10n.realmUploadFailed(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _autoConfigureRealmServer() async {
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final pref = context.read<SharedPreferences>();
    final xApiClient = context.read<XApiClient>();

    setState(() => _configuring = true);
    try {
      final buildConfig = context.read<AuthBloc>().state.proUser
          ? buildProRealmServerConfig
          : buildPublicRealmServerConfig;
      final config = await buildConfig(
        deviceId: _deviceId,
        pref: pref,
        generateCert: xApiClient.generateCert,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _authController.text = config.auth;
        _hysteria = config.hysteria.deepCopy();
        _hysteria.tlsConfig = _hysteria.tlsConfig.deepCopy();
      });
      saveLocalRealmServerConfig(pref, config);
      if (!mounted) {
        return;
      }
      context.read<XController>().restart();
      _showSnackBar(SnackBar(content: Text(l10n.realmAutoConfigured)));
    } catch (e) {
      _showSnackBar(
        SnackBar(content: Text(l10n.realmAutoConfigureFailed(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() => _configuring = false);
      }
    }
  }

  Future<void> _showServerConfigDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final fullScreen = Provider.of<MyLayout>(context, listen: false).isCompact;
    final _RealmServerConfigEditResult? result = fullScreen
        ? await Navigator.of(
            context,
            rootNavigator: true,
          ).push<_RealmServerConfigEditResult>(
            CupertinoPageRoute(
              builder: (ctx) => _RealmServerConfigDialog(
                initialAuth: _authController.text,
                initialHysteria: _hysteria,
                l10n: l10n,
                fullScreen: true,
              ),
            ),
          )
        : await showDialog<_RealmServerConfigEditResult>(
            context: context,
            barrierDismissible: false,
            builder: (context) => _RealmServerConfigDialog(
              initialAuth: _authController.text,
              initialHysteria: _hysteria,
              l10n: l10n,
            ),
          );
    if (result != null && mounted) {
      setState(() {
        _authController.text = result.auth;
        _hysteria = result.hysteria;
      });
      _persistRealmConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.hysteriaRealm)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.enableRealmServer),
              subtitle: Text(l10n.enableRealmServerDesc),
              value: _enabled,
              onChanged: (v) {
                setState(() => _enabled = v);
                context.read<SharedPreferences>().setRealmServerEnabled(v);
                _persistRealmConfig();
              },
            ),
            const Gap(8),
            _ServerConfigPreviewCard(
              auth: _authController.text,
              hysteria: _hysteria,
              onTap: _showServerConfigDialog,
            ),
            const Gap(8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _configuring ? null : _autoConfigureRealmServer,
                icon: _configuring
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : const Icon(Icons.auto_fix_high_outlined),
                label: Text(l10n.autoConfigureRealmServer),
              ),
            ),
            ...[
              const Gap(16),
              TextDivider(text: l10n.registerForOtherDevices),
              const Gap(8),
              Text(
                l10n.registerForOtherDevicesDesc,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(10),
              TextFormField(
                controller: _deviceNameController,
                decoration: InputDecoration(
                  labelText: l10n.realmDeviceName,
                  hintText: l10n.realmDeviceNameHint,
                  helperText: l10n.realmDeviceNameHelper,
                ),
                onEditingComplete: _persistDeviceName,
              ),
              const Gap(10),
              TextFormField(
                controller: _cloudPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: l10n.realmCloudEncryptionPassword,
                  helperText: l10n.realmCloudEncryptionPasswordHelper,
                ),
              ),
              const Gap(10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _sharing || _uploading ? null : _copyRealmUrl,
                    icon: const Icon(Icons.copy_outlined),
                    label: Text(l10n.copy),
                  ),
                  OutlinedButton.icon(
                    onPressed: _sharing || _uploading ? null : _showRealmQrCode,
                    icon: const Icon(Icons.qr_code),
                    label: Text(l10n.qrCode),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _uploading || _sharing
                        ? null
                        : _uploadDeviceInfo,
                    icon: _uploading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_outlined),
                    label: Text(l10n.uploadToCloud),
                  ),
                ],
              ),
            ],
            const Gap(100),
          ],
        ),
      ),
    );
  }
}

class _RealmServerConfigEditResult {
  const _RealmServerConfigEditResult({
    required this.auth,
    required this.hysteria,
  });

  final String auth;
  final Hysteria2ServerConfig hysteria;
}

class _ServerConfigPreviewCard extends StatelessWidget {
  const _ServerConfigPreviewCard({
    required this.auth,
    required this.hysteria,
    required this.onTap,
  });

  final String auth;
  final Hysteria2ServerConfig hysteria;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final realm = hysteria.realm;
    final parsed = parseRealmAddr(realm.realmAddr);
    final configured = hysteriaRealmEnabled(realm) && auth.trim().isNotEmpty;
    final obfsPassword = hysteria.obfs.salamander.password;
    final tlsSni = hysteria.tlsConfig.serverName;

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.realmServerConfiguration,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Icon(
                    configured
                        ? Icons.check_circle
                        : Icons.warning_amber_rounded,
                    size: 18,
                    color: configured
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                  const Gap(8),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const Gap(4),
              Text(
                configured ? l10n.realmReadyToRun : l10n.realmNeedsSetup,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(12),
              _PreviewRow(
                label: l10n.realmAuth,
                value: auth.trim().isEmpty
                    ? l10n.realmNotSet
                    : l10n.realmConfigured,
              ),
              if (parsed != null) ...[
                _PreviewRow(
                  label: l10n.realmRendezvous,
                  value: parsed.port != null
                      ? '${parsed.host}:${parsed.port}'
                      : parsed.host,
                ),
                _PreviewRow(label: l10n.realmId, value: parsed.realmId),
              ] else
                _PreviewRow(
                  label: l10n.realmUrl,
                  value: l10n.realmNotConfigured,
                ),
              if (realm.localPort > 0)
                _PreviewRow(
                  label: l10n.realmLocalPort,
                  value: '${realm.localPort}',
                ),
              if (tlsSni.isNotEmpty)
                _PreviewRow(label: l10n.realmTlsSni, value: tlsSni),
              if (obfsPassword.isNotEmpty)
                _PreviewRow(
                  label: l10n.realmObfuscation,
                  value: l10n.salamander,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RealmServerConfigDialog extends StatefulWidget {
  const _RealmServerConfigDialog({
    required this.initialAuth,
    required this.initialHysteria,
    required this.l10n,
    this.fullScreen = false,
  });

  final String initialAuth;
  final Hysteria2ServerConfig initialHysteria;
  final AppLocalizations l10n;
  final bool fullScreen;

  @override
  State<_RealmServerConfigDialog> createState() =>
      _RealmServerConfigDialogState();
}

class _RealmServerConfigDialogState extends State<_RealmServerConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _authController;
  late Hysteria2ServerConfig _hysteria;

  @override
  void initState() {
    super.initState();
    _authController = TextEditingController(text: widget.initialAuth);
    _hysteria = widget.initialHysteria.deepCopy();
    _hysteria.tlsConfig = _hysteria.tlsConfig.deepCopy();
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      _RealmServerConfigEditResult(
        auth: _authController.text.trim(),
        hysteria: _hysteria,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;

    final form = Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _authController,
              decoration: InputDecoration(
                labelText: l10n.password,
                helper: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _authController.text = const Uuid().v4();
                      });
                    },
                    child: Text(l10n.generatePassword),
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.fieldRequired;
                }
                return null;
              },
            ),
            const Gap(16),
            Hysteria(
              quicConfig: _hysteria.quic,
              tlsConfig: _hysteria.tlsConfig,
              obfsConfig: _hysteria.obfs,
              bandwidthConfig: _hysteria.bandwidth,
              server: true,
            ),
            const Gap(10),
            Row(
              children: [
                Text(
                  l10n.ignoreClientBandwidth,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Switch(
                  value: _hysteria.ignoreClientBandwidth,
                  onChanged: (value) {
                    setState(() => _hysteria.ignoreClientBandwidth = value);
                  },
                ),
              ],
            ),
            const Gap(10),
            TextDivider(text: l10n.realmSection),
            const Gap(10),
            HysteriaRealmConfig(config: _hysteria.ensureRealm(), server: true),
          ],
        ),
      ),
    );

    if (widget.fullScreen) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.realmServerConfiguration),
          actions: [TextButton(onPressed: _save, child: Text(l10n.save))],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: form,
          ),
        ),
      );
    }

    return AlertDialog(
      title: Text(l10n.realmServerConfiguration),
      content: SizedBox(width: 480, child: form),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
