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

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/app/api/api.pb.dart';
import 'package:vx/app/file_transfer/file_transfer_controller.dart';
import 'package:vx/app/file_transfer/file_transfer_paths.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/data/realm_device.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/qr.dart';
import 'package:vx/utils/realm.dart';
import 'package:vx/utils/realm_url_crypto.dart';
import 'package:vx/widgets/form_dialog.dart';
import 'package:vx/widgets/pro_icon.dart';
import 'package:vx/widgets/pro_promotion.dart';
import 'package:vx/widgets/take_picture.dart';
import 'package:vx/widgets/text_divider.dart';

void openFileTransferPage(BuildContext context) {
  final controller = context.read<FileTransferController>();
  if (controller.pageOpen) return;
  final navigator = Navigator.of(context);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (controller.pageOpen) return;
    controller.setPageOpen(true);
    navigator
        .push(
          CupertinoPageRoute<void>(builder: (_) => const FileTransferPage()),
        )
        .whenComplete(() => controller.setPageOpen(false));
  });
}

class FileTransferPage extends StatefulWidget {
  const FileTransferPage({super.key, this.showAppBar = true});
  final bool showAppBar;

  @override
  State<FileTransferPage> createState() => _FileTransferPageState();
}

class _FileTransferPageState extends State<FileTransferPage> {
  int _tab = 0;
  final _urlController = TextEditingController();
  String? _pickedFilePath;
  String? _saveDir;
  List<FileTransferPeerDevice> _peers = [];
  bool _peersLoading = false;
  String? _peersError;
  String? _selectedPeerId;

  @override
  void initState() {
    super.initState();
    _loadSaveDir();
    _loadPeers();
  }

  Future<void> _loadSaveDir() async {
    final dir = await resolvedFileTransferSaveDir(
      context.read<SharedPreferences>(),
    );
    if (mounted) {
      setState(() => _saveDir = dir);
    }
  }

  Future<void> _loadPeers() async {
    final loggedIn = context.read<AuthBloc>().state.isAuthenticated;
    if (!loggedIn) {
      setState(() {
        _peers = [];
        _peersError = null;
        _peersLoading = false;
      });
      return;
    }
    setState(() {
      _peersLoading = true;
      _peersError = null;
    });
    try {
      final peers = await context
          .read<RealmDeviceService>()
          .fetchFileTransferPeerDevices();
      if (!mounted) return;
      setState(() {
        _peers = peers;
        _peersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _peersError = e.toString();
        _peersLoading = false;
      });
    }
  }

  Future<void> _selectPeer(FileTransferPeerDevice device) async {
    var url = device.fileTransferUrl;
    if (device.isEncrypted) {
      final l10n = AppLocalizations.of(context)!;
      final password = await showStringForm(
        context,
        title: l10n.realmDecryptPassword,
        helperText: l10n.realmDecryptPasswordDesc,
        labelText: l10n.password,
        obscureText: true,
      );
      if (password == null || password.isEmpty) return;
      try {
        url = decryptRealmUrl(device.fileTransferUrl, password);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.realmDecryptFailed)));
        return;
      }
    }
    setState(() => _selectedPeerId = device.deviceId);
    _urlController.text = url;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(l10n.fileTransfer),
              actions: [
                IconButton(
                  tooltip: l10n.fileTransferMinimize,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 0,
                  label: Text(l10n.fileTransferReceive),
                  icon: const Icon(Icons.download_rounded),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text(l10n.fileTransferSend),
                  icon: const Icon(Icons.upload_rounded),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() => _tab = s.first),
            ),
            const Gap(16),
            if (_tab == 0)
              _ReceivePane(saveDir: _saveDir, onChangeFolder: _pickSaveDir),
            if (_tab == 1)
              _SendPane(
                urlController: _urlController,
                pickedFilePath: _pickedFilePath,
                onPickFile: _pickFile,
                peers: _peers,
                peersLoading: _peersLoading,
                peersError: _peersError,
                selectedPeerId: _selectedPeerId,
                onRefreshPeers: _loadPeers,
                onSelectPeer: _selectPeer,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickSaveDir() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null || !mounted) return;
    context.read<SharedPreferences>().setFileTransferSaveDir(path);
    setState(() => _saveDir = path);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    setState(() => _pickedFilePath = path);
  }
}

class _ReceivePane extends StatefulWidget {
  const _ReceivePane({required this.saveDir, required this.onChangeFolder});
  final String? saveDir;
  final VoidCallback onChangeFolder;

  @override
  State<_ReceivePane> createState() => _ReceivePaneState();
}

class _ReceivePaneState extends State<_ReceivePane> {
  final _cloudPasswordController = TextEditingController();
  final _deviceNameController = TextEditingController();
  bool _uploading = false;
  bool _deleting = false;
  bool _published = false;
  bool _regenerating = false;

  @override
  void initState() {
    super.initState();
    _refreshPublished();
    _loadDeviceName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FileTransferController>().ensureShareUrl(
        proUser: context.read<AuthBloc>().state.proUser,
      );
    });
  }

  Future<void> _loadDeviceName() async {
    final stored = context.read<SharedPreferences>().realmDeviceName;
    if (stored != null && stored.trim().isNotEmpty) {
      _deviceNameController.text = stored;
      return;
    }
    final name = await defaultRealmDeviceName();
    if (!mounted || _deviceNameController.text.isNotEmpty) return;
    setState(() => _deviceNameController.text = name);
  }

  void _persistDeviceName() {
    final name = _deviceNameController.text.trim();
    if (name.isEmpty) return;
    context.read<SharedPreferences>().setRealmDeviceName(name);
  }

  Future<void> _regenerateUrl() async {
    final current = context.read<FileTransferController>().shareUrl;
    final endpoint = await showDialog<_RealmServerEndpoint>(
      context: context,
      builder: (context) => _RegenerateUrlDialog(currentUrl: current),
    );
    if (endpoint == null || !mounted) return;
    final pro = context.read<AuthBloc>().state.proUser;
    if (endpoint.host == defaultRealmRendezvousHost && !pro) {
      showProPromotionDialog(context);
      return;
    }
    setState(() => _regenerating = true);
    try {
      await context.read<FileTransferController>().regenerateShareUrl(
        proUser: pro,
        realmHost: endpoint.host,
        realmPort: endpoint.port,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  @override
  void dispose() {
    _cloudPasswordController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _refreshPublished() async {
    if (!context.read<AuthBloc>().state.isAuthenticated) {
      if (mounted) setState(() => _published = false);
      return;
    }
    try {
      final published = await context
          .read<RealmDeviceService>()
          .hasPublishedFileTransferUrl();
      if (mounted) setState(() => _published = published);
    } catch (_) {}
  }

  String? _urlToPublish() {
    final live = context.read<FileTransferController>().shareUrl;
    if (live.isNotEmpty) return live;
    return context.read<SharedPreferences>().fileTransferShareUrl;
  }

  Future<void> _upload() async {
    final l10n = AppLocalizations.of(context)!;
    if (!context.read<AuthBloc>().state.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fileTransferSignInToSyncDevices)),
      );
      return;
    }
    final url = _urlToPublish();
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fileTransferStartReceiveToUpload)),
      );
      return;
    }
    final name = _deviceNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.enterDeviceName)));
      return;
    }
    setState(() => _uploading = true);
    try {
      await context.read<RealmDeviceService>().updateFileTransferUrl(
        url,
        name: name,
        cloudEncryptionPassword: _cloudPasswordController.text,
      );
      if (!mounted) return;
      setState(() => _published = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.fileTransferUrlUploaded)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.realmUploadFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.fileTransferDeleteUrlConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await context.read<RealmDeviceService>().deleteFileTransferUrl();
      if (!mounted) return;
      setState(() => _published = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.fileTransferUrlDeleted)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.realmUploadFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<FileTransferController>();
    final event = controller.receiveEvent;
    final progress = _progressOf(event);
    final loggedIn = context.watch<AuthBloc>().state.isAuthenticated;
    final busy = _uploading || _deleting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.fileTransferReceiveHint,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Gap(12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.folder_outlined),
          title: Text(l10n.fileTransferSaveFolder),
          subtitle: Text(widget.saveDir ?? '…'),
          trailing: TextButton(
            onPressed: widget.onChangeFolder,
            child: Text(l10n.fileTransferChooseFolder),
          ),
        ),
        const Gap(8),

        if (controller.isReceiving)
          FilledButton.tonalIcon(
            onPressed: controller.stopReceive,
            icon: const Icon(Icons.stop_rounded),
            label: Text(l10n.fileTransferStopReceive),
          )
        else
          FilledButton.icon(
            onPressed: () {
              final pro = context.read<AuthBloc>().state.proUser;
              controller.startReceive(proUser: pro);
            },
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(l10n.fileTransferStartReceive),
          ),
        const Gap(16),
        if (event != null) ...[
          Text(_statusLabel(l10n, event.state)),
          if (progress != null) ...[
            const Gap(8),
            LinearProgressIndicator(value: progress),
            const Gap(4),
            Text(
              _progressLabel(event),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (event.filename.isNotEmpty) ...[
            const Gap(8),
            Text(event.filename, style: Theme.of(context).textTheme.titleSmall),
          ],
          if (event.savePath.isNotEmpty &&
              event.state == FileTransferEvent_State.STATE_COMPLETED) ...[
            const Gap(4),
            Text(
              l10n.fileTransferReceivedAs(event.savePath),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (controller.receiveError != null) ...[
            const Gap(8),
            Text(
              controller.receiveError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
        if (controller.shareUrl.isNotEmpty) ...[
          const Gap(16),
          TextDivider(text: l10n.fileTransferShareUrl),
          const Gap(8),
          SelectableText(controller.shareUrl),
          const Gap(8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _regenerating ? null : _regenerateUrl,
                icon: _regenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(l10n.fileTransferRegenerateUrl),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: controller.shareUrl),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.copiedToClipboard)),
                    );
                  }
                },
                icon: const Icon(Icons.copy_outlined),
                label: Text(l10n.copy),
              ),
              OutlinedButton.icon(
                onPressed: () => shareQrCode(context, controller.shareUrl),
                icon: const Icon(Icons.qr_code),
                label: Text(l10n.qrCode),
              ),
            ],
          ),
        ],
        const Gap(16),
        TextDivider(text: l10n.fileTransferUploadUrlToCloud),
        const Gap(8),
        if (!loggedIn)
          Text(
            l10n.fileTransferSignInToSyncDevices,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else ...[
          TextFormField(
            controller: _deviceNameController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.realmDeviceName,
              hintText: l10n.realmDeviceNameHint,
              helperText: l10n.realmDeviceNameHelper,
            ),
            onEditingComplete: _persistDeviceName,
            onTapOutside: (_) => _persistDeviceName(),
          ),
          const Gap(8),
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
            children: [
              FilledButton.tonalIcon(
                onPressed: busy ? null : _upload,
                icon: _uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(l10n.uploadToCloud),
              ),
              if (_published)
                OutlinedButton.icon(
                  onPressed: busy ? null : _delete,
                  icon: _deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  label: Text(l10n.fileTransferDeleteCloudUrl),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _RealmServerEndpoint {
  const _RealmServerEndpoint({required this.host, this.port});

  final String host;
  final int? port;
}

enum _RealmServerChoice { public, pro, custom }

_RealmServerEndpoint? _parseRealmServerInput(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;
  if (text.contains('://')) {
    final realm = parseRealmAddr(text);
    if (realm != null) {
      final port = realm.port == null ? null : int.tryParse(realm.port!);
      return _RealmServerEndpoint(host: realm.host, port: port);
    }
    final uri = Uri.tryParse(text);
    if (uri == null || uri.host.isEmpty) return null;
    return _RealmServerEndpoint(
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    );
  }
  final ipv6 = RegExp(r'^\[(.+)\](?::(\d+))?$').firstMatch(text);
  if (ipv6 != null) {
    final portText = ipv6.group(2);
    final port = portText == null ? null : int.tryParse(portText);
    if (portText != null && (port == null || port < 1 || port > 65535)) {
      return null;
    }
    return _RealmServerEndpoint(host: '[${ipv6.group(1)!}]', port: port);
  }
  final colon = text.lastIndexOf(':');
  if (colon > 0 && !text.substring(0, colon).contains(':')) {
    final port = int.tryParse(text.substring(colon + 1));
    final host = text.substring(0, colon);
    if (host.isEmpty || port == null || port < 1 || port > 65535) return null;
    return _RealmServerEndpoint(host: host, port: port);
  }
  if (text.contains(' ') || text.contains('/') || text.contains(':')) {
    return null;
  }
  return _RealmServerEndpoint(host: text);
}

class _RegenerateUrlDialog extends StatefulWidget {
  const _RegenerateUrlDialog({required this.currentUrl});

  final String currentUrl;

  @override
  State<_RegenerateUrlDialog> createState() => _RegenerateUrlDialogState();
}

class _RegenerateUrlDialogState extends State<_RegenerateUrlDialog> {
  late _RealmServerChoice _choice;
  late final TextEditingController _customController;
  String? _error;

  @override
  void initState() {
    super.initState();
    final parsed = parseRealmAddr(widget.currentUrl);
    if (parsed?.host == defaultRealmRendezvousHost) {
      _choice = _RealmServerChoice.pro;
      _customController = TextEditingController();
    } else if (parsed != null && parsed.host != publicRealmRendezvousHost) {
      _choice = _RealmServerChoice.custom;
      final port = parsed.port;
      _customController = TextEditingController(
        text: port == null ? parsed.host : '${parsed.host}:$port',
      );
    } else {
      _choice = _RealmServerChoice.public;
      _customController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final _RealmServerEndpoint? endpoint;
    switch (_choice) {
      case _RealmServerChoice.public:
        endpoint = const _RealmServerEndpoint(host: publicRealmRendezvousHost);
      case _RealmServerChoice.pro:
        if (context.read<AuthBloc>().state.proUser != true) {
          showProPromotionDialog(context);
          return;
        }
        endpoint = const _RealmServerEndpoint(host: defaultRealmRendezvousHost);
      case _RealmServerChoice.custom:
        endpoint = _parseRealmServerInput(_customController.text);
        if (endpoint == null) {
          setState(() => _error = l10n.fileTransferInvalidRealmServer);
          return;
        }
        if (endpoint.host == defaultRealmRendezvousHost &&
            context.read<AuthBloc>().state.proUser != true) {
          showProPromotionDialog(context);
          return;
        }
    }
    Navigator.of(context).pop(endpoint);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pro = context.watch<AuthBloc>().state.proUser;
    return AlertDialog(
      title: Text(l10n.fileTransferRegenerateUrlTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.fileTransferRegenerateUrlDesc),
          const Gap(8),
          RadioGroup<_RealmServerChoice>(
            groupValue: _choice,
            onChanged: (value) {
              if (value == null) return;
              if (value == _RealmServerChoice.pro && !pro) {
                showProPromotionDialog(context);
                return;
              }
              setState(() {
                _choice = value;
                _error = null;
              });
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<_RealmServerChoice>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(publicRealmRendezvousHost),
                  value: _RealmServerChoice.public,
                ),
                RadioListTile<_RealmServerChoice>(
                  contentPadding: EdgeInsets.zero,
                  title: AppendProIcon(
                    child: const Text(defaultRealmRendezvousHost),
                  ),
                  value: _RealmServerChoice.pro,
                ),
                RadioListTile<_RealmServerChoice>(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.fileTransferCustomRealmServer),
                  value: _RealmServerChoice.custom,
                ),
              ],
            ),
          ),
          if (_choice == _RealmServerChoice.custom) ...[
            const Gap(4),
            TextField(
              controller: _customController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.fileTransferCustomRealmServerHint,
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ] else if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.fileTransferRegenerateUrl),
        ),
      ],
    );
  }
}

class _SendPane extends StatelessWidget {
  const _SendPane({
    required this.urlController,
    required this.pickedFilePath,
    required this.onPickFile,
    required this.peers,
    required this.peersLoading,
    required this.peersError,
    required this.selectedPeerId,
    required this.onRefreshPeers,
    required this.onSelectPeer,
  });
  final TextEditingController urlController;
  final String? pickedFilePath;
  final VoidCallback onPickFile;
  final List<FileTransferPeerDevice> peers;
  final bool peersLoading;
  final String? peersError;
  final String? selectedPeerId;
  final VoidCallback onRefreshPeers;
  final ValueChanged<FileTransferPeerDevice> onSelectPeer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = context.watch<FileTransferController>();
    final event = controller.sendEvent;
    final progress = _progressOf(event);
    final loggedIn = context.watch<AuthBloc>().state.isAuthenticated;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.fileTransferSendHint,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Gap(12),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.fileTransferYourDevices,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            IconButton(
              tooltip: l10n.fileTransferRefreshDevices,
              onPressed: peersLoading ? null : onRefreshPeers,
              icon: peersLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        if (!loggedIn)
          Text(
            l10n.fileTransferSignInToSyncDevices,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else if (peersError != null)
          Text(
            l10n.failedLoadRealmDevices(peersError!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          )
        else if (!peersLoading && peers.isEmpty)
          Text(
            l10n.fileTransferNoSyncedDevices,
            style: Theme.of(context).textTheme.bodySmall,
          )
        else
          ...peers.map(
            (device) => ListTile(
              contentPadding: EdgeInsets.zero,
              selected: selectedPeerId == device.deviceId,
              leading: Icon(
                selectedPeerId == device.deviceId
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: Text(device.name),
              trailing: device.isEncrypted
                  ? const Icon(Icons.lock_outline, size: 18)
                  : null,
              onTap: () => onSelectPeer(device),
            ),
          ),
        const Gap(12),
        TextField(
          controller: urlController,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n.fileTransferPasteAddress,
            hintText: l10n.fileTransferAddressHint,
            border: const OutlineInputBorder(),
          ),
        ),
        const Gap(8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final data = await Clipboard.getData(Clipboard.kTextPlain);
                final text = data?.text?.trim();
                if (text != null && text.isNotEmpty) {
                  urlController.text = text;
                }
              },
              icon: const Icon(Icons.paste_outlined),
              label: Text(l10n.clipboard),
            ),
            if (Platform.isAndroid || Platform.isIOS)
              OutlinedButton.icon(
                onPressed: () async {
                  final barcode = await Navigator.of(context).push<Barcode?>(
                    MaterialPageRoute(builder: (_) => const ScanQrCode()),
                  );
                  final value = barcode?.displayValue;
                  if (value != null && value.isNotEmpty) {
                    urlController.text = value;
                  }
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(l10n.scanQrCode),
              ),
          ],
        ),
        const Gap(16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.insert_drive_file_outlined),
          title: Text(l10n.fileTransferPickFile),
          subtitle: Text(
            pickedFilePath ?? l10n.fileTransferNoFileSelected,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: TextButton(onPressed: onPickFile, child: Text(l10n.add)),
        ),
        const Gap(8),
        if (controller.isSending)
          FilledButton.tonalIcon(
            onPressed: controller.stopSend,
            icon: const Icon(Icons.stop_rounded),
            label: Text(l10n.cancel),
          )
        else
          FilledButton.icon(
            onPressed: () {
              final url = urlController.text.trim();
              final path = pickedFilePath;
              if (url.isEmpty || path == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.fileTransferSendMissing)),
                );
                return;
              }
              controller.startSend(realmUrl: url, filePath: path);
            },
            icon: const Icon(Icons.send_rounded),
            label: Text(l10n.fileTransferSend),
          ),
        if (event != null) ...[
          const Gap(16),
          Text(_statusLabel(l10n, event.state)),
          if (progress != null) ...[
            const Gap(8),
            LinearProgressIndicator(value: progress),
            const Gap(4),
            Text(
              _progressLabel(event),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (event.filename.isNotEmpty)
            Text(event.filename, style: Theme.of(context).textTheme.titleSmall),
          if (controller.sendError != null) ...[
            const Gap(8),
            Text(
              controller.sendError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ],
    );
  }
}

double? _progressOf(FileTransferEvent? event) {
  if (event == null) return null;
  final total = event.bytesTotal.toInt();
  if (total <= 0) return null;
  return (event.bytesDone.toInt() / total).clamp(0, 1);
}

String _progressLabel(FileTransferEvent event) {
  final done = event.bytesDone.toInt();
  final total = event.bytesTotal.toInt();
  if (total <= 0) return _formatBytes(done);
  return '${_formatBytes(done)} / ${_formatBytes(total)}';
}

String _statusLabel(AppLocalizations l10n, FileTransferEvent_State state) {
  switch (state) {
    case FileTransferEvent_State.STATE_STARTING:
      return l10n.fileTransferStarting;
    case FileTransferEvent_State.STATE_WAITING:
      return l10n.fileTransferWaiting;
    case FileTransferEvent_State.STATE_CONNECTING:
      return l10n.fileTransferConnecting;
    case FileTransferEvent_State.STATE_TRANSFERRING:
      return l10n.fileTransferTransferring;
    case FileTransferEvent_State.STATE_COMPLETED:
      return l10n.fileTransferCompleted;
    case FileTransferEvent_State.STATE_FAILED:
      return l10n.fileTransferFailed;
    case FileTransferEvent_State.STATE_CANCELLED:
      return l10n.fileTransferCancelled;
    case FileTransferEvent_State.STATE_UNSPECIFIED:
    default:
      return '';
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
}

class FileTransferMiniBar extends StatelessWidget {
  const FileTransferMiniBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<FileTransferController>();
    if (!controller.showMiniBar) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final event = controller.miniEvent;
    final progress = _progressOf(event);
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Positioned(
      left: 12,
      right: 12,
      bottom: wide ? 12 : 96,
      child: SafeArea(
        child: Material(
          elevation: 4,
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => openFileTransferPage(context),
                    child: Row(
                      children: [
                        Icon(
                          controller.miniIsSend
                              ? Icons.upload_rounded
                              : Icons.download_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                event == null
                                    ? l10n.fileTransfer
                                    : _statusLabel(l10n, event.state),
                                style: theme.textTheme.titleSmall,
                              ),
                              if (event != null && event.filename.isNotEmpty)
                                Text(
                                  event.filename,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              if (event != null && progress != null) ...[
                                const Gap(6),
                                LinearProgressIndicator(value: progress),
                                const Gap(2),
                                Text(
                                  _progressLabel(event),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ] else if (event != null &&
                                  event.state ==
                                      FileTransferEvent_State
                                          .STATE_TRANSFERRING) ...[
                                const Gap(6),
                                const LinearProgressIndicator(),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.close,
                  onPressed: controller.dismissMiniBar,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
