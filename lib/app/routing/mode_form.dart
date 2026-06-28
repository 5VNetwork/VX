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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:tm/protos/vx/common/geo/geo.pb.dart';
import 'package:tm/protos/vx/common/net/net.pb.dart';
import 'package:tm/protos/vx/dns/dns.pb.dart';
import 'package:tm/protos/vx/outbound/outbound.pb.dart';
import 'package:tm/protos/vx/router/router.pb.dart';
import 'package:vx/app/log/log_page.dart';
import 'package:vx/app/outbound/outbound_repo.dart';
import 'package:vx/app/routing/add_dialog.dart';
import 'package:vx/app/routing/mode_widget.dart';
import 'package:vx/app/routing/routing_page.dart';
import 'package:vx/common/config.dart';
import 'package:flutter_common/util/net.dart';
import 'package:vx/data/database.dart';
import 'package:vx/data/database_provider.dart';
import 'package:vx/widgets/form_dialog.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/widgets/text_divider.dart';

enum OutboundType { node, selector, block }

final directHandler = OutboundHandler(
  id: -1,
  config: HandlerConfig(outbound: OutboundHandlerConfig(tag: directHandlerTag)),
);

final proxySelector = HandlerSelector(
  name: defaultProxySelectorTag,
  config: SelectorConfig(),
);

class RouteRuleForm extends StatefulWidget {
  const RouteRuleForm({super.key, this.ruleConfig});
  final RuleConfig? ruleConfig;

  @override
  State<RouteRuleForm> createState() => _RouteRuleFormState();
}

enum ConditionSection {
  fake,
  hasNoDomain,
  ipv6,
  network,
  inbound,
  domain,
  ip,
  srcIp,
  app,
  all,
  port,
  protocol,
}

bool conditionIsEmpty(Condition c) {
  return c.inboundTags.isEmpty &&
      !c.fakeIp &&
      !c.hasNoDomain &&
      !c.ipv6 &&
      c.domainTags.isEmpty &&
      c.geoDomains.isEmpty &&
      c.dstCidrs.isEmpty &&
      c.dstIpTags.isEmpty &&
      c.srcCidrs.isEmpty &&
      c.srcIpTags.isEmpty &&
      c.appIds.isEmpty &&
      c.appTags.isEmpty &&
      c.allTags.isEmpty &&
      c.networks.isEmpty &&
      !c.resolveDomain &&
      !c.resolveSoftRewrite &&
      !c.resolveSoftNoRewrite &&
      !c.skipSniff &&
      c.usernames.isEmpty &&
      c.srcPortRanges.isEmpty &&
      c.dstPortRanges.isEmpty &&
      c.protocols.isEmpty;
}

void clearLegacyRuleConditionFields(RuleConfig rule) {
  rule
    ..clearCondition()
    ..srcCidrs.clear()
    ..srcIpTags.clear()
    ..dstCidrs.clear()
    ..dstIpTags.clear()
    ..resolveDomain = false
    ..resolveSoftRewrite = false
    ..resolveSoftNoRewrite = false
    ..geoDomains.clear()
    ..domainTags.clear()
    ..skipSniff = false
    ..usernames.clear()
    ..inboundTags.clear()
    ..networks.clear()
    ..srcPortRanges.clear()
    ..dstPortRanges.clear()
    ..appIds.clear()
    ..ipv6 = false
    ..fakeIp = false
    ..matchAll = false
    ..appTags.clear()
    ..allTags.clear()
    ..protocols.clear();
}

List<Condition> loadConditionsFromRuleConfig(RuleConfig rule) {
  if (rule.conditions.isNotEmpty) {
    return rule.conditions.map((c) => c.clone()).toList();
  }
  if (rule.hasCondition()) {
    return [rule.condition.clone()];
  }
  return [
    Condition(
      inboundTags: rule.inboundTags,
      fakeIp: rule.fakeIp,
      domainTags: rule.domainTags,
      geoDomains: rule.geoDomains,
      appTags: rule.appTags,
      appIds: rule.appIds,
      dstCidrs: rule.dstCidrs,
      dstIpTags: rule.dstIpTags,
      allTags: rule.allTags,
      networks: rule.networks,
      skipSniff: rule.skipSniff,
      resolveDomain: rule.resolveDomain,
      resolveSoftRewrite: rule.resolveSoftRewrite,
      resolveSoftNoRewrite: rule.resolveSoftNoRewrite,
      srcCidrs: rule.srcCidrs,
      srcIpTags: rule.srcIpTags,
      srcPortRanges: rule.srcPortRanges,
      dstPortRanges: rule.dstPortRanges,
      usernames: rule.usernames,
      protocols: rule.protocols,
      ipv6: rule.ipv6,
    ),
  ];
}

void clearLegacyFallbackConditionFields(RuleConfig_Fallback fallback) {
  fallback
    ..clearCondition()
    ..dstIpTags.clear()
    ..domainTags.clear();
}

List<Condition> loadConditionsFromFallback(RuleConfig_Fallback fallback) {
  if (fallback.conditions.isNotEmpty) {
    return fallback.conditions.map((c) => c.clone()).toList();
  }
  if (fallback.hasCondition()) {
    return [fallback.condition.clone()];
  }
  return [
    Condition(domainTags: fallback.domainTags, dstIpTags: fallback.dstIpTags),
  ];
}

void updateConditionNontrivial(
  Condition condition,
  Map<ConditionSection, bool> nontrivial,
) {
  nontrivial[ConditionSection.inbound] = condition.inboundTags.isNotEmpty;
  nontrivial[ConditionSection.domain] =
      condition.geoDomains.isNotEmpty ||
      condition.domainTags.isNotEmpty ||
      condition.skipSniff;
  nontrivial[ConditionSection.ip] =
      condition.dstCidrs.isNotEmpty || condition.dstIpTags.isNotEmpty;
  nontrivial[ConditionSection.srcIp] =
      condition.srcCidrs.isNotEmpty || condition.srcIpTags.isNotEmpty;
  nontrivial[ConditionSection.ipv6] = condition.ipv6;
  nontrivial[ConditionSection.hasNoDomain] = condition.hasNoDomain;
  nontrivial[ConditionSection.app] =
      condition.appIds.isNotEmpty || condition.appTags.isNotEmpty;
  nontrivial[ConditionSection.fake] = condition.fakeIp;
  nontrivial[ConditionSection.all] = condition.allTags.isNotEmpty;
  nontrivial[ConditionSection.network] = condition.networks.isNotEmpty;
  nontrivial[ConditionSection.port] =
      condition.srcPortRanges.isNotEmpty || condition.dstPortRanges.isNotEmpty;
  nontrivial[ConditionSection.protocol] = condition.protocols.isNotEmpty;
}

class _RouteRuleFormState extends State<RouteRuleForm> with FormDataGetter {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ruleConfig = RuleConfig();
  List<Condition> _conditions = [Condition()];
  bool _matchAll = false;
  OutboundType _outboundType = OutboundType.node;

  List<OutboundHandler>? _outboundHandlers;
  OutboundHandler? _selectedOutboundHandler;
  String? nodeSelectError;

  List<HandlerSelector>? _selectors;
  HandlerSelector? _selectedSelector;
  String? selectorSelectError;

  @override
  Object? get formData {
    if (_formKey.currentState?.validate() ?? false) {
      if (_outboundType == OutboundType.node) {
        _ruleConfig.selectorTag = '';
        if (_selectedOutboundHandler == directHandler) {
          _ruleConfig.outboundTag = directHandlerTag;
        } else if (_selectedOutboundHandler == null) {
          setState(() {
            nodeSelectError = AppLocalizations.of(
              context,
            )!.selectAtleastOneNode;
          });
          return null;
        } else {
          _ruleConfig.outboundTag = _selectedOutboundHandler!.id.toString();
        }
      } else if (_outboundType == OutboundType.block) {
        _ruleConfig.outboundTag = '';
        _ruleConfig.selectorTag = '';
      } else if (_outboundType == OutboundType.selector) {
        _ruleConfig.outboundTag = '';
        if (_selectedSelector == null) {
          setState(() {
            selectorSelectError = AppLocalizations.of(
              context,
            )!.selectAtleastOneSelector;
          });
          return null;
        } else if (_selectedSelector == proxySelector) {
          _ruleConfig.selectorTag = defaultProxySelectorTag;
        } else {
          _ruleConfig.selectorTag = _selectedSelector!.name;
        }
      }
      _ruleConfig.ruleName = _nameController.text;
      clearLegacyRuleConditionFields(_ruleConfig);
      _ruleConfig.conditions.clear();
      if (_matchAll) {
        _ruleConfig.matchAll = true;
      } else {
        _ruleConfig.conditions.addAll(
          _conditions.where((c) => !conditionIsEmpty(c)),
        );
      }
      return _ruleConfig;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.ruleConfig != null) {
      _nameController.text = widget.ruleConfig!.ruleName;
      _ruleConfig.mergeFromMessage(widget.ruleConfig!);
      _conditions = loadConditionsFromRuleConfig(widget.ruleConfig!);
      _matchAll = widget.ruleConfig!.matchAll;
      if (_matchAll) {
        _conditions = [Condition()];
      }
      if (_ruleConfig.selectorTag.isNotEmpty) {
        _outboundType = OutboundType.selector;
        if (_ruleConfig.selectorTag == defaultProxySelectorTag) {
          _selectedSelector = proxySelector;
        }
      }
      if (_ruleConfig.outboundTag == directHandlerTag) {
        _selectedOutboundHandler = directHandler;
      }
      if (_ruleConfig.outboundTag.isEmpty && _ruleConfig.selectorTag.isEmpty) {
        _outboundType = OutboundType.block;
      }
    }
    context.read<OutboundRepo>().getAllHandlers().then((l) {
      _outboundHandlers = l;
      if (_outboundType == OutboundType.node) {
        setState(() {
          _selectedOutboundHandler ??= l
              .where((e) => e.id.toString() == _ruleConfig.outboundTag)
              .firstOrNull;
        });
      }
    });
    context
        .read<DatabaseProvider>()
        .database
        .managers
        .handlerSelectors
        .get()
        .then((l) {
          _selectors = l;
          if (_outboundType == OutboundType.selector) {
            setState(() {
              _selectedSelector ??= l
                  .where((e) => e.name == _ruleConfig.selectorTag)
                  .firstOrNull;
            });
          }
        });
  }

  void _addCondition() {
    setState(() {
      _conditions.add(Condition());
    });
  }

  void _removeCondition(int index) {
    setState(() {
      _conditions.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.pleaseEnterRuleName;
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.ruleName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const Gap(10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ChoiceChip(
                        label: Text(AppLocalizations.of(context)!.node),
                        selected: _outboundType == OutboundType.node,
                        onSelected: (value) {
                          if (value) {
                            setState(() {
                              _outboundType = OutboundType.node;
                            });
                          }
                        },
                      ),
                      const Gap(5),
                      ChoiceChip(
                        label: Text(AppLocalizations.of(context)!.selector),
                        selected: _outboundType == OutboundType.selector,
                        onSelected: (value) {
                          if (value) {
                            setState(() {
                              _outboundType = OutboundType.selector;
                            });
                          }
                        },
                      ),
                      const Gap(5),
                      ChoiceChip(
                        label: Text(AppLocalizations.of(context)!.block),
                        selected: _outboundType == OutboundType.block,
                        onSelected: (value) {
                          if (value) {
                            setState(() {
                              _outboundType = OutboundType.block;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const Gap(10),
                  if (_outboundType == OutboundType.node)
                    DropdownMenu<OutboundHandler>(
                      label: Text(AppLocalizations.of(context)!.node),
                      menuHeight: 320,
                      initialSelection: _selectedOutboundHandler,
                      onSelected: (value) {
                        setState(() {
                          nodeSelectError = null;
                          _selectedOutboundHandler = value;
                        });
                      },
                      errorText: nodeSelectError,
                      dropdownMenuEntries: [
                        DropdownMenuEntry(
                          label: AppLocalizations.of(context)!.direct,
                          value: directHandler,
                        ),
                        ..._outboundHandlers
                                ?.map(
                                  (e) => DropdownMenuEntry(
                                    label: e.name,
                                    value: e,
                                  ),
                                )
                                .toList() ??
                            [],
                      ],
                    ),
                  if (_outboundType == OutboundType.selector)
                    DropdownMenu<HandlerSelector>(
                      label: Text(AppLocalizations.of(context)!.selector),
                      initialSelection: _selectedSelector,
                      onSelected: (value) {
                        setState(() {
                          selectorSelectError = null;
                          _selectedSelector = value;
                        });
                      },
                      errorText: selectorSelectError,
                      dropdownMenuEntries: [
                        DropdownMenuEntry(
                          label: AppLocalizations.of(
                            context,
                          )!.defaultSelectorTag,
                          value: proxySelector,
                        ),
                        ..._selectors
                                ?.where((e) => e.name != proxySelector.name)
                                .map(
                                  (e) => DropdownMenuEntry(
                                    label: e.name,
                                    value: e,
                                  ),
                                )
                                .toList() ??
                            [],
                      ],
                    ),
                ],
              ),
              const Gap(5),
              Row(
                children: [
                  Text(AppLocalizations.of(context)!.matchAll),
                  const Gap(5),
                  Switch(
                    value: _matchAll,
                    onChanged: (value) {
                      setState(() {
                        _matchAll = value;
                      });
                    },
                  ),
                ],
              ),
              const Gap(10),
              if (!_matchAll)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextDivider(text: AppLocalizations.of(context)!.condition),
                    const Gap(5),
                    Text(
                      AppLocalizations.of(context)!.ruleMatchCondition,
                      style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Gap(10),
                    ...List.generate(_conditions.length, (index) {
                      return _RouteConditionEditor(
                        key: ObjectKey(_conditions[index]),
                        condition: _conditions[index],
                        index: index,
                        canDelete: _conditions.length > 1,
                        onDelete: () => _removeCondition(index),
                      );
                    }),
                    const Gap(5),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: _addCondition,
                        icon: const Icon(Icons.add_rounded),
                        label: Text(AppLocalizations.of(context)!.condition),
                      ),
                    ),
                  ],
                ),
              const Gap(10),
              _Fallbacks(
                rule: _ruleConfig,
                selectors: _selectors,
                outboundHandlers: _outboundHandlers,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteConditionEditor extends StatefulWidget {
  const _RouteConditionEditor({
    super.key,
    required this.condition,
    required this.index,
    required this.canDelete,
    required this.onDelete,
    this.onChanged,
  });

  final Condition condition;
  final int index;
  final bool canDelete;
  final VoidCallback onDelete;
  final VoidCallback? onChanged;

  @override
  State<_RouteConditionEditor> createState() => _RouteConditionEditorState();
}

class _RouteConditionEditorState extends State<_RouteConditionEditor> {
  late final Map<ConditionSection, bool> _nontrivial = Map.fromEntries(
    ConditionSection.values.map((e) => MapEntry(e, false)),
  );
  final List<bool> _isExpanded = List.filled(8, false);

  @override
  void initState() {
    super.initState();
    updateConditionNontrivial(widget.condition, _nontrivial);
  }

  void _onChanged() {
    updateConditionNontrivial(widget.condition, _nontrivial);
    setState(() {});
    widget.onChanged?.call();
  }

  void _toggleExpanded(int panelIndex) {
    setState(() {
      _isExpanded[panelIndex] = !_isExpanded[panelIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final condition = widget.condition;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${l10n.condition} ${widget.index + 1}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (widget.canDelete)
                    IconButton(
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l10n.delete,
                    ),
                ],
              ),
              const Gap(5),
              Text(
                l10n.conditionMatch,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(5),
              Text(
                l10n.enabledSubconditions(
                  _nontrivial.values.where((e) => e).length,
                ),
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (_nontrivial[ConditionSection.domain]! &&
                  _nontrivial[ConditionSection.ip]!)
                Padding(
                  padding: const EdgeInsets.only(top: 5.0),
                  child: Text(
                    l10n.conditaionWarn1,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium!.copyWith(color: Colors.deepOrange),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Fake IP'),
                        const Gap(3),
                        Checkbox(
                          value: condition.fakeIp,
                          onChanged: (value) {
                            condition.fakeIp = value ?? false;
                            _onChanged();
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.hasNoDomain),
                        const Gap(3),
                        Checkbox(
                          value: condition.hasNoDomain,
                          onChanged: (value) {
                            condition.hasNoDomain = value ?? false;
                            _onChanged();
                          },
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('IPv6'),
                        const Gap(3),
                        Checkbox(
                          value: condition.ipv6,
                          onChanged: (value) {
                            condition.ipv6 = value ?? false;
                            _onChanged();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(5),
              Row(
                children: [
                  const Text('Network'),
                  const Gap(10),
                  FilterChip(
                    label: const Text('TCP'),
                    selected: condition.networks.contains(Network.TCP),
                    onSelected: (value) {
                      value
                          ? condition.networks.add(Network.TCP)
                          : condition.networks.remove(Network.TCP);
                      _onChanged();
                    },
                  ),
                  const Gap(10),
                  FilterChip(
                    label: const Text('UDP'),
                    selected: condition.networks.contains(Network.UDP),
                    onSelected: (value) {
                      value
                          ? condition.networks.add(Network.UDP)
                          : condition.networks.remove(Network.UDP);
                      _onChanged();
                    },
                  ),
                ],
              ),
              const Gap(10),
              Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ExpansionPanelList(
                  expansionCallback: (panelIndex, _) {
                    _toggleExpanded(panelIndex);
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
                      headerBuilder: (context, _) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              l10n.inbound,
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(
                                    color:
                                        _nontrivial[ConditionSection.inbound]!
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                            ),
                          ),
                        );
                      },
                      isExpanded: _isExpanded[0],
                      body: InboundCondition(
                        condition: condition,
                        onChanged: _onChanged,
                      ),
                    ),
                    ExpansionPanel(
                      canTapOnHeader: true,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      headerBuilder: (context, _) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              l10n.domain,
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(
                                    color: _nontrivial[ConditionSection.domain]!
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                            ),
                          ),
                        );
                      },
                      isExpanded: _isExpanded[1],
                      body: DomainCondition(
                        condition: condition,
                        onChanged: _onChanged,
                      ),
                    ),
                    ExpansionPanel(
                      canTapOnHeader: true,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      headerBuilder: (context, _) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              l10n.dstIpSet,
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(
                                    color: _nontrivial[ConditionSection.ip]!
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                            ),
                          ),
                        );
                      },
                      isExpanded: _isExpanded[2],
                      body: IPCondition(
                        condition: condition,
                        onChanged: _onChanged,
                      ),
                    ),
                    ExpansionPanel(
                      canTapOnHeader: true,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      headerBuilder: (context, _) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '${l10n.source} IP',
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(
                                    color: _nontrivial[ConditionSection.srcIp]!
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                            ),
                          ),
                        );
                      },
                      isExpanded: _isExpanded[3],
                      body: SrcIPCondition(
                        condition: condition,
                        onChanged: _onChanged,
                      ),
                    ),
                    ExpansionPanel(
                      canTapOnHeader: true,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      headerBuilder: (context, _) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              l10n.app,
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(
                                    color: _nontrivial[ConditionSection.app]!
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                            ),
                          ),
                        );
                      },
                      isExpanded: _isExpanded[4],
                      body: AppCondition(
                        condition: condition,
                        onChanged: _onChanged,
                      ),
                    ),
                    ExpansionPanel(
                      canTapOnHeader: true,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      headerBuilder: (context, _) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '${l10n.domain}/IP/${l10n.app}',
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(
                                    color: _nontrivial[ConditionSection.all]!
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                            ),
                          ),
                        );
                      },
                      isExpanded: _isExpanded[5],
                      body: AllCondition(
                        condition: condition,
                        onChanged: _onChanged,
                      ),
                    ),
                    ExpansionPanel(
                      canTapOnHeader: true,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      headerBuilder: (context, _) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              l10n.port,
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(
                                    color: _nontrivial[ConditionSection.port]!
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                            ),
                          ),
                        );
                      },
                      isExpanded: _isExpanded[6],
                      body: PortCondition(
                        condition: condition,
                        onChanged: _onChanged,
                      ),
                    ),
                    ExpansionPanel(
                      canTapOnHeader: true,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      headerBuilder: (context, _) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              l10n.protocol,
                              style: Theme.of(context).textTheme.titleMedium!
                                  .copyWith(
                                    color:
                                        _nontrivial[ConditionSection.protocol]!
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                            ),
                          ),
                        );
                      },
                      isExpanded: _isExpanded[7],
                      body: ProtocolCondition(
                        condition: condition,
                        onChanged: _onChanged,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fallbacks extends StatefulWidget {
  const _Fallbacks({
    super.key,
    required this.rule,
    required this.selectors,
    required this.outboundHandlers,
  });

  final RuleConfig rule;
  final List<HandlerSelector>? selectors;
  final List<OutboundHandler>? outboundHandlers;

  @override
  State<_Fallbacks> createState() => _FallbacksState();
}

class _FallbacksState extends State<_Fallbacks> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fallbacks = widget.rule.fallbacks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextDivider(text: l10n.fallback),
        Gap(10),
        Text(
          l10n.fallbackDesc,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Gap(10),
        Column(
          children: [
            for (final (index, fallback) in fallbacks.indexed)
              _Fallback(
                index: index,
                fallback: fallback,
                onDelete: () {
                  setState(() {
                    widget.rule.fallbacks.remove(fallback);
                  });
                },
                selectors: widget.selectors,
                outboundHandlers: widget.outboundHandlers,
              ),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            onPressed: () {
              setState(() {
                final fallback = RuleConfig_Fallback()..matchAll = true;
                widget.rule.fallbacks.add(fallback);
              });
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(l10n.fallback),
          ),
        ),
      ],
    );
  }
}

class _Fallback extends StatefulWidget {
  _Fallback({
    super.key,
    required this.index,
    required this.fallback,
    this.selectors,
    this.outboundHandlers,
    required this.onDelete,
  });
  final int index;
  final RuleConfig_Fallback fallback;
  final List<HandlerSelector>? selectors;
  final List<OutboundHandler>? outboundHandlers;
  Function onDelete;

  @override
  State<_Fallback> createState() => _FallbackState();
}

class _FallbackState extends State<_Fallback> {
  List<Condition> _conditions = [Condition()];

  @override
  initState() {
    super.initState();
    if (widget.fallback.selectorTag.isEmpty &&
        widget.fallback.outboundTag.isEmpty) {
      widget.fallback.selectorTag = defaultProxySelectorTag;
    }
    _conditions = loadConditionsFromFallback(widget.fallback);
    if (widget.fallback.matchAll) {
      _conditions = [Condition()];
    }
    _syncFallbackConditions();
  }

  void _syncFallbackConditions() {
    clearLegacyFallbackConditionFields(widget.fallback);
    widget.fallback.conditions.clear();
    if (!widget.fallback.matchAll) {
      widget.fallback.conditions.addAll(
        _conditions.where((c) => !conditionIsEmpty(c)),
      );
    }
  }

  void _addCondition() {
    setState(() {
      _conditions.add(Condition());
      _syncFallbackConditions();
    });
  }

  void _removeCondition(int index) {
    setState(() {
      _conditions.removeAt(index);
      _syncFallbackConditions();
    });
  }

  OutboundHandler? _getHandlerForFallback(RuleConfig_Fallback fallback) {
    if (fallback.outboundTag.isEmpty) {
      return null;
    }
    if (fallback.outboundTag == directHandlerTag) {
      return directHandler;
    }
    return widget.outboundHandlers
        ?.where((e) => e.id.toString() == fallback.outboundTag)
        .firstOrNull;
  }

  HandlerSelector? _getSelectorForFallback(RuleConfig_Fallback fallback) {
    if (fallback.selectorTag.isEmpty) {
      return null;
    }
    if (fallback.selectorTag == defaultProxySelectorTag) {
      return proxySelector;
    }
    return widget.selectors
        ?.where((e) => e.name == fallback.selectorTag)
        .firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.fallback} ${widget.index + 1}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Gap(8),
            Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.node),
                  selected: widget.fallback.outboundTag.isNotEmpty,
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() {
                      widget.fallback.selectorTag = '';
                      if (widget.fallback.outboundTag.isEmpty) {
                        widget.fallback.outboundTag = directHandlerTag;
                      }
                    });
                  },
                ),
                const Gap(5),
                ChoiceChip(
                  label: Text(l10n.selector),
                  selected: widget.fallback.selectorTag.isNotEmpty,
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() {
                      widget.fallback.outboundTag = '';
                      if (widget.fallback.selectorTag.isEmpty) {
                        widget.fallback.selectorTag = defaultProxySelectorTag;
                      }
                    });
                  },
                ),
                const Spacer(),
                IconButton(
                  tooltip: l10n.delete,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    widget.onDelete();
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const Gap(8),
            if (widget.fallback.outboundTag.isNotEmpty)
              DropdownMenu<OutboundHandler>(
                label: Text(l10n.node),
                initialSelection: _getHandlerForFallback(widget.fallback),
                onSelected: (value) {
                  setState(() {
                    if (value == null) {
                    } else if (value == directHandler) {
                      widget.fallback.outboundTag = directHandlerTag;
                    } else {
                      widget.fallback.outboundTag = value.id.toString();
                    }
                  });
                },
                dropdownMenuEntries: [
                  DropdownMenuEntry(label: l10n.direct, value: directHandler),
                  ...?widget.outboundHandlers
                      ?.map((e) => DropdownMenuEntry(label: e.name, value: e))
                      .toList(),
                ],
              ),
            if (widget.fallback.selectorTag.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: DropdownMenu<HandlerSelector>(
                  label: Text(l10n.selector),
                  initialSelection: _getSelectorForFallback(widget.fallback),
                  onSelected: (value) {
                    setState(() {
                      if (value == proxySelector) {
                        widget.fallback.selectorTag = defaultProxySelectorTag;
                      } else if (value != null) {
                        widget.fallback.selectorTag = value.name;
                      }
                    });
                  },
                  dropdownMenuEntries: [
                    DropdownMenuEntry(
                      label: l10n.defaultSelectorTag,
                      value: proxySelector,
                    ),
                    ...?widget.selectors
                        ?.where((e) => e.name != proxySelector.name)
                        .map((e) => DropdownMenuEntry(label: e.name, value: e))
                        .toList(),
                  ],
                ),
              ),
            const Gap(8),
            SwitchListTile(
              value: widget.fallback.hasAction()
                  ? widget.fallback.action.ipToDomain
                  : false,
              title: Text(l10n.rewriteIpToDomain),
              subtitle: Text(
                l10n.rewriteIpToDomainDesc,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  final action = widget.fallback.hasAction()
                      ? widget.fallback.action
                      : (widget.fallback.action = RuleConfig_Fallback_Action());
                  action.ipToDomain = value;
                });
              },
            ),
            const Gap(8),
            Row(
              children: [
                Text(AppLocalizations.of(context)!.matchAll),
                const Gap(5),
                Switch(
                  value: widget.fallback.matchAll,
                  onChanged: (value) {
                    setState(() {
                      widget.fallback.matchAll = value;
                      if (widget.fallback.matchAll) {
                        _conditions = [Condition()];
                      }
                      _syncFallbackConditions();
                    });
                  },
                ),
              ],
            ),
            if (!widget.fallback.matchAll)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextDivider(text: AppLocalizations.of(context)!.condition),
                  const Gap(5),
                  Text(
                    AppLocalizations.of(context)!.ruleMatchCondition,
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(10),
                  ...List.generate(_conditions.length, (index) {
                    return _RouteConditionEditor(
                      key: ObjectKey(_conditions[index]),
                      condition: _conditions[index],
                      index: index,
                      canDelete: _conditions.length > 1,
                      onDelete: () => _removeCondition(index),
                      onChanged: _syncFallbackConditions,
                    );
                  }),
                  const Gap(5),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _addCondition,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(AppLocalizations.of(context)!.condition),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class DnsRuleForm extends StatefulWidget {
  const DnsRuleForm({super.key, this.ruleConfig});
  final DnsRuleConfig? ruleConfig;

  @override
  State<DnsRuleForm> createState() => _DnsRuleFormState();
}

class _DnsRuleFormState extends State<DnsRuleForm> with FormDataGetter {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ruleConfig = DnsRuleConfig();
  final List<bool> _isExpanded = List.filled(1, false);
  final List<bool> _nontrivial = List.filled(2, false);

  List<DnsServer> _dnsServers = [/* ...defaultDnsServers */];
  DnsServer? _selectedDnsServer;
  String? dnsServerSelectError;

  @override
  Object? get formData {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedDnsServer == null) {
        setState(() {
          dnsServerSelectError = AppLocalizations.of(
            context,
          )!.selectAtleastOneDnsServer;
        });
        return null;
      }
      _ruleConfig.dnsServerName = _selectedDnsServer!.name;
      _ruleConfig.ruleName = _nameController.text;
      return _ruleConfig;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (widget.ruleConfig != null) {
      _nameController.text = widget.ruleConfig!.ruleName;
      _ruleConfig.mergeFromMessage(widget.ruleConfig!);
      _selectedDnsServer = _dnsServers
          .where((e) => e.name == _ruleConfig.dnsServerName)
          .firstOrNull;
    }
    _updateNontrivial();
    context.read<DatabaseProvider>().database.managers.dnsServers.get().then((
      l,
    ) {
      _dnsServers = [/* ...defaultDnsServers */ ...l];
      setState(() {
        _selectedDnsServer ??= l
            .where((e) => e.name == _ruleConfig.dnsServerName)
            .firstOrNull;
      });
    });
  }

  void _updateNontrivial() {
    _nontrivial[0] = _ruleConfig.includedTypes.isNotEmpty;
    _nontrivial[1] =
        _ruleConfig.domains.isNotEmpty || _ruleConfig.domainTags.isNotEmpty;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context)!.pleaseEnterRuleName;
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.ruleName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const Gap(10),
              DropdownMenu<DnsServer>(
                label: Text(AppLocalizations.of(context)!.dnsServer),
                initialSelection: _selectedDnsServer,
                requestFocusOnTap: false,
                width: 180,
                onSelected: (value) {
                  setState(() {
                    dnsServerSelectError = null;
                    _selectedDnsServer = value;
                  });
                },
                errorText: dnsServerSelectError,
                dropdownMenuEntries: _dnsServers
                    .map((e) => DropdownMenuEntry(label: e.name, value: e))
                    .toList(),
              ),
              const Gap(5),
              Column(
                children: [
                  TextDivider(text: AppLocalizations.of(context)!.condition),
                  const Gap(5),
                  Text(
                    '${AppLocalizations.of(context)!.howDnsRuleMatch} ${AppLocalizations.of(context)!.enabledConditions(_nontrivial.where((e) => e).length)}',
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DnsIncludedTypeCondition(
                      dnsRule: _ruleConfig,
                      onChanged: _updateNontrivial,
                    ),
                  ),
                  const Gap(10),
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
                                  AppLocalizations.of(context)!.domain,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(
                                        color: _nontrivial[1]
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : null,
                                      ),
                                ),
                              ),
                            );
                          },
                          isExpanded: _isExpanded[0],
                          body: DomainCondition(
                            dnsRule: _ruleConfig,
                            onChanged: _updateNontrivial,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DnsIncludedTypeCondition extends StatelessWidget {
  const DnsIncludedTypeCondition({
    super.key,
    required this.dnsRule,
    required this.onChanged,
  });
  final DnsRuleConfig dnsRule;
  final Function() onChanged;
  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: DnsType.values
          .map(
            (e) => StatefulBuilder(
              builder: (ctx, setState) {
                return MenuItemButton(
                  leadingIcon: Checkbox(
                    value: dnsRule.includedTypes.contains(e),
                    onChanged: (value) async {
                      setState(() {
                        if (value ?? false) {
                          dnsRule.includedTypes.add(e);
                        } else {
                          dnsRule.includedTypes.remove(e);
                        }
                        onChanged();
                      });
                    },
                  ),
                  closeOnActivate: false,
                  onPressed: () {
                    setState(() {
                      if (dnsRule.includedTypes.contains(e)) {
                        dnsRule.includedTypes.remove(e);
                      } else {
                        dnsRule.includedTypes.add(e);
                      }
                      onChanged();
                    });
                  },
                  child: Text(e.name),
                );
              },
            ),
          )
          .toList(),
      builder: (context, controller, child) {
        return Tooltip(
          preferBelow: false,
          message: AppLocalizations.of(context)!.dnsTypeConditionDesc,
          child: ActionChip(
            label: Text(AppLocalizations.of(context)!.dnsType),
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            avatar: dnsRule.includedTypes.isNotEmpty
                ? const Icon(Icons.check_box_outlined)
                : const Icon(Icons.check_box_outline_blank_rounded),
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
          ),
        );
      },
    );
  }
}

List<Widget> buildWrapChildrenForDomains(
  BuildContext context,
  List<Domain> geoDomains,
  Function(Domain)? onDelete,
) {
  final children = <Widget>[];
  children.add(
    WrapChild(
      shape: chipBorderRadius,
      text: AppLocalizations.of(context)!.keyword,
      backgroundColor: pinkColorTheme.secondaryContainer,
      foregroundColor: pinkColorTheme.onSecondaryContainer,
    ),
  );
  children.addAll(
    geoDomains
        .where((domain) => domain.type == Domain_Type.Plain)
        .map(
          (domain) => WrapChild(
            shape: chipBorderRadius,
            text: domain.value,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerLowest,
            onDelete: onDelete != null ? () => onDelete(domain) : null,
          ),
        ),
  );

  children.add(
    WrapChild(
      shape: chipBorderRadius,
      text: AppLocalizations.of(context)!.rootDomain,
      backgroundColor: greenColorTheme.secondaryContainer,
      foregroundColor: greenColorTheme.onSecondaryContainer,
    ),
  );
  children.addAll(
    geoDomains
        .where((domain) => domain.type == Domain_Type.RootDomain)
        .map(
          (domain) => WrapChild(
            shape: chipBorderRadius,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerLowest,
            text: domain.value,
            onDelete: onDelete != null ? () => onDelete(domain) : null,
          ),
        ),
  );
  children.add(
    WrapChild(
      shape: chipBorderRadius,
      text: AppLocalizations.of(context)!.exact,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
    ),
  );
  children.addAll(
    geoDomains
        .where((domain) => domain.type == Domain_Type.Full)
        .map(
          (domain) => WrapChild(
            shape: chipBorderRadius,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerLowest,
            text: domain.value,
            onDelete: onDelete != null ? () => onDelete(domain) : null,
          ),
        ),
  );
  children.add(
    WrapChild(
      shape: chipBorderRadius,
      text: AppLocalizations.of(context)!.regularExpression,
      backgroundColor: purpleColorTheme.secondaryContainer,
      foregroundColor: purpleColorTheme.onSecondaryContainer,
    ),
  );
  children.addAll(
    geoDomains
        .where((domain) => domain.type == Domain_Type.Regex)
        .map(
          (domain) => WrapChild(
            shape: chipBorderRadius,
            text: domain.value,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerLowest,
            onDelete: onDelete != null ? () => onDelete(domain) : null,
          ),
        ),
  );

  return children;
}

class InboundCondition extends StatefulWidget {
  const InboundCondition({
    super.key,
    required this.condition,
    required this.onChanged,
  });
  final Condition condition;
  final Function() onChanged;
  @override
  State<InboundCondition> createState() => _InboundConditionState();
}

class _InboundConditionState extends State<InboundCondition> {
  final _inboundController = TextEditingController();
  @override
  void dispose() {
    _inboundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
        top: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.inbound,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(5),
          Wrap(
            runSpacing: 10,
            spacing: 10,
            children: widget.condition.inboundTags
                .map(
                  (e) => WrapChild(
                    shape: chipBorderRadius,
                    text: e,
                    onDelete: () => setState(() {
                      widget.condition.inboundTags.remove(e);
                      widget.onChanged();
                    }),
                  ),
                )
                .toList(),
          ),
          const Gap(10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _inboundController,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      widget.condition.inboundTags.add(_inboundController.text);
                      _inboundController.clear();
                      setState(() {
                        widget.onChanged();
                      });
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.inbound,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
              const Gap(5),
              IconButton.filledTonal(
                onPressed: () {
                  if (_inboundController.text.isNotEmpty) {
                    widget.condition.inboundTags.add(_inboundController.text);
                    _inboundController.clear();
                    setState(() {
                      widget.onChanged();
                    });
                  }
                },
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(0),
                icon: const Icon(Icons.add_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DomainCondition extends StatefulWidget {
  const DomainCondition({
    super.key,
    this.rule,
    this.dnsRule,
    this.condition,
    required this.onChanged,
  });
  final RuleConfig? rule;
  final DnsRuleConfig? dnsRule;
  final Condition? condition;
  final Function() onChanged;
  @override
  State<DomainCondition> createState() => _DomainConditionState();
}

class _DomainConditionState extends State<DomainCondition> {
  List<Domain> get _geoDomains =>
      widget.condition?.geoDomains ??
      widget.rule?.geoDomains ??
      widget.dnsRule!.domains;

  List<String> get _domainTags =>
      widget.condition?.domainTags ??
      widget.rule?.domainTags ??
      widget.dnsRule!.domainTags;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
        top: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.domain,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(5),
          Wrap(
            runSpacing: 10,
            spacing: 10,
            children: buildWrapChildrenForDomains(context, _geoDomains, (
              domain,
            ) {
              setState(() {
                _geoDomains.remove(domain);
                widget.onChanged();
              });
            }),
          ),
          const Gap(10),
          DomainCollector(
            onAdd: (p0) {
              _geoDomains.add(p0);
              setState(() {
                widget.onChanged();
              });
            },
          ),
          const Gap(10),
          Text(
            AppLocalizations.of(context)!.domainSet,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(5),
          _DomainSet(
            domainTags: _domainTags,
            onChanged: () {
              widget.onChanged();
            },
          ),
          if (widget.condition != null || widget.rule != null)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: CheckboxListTile(
                value: !(widget.condition?.skipSniff ?? widget.rule!.skipSniff),
                title: Text(
                  AppLocalizations.of(context)!.sniffDomainForIpConnection,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                onChanged: (v) {
                  if (widget.condition != null) {
                    widget.condition!.skipSniff = !(v ?? false);
                  } else {
                    widget.rule!.skipSniff = !(v ?? false);
                  }
                  setState(() {
                    widget.onChanged();
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}

class IPSet extends StatefulWidget {
  const IPSet({super.key, required this.ipTags, required this.onChanged});
  final List<String> ipTags;
  final Function() onChanged;

  @override
  State<IPSet> createState() => _IPSetState();
}

class _IPSetState extends State<IPSet> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 10,
      spacing: 10,
      children:
          widget.ipTags
              .map<Widget>(
                (e) => MenuAnchor(
                  menuChildren: [
                    MenuItemButton(
                      onPressed: () {
                        widget.ipTags.remove(e);
                        setState(() {
                          widget.onChanged();
                        });
                      },
                      child: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ],
                  builder: (context, controller, child) => GestureDetector(
                    onDoubleTap: () {
                      widget.ipTags.remove(e);
                      setState(() {
                        widget.onChanged();
                      });
                    },
                    onSecondaryTapDown: (details) {
                      controller.open(
                        position: Offset(
                          details.localPosition.dx,
                          details.localPosition.dy,
                        ),
                      );
                    },
                    onLongPress: () {
                      controller.open();
                    },
                    child: Chip(label: Text(e)),
                  ),
                ),
              )
              .toList()
            ..add(
              IPSetPicker(
                onChanged: (p0) {
                  widget.ipTags.add(p0);
                  setState(() {
                    widget.onChanged();
                  });
                },
              ),
            ),
    );
  }
}

class _DomainSet extends StatefulWidget {
  const _DomainSet({
    super.key,
    required this.domainTags,
    required this.onChanged,
  });
  final List<String> domainTags;
  final Function() onChanged;
  @override
  State<_DomainSet> createState() => __DomainSetState();
}

class __DomainSetState extends State<_DomainSet> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      runSpacing: 10,
      spacing: 10,
      children:
          widget.domainTags
              .map<Widget>(
                (e) => MenuAnchor(
                  menuChildren: [
                    MenuItemButton(
                      onPressed: () {
                        widget.domainTags.remove(e);
                        setState(() {
                          widget.onChanged();
                        });
                      },
                      child: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ],
                  builder: (context, controller, child) => GestureDetector(
                    onDoubleTap: () {
                      widget.domainTags.remove(e);
                      setState(() {
                        widget.onChanged();
                      });
                    },
                    onSecondaryTapDown: (details) {
                      controller.open(
                        position: Offset(
                          details.localPosition.dx,
                          details.localPosition.dy,
                        ),
                      );
                    },
                    onLongPress: () {
                      controller.open();
                    },
                    child: Chip(label: Text(e)),
                  ),
                ),
              )
              .toList()
            ..add(
              DomainSetPicker(
                onChanged: (p0) {
                  widget.domainTags.add(p0);
                  setState(() {
                    widget.onChanged();
                  });
                },
              ),
            ),
    );
  }
}

class IPSetPicker extends StatefulWidget {
  const IPSetPicker({super.key, required this.onChanged});
  final Function(String) onChanged;

  @override
  State<IPSetPicker> createState() => _IPSetPickerState();
}

class _IPSetPickerState extends State<IPSetPicker> {
  Future<List<GreatIpSet>>? _getGreatIpSetsFuture;
  Future<List<AtomicIpSet>>? _getAtomicIpSetsFuture;
  @override
  void initState() {
    super.initState();
    final database = context.read<DatabaseProvider>().database;
    _getGreatIpSetsFuture = database.managers.greatIpSets.get();
    _getAtomicIpSetsFuture = database.managers.atomicIpSets.get();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        FutureBuilder(
          future: _getGreatIpSetsFuture,
          builder: (ctx, snaoshot) {
            if (!snaoshot.hasData) {
              return const SizedBox.shrink();
            }
            final menuChildren = <Widget>[];
            for (final e in snaoshot.data!) {
              menuChildren.add(
                MenuItemButton(
                  onPressed: () {
                    widget.onChanged(e.greatIpSetConfig.name);
                  },
                  child: Text(
                    localizedSetName(context, e.greatIpSetConfig.name),
                  ),
                ),
              );
              if (e.greatIpSetConfig.oppositeName.isNotEmpty) {
                menuChildren.add(
                  MenuItemButton(
                    onPressed: () {
                      widget.onChanged(e.greatIpSetConfig.oppositeName);
                    },
                    child: Text(
                      localizedSetName(
                        context,
                        e.greatIpSetConfig.oppositeName,
                      ),
                    ),
                  ),
                );
              }
            }
            return SubmenuButton(
              menuChildren: menuChildren,
              child: Text(AppLocalizations.of(context)!.greatIpSet),
            );
          },
        ),
        FutureBuilder(
          future: _getAtomicIpSetsFuture,
          builder: (ctx, snaoshot) {
            if (!snaoshot.hasData) {
              return const SizedBox.shrink();
            }
            return SubmenuButton(
              menuChildren: snaoshot.data!
                  .map(
                    (e) => MenuItemButton(
                      onPressed: () {
                        widget.onChanged(e.name);
                      },
                      child: Text(e.name),
                    ),
                  )
                  .toList(),
              child: Text(AppLocalizations.of(context)!.atmoicIpSet),
            );
          },
        ),
      ],
      builder: (context, controller, child) => IconButton.filledTonal(
        onPressed: () => controller.open(),
        style: IconButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(0),
        ),
        icon: const Icon(Icons.add_rounded, size: 18),
      ),
    );
  }
}

class DomainSetPicker extends StatefulWidget {
  const DomainSetPicker({super.key, required this.onChanged});
  final Function(String) onChanged;
  @override
  State<DomainSetPicker> createState() => _DomainSetPickerState();
}

class _DomainSetPickerState extends State<DomainSetPicker> {
  Future<List<GreatDomainSet>>? _getGreatDomainSetsFuture;
  Future<List<AtomicDomainSet>>? _getAtomicDomainSetsFuture;
  @override
  void initState() {
    super.initState();
    final database = context.read<DatabaseProvider>().database;
    _getGreatDomainSetsFuture = database.managers.greatDomainSets.get();
    _getAtomicDomainSetsFuture = database.managers.atomicDomainSets.get();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        FutureBuilder(
          future: _getGreatDomainSetsFuture,
          builder: (ctx, snaoshot) {
            if (!snaoshot.hasData) {
              return const SizedBox.shrink();
            }
            final menuChildren = <Widget>[];
            for (final e in snaoshot.data!) {
              menuChildren.add(
                MenuItemButton(
                  onPressed: () {
                    widget.onChanged(e.set.name);
                  },
                  child: Text(localizedSetName(context, e.set.name)),
                ),
              );
              if (e.set.oppositeName.isNotEmpty) {
                menuChildren.add(
                  MenuItemButton(
                    onPressed: () {
                      widget.onChanged(e.set.oppositeName);
                    },
                    child: Text(localizedSetName(context, e.set.oppositeName)),
                  ),
                );
              }
            }
            return SubmenuButton(
              menuChildren: menuChildren,
              child: Text(AppLocalizations.of(context)!.greatDomainSet),
            );
          },
        ),
        FutureBuilder(
          future: _getAtomicDomainSetsFuture,
          builder: (ctx, snaoshot) {
            if (!snaoshot.hasData) {
              return const SizedBox.shrink();
            }
            return SubmenuButton(
              menuChildren: snaoshot.data!
                  .map(
                    (e) => MenuItemButton(
                      onPressed: () {
                        widget.onChanged(e.name);
                      },
                      child: Text(localizedSetName(context, e.name)),
                    ),
                  )
                  .toList(),
              child: Text(AppLocalizations.of(context)!.atmoicDomainSet),
            );
          },
        ),
      ],
      builder: (context, controller, child) => IconButton.filledTonal(
        onPressed: () => controller.open(),
        style: IconButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(0),
        ),
        icon: const Icon(Icons.add_rounded, size: 18),
      ),
    );
  }
}

class IPCondition extends StatefulWidget {
  const IPCondition({
    super.key,
    required this.condition,
    required this.onChanged,
  });
  final Condition condition;
  final Function() onChanged;

  @override
  State<IPCondition> createState() => _IPConditionState();
}

class _IPConditionState extends State<IPCondition> {
  final _ipController = TextEditingController();
  Future<List<GreatIpSet>>? _getGreatIpSetsFuture;
  Future<List<AtomicIpSet>>? _getAtomicIpSetsFuture;
  @override
  void initState() {
    super.initState();
    final database = context.read<DatabaseProvider>().database;
    _getGreatIpSetsFuture = database.managers.greatIpSets.get();
    _getAtomicIpSetsFuture = database.managers.atomicIpSets.get();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
        top: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IP',
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(5),
          Wrap(
            runSpacing: 10,
            spacing: 10,
            children: widget.condition.dstCidrs
                .map(
                  (e) => WrapChild(
                    shape: chipBorderRadius,
                    text: e,
                    onDelete: () => setState(() {
                      widget.condition.dstCidrs.remove(e);
                      widget.onChanged();
                    }),
                  ),
                )
                .toList(),
          ),
          const Gap(10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ipController,
                  decoration: InputDecoration(
                    labelText: 'IP',
                    hintText: '10.0.0.0/24',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
              const Gap(5),
              IconButton.filledTonal(
                onPressed: () {
                  if (_ipController.text.isNotEmpty) {
                    if (!isValidCidr(_ipController.text)) {
                      return;
                    }
                    widget.condition.dstCidrs.add(_ipController.text);
                    _ipController.clear();
                    setState(() {
                      widget.onChanged();
                    });
                  }
                },
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(0),
                icon: const Icon(Icons.add_rounded, size: 18),
              ),
            ],
          ),
          const Gap(10),
          Text(
            AppLocalizations.of(context)!.ipSet,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(5),
          IPSet(
            ipTags: widget.condition.dstIpTags,
            onChanged: () {
              widget.onChanged();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: CheckboxListTile(
              value: widget.condition.resolveDomain,
              title: Text(
                AppLocalizations.of(context)!.resolveDomain,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              onChanged: (v) {
                widget.condition.resolveDomain = v ?? false;
                setState(() {
                  widget.onChanged();
                });
              },
            ),
          ),
          CheckboxListTile(
            value: widget.condition.resolveSoftRewrite,
            title: Text(
              'Resolve domain (soft, rewrite)',
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onChanged: (v) {
              widget.condition.resolveSoftRewrite = v ?? false;
              setState(() {
                widget.onChanged();
              });
            },
          ),
          CheckboxListTile(
            value: widget.condition.resolveSoftNoRewrite,
            title: Text(
              'Resolve domain (soft, no rewrite)',
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onChanged: (v) {
              widget.condition.resolveSoftNoRewrite = v ?? false;
              setState(() {
                widget.onChanged();
              });
            },
          ),
        ],
      ),
    );
  }
}

class SrcIPCondition extends StatefulWidget {
  const SrcIPCondition({
    super.key,
    required this.condition,
    required this.onChanged,
  });
  final Condition condition;
  final Function() onChanged;

  @override
  State<SrcIPCondition> createState() => _SrcIPConditionState();
}

class _SrcIPConditionState extends State<SrcIPCondition> {
  final _ipController = TextEditingController();

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
        top: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.source} IP',
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(5),
          Wrap(
            runSpacing: 10,
            spacing: 10,
            children: widget.condition.srcCidrs
                .map(
                  (e) => WrapChild(
                    shape: chipBorderRadius,
                    text: e,
                    onDelete: () => setState(() {
                      widget.condition.srcCidrs.remove(e);
                      widget.onChanged();
                    }),
                  ),
                )
                .toList(),
          ),
          const Gap(10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ipController,
                  decoration: InputDecoration(
                    labelText: '${l10n.source} IP',
                    hintText: '10.0.0.0/24',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
              const Gap(5),
              IconButton.filledTonal(
                onPressed: () {
                  if (_ipController.text.isNotEmpty) {
                    if (!isValidCidr(_ipController.text)) {
                      return;
                    }
                    widget.condition.srcCidrs.add(_ipController.text);
                    _ipController.clear();
                    setState(() {
                      widget.onChanged();
                    });
                  }
                },
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(0),
                icon: const Icon(Icons.add_rounded, size: 18),
              ),
            ],
          ),
          const Gap(10),
          Text(
            l10n.ipSet,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(5),
          IPSet(
            ipTags: widget.condition.srcIpTags,
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );
  }
}

String _portRangeLabel(PortRange range) {
  if (range.from == range.to) {
    return '${range.from}';
  }
  return '${range.from}-${range.to}';
}

class PortCondition extends StatefulWidget {
  const PortCondition({
    super.key,
    required this.condition,
    required this.onChanged,
  });
  final Condition condition;
  final Function() onChanged;

  @override
  State<PortCondition> createState() => _PortConditionState();
}

class _PortConditionState extends State<PortCondition> {
  final _srcPortController = TextEditingController();
  final _dstPortController = TextEditingController();

  @override
  void dispose() {
    _srcPortController.dispose();
    _dstPortController.dispose();
    super.dispose();
  }

  Widget _buildPortSection({
    required String label,
    required List<PortRange> portRanges,
    required TextEditingController controller,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Gap(5),
        Wrap(
          runSpacing: 10,
          spacing: 10,
          children: portRanges
              .map(
                (e) => WrapChild(
                  shape: chipBorderRadius,
                  text: _portRangeLabel(e),
                  onDelete: () => setState(() {
                    portRanges.remove(e);
                    widget.onChanged();
                  }),
                ),
              )
              .toList(),
        ),
        const Gap(10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: l10n.outboundPortHintExample,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
            const Gap(5),
            IconButton.filledTonal(
              onPressed: () {
                final parsed = tryParsePorts(controller.text.trim());
                if (parsed == null || parsed.isEmpty) {
                  return;
                }
                portRanges.addAll(parsed);
                controller.clear();
                setState(() {
                  widget.onChanged();
                });
              },
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(0),
              icon: const Icon(Icons.add_rounded, size: 18),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
        top: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPortSection(
            label: '${l10n.source} ${l10n.port}',
            portRanges: widget.condition.srcPortRanges,
            controller: _srcPortController,
          ),
          const Gap(10),
          _buildPortSection(
            label: '${l10n.destination} ${l10n.port}',
            portRanges: widget.condition.dstPortRanges,
            controller: _dstPortController,
          ),
        ],
      ),
    );
  }
}

class ProtocolCondition extends StatelessWidget {
  const ProtocolCondition({
    super.key,
    required this.condition,
    required this.onChanged,
  });
  final Condition condition;
  final Function() onChanged;

  static const _protocols = ['tls', 'http1', 'quic', 'bittorrent'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
        top: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.protocol,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(5),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _protocols
                .map(
                  (protocol) => FilterChip(
                    label: Text(protocol),
                    selected: condition.protocols.contains(protocol),
                    onSelected: (value) {
                      value
                          ? condition.protocols.add(protocol)
                          : condition.protocols.remove(protocol);
                      onChanged();
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class AllCondition extends StatefulWidget {
  const AllCondition({
    super.key,
    required this.condition,
    required this.onChanged,
  });
  final Condition condition;
  final Function() onChanged;

  @override
  State<AllCondition> createState() => _AllConditionState();
}

class _AllConditionState extends State<AllCondition> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
        top: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.domainIpAppConditionDesc,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(5),
          Text(
            AppLocalizations.of(context)!.setName,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(5),
          Wrap(
            runSpacing: 10,
            spacing: 10,
            children: widget.condition.allTags
                .map(
                  (e) => WrapChild(
                    shape: chipBorderRadius,
                    text: e,
                    onDelete: () {
                      setState(() {
                        widget.condition.allTags.remove(e);
                        widget.onChanged();
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const Gap(10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      setState(() {
                        widget.condition.allTags.add(_controller.text);
                        _controller.clear();
                        widget.onChanged();
                      });
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.setName,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
              const Gap(5),
              IconButton.filledTonal(
                onPressed: () {
                  setState(() {
                    widget.condition.allTags.add(_controller.text);
                    _controller.clear();
                    widget.onChanged();
                  });
                },
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(0),
                icon: const Icon(Icons.add_rounded, size: 18),
              ),
            ],
          ),
          const Gap(5),
          CheckboxListTile(
            value: widget.condition.resolveDomain,
            title: Text(
              AppLocalizations.of(context)!.resolveDomain,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onChanged: (v) {
              widget.condition.resolveDomain = v ?? false;
              setState(() {
                widget.onChanged();
              });
            },
          ),
          const Gap(5),
          CheckboxListTile(
            value: !widget.condition.skipSniff,
            title: Text(
              AppLocalizations.of(context)!.sniffDomainForIpConnection,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onChanged: (v) {
              widget.condition.skipSniff = !(v ?? false);
              setState(() {
                widget.onChanged();
              });
            },
          ),
        ],
      ),
    );
  }
}

class AppCondition extends StatefulWidget {
  const AppCondition({
    super.key,
    required this.condition,
    required this.onChanged,
  });
  final Condition condition;
  final Function() onChanged;
  @override
  State<AppCondition> createState() => _AppConditionState();
}

class _AppConditionState extends State<AppCondition> {
  final _appController = TextEditingController();
  Future<List<AppSet>>? _getAppSetsFuture;
  AppId_Type _type = AppId_Type.Keyword;

  @override
  void initState() {
    super.initState();
    final database = context.read<DatabaseProvider>().database;
    _getAppSetsFuture = database.managers.appSets.get();
  }

  @override
  void dispose() {
    _appController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        bottom: 16.0,
        top: 5.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.app,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(5),
          Column(
            children: widget.condition.appIds
                .map(
                  (e) => ListTile(
                    title: Text(e.value),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    shape: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    tileColor: Theme.of(context).colorScheme.surfaceContainer,
                    subtitle: Platform.isAndroid
                        ? null
                        : Text(e.type.toLocalString(context)),
                    trailing: IconButton(
                      onPressed: () {
                        setState(() {
                          widget.condition.appIds.remove(e);
                          widget.onChanged();
                        });
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                )
                .toList(),
          ),
          const Gap(10),
          DropdownMenu<AppId_Type>(
            width: 120,
            label: Text(AppLocalizations.of(context)!.type),
            initialSelection: _type,
            requestFocusOnTap: false,
            onSelected: (AppId_Type? t) {
              if (t != null) {
                _type = t;
              }
              setState(() {});
            },
            dropdownMenuEntries: AppId_Type.values
                .map(
                  (e) => DropdownMenuEntry(
                    label: e.toLocalString(context),
                    value: e,
                  ),
                )
                .toList(),
          ),
          const Gap(5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _appController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.app,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      widget.condition.appIds.add(
                        AppId(value: value, type: _type),
                      );
                      _appController.clear();
                    }
                    return null;
                  },
                ),
              ),
              const Gap(5),
              IconButton.filledTonal(
                onPressed: () {
                  widget.condition.appIds.add(
                    AppId(value: _appController.text, type: _type),
                  );
                  _appController.clear();
                  setState(() {
                    widget.onChanged();
                  });
                },
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(0),
                icon: const Icon(Icons.add_rounded, size: 18),
              ),
            ],
          ),
          const Gap(10),
          Text(
            AppLocalizations.of(context)!.appSet,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(5),
          Wrap(
            runSpacing: 10,
            spacing: 10,
            children:
                widget.condition.appTags
                    .map<Widget>(
                      (e) => MenuAnchor(
                        menuChildren: [
                          MenuItemButton(
                            onPressed: () {
                              widget.condition.appTags.remove(e);
                              setState(() {
                                widget.onChanged();
                              });
                            },
                            child: Text(AppLocalizations.of(context)!.delete),
                          ),
                        ],
                        builder: (context, controller, child) =>
                            GestureDetector(
                              onDoubleTap: () {
                                widget.condition.appTags.remove(e);
                                setState(() {
                                  widget.onChanged();
                                });
                              },
                              onSecondaryTapDown: (details) {
                                controller.open(
                                  position: Offset(
                                    details.localPosition.dx,
                                    details.localPosition.dy,
                                  ),
                                );
                              },
                              onLongPress: () {
                                controller.open();
                              },
                              child: Chip(label: Text(e)),
                            ),
                      ),
                    )
                    .toList()
                  ..add(
                    FutureBuilder(
                      future: _getAppSetsFuture,
                      builder: (ctx, snaoshot) {
                        if (!snaoshot.hasData) {
                          return const SizedBox.shrink();
                        }
                        return MenuAnchor(
                          menuChildren: snaoshot.data!
                              .map(
                                (e) => MenuItemButton(
                                  onPressed: () {
                                    widget.condition.appTags.add(e.name);
                                    setState(() {
                                      widget.onChanged();
                                    });
                                  },
                                  child: Text(e.name),
                                ),
                              )
                              .toList(),
                          builder: (context, controller, child) =>
                              IconButton.filledTonal(
                                onPressed: () => controller.open(),
                                style: IconButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.all(0),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 18),
                              ),
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

class DomainCollector extends StatefulWidget {
  const DomainCollector({super.key, required this.onAdd});
  final Function(Domain) onAdd;
  @override
  State<DomainCollector> createState() => _DomainCollectorState();
}

class _DomainCollectorState extends State<DomainCollector> {
  Domain_Type _type = Domain_Type.Plain;
  final _domainController = TextEditingController();

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownMenu<Domain_Type>(
          width: 120,
          label: Text(
            AppLocalizations.of(context)!.type,
            style: Theme.of(context).textTheme.labelMedium!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          initialSelection: _type,
          requestFocusOnTap: false,
          onSelected: (Domain_Type? t) {
            setState(() {
              if (t != null) {
                _type = t;
              }
            });
          },
          dropdownMenuEntries: Domain_Type.values
              .map(
                (e) => DropdownMenuEntry(
                  label: e.toLocalString(context),
                  value: e,
                ),
              )
              .toList(),
        ),
        const Gap(10),
        Expanded(
          child: TextFormField(
            controller: _domainController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.domain,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
        const Gap(5),
        IconButton.filledTonal(
          onPressed: () {
            widget.onAdd(Domain(type: _type, value: _domainController.text));
            _domainController.clear();
          },
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(0),
          icon: const Icon(Icons.add_rounded, size: 18),
        ),
      ],
    );
  }
}
