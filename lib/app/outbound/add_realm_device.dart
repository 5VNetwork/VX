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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tm/protos/app/api/api.pb.dart';
import 'package:tm/protos/vx/outbound/outbound.pb.dart';
import 'package:vx/app/outbound/outbounds_bloc.dart';
import 'package:vx/data/realm_device.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/realm_url_crypto.dart';
import 'package:vx/utils/xapi_client.dart';
import 'package:vx/widgets/form_dialog.dart';

Future<void> showAddRealmDeviceDialog(BuildContext context) async {
  final realmDeviceService = context.read<RealmDeviceService>();
  final outBloc = context.read<OutboundBloc>();
  final xApiClient = context.read<XApiClient>();
  final l10n = AppLocalizations.of(context)!;

  late List<RealmPeerDevice> devices;
  try {
    devices = await realmDeviceService.fetchRealmPeerDevices();
  } catch (e) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.failedLoadRealmDevices(e.toString()))),
    );
    return;
  }

  if (!context.mounted) {
    return;
  }

  if (devices.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.noRealmDevicesFound)));
    return;
  }

  RealmPeerDevice? selected = devices.first;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(l10n.addRealmOutbound),
            content: SizedBox(
              width: 420,
              child: DropdownMenu<RealmPeerDevice>(
                initialSelection: selected,
                label: Text(l10n.realmDevicePicker),
                expandedInsets: EdgeInsets.zero,
                dropdownMenuEntries: devices
                    .map(
                      (device) => DropdownMenuEntry(
                        value: device,
                        label: device.name,
                        leadingIcon: device.isEncrypted
                            ? const Icon(Icons.lock_outline, size: 18)
                            : null,
                      ),
                    )
                    .toList(),
                onSelected: (value) {
                  if (value != null) {
                    setState(() => selected = value);
                  }
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.add),
              ),
            ],
          );
        },
      );
    },
  );

  if (confirmed != true || selected == null) {
    return;
  }

  final device = selected!;
  var realmUrl = device.realmUrl;
  if (device.isEncrypted) {
    if (!context.mounted) {
      return;
    }
    final password = await showStringForm(
      context,
      title: l10n.realmDecryptPassword,
      helperText: l10n.realmDecryptPasswordDesc,
      labelText: l10n.password,
      obscureText: true,
    );
    if (password == null || password.isEmpty) {
      return;
    }
    try {
      realmUrl = decryptRealmUrl(device.realmUrl, password);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.realmDecryptFailed)));
      }
      return;
    }
  }

  DecodeResponse result;
  try {
    result = await xApiClient.decode(realmUrl);
  } catch (e) {
    logger.e('Failed to decode realm URL: $e');
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidRealmUrlForDevice)));
    }
    return;
  }

  if (!context.mounted) {
    return;
  }

  if (result.handlers.isEmpty) {
    logger.e('No handlers found in result: $result');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.invalidRealmUrlForDevice)));
    return;
  }

  final outbound = result.handlers.first.deepCopy()..tag = device.name;
  outBloc.add(AddHandlersEvent([HandlerConfig(outbound: outbound)]));
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(l10n.addedRealmDevice(device.name))));
}
