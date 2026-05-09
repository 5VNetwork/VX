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
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:tm/protos/vx/common/geo/geo.pb.dart';
import 'package:tm/protos/vx/geo/geo.pb.dart';
import 'package:vx/app/routing/mode_widget.dart';
import 'package:vx/app/routing/routing_page.dart';
import 'package:vx/app/routing/mode_form.dart';
import 'package:flutter_common/util/net.dart';
import 'package:vx/data/database.dart';
import 'package:vx/data/database_provider.dart';
import 'package:vx/widgets/form_dialog.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/widgets/text_divider.dart';

class GreatDomainSetForm extends StatefulWidget {
  const GreatDomainSetForm({super.key, this.domainSetConfig});
  final GreatDomainSetConfig? domainSetConfig;

  @override
  State<GreatDomainSetForm> createState() => _GreatDomainSetFormState();
}

class _GreatDomainSetFormState extends State<GreatDomainSetForm>
    with FormDataGetter {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _oppositeNameController = TextEditingController();
  final GreatDomainSetConfig _domainSetConfig = GreatDomainSetConfig();
  @override
  Object? get formData {
    if (_formKey.currentState!.validate()) {
      _domainSetConfig.name = _nameController.text;
      _domainSetConfig.oppositeName = _oppositeNameController.text;
      return _domainSetConfig;
    } else {
      return null;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.domainSetConfig != null) {
      _domainSetConfig.mergeFromMessage(widget.domainSetConfig!);
      _nameController.text = _domainSetConfig.name;
      _oppositeNameController.text = _domainSetConfig.oppositeName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _oppositeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.nameCannotBeEmpty;
              }

              return null;
            },
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.name,
              helperText: AppLocalizations.of(context)!.setNameDuplicate,
              helperStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const Gap(10),
          TextFormField(
            controller: _oppositeNameController,
            validator: (value) {
              return null;
            },
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.mutuallyExclusiveSetName,
              helperText: AppLocalizations.of(context)!.setNameDuplicate,
              helperStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const Gap(5),
          Text(
            AppLocalizations.of(context)!.include,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const Gap(5),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children:
                _domainSetConfig.inNames
                    .map<Widget>(
                      (e) => WrapChip(
                        text: localizedSetName(context, e),
                        onDelete: () {
                          _domainSetConfig.inNames.remove(e);
                          setState(() {});
                        },
                      ),
                    )
                    .toList()
                  ..add(
                    DomainSetPicker(
                      onChanged: (p0) async {
                        setState(() {
                          _domainSetConfig.inNames.add(p0);
                          _domainSetConfig.exNames.remove(p0);
                        });
                      },
                    ),
                  ),
          ),
          const Gap(5),
          Text(
            AppLocalizations.of(context)!.exclude,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const Gap(5),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children:
                _domainSetConfig.exNames
                    .map<Widget>(
                      (e) => WrapChip(
                        text: localizedSetName(context, e),
                        onDelete: () {
                          _domainSetConfig.exNames.remove(e);
                          setState(() {});
                        },
                      ),
                    )
                    .toList()
                  ..add(
                    DomainSetPicker(
                      onChanged: (p0) async {
                        _domainSetConfig.exNames.add(p0);
                        _domainSetConfig.inNames.remove(p0);
                        setState(() {});
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class GreatIpSetForm extends StatefulWidget {
  const GreatIpSetForm({super.key, this.ipSetConfig});
  final GreatIPSetConfig? ipSetConfig;

  @override
  State<GreatIpSetForm> createState() => _GreatIpSetFormState();
}

class _GreatIpSetFormState extends State<GreatIpSetForm> with FormDataGetter {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final GreatIPSetConfig _greatIpSetConfig = GreatIPSetConfig();
  List<AtomicIpSet> _atomicIpSetConfigs = [];
  final _oppositeNameController = TextEditingController();

  @override
  Object? get formData {
    if (_formKey.currentState!.validate()) {
      _greatIpSetConfig.name = _nameController.text;
      _greatIpSetConfig.oppositeName = _oppositeNameController.text;
      return _greatIpSetConfig;
    } else {
      return null;
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.ipSetConfig != null) {
      _greatIpSetConfig.mergeFromMessage(widget.ipSetConfig!);
      _nameController.text = _greatIpSetConfig.name;
      _oppositeNameController.text = _greatIpSetConfig.oppositeName;
    }
    final database = context.read<DatabaseProvider>().database;
    database.managers.atomicIpSets.get().then((value) {
      _atomicIpSetConfigs = value;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.nameCannotBeEmpty;
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.name,
              helperText: AppLocalizations.of(context)!.setNameDuplicate,
              helperStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          const Gap(10),
          TextFormField(
            controller: _oppositeNameController,
            validator: (value) {
              return null;
            },
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.mutuallyExclusiveSetName,
            ),
          ),
          const Gap(5),
          Text(
            AppLocalizations.of(context)!.include,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const Gap(5),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children:
                _greatIpSetConfig.inNames
                    .map<Widget>(
                      (e) => WrapChip(
                        text: localizedSetName(context, e),
                        onDelete: () {
                          _greatIpSetConfig.inNames.remove(e);
                          setState(() {});
                        },
                      ),
                    )
                    .toList()
                  ..add(
                    MenuAnchor(
                      menuChildren: _atomicIpSetConfigs
                          .where(
                            (e) => !_greatIpSetConfig.inNames.contains(e.name),
                          )
                          .map(
                            (e) => MenuItemButton(
                              onPressed: () {
                                _greatIpSetConfig.inNames.add(e.name);
                                _greatIpSetConfig.exNames.remove(e.name);
                                setState(() {});
                              },
                              child: Text(localizedSetName(context, e.name)),
                            ),
                          )
                          .toList(),
                      builder: (context, controller, child) {
                        return IconButton.filledTonal(
                          onPressed: () => controller.open(),
                          style: IconButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(0),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                        );
                      },
                    ),
                  ),
          ),
          const Gap(5),
          Text(
            AppLocalizations.of(context)!.exclude,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const Gap(5),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children:
                _greatIpSetConfig.exNames
                    .map<Widget>(
                      (e) => WrapChip(
                        text: localizedSetName(context, e),
                        onDelete: () {
                          _greatIpSetConfig.exNames.remove(e);
                          setState(() {});
                        },
                      ),
                    )
                    .toList()
                  ..add(
                    MenuAnchor(
                      menuChildren: _atomicIpSetConfigs
                          .where(
                            (e) => !_greatIpSetConfig.exNames.contains(e.name),
                          )
                          .map(
                            (e) => MenuItemButton(
                              onPressed: () {
                                _greatIpSetConfig.exNames.add(e.name);
                                _greatIpSetConfig.inNames.remove(e.name);
                                setState(() {});
                              },
                              child: Text(localizedSetName(context, e.name)),
                            ),
                          )
                          .toList(),
                      builder: (context, controller, child) {
                        return IconButton.filledTonal(
                          onPressed: () => controller.open(),
                          style: IconButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(0),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class WrapChip extends StatelessWidget {
  const WrapChip({super.key, required this.text, this.onDelete, this.onTap});
  final String text;
  final Function()? onDelete;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = MenuAnchor(
      menuChildren: [
        MenuItemButton(
          onPressed: onDelete,
          child: Text(AppLocalizations.of(context)!.delete),
        ),
      ],
      builder: (context, controller, child) {
        return GestureDetector(
          onDoubleTap: onDelete,
          onLongPressStart: (details) {
            controller.open(
              position: Offset(
                details.localPosition.dx,
                details.localPosition.dy,
              ),
            );
          },
          onSecondaryTapDown: (details) {
            controller.open(
              position: Offset(
                details.localPosition.dx,
                details.localPosition.dy,
              ),
            );
          },
          child: onTap != null
              ? ActionChip(onPressed: onTap, label: Text(text))
              : Chip(
                  label: Text(
                    text,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(),
                  ),
                ),
        );
      },
    );
    return chip;
  }
}

class SmallDomainSetForm extends StatefulWidget {
  const SmallDomainSetForm({super.key, this.atomicDomainSet});
  final AtomicDomainSet? atomicDomainSet;
  @override
  State<SmallDomainSetForm> createState() => _SmallDomainSetFormState();
}

class _SmallDomainSetFormState extends State<SmallDomainSetForm>
    with FormDataGetter {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _geositeCodeController = TextEditingController();
  final _geositeAttributeController = TextEditingController();
  final _geositeCodes = <String>[];
  final _geositeAttributes = <String>[];
  final _clashRuleUrls = <String>[];
  final _geositeUrlController = TextEditingController();
  List<Domain> _domains = [];
  bool _useBloomFilter = false;
  // FilePickerResult? _geositeFilePickerResult;
  bool _inverse = false;

  @override
  Object? get formData {
    if (_formKey.currentState!.validate()) {
      if (_geositeCodeController.text.isNotEmpty) {
        _geositeCodes.add(_geositeCodeController.text);
      }
      if (_geositeAttributeController.text.isNotEmpty) {
        _geositeAttributes.add(_geositeAttributeController.text);
      }
      return AtomicDomainSet(
        name: _nameController.text,
        inverse: _inverse,
        geoUrl: _geositeUrlController.text,
        geositeConfig: GeositeConfig(
          codes: _geositeCodes,
          attributes: _geositeAttributes,
        ),
        clashRuleUrls: _clashRuleUrls,
        useBloomFilter: _useBloomFilter,
      );
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.atomicDomainSet != null) {
      _nameController.text = widget.atomicDomainSet!.name;
      widget.atomicDomainSet!.geositeConfig?.filepath ?? '';
      _geositeCodes.addAll(widget.atomicDomainSet!.geositeConfig?.codes ?? []);
      _geositeAttributes.addAll(
        widget.atomicDomainSet!.geositeConfig?.attributes ?? [],
      );
      _inverse = widget.atomicDomainSet!.inverse;
      _clashRuleUrls.addAll(widget.atomicDomainSet!.clashRuleUrls ?? []);
      context
          .read<DatabaseProvider>()
          .database
          .managers
          .geoDomains
          .filter((e) => e.domainSetName.name(widget.atomicDomainSet!.name))
          .get()
          .then((value) {
            _domains = value.map((e) => e.geoDomain).toList();
            setState(() {});
          });
      _geositeUrlController.text = widget.atomicDomainSet!.geoUrl ?? '';
      _useBloomFilter = widget.atomicDomainSet!.useBloomFilter;
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _geositeUrlController.dispose();
    _nameController.dispose();
    _geositeCodeController.dispose();
    _geositeAttributeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 400),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.nameCannotBeEmpty;
                }
                return null;
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                labelText: AppLocalizations.of(context)!.name,
                helperText: AppLocalizations.of(context)!.setNameDuplicate,
                helperStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Gap(5),
            CheckboxListTile(
              value: _useBloomFilter,
              onChanged: (value) {
                setState(() {
                  _useBloomFilter = value ?? false;
                });
              },
              title: Text(
                AppLocalizations.of(context)!.useBloomFilter,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              subtitle: Text(
                AppLocalizations.of(context)!.useBloomFilterDesc,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.inverse),
              value: _inverse,
              onChanged: (value) {
                setState(() {
                  _inverse = value;
                });
              },
            ),
            const Gap(5),
            const TextDivider(text: 'GeoSite'),
            const Gap(5),
            TextFormField(
              controller: _geositeUrlController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                labelText: 'URL',
                helperText: AppLocalizations.of(context)!.geositeUrlDesc,
                helperStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Gap(5),
            Text(
              'GeoSite Codes',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(5),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: _geositeCodes
                  .map(
                    (e) => WrapChip(
                      text: e,
                      onDelete: () {
                        _geositeCodes.remove(e);
                        setState(() {});
                      },
                    ),
                  )
                  .toList(),
            ),
            const Gap(5),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _geositeCodeController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      labelText: 'GeoSite Code',
                    ),
                  ),
                ),
                const Gap(10),
                IconButton.filledTonal(
                  onPressed: () {
                    _geositeCodes.add(_geositeCodeController.text);
                    _geositeCodeController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const Gap(10),
            Text(
              'GeoSite Attributes',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(5),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: _geositeAttributes
                  .map(
                    (e) => WrapChip(
                      text: e,
                      onDelete: () {
                        _geositeAttributes.remove(e);
                        setState(() {});
                      },
                    ),
                  )
                  .toList(),
            ),
            const Gap(5),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _geositeAttributeController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      labelText: 'GeoSite Attribute',
                    ),
                  ),
                ),
                const Gap(10),
                IconButton.filledTonal(
                  onPressed: () {
                    _geositeAttributes.add(_geositeAttributeController.text);
                    _geositeAttributeController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const Gap(5),
            const TextDivider(text: 'Urls'),
            const Gap(5),
            ClashRule(clashRuleUrls: _clashRuleUrls),
            const Gap(10),
            TextDivider(text: AppLocalizations.of(context)!.domain),
            const Gap(5),
            Wrap(
              runSpacing: 10,
              spacing: 10,
              children: buildWrapChildrenForDomains(context, _domains, null),
            ),
            const Gap(10),
          ],
        ),
      ),
    );
  }
}

class ClashRule extends StatefulWidget {
  const ClashRule({super.key, required this.clashRuleUrls});
  final List<String> clashRuleUrls;
  @override
  State<ClashRule> createState() => _ClashRuleState();
}

class _ClashRuleState extends State<ClashRule> {
  final _clashRuleUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _clashRuleUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          children: widget.clashRuleUrls
              .map(
                (e) => ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  shape: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        widget.clashRuleUrls.remove(e);
                      });
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                  tileColor: Theme.of(context).colorScheme.surfaceContainer,
                  title: Text(e),
                ),
              )
              .toList(),
        ),
        const Gap(10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _clashRuleUrlController,
                decoration: InputDecoration(
                  helperText: AppLocalizations.of(
                    context,
                  )!.clashFormatSupported,
                  hintText: "https://example.com/clash-rules",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  labelText: 'Urls',
                ),
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      !widget.clashRuleUrls.contains(value) &&
                      isValidHttpHttpsUrl(value)) {
                    widget.clashRuleUrls.add(value);
                  }
                  return null;
                },
              ),
            ),
            const Gap(10),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: IconButton.filledTonal(
                onPressed: () {
                  if (_clashRuleUrlController.text.isEmpty ||
                      widget.clashRuleUrls.contains(
                        _clashRuleUrlController.text,
                      ) ||
                      !isValidHttpHttpsUrl(_clashRuleUrlController.text)) {
                    return;
                  }
                  widget.clashRuleUrls.add(_clashRuleUrlController.text);
                  _clashRuleUrlController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.add_rounded),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SmallIpSetForm extends StatefulWidget {
  const SmallIpSetForm({super.key, this.atomicIpSet});
  final AtomicIpSet? atomicIpSet;
  @override
  State<SmallIpSetForm> createState() => _SmallIpSetFormState();
}

class _SmallIpSetFormState extends State<SmallIpSetForm> with FormDataGetter {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _geoIpFilePathController = TextEditingController();
  final _geoIpCodeController = TextEditingController();
  final _clashRuleUrls = <String>[];
  final _geoIpCodes = <String>[];
  List<CIDR> _cidrs = [];
  final _geoUrlController = TextEditingController();
  bool _inverse = false;

  @override
  Object? get formData {
    if (_formKey.currentState!.validate()) {
      if (_geoIpFilePathController.text.isNotEmpty) {
        _geoIpCodes.add(_geoIpFilePathController.text);
        _geoIpFilePathController.clear();
      }
      return AtomicIpSet(
        inverse: _inverse,
        name: _nameController.text,
        clashRuleUrls: _clashRuleUrls,
        geoIpConfig: GeoIPConfig(
          filepath: _geoIpFilePathController.text,
          codes: _geoIpCodes,
        ),
        geoUrl: _geoUrlController.text,
      );
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.atomicIpSet != null) {
      _nameController.text = widget.atomicIpSet!.name;
      _geoIpFilePathController.text =
          widget.atomicIpSet!.geoIpConfig?.filepath ?? '';
      _geoIpCodes.addAll(widget.atomicIpSet!.geoIpConfig?.codes ?? []);
      _inverse = widget.atomicIpSet!.inverse;
      _clashRuleUrls.addAll(widget.atomicIpSet!.clashRuleUrls ?? []);
      context
          .read<DatabaseProvider>()
          .database
          .managers
          .cidrs
          .filter((e) => e.ipSetName.name(widget.atomicIpSet!.name))
          .get()
          .then((value) {
            _cidrs = value.map((e) => e.cidr).toList();
            setState(() {});
          });
      _geoUrlController.text = widget.atomicIpSet!.geoUrl ?? '';
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _nameController.dispose();
    _geoIpFilePathController.dispose();
    _geoIpCodeController.dispose();
    _geoUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 400),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.nameCannotBeEmpty;
                }
                return null;
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                labelText: AppLocalizations.of(context)!.name,
                helperText: AppLocalizations.of(context)!.setNameDuplicate,
                helperStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.inverse),
              value: _inverse,
              onChanged: (value) {
                setState(() {
                  _inverse = value;
                });
              },
            ),
            const Gap(5),
            const TextDivider(text: 'GeoIP'),
            const Gap(5),
            TextFormField(
              controller: _geoUrlController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                labelText: 'URL',
                helperText: AppLocalizations.of(context)!.geoUrlDesc,
                helperStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Gap(5),
            Text(
              'GeoIP Codes',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(5),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: _geoIpCodes
                  .map(
                    (e) => WrapChip(
                      text: e,
                      onDelete: () {
                        _geoIpCodes.remove(e);
                        setState(() {});
                      },
                    ),
                  )
                  .toList(),
            ),
            const Gap(5),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _geoIpCodeController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      labelText: 'GeoIP Code',
                    ),
                  ),
                ),
                const Gap(10),
                IconButton.filledTonal(
                  onPressed: () {
                    if (_geoIpCodeController.text.isEmpty) {
                      return;
                    }
                    _geoIpCodes.add(_geoIpCodeController.text);
                    _geoIpCodeController.clear();
                    setState(() {});
                  },
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const Gap(5),
            const TextDivider(text: 'Clash Rules'),
            const Gap(5),
            ClashRule(clashRuleUrls: _clashRuleUrls),
            const Gap(10),
            const TextDivider(text: 'IP'),
            const Gap(5),
            Wrap(
              runSpacing: 10,
              spacing: 10,
              children: _cidrs
                  .map((e) => WrapChip(text: cidrToString(e)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class ClashRuleSet extends StatefulWidget {
  const ClashRuleSet({super.key});

  @override
  State<ClashRuleSet> createState() => _ClashRuleSetState();
}

class _ClashRuleSetState extends State<ClashRuleSet> with FormDataGetter {
  final _setNameController = TextEditingController();
  final List<String> _clashRuleUrls = [];
  final _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
  }

  @override
  Object? get formData {
    if (!_formKey.currentState!.validate()) {
      return null;
    }
    if (_setNameController.text.isEmpty) {
      return null;
    }
    if (_clashRuleUrls.isEmpty) {
      return null;
    }
    return (name: _setNameController.text, clashRuleUrls: _clashRuleUrls);
  }

  @override
  void dispose() {
    _setNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _setNameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.nameCannotBeEmpty;
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.setName,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                helperText: AppLocalizations.of(context)!.setNameDuplicate,
                helperStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Gap(10),
            ClashRule(clashRuleUrls: _clashRuleUrls),
          ],
        ),
      ),
    );
  }
}
