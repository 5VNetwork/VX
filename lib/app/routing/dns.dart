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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tm/protos/vx/dns/dns.pb.dart';
import 'package:vx/app/log/log_page.dart';
import 'package:vx/app/routing/mode_form.dart';
import 'package:vx/app/routing/repo.dart';
import 'package:flutter_common/util/net.dart';
import 'package:vx/data/database.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/main.dart';
import 'package:vx/widgets/form_dialog.dart';

part 'dns_records.dart';

enum _DnsSection { servers, records }

class DnsServersWidget extends StatefulWidget {
  const DnsServersWidget({super.key});

  @override
  State<DnsServersWidget> createState() => _DnsServersWidgetState();
}

class _DnsServersWidgetState extends State<DnsServersWidget> {
  _DnsSection _section = _DnsSection.servers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: ChoiceChip(
                label: Text(AppLocalizations.of(context)!.dnsServer),
                selected: _section == _DnsSection.servers,
                onSelected: (value) {
                  setState(() {
                    _section = _DnsSection.servers;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: ChoiceChip(
                label: Text(AppLocalizations.of(context)!.dnsRecord),
                selected: _section == _DnsSection.records,
                onSelected: (value) {
                  setState(() {
                    _section = _DnsSection.records;
                  });
                },
              ),
            ),
          ],
        ),
        Gap(10),
        Expanded(
          child: _section == _DnsSection.servers
              ? const DnsServers()
              : const _DnsRecords(),
        ),
      ],
    );
  }
}

class DnsServers extends StatefulWidget {
  const DnsServers({super.key});

  @override
  State<DnsServers> createState() => _DnsServersState();
}

class _DnsServersState extends State<DnsServers>
    with AutomaticKeepAliveClientMixin<DnsServers> {
  static const String _reservedDnsServerName = 'Hijack';
  final width = 300;

  List<DnsServer> _servers = [/* ...defaultDnsServers */];
  List<DnsServer> _concurrentServers = [];
  List<DnsServer> _serialServers = [];
  late DnsRepo _dnsRepo;
  StreamSubscription? _dnsServersSubscription;
  StreamSubscription? _concurrentDnsServersSubscription;
  StreamSubscription? _serialDnsServersSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dnsRepo = Provider.of<DnsRepo>(context, listen: true);
    _dnsServersSubscription?.cancel();
    _concurrentDnsServersSubscription?.cancel();
    _serialDnsServersSubscription?.cancel();
    _dnsServersSubscription = _dnsRepo.getDnsServersStream().listen((value) {
      setState(() {
        _servers = [/* ...defaultDnsServers */];
        _servers.addAll(value);
      });
    });
    _concurrentDnsServersSubscription = _dnsRepo
        .getConcurrentDnsServersStream()
        .listen((value) {
          setState(() {
            _concurrentServers = value;
          });
        });
    _serialDnsServersSubscription = _dnsRepo.getSerialDnsServersStream().listen(
      (value) {
        setState(() {
          _serialServers = value;
        });
      },
    );
  }

  @override
  void dispose() {
    _dnsServersSubscription?.cancel();
    _concurrentDnsServersSubscription?.cancel();
    _serialDnsServersSubscription?.cancel();
    super.dispose();
  }

  bool _nameExists(String name, {String? ignoreName}) {
    bool existsIn(String itemName) =>
        itemName == name && (ignoreName == null || itemName != ignoreName);
    return _servers.any((e) => existsIn(e.name)) ||
        _concurrentServers.any((e) => existsIn(e.name)) ||
        _serialServers.any((e) => existsIn(e.name));
  }

  List<DnsServer> _allDnsServersForSelection({String? excludeName}) {
    return [
      ..._servers,
      ..._concurrentServers,
      ..._serialServers,
    ].where((e) => excludeName == null || e.name != excludeName).toList();
  }

  bool _isReservedName(String name) =>
      name.trim() == _reservedDnsServerName;

  void _onAdd() async {
    final k = GlobalKey();
    final config = await showMyAdaptiveDialog<DnsServerConfig?>(
      context,
      _DnsServerForm(key: k),
      title: AppLocalizations.of(context)!.addDnsServer,
      onSave: (BuildContext context) {
        final formData = (k.currentState as FormDataGetter).formData;
        if (formData != null) {
          context.pop(formData);
        }
      },
    );
    if (config != null) {
      if (_isReservedName(config.name)) {
        snack(rootLocalizations()?.reservedDnsServerName);
        return;
      }
      if (_nameExists(config.name)) {
        snack(rootLocalizations()?.duplicateDnsServerName);
        return;
      }
      final ds = await _dnsRepo.addDnsServer(config.name, config);
      setState(() {
        _servers.add(ds);
      });
    }
  }

  void _onEdit(int index) async {
    final k = GlobalKey();
    final config = await showMyAdaptiveDialog<DnsServerConfig?>(
      context,
      _DnsServerForm(key: k, dnsServer: _servers[index]),
      title: AppLocalizations.of(context)!.edit,
      onSave: (BuildContext context) {
        final formData = (k.currentState as FormDataGetter).formData;
        if (formData != null) {
          context.pop(formData);
        }
      },
    );
    if (config != null) {
      if (_isReservedName(config.name)) {
        snack(rootLocalizations()?.reservedDnsServerName);
        return;
      }
      if (_nameExists(config.name, ignoreName: _servers[index].name)) {
        snack(rootLocalizations()?.duplicateDnsServerName);
        return;
      }
      await _dnsRepo.updateDnsServer(
        _servers[index],
        dnsServerName: config.name,
        dnsServer: config,
      );
      setState(() {
        _servers[index] = DnsServer(
          id: _servers[index].id,
          name: config.name,
          dnsServer: config,
        );
      });
    }
  }

  void _onAddConcurrent() async {
    final k = GlobalKey();
    final config = await showMyAdaptiveDialog<ConcurrentDnsServer?>(
      context,
      _ConcurrentDnsServerForm(
        key: k,
        dnsServers: _allDnsServersForSelection(),
      ),
      title: AppLocalizations.of(context)!.addConcurrentDnsServer,
      onSave: (BuildContext context) {
        final formData = (k.currentState as FormDataGetter).formData;
        if (formData != null) {
          context.pop(formData);
        }
      },
    );
    if (config != null) {
      if (_isReservedName(config.name)) {
        snack(rootLocalizations()?.reservedDnsServerName);
        return;
      }
      if (_nameExists(config.name)) {
        snack(rootLocalizations()?.duplicateDnsServerName);
        return;
      }
      await _dnsRepo.addConcurrentDnsServer(config.name, config);
    }
  }

  void _onEditConcurrent(int index) async {
    final k = GlobalKey();
    final row = _concurrentServers[index];
    final config = await showMyAdaptiveDialog<ConcurrentDnsServer?>(
      context,
      _ConcurrentDnsServerForm(
        key: k,
        dnsServers: _allDnsServersForSelection(excludeName: row.name),
        concurrentDnsServer: row,
      ),
      title: AppLocalizations.of(context)!.edit,
      onSave: (BuildContext context) {
        final formData = (k.currentState as FormDataGetter).formData;
        if (formData != null) {
          context.pop(formData);
        }
      },
    );
    if (config != null) {
      if (_isReservedName(config.name)) {
        snack(rootLocalizations()?.reservedDnsServerName);
        return;
      }
      if (_nameExists(config.name, ignoreName: row.name)) {
        snack(rootLocalizations()?.duplicateDnsServerName);
        return;
      }
      await _dnsRepo.updateConcurrentDnsServer(
        row,
        name: config.name,
        config: config,
      );
    }
  }

  void _onAddSerial() async {
    final k = GlobalKey();
    final config = await showMyAdaptiveDialog<SerialDnsServer?>(
      context,
      _SerialDnsServerForm(key: k, dnsServers: _allDnsServersForSelection()),
      title: AppLocalizations.of(context)!.addSerialDnsServer,
      onSave: (BuildContext context) {
        final formData = (k.currentState as FormDataGetter).formData;
        if (formData != null) {
          context.pop(formData);
        }
      },
    );
    if (config != null) {
      if (_isReservedName(config.name)) {
        snack(rootLocalizations()?.reservedDnsServerName);
        return;
      }
      if (_nameExists(config.name)) {
        snack(rootLocalizations()?.duplicateDnsServerName);
        return;
      }
      await _dnsRepo.addSerialDnsServer(config.name, config);
    }
  }

  void _onEditSerial(int index) async {
    final k = GlobalKey();
    final row = _serialServers[index];
    final config = await showMyAdaptiveDialog<SerialDnsServer?>(
      context,
      _SerialDnsServerForm(
        key: k,
        dnsServers: _allDnsServersForSelection(excludeName: row.name),
        serialDnsServer: row,
      ),
      title: AppLocalizations.of(context)!.edit,
      onSave: (BuildContext context) {
        final formData = (k.currentState as FormDataGetter).formData;
        if (formData != null) {
          context.pop(formData);
        }
      },
    );
    if (config != null) {
      if (_isReservedName(config.name)) {
        snack(rootLocalizations()?.reservedDnsServerName);
        return;
      }
      if (_nameExists(config.name, ignoreName: row.name)) {
        snack(rootLocalizations()?.duplicateDnsServerName);
        return;
      }
      await _dnsRepo.updateSerialDnsServer(
        row,
        name: config.name,
        config: config,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth ~/ width;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MenuAnchor(
              menuChildren: [
                MenuItemButton(
                  onPressed: _onAdd,
                  child: Text(AppLocalizations.of(context)!.dnsServer),
                ),
                MenuItemButton(
                  onPressed: _onAddConcurrent,
                  child: Text(
                    AppLocalizations.of(context)!.concurrentDnsServerType,
                  ),
                ),
                MenuItemButton(
                  onPressed: _onAddSerial,
                  child: Text(
                    AppLocalizations.of(context)!.serialDnsServerType,
                  ),
                ),
              ],
              builder: (context, controller, child) {
                return FilledButton.tonal(
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.addDnsServer),
                );
              },
            ),
            const SizedBox(height: 5),
            Expanded(
              child: MasonryGridView.count(
                padding: const EdgeInsets.only(bottom: 70),
                crossAxisCount: count,
                itemCount:
                    _servers.length +
                    _concurrentServers.length +
                    _serialServers.length,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                itemBuilder: (context, index) {
                  final normalLen = _servers.length;
                  final concurrentLen = _concurrentServers.length;
                  if (index < normalLen) {
                    final server = _servers[index];
                    return Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          _onEdit(index);
                        },
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    server.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _getDnsServerType(server).label(context),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  _getDnsServerWidget(context, server),
                                  if (server.dnsServer!.clientIp.isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 5),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.clientIp,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(height: 5),
                                        Chip(
                                          shape: chipBorderRadius,
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerLow,
                                          label: Text(
                                            server.dnsServer!.clientIp,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 5,
                              top: 5,
                              child: IconButton(
                                onPressed: () async {
                                  await _dnsRepo.removeDnsServer(server);
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (index < normalLen + concurrentLen) {
                    final i = index - normalLen;
                    final row = _concurrentServers[i];
                    return _CompositeDnsCard(
                      name: row.name,
                      type: AppLocalizations.of(
                        context,
                      )!.concurrentDnsServerType,
                      selectedDnsServers: row.concurrentDnsServer!.dnsServers,
                      onTap: () => _onEditConcurrent(i),
                      onDelete: () async {
                        await _dnsRepo.removeConcurrentDnsServer(row);
                      },
                    );
                  }
                  final i = index - normalLen - concurrentLen;
                  final row = _serialServers[i];
                  return _CompositeDnsCard(
                    name: row.name,
                    type: AppLocalizations.of(context)!.serialDnsServerType,
                    selectedDnsServers: row.serialDnsServer!.dnsServers,
                    intervalSeconds: row.serialDnsServer!.interval,
                    onTap: () => _onEditSerial(i),
                    onDelete: () async {
                      await _dnsRepo.removeSerialDnsServer(row);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

DnsServerType _getDnsServerType(DnsServer server) {
  final config = server.dnsServer;
  if (config == null) {
    return DnsServerType.plain;
  }
  if (config.hasFakeDnsServer()) {
    return DnsServerType.fake;
  } else if (config.hasPlainDnsServer()) {
    return DnsServerType.plain;
  } else if (config.hasDohDnsServer()) {
    return DnsServerType.doh;
  } else if (config.hasTlsDnsServer()) {
    return DnsServerType.tls;
  } else if (config.hasQuicDnsServer()) {
    return DnsServerType.quic;
  } else if (config.hasGoDnsServer()) {
    return DnsServerType.go;
  } else if (config.hasEmptyDnsServer()) {
    return DnsServerType.empty;
  }
  return DnsServerType.plain;
}

Widget _getDnsServerWidget(BuildContext context, DnsServer server) {
  final config = server.dnsServer;
  if (config == null) {
    return const SizedBox.shrink();
  }
  if (config.hasFakeDnsServer()) {
    return _FakeDns(fakeDnsServer: config.fakeDnsServer);
  } else if (config.hasPlainDnsServer()) {
    return _PlainTlsDnsServer(
      addresses: config.plainDnsServer.addresses,
      useDefaultDns: config.plainDnsServer.useDefaultDns,
    );
  } else if (config.hasTlsDnsServer()) {
    return _PlainTlsDnsServer(addresses: config.tlsDnsServer.addresses);
  } else if (config.hasDohDnsServer()) {
    return _PlainTlsDnsServer(addresses: [config.dohDnsServer.url]);
  } else if (config.hasQuicDnsServer()) {
    return _PlainTlsDnsServer(addresses: [config.quicDnsServer.address]);
  } else if (config.hasGoDnsServer()) {
    return Text(AppLocalizations.of(context)!.useSystemDnsResolver);
  } else if (config.hasEmptyDnsServer()) {
    return Text(AppLocalizations.of(context)!.alwaysReturnEmptyDnsAnswer);
  }
  return const SizedBox.shrink();
}

class _FakeDns extends StatelessWidget {
  const _FakeDns({required this.fakeDnsServer});
  final FakeDnsServer fakeDnsServer;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.dnsPool,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 5),
        Wrap(
          runSpacing: 5,
          spacing: 5,
          children: fakeDnsServer.poolConfigs
              .map(
                (e) => Chip(
                  shape: chipBorderRadius,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerLow,
                  label: Text(e.cidr),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _PlainTlsDnsServer extends StatelessWidget {
  const _PlainTlsDnsServer({required this.addresses, this.useDefaultDns});
  final Iterable<String> addresses;
  final bool? useDefaultDns;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.address,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (useDefaultDns != null && useDefaultDns!)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              AppLocalizations.of(context)!.useDefaultNicDnsServer,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        const SizedBox(height: 5),
        Wrap(
          runSpacing: 5,
          spacing: 5,
          children: addresses
              .map(
                (e) => Chip(
                  shape: chipBorderRadius,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerLow,
                  label: Text(e),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _CompositeDnsCard extends StatelessWidget {
  const _CompositeDnsCard({
    required this.name,
    required this.type,
    required this.selectedDnsServers,
    required this.onTap,
    required this.onDelete,
    this.intervalSeconds,
  });

  final String name;
  final String type;
  final List<String> selectedDnsServers;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;
  final int? intervalSeconds;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          type,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              if (intervalSeconds != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${AppLocalizations.of(context)!.interval}: ${intervalSeconds!}${AppLocalizations.of(context)!.seconds}',
                ),
              ],
              if (selectedDnsServers.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  runSpacing: 5,
                  spacing: 5,
                  children: selectedDnsServers
                      .map(
                        (e) => Chip(
                          shape: chipBorderRadius,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          label: Text(e),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConcurrentDnsServerForm extends StatefulWidget {
  const _ConcurrentDnsServerForm({
    super.key,
    required this.dnsServers,
    this.concurrentDnsServer,
  });

  final List<DnsServer> dnsServers;
  final DnsServer? concurrentDnsServer;

  @override
  State<_ConcurrentDnsServerForm> createState() =>
      _ConcurrentDnsServerFormState();
}

class _ConcurrentDnsServerFormState extends State<_ConcurrentDnsServerForm>
    with FormDataGetter {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<String> _selectedServers = [];

  @override
  void initState() {
    super.initState();
    final config = widget.concurrentDnsServer?.concurrentDnsServer;
    if (config != null) {
      _nameController.text = config.name;
      _selectedServers.addAll(config.dnsServers);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Object? get formData {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return null;
    }
    if (_selectedServers.isEmpty) {
      return null;
    }
    return ConcurrentDnsServer(
      name: _nameController.text.trim(),
      dnsServers: List<String>.from(_selectedServers),
    );
  }

  List<DnsServer> get _unselectedServers => widget.dnsServers
      .where((e) => !_selectedServers.contains(e.name))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? AppLocalizations.of(context)!.fieldRequired
                : null,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.name,
            ),
          ),
          const Gap(10),
          Text(
            AppLocalizations.of(context)!.dnsServers,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const Gap(6),
          MenuAnchor(
            menuChildren: _unselectedServers
                .map(
                  (server) => MenuItemButton(
                    onPressed: () {
                      setState(() {
                        _selectedServers.add(server.name);
                      });
                    },
                    child: Text(
                      '${server.name} (${_getDnsServerType(server).label(context)})',
                    ),
                  ),
                )
                .toList(),
            builder: (context, controller, child) {
              return OutlinedButton.icon(
                onPressed: _unselectedServers.isEmpty
                    ? null
                    : () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.addDnsServer),
              );
            },
          ),
          const Gap(8),
          if (_selectedServers.isNotEmpty)
            SizedBox(
              width: 320,
              height: 220,
              child: ReorderableListView.builder(
                itemCount: _selectedServers.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _selectedServers.removeAt(oldIndex);
                    _selectedServers.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final name = _selectedServers[index];
                  return ListTile(
                    key: ValueKey('concurrent-$name-$index'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(name),
                    leading: IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedServers.removeAt(index);
                        });
                      },
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  );
                },
              ),
            ),
          if (_selectedServers.isEmpty)
            Text(
              AppLocalizations.of(context)!.selectAtleastOneDnsServer,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
        ],
      ),
    );
  }
}

class _SerialDnsServerForm extends StatefulWidget {
  const _SerialDnsServerForm({
    super.key,
    required this.dnsServers,
    this.serialDnsServer,
  });

  final List<DnsServer> dnsServers;
  final DnsServer? serialDnsServer;

  @override
  State<_SerialDnsServerForm> createState() => _SerialDnsServerFormState();
}

class _SerialDnsServerFormState extends State<_SerialDnsServerForm>
    with FormDataGetter {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _intervalController = TextEditingController(text: '1');
  final List<String> _selectedServers = [];

  @override
  void initState() {
    super.initState();
    final config = widget.serialDnsServer?.serialDnsServer;
    if (config != null) {
      _nameController.text = config.name;
      _intervalController.text = config.interval.toString();
      _selectedServers.addAll(config.dnsServers);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Object? get formData {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return null;
    }
    if (_selectedServers.isEmpty) {
      return null;
    }
    return SerialDnsServer(
      name: _nameController.text.trim(),
      interval: int.tryParse(_intervalController.text.trim()) ?? 1,
      dnsServers: List<String>.from(_selectedServers),
    );
  }

  List<DnsServer> get _unselectedServers => widget.dnsServers
      .where((e) => !_selectedServers.contains(e.name))
      .toList();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            validator: (value) => (value == null || value.trim().isEmpty)
                ? AppLocalizations.of(context)!.fieldRequired
                : null,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.name,
            ),
          ),
          const Gap(10),
          TextFormField(
            controller: _intervalController,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return AppLocalizations.of(context)!.fieldRequired;
              }
              if (int.tryParse(value) == null) {
                return AppLocalizations.of(context)!.invalidInterval;
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.interval,
              suffixText: AppLocalizations.of(context)!.seconds,
            ),
          ),
          const Gap(10),
          Text(
            AppLocalizations.of(context)!.dnsServers,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const Gap(6),
          MenuAnchor(
            menuChildren: _unselectedServers
                .map(
                  (server) => MenuItemButton(
                    onPressed: () {
                      setState(() {
                        _selectedServers.add(server.name);
                      });
                    },
                    child: Text(
                      '${server.name} (${_getDnsServerType(server).label(context)})',
                    ),
                  ),
                )
                .toList(),
            builder: (context, controller, child) {
              return OutlinedButton.icon(
                onPressed: _unselectedServers.isEmpty
                    ? null
                    : () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.addDnsServer),
              );
            },
          ),
          const Gap(8),
          if (_selectedServers.isNotEmpty)
            SizedBox(
              width: 320,
              height: 220,
              child: ReorderableListView.builder(
                itemCount: _selectedServers.length,

                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _selectedServers.removeAt(oldIndex);
                    _selectedServers.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final name = _selectedServers[index];
                  return ListTile(
                    key: ValueKey('serial-$name-$index'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(name),
                    leading: IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedServers.removeAt(index);
                        });
                      },
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  );
                },
              ),
            ),
          if (_selectedServers.isEmpty)
            Text(
              AppLocalizations.of(context)!.selectAtleastOneDnsServer,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
        ],
      ),
    );
  }
}

class _DnsServerForm extends StatefulWidget {
  const _DnsServerForm({super.key, this.dnsServer});
  final DnsServer? dnsServer;
  @override
  State<_DnsServerForm> createState() => __DnsServerFormState();
}

class __DnsServerFormState extends State<_DnsServerForm> with FormDataGetter {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fakeDnsPoolController = TextEditingController();
  final _lruSizeController = TextEditingController(text: '6666');
  final _dnsServerAddressController = TextEditingController();
  final _clientIpController = TextEditingController();
  final _cacheDurationController = TextEditingController();
  final List<String> _ipTags = [];
  bool _useDefaultDns = false;
  DnsServerType? _type = DnsServerType.plain;

  List<String> _splitCsv(String value) => value
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  @override
  Object? get formData {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return null;
    }
    if (_type == null) {
      return null;
    }
    final name = _nameController.text.trim();
    final clientIp = _clientIpController.text.trim();
    final cacheDuration = int.tryParse(_cacheDurationController.text.trim());
    final addresses = _splitCsv(_dnsServerAddressController.text);
    if (_type == DnsServerType.fake) {
      final lruSize = int.parse(_lruSizeController.text.trim());
      return DnsServerConfig(
        name: name,
        fakeDnsServer: FakeDnsServer(
          poolConfigs: _splitCsv(_fakeDnsPoolController.text)
              .map(
                (e) => FakeDnsServer_PoolConfig(cidr: e, lruSize: lruSize),
              )
              .toList(),
        ),
      );
    }
    if (_type == DnsServerType.plain) {
      return DnsServerConfig(
        name: name,
        ipTags: _ipTags,
        cacheDuration: cacheDuration,
        clientIp: clientIp,
        plainDnsServer: PlainDnsServer(
          useDefaultDns: _useDefaultDns,
          addresses: addresses,
        ),
      );
    }
    if (_type == DnsServerType.tls) {
      return DnsServerConfig(
        name: name,
        ipTags: _ipTags,
        cacheDuration: cacheDuration,
        clientIp: clientIp,
        tlsDnsServer: TlsDnsServer(addresses: addresses),
      );
    }
    if (_type == DnsServerType.doh) {
      return DnsServerConfig(
        name: name,
        clientIp: clientIp,
        ipTags: _ipTags,
        cacheDuration: cacheDuration,
        dohDnsServer: DohDnsServer(url: _dnsServerAddressController.text.trim()),
      );
    }
    if (_type == DnsServerType.quic) {
      return DnsServerConfig(
        name: name,
        clientIp: clientIp,
        ipTags: _ipTags,
        cacheDuration: cacheDuration,
        quicDnsServer: QuicDnsServer(
          address: _dnsServerAddressController.text.trim(),
        ),
      );
    }
    if (_type == DnsServerType.go) {
      return DnsServerConfig(
        name: name,
        clientIp: clientIp,
        ipTags: _ipTags,
        cacheDuration: cacheDuration,
        goDnsServer: GoDnsServer(),
      );
    }
    if (_type == DnsServerType.empty) {
      return DnsServerConfig(
        name: name,
        clientIp: clientIp,
        ipTags: _ipTags,
        cacheDuration: cacheDuration,
        emptyDnsServer: EmptyDnsServer(),
      );
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.dnsServer != null) {
      _nameController.text = widget.dnsServer!.name;
      _type = _getDnsServerType(widget.dnsServer!);
      _ipTags.addAll(widget.dnsServer!.dnsServer!.ipTags);
      _clientIpController.text = widget.dnsServer!.dnsServer!.clientIp;
      _cacheDurationController.text =
          widget.dnsServer!.dnsServer!.cacheDuration != 0
          ? widget.dnsServer!.dnsServer!.cacheDuration.toString()
          : '';
      if (widget.dnsServer!.dnsServer!.hasFakeDnsServer()) {
        _fakeDnsPoolController.text = widget
            .dnsServer!
            .dnsServer!
            .fakeDnsServer
            .poolConfigs
            .map((e) => e.cidr)
            .join(',');
        _lruSizeController.text =
            widget
                .dnsServer!
                .dnsServer!
                .fakeDnsServer
                .poolConfigs
                .firstOrNull
                ?.lruSize
                .toString() ??
            '6666';
      } else if (widget.dnsServer!.dnsServer!.hasPlainDnsServer()) {
        _useDefaultDns =
            widget.dnsServer!.dnsServer!.plainDnsServer.useDefaultDns;
        _dnsServerAddressController.text = widget
            .dnsServer!
            .dnsServer!
            .plainDnsServer
            .addresses
            .join(',');
      } else if (widget.dnsServer!.dnsServer!.hasDohDnsServer()) {
        _dnsServerAddressController.text =
            widget.dnsServer!.dnsServer!.dohDnsServer.url;
      } else if (widget.dnsServer!.dnsServer!.hasTlsDnsServer()) {
        _dnsServerAddressController.text = widget
            .dnsServer!
            .dnsServer!
            .tlsDnsServer
            .addresses
            .join(',');
      } else if (widget.dnsServer!.dnsServer!.hasQuicDnsServer()) {
        _dnsServerAddressController.text =
            widget.dnsServer!.dnsServer!.quicDnsServer.address;
      } else if (widget.dnsServer!.dnsServer!.hasGoDnsServer()) {
        // no specific fields
      } else if (widget.dnsServer!.dnsServer!.hasEmptyDnsServer()) {
        // no specific fields
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fakeDnsPoolController.dispose();
    _dnsServerAddressController.dispose();
    _lruSizeController.dispose();
    _clientIpController.dispose();
    _cacheDurationController.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.empty;
    }
    return null;
  }

  String? validAddressPorts(String? value, {bool optional = false}) {
    final items = _splitCsv(value ?? '');
    if (items.isEmpty) {
      return optional ? null : AppLocalizations.of(context)!.empty;
    }
    for (final addressPort in items) {
      if (!isValidAddressPort(addressPort)) {
        return AppLocalizations.of(context)!.invalidAddress;
      }
    }
    return null;
  }

  String? _validPositiveInt(String? value) {
    final required = _required(value);
    if (required != null) {
      return required;
    }
    final n = int.tryParse(value!.trim());
    if (n == null || n <= 0) {
      return AppLocalizations.of(context)!.invalidInterval;
    }
    return null;
  }

  String? _validOptionalNonNegativeInt(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final n = int.tryParse(value.trim());
    if (n == null || n < 0) {
      return AppLocalizations.of(context)!.invalidInterval;
    }
    return null;
  }

  String? _validDohUrl(String? value) {
    final required = _required(value);
    if (required != null) {
      return required;
    }
    final uri = Uri.tryParse(value!.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return AppLocalizations.of(context)!.invalidUrl;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            validator: _required,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              labelText: AppLocalizations.of(context)!.name,
            ),
          ),
          const SizedBox(height: 10),
          FormField<DnsServerType>(
            initialValue: _type,
            validator: (value) =>
                _type == null ? AppLocalizations.of(context)!.empty : null,
            builder: (state) {
              return DropdownMenu<DnsServerType>(
                label: Text(AppLocalizations.of(context)!.type),
                initialSelection: _type,
                errorText: state.errorText,
                onSelected: (value) {
                  setState(() {
                    _type = value;
                  });
                  state.didChange(value);
                },
                dropdownMenuEntries: DnsServerType.values
                    .map(
                      (e) =>
                          DropdownMenuEntry(value: e, label: e.label(context)),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 10),
          if (_type == DnsServerType.fake)
            Column(
              children: [
                TextFormField(
                  controller: _fakeDnsPoolController,
                  validator: (value) {
                    final required = _required(value);
                    if (required != null) {
                      return required;
                    }
                    for (final cidr in _splitCsv(value!)) {
                      if (!isValidCidr(cidr)) {
                        return AppLocalizations.of(context)!.invalidCidr;
                      }
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: '198.18.0.0/15,fc00::/18',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    labelText: AppLocalizations.of(context)!.dnsPool,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _lruSizeController,
                  keyboardType: TextInputType.number,
                  validator: _validPositiveInt,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.lruSize,
                    helperMaxLines: 2,
                    helperText: AppLocalizations.of(context)!.lruSizeDesc,
                  ),
                ),
              ],
            ),
          if (_type == DnsServerType.plain)
            Column(
              children: [
                TextFormField(
                  controller: _dnsServerAddressController,
                  validator: (value) =>
                      validAddressPorts(value, optional: _useDefaultDns),
                  decoration: InputDecoration(
                    helperText: AppLocalizations.of(context)!.addDnsAddressHint,
                    helperMaxLines: 5,
                    hintText: '1.1.1.1:53,[2001:4860:4860::8888]:53',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    labelText: AppLocalizations.of(context)!.addresses,
                  ),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: _useDefaultDns,
                  onChanged: (value) {
                    setState(() {
                      _useDefaultDns = value ?? false;
                    });
                    _formKey.currentState?.validate();
                  },
                  title: Text(
                    AppLocalizations.of(context)!.useDefaultDnsServer,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          if (_type == DnsServerType.doh)
            Column(
              children: [
                TextFormField(
                  controller: _dnsServerAddressController,
                  validator: _validDohUrl,
                  decoration: InputDecoration(
                    hintText: 'https://1.1.1.1/dns-query',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    labelText: AppLocalizations.of(context)!.address,
                  ),
                ),
              ],
            ),
          if (_type == DnsServerType.tls)
            Column(
              children: [
                TextFormField(
                  controller: _dnsServerAddressController,
                  validator: validAddressPorts,
                  decoration: InputDecoration(
                    hintText: '1.1.1.1:853,[2001:4860:4860::8888]:853',
                    helperText: AppLocalizations.of(context)!.addDnsAddressHint,
                    helperMaxLines: 3,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    labelText: AppLocalizations.of(context)!.addresses,
                  ),
                ),
              ],
            ),
          if (_type == DnsServerType.quic)
            Column(
              children: [
                TextFormField(
                  controller: _dnsServerAddressController,
                  validator: (value) {
                    final required = _required(value);
                    if (required != null) {
                      return required;
                    }
                    if (!isValidAddressPort(value!.trim())) {
                      return AppLocalizations.of(context)!.invalidAddress;
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'dns.adguard.com:853',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    labelText: AppLocalizations.of(context)!.address,
                  ),
                ),
              ],
            ),
          if (_type != DnsServerType.fake && _type != DnsServerType.empty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_type != DnsServerType.go)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextFormField(
                      controller: _clientIpController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        if (!isValidIp(value.trim())) {
                          return AppLocalizations.of(context)!.invalidIp;
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        hintText: '123.123.123.123',
                        labelText: AppLocalizations.of(context)!.clientIp,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _cacheDurationController,
                  keyboardType: TextInputType.number,
                  validator: _validOptionalNonNegativeInt,
                  decoration: InputDecoration(
                    hintText: '3600',
                    suffixText: 's',
                    labelText: AppLocalizations.of(context)!.cacheDuration,
                    helperText: AppLocalizations.of(context)!.cacheDurationDesc,
                    helperMaxLines: 2,
                  ),
                ),
                const SizedBox(height: 10),
                _IpTags(dstIpTags: _ipTags, onChanged: () {}),
              ],
            ),
        ],
      ),
    );
  }
}

class _IpTags extends StatelessWidget {
  const _IpTags({required this.dstIpTags, required this.onChanged});
  final List<String> dstIpTags;
  final Function() onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.resultIpSet),
        const SizedBox(height: 5),
        Text(
          AppLocalizations.of(context)!.resultIpSetDesc,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        IPSet(ipTags: dstIpTags, onChanged: onChanged),
      ],
    );
  }
}

enum DnsServerType { fake, plain, doh, tls, quic, go, empty }

extension DnsServerTypeI18n on DnsServerType {
  String label(BuildContext context) {
    final al = AppLocalizations.of(context)!;
    switch (this) {
      case DnsServerType.fake:
        return al.dnsTypeFake;
      case DnsServerType.plain:
        return al.dnsTypePlain;
      case DnsServerType.doh:
        return al.dnsTypeDoh;
      case DnsServerType.tls:
        return al.dnsTypeTls;
      case DnsServerType.quic:
        return al.dnsTypeQuic;
      case DnsServerType.go:
        return al.dnsTypeGo;
      case DnsServerType.empty:
        return al.dnsTypeEmpty;
    }
  }
}
