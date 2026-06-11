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

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vx/app/home/home.dart';
import 'package:vx/app/outbound/outbound_repo.dart';
import 'package:vx/app/routing/repo.dart';
import 'package:vx/app/routing/selector_test_fields_form.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:tm/protos/vx/router/router.pb.dart';
import 'package:vx/app/control.dart';
import 'package:vx/app/outbound/outbound_page.dart';
import 'package:vx/app/outbound/outbounds_bloc.dart';
import 'package:vx/app/outbound/subscription.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/app/routing/routing_page.dart';
import 'package:vx/app/routing/selector_being_used.dart';
import 'package:vx/data/database.dart';
import 'package:vx/main.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:vx/utils/geoip.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/widgets/form_dialog.dart';
import 'package:vx/widgets/handler_picker.dart';
import 'package:vx/widgets/info_widget.dart';

class SelectorsWidget extends StatefulWidget {
  const SelectorsWidget({super.key});

  @override
  State<SelectorsWidget> createState() => _SelectorsWidgetState();
}

class _SelectorsWidgetState extends State<SelectorsWidget> {
  final width = 300;
  List<SelectorConfig> _configs = [];
  StreamSubscription? _selectorSubscription;

  Future<void> _removeSelectorAt(int index) async {
    final controller = context.read<XController>();
    await context.read<SelectorRepo>().removeSelector(_configs[index].tag);
    controller.selectorRemove(_configs[index].tag);
    _configs.removeAt(index);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showEditSelectorForm(int index) async {
    final config = _configs[index];
    final edited = await showSelectorTestFieldsForm(context, config);
    if (edited == null) return;
    await context.read<SelectorRepo>().updateSelector(edited);
    if (!mounted) return;
    setState(() {
      _configs[index] = edited;
    });
    context.read<XController>().selectorSelectStrategyOrLandhandlerChange(
      edited,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectorSubscription?.cancel();
    _selectorSubscription = Provider.of<SelectorRepo>(context, listen: true)
        .getSelectorsStream()
        .listen((values) {
          setState(() {
            _configs = values;
          });
        });
  }

  @override
  void dispose() {
    _selectorSubscription?.cancel();
    super.dispose();
  }

  void _onAdd() async {
    final selectorRepo = Provider.of<SelectorRepo>(context, listen: false);
    final controller = context.read<XController>();
    final name = await showStringForm(
      context,
      title: AppLocalizations.of(context)!.addSelector,
      helperText: AppLocalizations.of(context)!.selectorNameDuplicate,
    );
    if (name != null) {
      if (_configs.any((e) => e.tag == name)) {
        snack(rootLocalizations()?.selectorNameDuplicate);
        return;
      }
      final hs = SelectorConfig(
        tag: name,
        filter: SelectorConfig_Filter(all: true),
      );
      setState(() {
        _configs.add(hs);
      });
      // final data = HandlerSelectorsCompanion(
      //   name: Value(name),
      //   config: Value(hs),
      // );
      // await database
      //     .into(database.handlerSelectors)
      //     .insert(data, mode: InsertMode.insertOrIgnore);
      selectorRepo.addSelector(hs);
      controller.selectorSelectStrategyOrLandhandlerChange(hs);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = constraints.maxWidth ~/ width;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: _onAdd,
                  child: Text(AppLocalizations.of(context)!.addSelector),
                ),
                const Gap(5),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => InfoDialog(
                        children: [
                          AppLocalizations.of(context)!.selectorDesc1,
                          AppLocalizations.of(context)!.selectorDesc2,
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline_rounded),
                ),
              ],
            ),
            const Gap(5),
            Expanded(
              child: MasonryGridView.count(
                padding: const EdgeInsets.only(bottom: 70),
                crossAxisCount: count,
                itemCount: _configs.length,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                itemBuilder: (context, index) {
                  if (_configs[index].tag == defaultProxySelectorTag) {
                    return const DefaultProxySelectorControl(showName: true);
                  }
                  return Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _configs[index].tag,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                              const Gap(5),
                              BlocProvider(
                                create: (context) => SelectorBeingUsedCubit(
                                  selectorTag: _configs[index].tag,
                                  xController: context.read<XController>(),
                                  outboundRepo: context.read<OutboundRepo>(),
                                ),
                                child: const SelectorBeingUsedView(),
                              ),
                              const Gap(5),
                              SelectorConfigWidget(
                                config: _configs[index],
                                onFilterChange: () {
                                  context
                                      .read<XController>()
                                      .selectorFilterChange(_configs[index]);
                                },
                                onBalanceStrategyChange: () {
                                  context
                                      .read<XController>()
                                      .selectorBalancingStrategyChange(
                                        _configs[index].tag,
                                        _configs[index].balanceStrategy,
                                      );
                                },
                                onStrategyOrLandHandlersChange: () {
                                  context
                                      .read<XController>()
                                      .selectorSelectStrategyOrLandhandlerChange(
                                        _configs[index],
                                      );
                                },
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 5,
                          top: 5,
                          child: MenuAnchor(
                            menuChildren: [
                              MenuItemButton(
                                leadingIcon: const Icon(Icons.home_outlined),
                                onPressed: () {
                                  context
                                      .read<HomeLayoutRepo>()
                                      .addWidgetIdToHome(
                                        'SELECTOR_${_configs[index].tag}',
                                      );
                                  snack(
                                    AppLocalizations.of(
                                      context,
                                    )!.addToHomeScreen,
                                  );
                                },
                                child: Text(
                                  AppLocalizations.of(context)!.addToHomeScreen,
                                ),
                              ),
                              MenuItemButton(
                                leadingIcon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showEditSelectorForm(index),
                                child: const Text('Edit'),
                              ),
                              MenuItemButton(
                                leadingIcon: const Icon(Icons.delete_outline),
                                onPressed: () => _removeSelectorAt(index),
                                child: const Text('Delete'),
                              ),
                            ],
                            builder: (context, controller, child) => IconButton(
                              onPressed: () {
                                controller.isOpen
                                    ? controller.close()
                                    : controller.open();
                              },
                              icon: const Icon(Icons.more_vert),
                            ),
                          ),
                        ),
                      ],
                    ),
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

// config is changed directly, when it is changed, the callbacks are called
class SelectorConfigWidget extends StatefulWidget {
  const SelectorConfigWidget({
    super.key,
    required this.config,
    required this.onStrategyOrLandHandlersChange,
    required this.onFilterChange,
    required this.onBalanceStrategyChange,
  });
  final SelectorConfig config;
  final Function() onStrategyOrLandHandlersChange;
  final Function() onFilterChange;
  final Function() onBalanceStrategyChange;
  @override
  State<SelectorConfigWidget> createState() => _SelectorConfigWidgetState();
}

class _SelectorConfigWidgetState extends State<SelectorConfigWidget>
    with AutomaticKeepAliveClientMixin<SelectorConfigWidget> {
  late final SelectorRepo _repo;

  /// To delete deleted handlers from the selector
  void _checkDeletedHandlerIds() async {
    final outboundRepo = context.read<OutboundRepo>();
    for (var handlerId in widget.config.filter.handlerIds) {
      final handler = await outboundRepo.getHandlerById(handlerId.toInt());
      if (handler == null) {
        await _repo.removeHandlerFromSelector(
          widget.config.tag,
          handlerId.toInt(),
        );
        widget.config.filter.handlerIds.remove(handlerId);
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _repo = Provider.of<SelectorRepo>(context, listen: false);
    _checkDeletedHandlerIds();
  }

  @override
  bool get wantKeepAlive => true;

  void _onAllChange(bool value) async {
    final config = widget.config;
    final copy = widget.config.deepCopy();
    copy.filter.all = value;
    await _repo.updateSelector(copy);
    setState(() {
      config.filter.all = value;
    });
    widget.onFilterChange();
  }

  void _onSelectStrategyChange(
    SelectorConfig_SelectingStrategy strategy,
  ) async {
    final config = widget.config;
    final copy = widget.config.deepCopy();
    copy.strategy = strategy;
    await _repo.updateSelector(copy);
    setState(() {
      config.strategy = strategy;
    });
    widget.onStrategyOrLandHandlersChange();
  }

  void _onBalanceStrategyChange(SelectorConfig_BalanceStrategy strategy) async {
    final config = widget.config;
    final copy = widget.config.deepCopy();
    copy.balanceStrategy = strategy;
    await _repo.updateSelector(copy);
    setState(() {
      config.balanceStrategy = strategy;
    });
    widget.onBalanceStrategyChange();
  }

  void _onLandHandlerChange(int handlerId, bool add) async {
    await _repo.updateSelector(widget.config);
    widget.onStrategyOrLandHandlersChange();
  }

  void _onLandHandlerReplace(int oldId, int newId) async {
    await _repo.updateSelector(widget.config);
    widget.onStrategyOrLandHandlersChange();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.range,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Gap(5),
        Row(
          children: [
            ChoiceChip(
              label: Text(AppLocalizations.of(context)!.allNodes),
              selected: widget.config.filter.all,
              onSelected: (value) async {
                if (value) {
                  _onAllChange(true);
                }
              },
            ),
            const Gap(5),
            ChoiceChip(
              label: Text(AppLocalizations.of(context)!.partialNodes),
              selected: !widget.config.filter.all,
              onSelected: (value) async {
                if (value) {
                  _onAllChange(false);
                }
              },
            ),
          ],
        ),
        if (!widget.config.filter.all)
          _SelectorFilter(
            config: widget.config,
            selectorRepo: _repo,
            onFilterChange: widget.onFilterChange,
          ),
        const Gap(10),
        Text(
          AppLocalizations.of(context)!.selectingStrategy,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const Gap(5),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            ...SelectorConfig_SelectingStrategy.values.map(
              (e) => ChoiceChip(
                label: Text(e.toLocalString(context)),
                selected: widget.config.strategy == e,
                onSelected: (value) {
                  if (value) {
                    _onSelectStrategyChange(e);
                  }
                },
              ),
            ),
          ],
        ),
        if (widget.config.strategy == SelectorConfig_SelectingStrategy.ALL_OK ||
            widget.config.strategy ==
                SelectorConfig_SelectingStrategy.TOP_PING ||
            widget.config.strategy ==
                SelectorConfig_SelectingStrategy.TOP_THROUGHPUT ||
            widget.config.strategy == SelectorConfig_SelectingStrategy.ALL)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(10),
              Text(
                AppLocalizations.of(context)!.balanceStrategy,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(5),
              Row(
                children: [
                  ChoiceChip(
                    label: Text(
                      SelectorConfig_BalanceStrategy.RANDOM.toLocalString(
                        context,
                      ),
                      // style: Theme.of(context).textTheme.bodySmall,
                    ),
                    selected:
                        widget.config.balanceStrategy ==
                        SelectorConfig_BalanceStrategy.RANDOM,
                    onSelected: (value) {
                      if (value) {
                        _onBalanceStrategyChange(
                          SelectorConfig_BalanceStrategy.RANDOM,
                        );
                      }
                    },
                  ),
                  const Gap(5),
                  ChoiceChip(
                    label: Text(
                      SelectorConfig_BalanceStrategy.MEMORY.toLocalString(
                        context,
                      ),
                    ),
                    selected:
                        widget.config.balanceStrategy ==
                        SelectorConfig_BalanceStrategy.MEMORY,
                    onSelected: (value) {
                      if (value) {
                        _onBalanceStrategyChange(
                          SelectorConfig_BalanceStrategy.MEMORY,
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        const Gap(10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tooltip(
              preferBelow: false,
              message: AppLocalizations.of(context)!.nodeChainDesc,
              child: Text(
                AppLocalizations.of(context)!.nodeChain,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 5, width: double.infinity),
            LandHandlerSelect(
              landHandlers: widget.config.landHandlers,
              onAdd: (handlerId) {
                _onLandHandlerChange(handlerId, true);
              },
              onRemove: (handlerId) {
                _onLandHandlerChange(handlerId, false);
              },
              onReplace: _onLandHandlerReplace,
            ),
          ],
        ),
      ],
    );
  }
}

class _SelectorFilter extends StatefulWidget {
  const _SelectorFilter({
    required this.config,
    required this.selectorRepo,
    required this.onFilterChange,
  });

  final SelectorConfig config;
  final SelectorRepo selectorRepo;
  final Function() onFilterChange;
  @override
  State<_SelectorFilter> createState() => _SelectorFilterState();
}

class _SelectorFilterState extends State<_SelectorFilter> {
  List<NodeGroup> _nodeMenuGroups = [];
  Map<String, List<OutboundHandler>> _handlersByGroup = {};
  bool _nodeMenuLoading = false;
  List<NodeGroup> _nodeGroupMenuGroups = [];

  Future<void> _loadNodeMenu() async {
    if (_nodeMenuLoading) return;
    setState(() {
      _nodeMenuLoading = true;
    });

    final repo = context.read<OutboundRepo>();
    final groups = context.read<OutboundBloc>().state.groups;
    final handlersByGroup = <String, List<OutboundHandler>>{};
    try {
      for (final group in groups) {
        final handlers = await repo.getHandlersByNodeGroup(group);
        handlersByGroup[group.name] = handlers
            .where((handler) => handler.config.hasOutbound())
            .toList();
      }
      if (!mounted) return;
      setState(() {
        _nodeMenuGroups = groups;
        _handlersByGroup = handlersByGroup;
        _nodeMenuLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nodeMenuLoading = false;
      });
    }
  }

  Widget _buildNodeGroupSubmenu(
    NodeGroup group,
    List<OutboundHandler> handlers,
  ) {
    final valueListenable = ValueNotifier(0);
    final selectedMap = <int, bool>{};
    for (final handler in handlers) {
      selectedMap[handler.id] = widget.config.filter.handlerIds.contains(
        Int64(handler.id),
      );
      if (selectedMap[handler.id]!) {
        valueListenable.value++;
      }
    }
    return SubmenuButton(
      leadingIcon: ValueListenableBuilder(
        valueListenable: valueListenable,
        builder: (context, value, child) {
          return value > 0
              ? const Icon(Icons.check_box_outlined)
              : const Icon(Icons.check_box_outline_blank_rounded);
        },
      ),
      menuChildren: handlers.map((e) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return MenuItemButton(
              leadingIcon: Checkbox(
                value: selectedMap[e.id],
                onChanged: (value) {
                  _onHandlerChange(
                    e.id,
                    value ?? false,
                    setState,
                    valueListenable,
                    selectedMap,
                  );
                },
              ),
              closeOnActivate: false,
              onPressed: () {
                _onHandlerChange(
                  e.id,
                  !selectedMap[e.id]!,
                  setState,
                  valueListenable,
                  selectedMap,
                );
              },
              child: Text(e.name),
            );
          },
        );
      }).toList(),
      child: Text(groupNametoLocalizedName(context, group.name)),
    );
  }

  void _onHandlerChange(
    int handlerId,
    bool selected,
    Function(void Function()) setState,
    ValueNotifier<int> valueListenable,
    Map<int, bool> selectedMap,
  ) async {
    try {
      if (selected) {
        await widget.selectorRepo.addHandlerToSelector(
          widget.config.tag,
          handlerId,
        );
        widget.config.filter.handlerIds.add(Int64(handlerId));
        valueListenable.value++;
        selectedMap[handlerId] = true;
      } else {
        await widget.selectorRepo.removeHandlerFromSelector(
          widget.config.tag,
          handlerId,
        );
        widget.config.filter.handlerIds.remove(Int64(handlerId));
        valueListenable.value--;
        selectedMap[handlerId] = false;
      }
    } catch (e) {
      logger.e('Error changing handler: $e');
      snack(e.toString());
    }
    setState(() {});
    widget.onFilterChange();
  }

  void _onHandlerGroupChange(
    String groupName,
    bool selected,
    Function(void Function()) setState,
  ) async {
    if (selected) {
      await widget.selectorRepo.addHandlerGroupToSelector(
        widget.config.tag,
        groupName,
      );
      widget.config.filter.groupTags.add(groupName);
    } else {
      await widget.selectorRepo.removeHandlerGroupFromSelector(
        widget.config.tag,
        groupName,
      );
      widget.config.filter.groupTags.remove(groupName);
    }
    setState(() {});
    widget.onFilterChange();
  }

  void _onSubChange(
    int subId,
    bool selected,
    Function(void Function()) setState,
  ) async {
    if (selected) {
      await widget.selectorRepo.addSubscriptionToSelector(
        widget.config.tag,
        subId,
      );
      widget.config.filter.subIds.add(Int64(subId));
    } else {
      await widget.selectorRepo.removeSubscriptionFromSelector(
        widget.config.tag,
        subId,
      );
      widget.config.filter.subIds.remove(Int64(subId));
    }
    setState(() {});
    widget.onFilterChange();
  }

  void _onPrefixChange(
    String prefix,
    bool selected,
    Function(void Function()) setState,
  ) async {
    if (selected) {
      widget.config.filter.prefixes.add(prefix);
    } else {
      widget.config.filter.prefixes.remove(prefix);
    }
    await widget.selectorRepo.updateSelector(widget.config);
    setState(() {});
    widget.onFilterChange();
  }

  void _onSubStringChange(
    String subString,
    bool selected,
    Function(void Function()) setState,
  ) async {
    if (selected) {
      widget.config.filter.subStrings.add(subString);
    } else {
      widget.config.filter.subStrings.remove(subString);
    }
    await widget.selectorRepo.updateSelector(widget.config);
    setState(() {});
    widget.onFilterChange();
  }

  void _onAreaChange(
    String area,
    bool selected,
    Function(void Function()) setState,
  ) async {
    if (selected) {
      widget.config.filter.countryCodes.add(area);
    } else {
      widget.config.filter.countryCodes.remove(area);
    }
    await widget.selectorRepo.updateSelector(widget.config);
    setState(() {});
    widget.onFilterChange();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          MenuAnchor(
            consumeOutsideTap: true,
            onClose: () {
              setState(() {
                _nodeMenuGroups = [];
                _handlersByGroup = {};
              });
            },
            menuChildren: _nodeMenuGroups.map((group) {
              final handlers =
                  _handlersByGroup[group.name] ?? const <OutboundHandler>[];
              return _buildNodeGroupSubmenu(group, handlers);
            }).toList(),
            builder: (context, controller, child) {
              return ActionChip(
                label: Text(AppLocalizations.of(context)!.node),
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                avatar: widget.config.filter.handlerIds.isNotEmpty
                    ? const Icon(Icons.check_box_outlined)
                    : const Icon(Icons.check_box_outline_blank_rounded),
                onPressed: () async {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    await _loadNodeMenu();
                    if (!mounted) return;
                    controller.open();
                  }
                },
              );
            },
          ),
          const Gap(5),
          MenuAnchor(
            consumeOutsideTap: true,
            menuChildren: _nodeGroupMenuGroups
                .map(
                  (e) => StatefulBuilder(
                    builder: (context, setState) {
                      late bool groupSelected;
                      if (e is MySubscription) {
                        groupSelected = widget.config.filter.subIds.contains(
                          Int64(e.id),
                        );
                      } else {
                        groupSelected = widget.config.filter.groupTags.contains(
                          e.name,
                        );
                      }
                      return MenuItemButton(
                        leadingIcon: Checkbox(
                          value: groupSelected,
                          onChanged: (value) {
                            if (value == true) {
                              if (e is MySubscription) {
                                _onSubChange(e.id, true, setState);
                              } else {
                                _onHandlerGroupChange(e.name, true, setState);
                              }
                            } else {
                              if (e is MySubscription) {
                                _onSubChange(e.id, false, setState);
                              } else {
                                _onHandlerGroupChange(e.name, false, setState);
                              }
                            }
                          },
                        ),
                        closeOnActivate: false,
                        onPressed: () {
                          if (groupSelected) {
                            if (e is MySubscription) {
                              _onSubChange(e.id, false, setState);
                            } else {
                              _onHandlerGroupChange(e.name, false, setState);
                            }
                          } else {
                            if (e is MySubscription) {
                              _onSubChange(e.id, true, setState);
                            } else {
                              _onHandlerGroupChange(e.name, true, setState);
                            }
                          }
                        },
                        child: Text(groupNametoLocalizedName(context, e.name)),
                      );
                    },
                  ),
                )
                .toList(),
            builder: (context, controller, child) {
              return ActionChip(
                label: Text(AppLocalizations.of(context)!.nodeGroup),
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                avatar:
                    widget.config.filter.groupTags.isNotEmpty ||
                        widget.config.filter.subIds.isNotEmpty
                    ? const Icon(Icons.check_box_outlined)
                    : const Icon(Icons.check_box_outline_blank_rounded),
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    setState(() {
                      _nodeGroupMenuGroups = context
                          .read<OutboundBloc>()
                          .state
                          .groups;
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) controller.open();
                    });
                  }
                },
              );
            },
          ),
          const Gap(5),
          MenuAnchor(
            menuChildren: [
              StatefulBuilder(
                builder: (ctx, setState0) {
                  return SubmenuButton(
                    leadingIcon: widget.config.filter.prefixes.isNotEmpty
                        ? const Icon(Icons.check_box_outlined)
                        : const Icon(Icons.check_box_outline_blank_rounded),
                    menuChildren: [
                      for (var prefix in widget.config.filter.prefixes)
                        MenuItemButton(
                          trailingIcon: const Icon(
                            Icons.delete_outline_rounded,
                          ),
                          onPressed: () {
                            _onPrefixChange(prefix, false, setState0);
                          },
                          closeOnActivate: false,
                          child: Text(prefix),
                        ),
                      const Divider(),
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.add_rounded),
                        onPressed: () async {
                          final value = await showStringForm(
                            context,
                            title: AppLocalizations.of(context)!.add,
                          );
                          if (value != null) {
                            _onPrefixChange(value, true, setState);
                          }
                        },
                        closeOnActivate: false,
                        child: Text(AppLocalizations.of(context)!.add),
                      ),
                    ],
                    child: Text(AppLocalizations.of(context)!.prefix),
                  );
                },
              ),
              StatefulBuilder(
                builder: (ctx, setState0) {
                  return SubmenuButton(
                    leadingIcon: widget.config.filter.subStrings.isNotEmpty
                        ? const Icon(Icons.check_box_outlined)
                        : const Icon(Icons.check_box_outline_blank_rounded),
                    menuChildren: [
                      for (var subString in widget.config.filter.subStrings)
                        MenuItemButton(
                          closeOnActivate: false,
                          leadingIcon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () {
                            _onSubStringChange(subString, false, setState0);
                          },
                          child: Text(subString),
                        ),
                      const Divider(),
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.add_rounded),
                        onPressed: () async {
                          final value = await showStringForm(
                            context,
                            title: AppLocalizations.of(context)!.add,
                          );
                          if (value != null) {
                            _onSubStringChange(value, true, setState);
                          }
                        },
                        closeOnActivate: false,
                        child: Text(AppLocalizations.of(context)!.add),
                      ),
                    ],
                    child: Text(AppLocalizations.of(context)!.subString),
                  );
                },
              ),
              FutureBuilder(
                future: context.read<OutboundRepo>().getAllCountryCodes(),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  final valueListenable = ValueNotifier(0);
                  valueListenable.value =
                      widget.config.filter.countryCodes.length;
                  return SubmenuButton(
                    leadingIcon: ValueListenableBuilder(
                      valueListenable: valueListenable,
                      builder: (context, value, child) {
                        return value > 0
                            ? const Icon(Icons.check_box_outlined)
                            : const Icon(Icons.check_box_outline_blank_rounded);
                      },
                    ),
                    menuChildren: [
                      for (var countryCode in snapshot.data ?? [])
                        StatefulBuilder(
                          builder: (ctx, setState) {
                            return MenuItemButton(
                              closeOnActivate: false,
                              leadingIcon: getCountryIcon(countryCode),
                              trailingIcon: Checkbox(
                                value: widget.config.filter.countryCodes
                                    .contains(countryCode),
                                onChanged: (value) {
                                  _onAreaChange(
                                    countryCode,
                                    value ?? false,
                                    setState,
                                  );
                                  valueListenable.value =
                                      widget.config.filter.countryCodes.length;
                                },
                              ),
                              onPressed: () {
                                _onAreaChange(
                                  countryCode,
                                  !widget.config.filter.countryCodes.contains(
                                    countryCode,
                                  ),
                                  setState,
                                );
                                valueListenable.value =
                                    widget.config.filter.countryCodes.length;
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(countryCode),
                              ),
                            );
                          },
                        ),
                    ],
                    child: Text(AppLocalizations.of(context)!.area),
                  );
                },
              ),
            ],
            builder: (context, controller, child) {
              return ActionChip(
                label: Text(AppLocalizations.of(context)!.others),
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                avatar:
                    widget.config.filter.prefixes.isNotEmpty ||
                        widget.config.filter.subStrings.isNotEmpty ||
                        widget.config.filter.countryCodes.isNotEmpty
                    ? const Icon(Icons.check_box_outlined)
                    : const Icon(Icons.check_box_outline_blank_rounded),
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// this widget modify [landHanlers] and call the callback when it changes
class LandHandlerSelect extends StatefulWidget {
  const LandHandlerSelect({
    super.key,
    required this.landHandlers,
    required this.onAdd,
    required this.onRemove,
    required this.onReplace,
  });
  final List<Int64> landHandlers;
  final Function(int) onAdd;
  final Function(int) onRemove;
  final Function(int, int) onReplace;

  @override
  State<LandHandlerSelect> createState() => _LandHandlerSelectState();
}

class _LandHandlerSelectState extends State<LandHandlerSelect> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 5,
      runSpacing: 5,
      children: [
        for (var handlerId in widget.landHandlers)
          FutureBuilder(
            future: context.read<OutboundRepo>().getHandlerById(
              handlerId.toInt(),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 32, width: 100);
              }
              return MenuAnchor(
                menuChildren: [
                  MenuItemButton(
                    onPressed: () {
                      setState(() {
                        widget.landHandlers.remove(handlerId);
                      });
                      widget.onRemove(handlerId.toInt());
                    },
                    child: Text(AppLocalizations.of(context)!.delete),
                  ),
                ],
                child: MenuAnchor(
                  menuChildren: context
                      .read<OutboundBloc>()
                      .state
                      .groups
                      .map(
                        (e) => FutureBuilder(
                          future: context
                              .read<OutboundRepo>()
                              .getHandlersByNodeGroup(e),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox.shrink();
                            }
                            return SubmenuButton(
                              menuChildren:
                                  snapshot.data
                                      ?.where((e) => e.config.hasOutbound())
                                      .map(
                                        (e) => MenuItemButton(
                                          onPressed: () {
                                            setState(() {
                                              widget.landHandlers[widget
                                                  .landHandlers
                                                  .indexOf(handlerId)] = Int64(
                                                e.id,
                                              );
                                            });
                                            widget.onReplace(
                                              handlerId.toInt(),
                                              e.id,
                                            );
                                          },
                                          child: Text(e.name),
                                        ),
                                      )
                                      .toList() ??
                                  [],
                              child: Text(
                                groupNametoLocalizedName(context, e.name),
                              ),
                            );
                          },
                        ),
                      )
                      .toList(),
                  builder: (context, controller, child) {
                    return GestureDetector(
                      onTap: () {
                        controller.isOpen
                            ? controller.close()
                            : controller.open(position: const Offset(0, 26));
                      },
                      child: snapshot.data == null
                          ? Chip(
                              avatar: Icon(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.deletedNode,
                              ),
                            )
                          : Chip(
                              deleteButtonTooltipMessage: '',
                              onDeleted: () {
                                controller.isOpen
                                    ? controller.close()
                                    : controller.open(
                                        position: const Offset(0, 26),
                                      );
                              },
                              deleteIcon: controller.isOpen
                                  ? const Icon(Icons.arrow_drop_up)
                                  : const Icon(Icons.arrow_drop_down),
                              avatar: snapshot.data!.countryIcon,
                              label: Text(snapshot.data!.name),
                            ),
                    );
                  },
                ),
                builder: (context, controller, child) => GestureDetector(
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
                  child: child,
                ),
              );
            },
          ),
        HandlerPicker(
          onPick: (handler) {
            setState(() {
              widget.landHandlers.add(Int64(handler.id));
            });
            widget.onAdd(handler.id);
          },
        ),
      ],
    );
  }
}

String localizedSelectorName(BuildContext context, String name) {
  if (name == defaultProxySelectorTag) {
    return AppLocalizations.of(context)!.proxy;
  }
  return name;
}

extension SelectorConfigExtension on SelectorConfig {
  String toLocalString(BuildContext? context) {
    if (tag == defaultProxySelectorTag) {
      return context == null ? tag : AppLocalizations.of(context)!.proxy;
    }
    return tag;
  }
}

extension SelectorConfigSelectingStrategyExtension
    on SelectorConfig_SelectingStrategy {
  String toLocalString(BuildContext context) {
    switch (this) {
      case SelectorConfig_SelectingStrategy.MOST_THROUGHPUT:
        return AppLocalizations.of(context)!.mostThroughput;
      case SelectorConfig_SelectingStrategy.ALL_OK:
        return AppLocalizations.of(context)!.allOk;
      case SelectorConfig_SelectingStrategy.ALL:
        return AppLocalizations.of(context)!.all;
      case SelectorConfig_SelectingStrategy.LEAST_PING:
        return AppLocalizations.of(context)!.lowestLatency;
      case SelectorConfig_SelectingStrategy.TOP_PING:
        return AppLocalizations.of(context)!.lowLatency;
      case SelectorConfig_SelectingStrategy.TOP_THROUGHPUT:
        return AppLocalizations.of(context)!.highThroughput;
      default:
        return '';
    }
  }
}

extension SelectorConfigBalanceStrategyExtension
    on SelectorConfig_BalanceStrategy {
  String toLocalString(BuildContext context) {
    switch (this) {
      case SelectorConfig_BalanceStrategy.RANDOM:
        return AppLocalizations.of(context)!.random;
      case SelectorConfig_BalanceStrategy.MEMORY:
        return AppLocalizations.of(context)!.balanceStrategyMemory;
      default:
        return '';
    }
  }
}
