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

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gap/gap.dart';
import 'package:tm/protos/vx/router/router.pb.dart';
import 'package:vx/app/control.dart';
import 'package:vx/app/home/home.dart';
import 'package:vx/app/outbound/outbound_page.dart';
import 'package:vx/app/outbound/outbound_repo.dart';
import 'package:vx/app/outbound/outbounds_bloc.dart';
import 'package:vx/app/outbound/subscription.dart';
import 'package:vx/app/routing/repo.dart';
import 'package:vx/app/routing/routing_page.dart';
import 'package:vx/app/routing/selector_being_used.dart';
import 'package:vx/app/routing/selector_cubit.dart';
import 'package:vx/app/routing/selector_test_fields_form.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/data/database.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/main.dart';
import 'package:vx/utils/geoip.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/widgets/form_dialog.dart';
import 'package:vx/widgets/handler_picker.dart';
import 'package:vx/widgets/info_widget.dart';

/// Grid of all selectors with controls to add, edit and delete them.
class SelectorsWidget extends StatelessWidget {
  const SelectorsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<SelectorRepo>();
    return BlocProvider(
      key: ObjectKey(repo),
      create: (context) => SelectorsCubit(
        selectorRepo: repo,
        xController: context.read<XController>(),
      ),
      child: const _SelectorsView(),
    );
  }
}

class _SelectorsView extends StatelessWidget {
  const _SelectorsView();

  static const _cardWidth = 300;

  Future<void> _onAdd(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<SelectorsCubit>();
    final name = await showStringForm(
      context,
      title: l10n.addSelector,
      helperText: l10n.selectorNameDuplicate,
    );
    if (name == null) return;
    if (!await cubit.add(name)) snack(l10n.selectorNameDuplicate);
  }

  void _showInfo(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) =>
          InfoDialog(children: [l10n.selectorDesc1, l10n.selectorDesc2]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectors = context.watch<SelectorsCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FilledButton.tonal(
              onPressed: () => _onAdd(context),
              child: Text(AppLocalizations.of(context)!.addSelector),
            ),
            const Gap(5),
            IconButton(
              onPressed: () => _showInfo(context),
              icon: const Icon(Icons.info_outline_rounded),
            ),
          ],
        ),
        const Gap(5),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => MasonryGridView.count(
              padding: const EdgeInsets.only(bottom: 70),
              crossAxisCount: constraints.maxWidth ~/ _cardWidth,
              itemCount: selectors.length,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              itemBuilder: (context, index) {
                final config = selectors[index];
                if (config.tag == defaultProxySelectorTag) {
                  return const DefaultProxySelectorControl(
                    key: ValueKey(defaultProxySelectorTag),
                    showName: true,
                  );
                }
                return _SelectorCard(key: ValueKey(config.tag), config: config);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectorCard extends StatelessWidget {
  const _SelectorCard({super.key, required this.config});

  final SelectorConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SelectorScope(
      config: config,
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainer,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.tag,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Gap(5),
                  BlocProvider(
                    create: (context) => SelectorBeingUsedCubit(
                      selectorTag: config.tag,
                      xController: context.read<XController>(),
                      outboundRepo: context.read<OutboundRepo>(),
                    ),
                    child: const SelectorBeingUsedView(),
                  ),
                  const Gap(5),
                  const SelectorConfigView(),
                ],
              ),
            ),
            const Positioned(right: 5, top: 5, child: _SelectorCardMenu()),
          ],
        ),
      ),
    );
  }
}

class _SelectorCardMenu extends StatelessWidget {
  const _SelectorCardMenu();

  Future<void> _edit(BuildContext context) async {
    final cubit = context.read<SelectorCubit>();
    final edited = await showSelectorTestFieldsForm(
      context,
      cubit.state.deepCopy(),
    );
    if (edited != null) await cubit.replace(edited);
  }

  void _addToHome(BuildContext context, String tag) {
    final l10n = AppLocalizations.of(context)!;
    context.read<HomeLayoutRepo>().addWidgetIdToHome('SELECTOR_$tag');
    snack(l10n.addToHomeScreen);
  }

  @override
  Widget build(BuildContext context) {
    final tag = context.read<SelectorCubit>().tag;
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.home_outlined),
          onPressed: () => _addToHome(context, tag),
          child: Text(AppLocalizations.of(context)!.addToHomeScreen),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_outlined),
          onPressed: () => _edit(context),
          child: const Text('Edit'),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.delete_outline),
          onPressed: () => context.read<SelectorsCubit>().remove(tag),
          child: const Text('Delete'),
        ),
      ],
      builder: (context, controller, child) => IconButton(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.more_vert),
      ),
    );
  }
}

/// Provides a [SelectorCubit] for [config] to [child].
class SelectorScope extends StatelessWidget {
  const SelectorScope({super.key, required this.config, required this.child});

  final SelectorConfig config;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<SelectorRepo>();
    return BlocProvider(
      key: ObjectKey(repo),
      create: (context) => SelectorCubit(
        initial: config,
        selectorRepo: repo,
        outboundRepo: context.read<OutboundRepo>(),
        xController: context.read<XController>(),
      ),
      child: child,
    );
  }
}

/// Editor for the selector provided by the nearest [SelectorScope].
class SelectorConfigView extends StatelessWidget {
  const SelectorConfigView({super.key});

  static const _balancedStrategies = {
    SelectorConfig_SelectingStrategy.ALL_OK,
    SelectorConfig_SelectingStrategy.TOP_PING,
    SelectorConfig_SelectingStrategy.TOP_THROUGHPUT,
    SelectorConfig_SelectingStrategy.ALL,
  };

  static const _balanceStrategies = [
    SelectorConfig_BalanceStrategy.RANDOM,
    SelectorConfig_BalanceStrategy.MEMORY,
  ];

  @override
  Widget build(BuildContext context) {
    final config = context.watch<SelectorCubit>().state;
    final cubit = context.read<SelectorCubit>();
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(l10n.range),
        const Gap(5),
        Row(
          children: [
            ChoiceChip(
              label: Text(l10n.allNodes),
              selected: config.filter.all,
              onSelected: (value) {
                if (value) cubit.setAllNodes(true);
              },
            ),
            const Gap(5),
            ChoiceChip(
              label: Text(l10n.partialNodes),
              selected: !config.filter.all,
              onSelected: (value) {
                if (value) cubit.setAllNodes(false);
              },
            ),
          ],
        ),
        if (!config.filter.all) _SelectorFilter(filter: config.filter),
        const Gap(10),
        _SectionLabel(l10n.selectingStrategy),
        const Gap(5),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            for (final strategy in SelectorConfig_SelectingStrategy.values)
              ChoiceChip(
                label: Text(strategy.toLocalString(context)),
                selected: config.strategy == strategy,
                onSelected: (value) {
                  if (value) cubit.setStrategy(strategy);
                },
              ),
          ],
        ),
        if (_balancedStrategies.contains(config.strategy)) ...[
          const Gap(10),
          _SectionLabel(l10n.balanceStrategy),
          const Gap(5),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final strategy in _balanceStrategies)
                ChoiceChip(
                  label: Text(strategy.toLocalString(context)),
                  selected: config.balanceStrategy == strategy,
                  onSelected: (value) {
                    if (value) cubit.setBalanceStrategy(strategy);
                  },
                ),
            ],
          ),
        ],
        const Gap(10),
        Tooltip(
          preferBelow: false,
          message: l10n.nodeChainDesc,
          child: _SectionLabel(l10n.nodeChain),
        ),
        const SizedBox(height: 5, width: double.infinity),
        LandHandlerSelect(
          landHandlers: config.landHandlers,
          onChanged: cubit.setLandHandlers,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Node / node group / other filters used when a selector does not cover all
/// nodes.
class _SelectorFilter extends StatelessWidget {
  const _SelectorFilter({required this.filter});

  final SelectorConfig_Filter filter;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SelectorCubit>();
    final groups = context.watch<OutboundBloc>().state.groups;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        children: [
          _MenuChip(
            label: l10n.node,
            active: filter.handlerIds.isNotEmpty,
            menuChildren: [
              for (final group in groups)
                _GroupHandlersSubmenu(
                  group: group,
                  leadingIconBuilder: (handlers) => _CheckIcon(
                    handlers.any(
                      (h) => filter.handlerIds.contains(Int64(h.id)),
                    ),
                  ),
                  itemBuilder: (handler) => _CheckMenuItem(
                    checked: filter.handlerIds.contains(Int64(handler.id)),
                    onChanged: (selected) =>
                        cubit.setHandlerSelected(handler.id, selected),
                    child: Text(handler.name),
                  ),
                ),
            ],
          ),
          _MenuChip(
            label: l10n.nodeGroup,
            active: filter.groupTags.isNotEmpty || filter.subIds.isNotEmpty,
            menuChildren: [
              for (final group in groups)
                if (group is MySubscription)
                  _CheckMenuItem(
                    checked: filter.subIds.contains(Int64(group.id)),
                    onChanged: (selected) =>
                        cubit.setSubscriptionSelected(group.id, selected),
                    child: Text(groupNametoLocalizedName(context, group.name)),
                  )
                else
                  _CheckMenuItem(
                    checked: filter.groupTags.contains(group.name),
                    onChanged: (selected) =>
                        cubit.setGroupSelected(group.name, selected),
                    child: Text(groupNametoLocalizedName(context, group.name)),
                  ),
            ],
          ),
          _MenuChip(
            label: l10n.others,
            active:
                filter.prefixes.isNotEmpty ||
                filter.subStrings.isNotEmpty ||
                filter.countryCodes.isNotEmpty,
            menuChildren: [
              _StringListSubmenu(
                label: l10n.prefix,
                values: filter.prefixes,
                onChanged: cubit.setPrefix,
              ),
              _StringListSubmenu(
                label: l10n.subString,
                values: filter.subStrings,
                onChanged: cubit.setSubString,
              ),
              _CountryCodeSubmenu(
                selected: filter.countryCodes,
                onChanged: cubit.setCountryCode,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckIcon extends StatelessWidget {
  const _CheckIcon(this.checked);

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Icon(
      checked
          ? Icons.check_box_outlined
          : Icons.check_box_outline_blank_rounded,
    );
  }
}

/// An [ActionChip] that toggles a dropdown menu.
class _MenuChip extends StatelessWidget {
  const _MenuChip({
    required this.label,
    required this.active,
    required this.menuChildren,
  });

  final String label;
  final bool active;
  final List<Widget> menuChildren;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      consumeOutsideTap: true,
      menuChildren: menuChildren,
      builder: (context, controller, child) => ActionChip(
        label: Text(label),
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        avatar: _CheckIcon(active),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

/// A menu item with a checkbox that stays open when toggled.
class _CheckMenuItem extends StatelessWidget {
  const _CheckMenuItem({
    required this.checked,
    required this.onChanged,
    required this.child,
    this.icon,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;
  final Widget child;

  /// When set, it is shown as the leading icon and the checkbox moves to the
  /// trailing side.
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final checkbox = Checkbox(
      value: checked,
      onChanged: (value) => onChanged(value ?? false),
    );
    return MenuItemButton(
      closeOnActivate: false,
      leadingIcon: icon ?? checkbox,
      trailingIcon: icon == null ? null : checkbox,
      onPressed: () => onChanged(!checked),
      child: child,
    );
  }
}

/// Submenu listing the handlers of [group], loaded when the menu is opened.
class _GroupHandlersSubmenu extends StatefulWidget {
  const _GroupHandlersSubmenu({
    required this.group,
    required this.itemBuilder,
    this.leadingIconBuilder,
  });

  final NodeGroup group;
  final Widget Function(OutboundHandler handler) itemBuilder;
  final Widget Function(List<OutboundHandler> handlers)? leadingIconBuilder;

  @override
  State<_GroupHandlersSubmenu> createState() => _GroupHandlersSubmenuState();
}

class _GroupHandlersSubmenuState extends State<_GroupHandlersSubmenu> {
  List<OutboundHandler> _handlers = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_GroupHandlersSubmenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.group.name != widget.group.name) _load();
  }

  Future<void> _load() async {
    try {
      final handlers = await context
          .read<OutboundRepo>()
          .getHandlersByNodeGroup(widget.group);
      if (!mounted) return;
      setState(() {
        _handlers = handlers.where((h) => h.config.hasOutbound()).toList();
      });
    } catch (e) {
      logger.e('Error loading handlers of ${widget.group.name}', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SubmenuButton(
      leadingIcon: widget.leadingIconBuilder?.call(_handlers),
      menuChildren: _handlers.map(widget.itemBuilder).toList(),
      child: Text(groupNametoLocalizedName(context, widget.group.name)),
    );
  }
}

/// Submenu to add and remove free-form strings.
class _StringListSubmenu extends StatelessWidget {
  const _StringListSubmenu({
    required this.label,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final List<String> values;
  final void Function(String value, bool selected) onChanged;

  Future<void> _add(BuildContext context) async {
    final value = await showStringForm(
      context,
      title: AppLocalizations.of(context)!.add,
    );
    if (value != null) onChanged(value, true);
  }

  @override
  Widget build(BuildContext context) {
    return SubmenuButton(
      leadingIcon: _CheckIcon(values.isNotEmpty),
      menuChildren: [
        for (final value in values)
          MenuItemButton(
            closeOnActivate: false,
            trailingIcon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => onChanged(value, false),
            child: Text(value),
          ),
        const Divider(),
        MenuItemButton(
          closeOnActivate: false,
          leadingIcon: const Icon(Icons.add_rounded),
          onPressed: () => _add(context),
          child: Text(AppLocalizations.of(context)!.add),
        ),
      ],
      child: Text(label),
    );
  }
}

/// Submenu to pick country codes among those of existing handlers.
class _CountryCodeSubmenu extends StatefulWidget {
  const _CountryCodeSubmenu({required this.selected, required this.onChanged});

  final List<String> selected;
  final void Function(String countryCode, bool selected) onChanged;

  @override
  State<_CountryCodeSubmenu> createState() => _CountryCodeSubmenuState();
}

class _CountryCodeSubmenuState extends State<_CountryCodeSubmenu> {
  List<String> _countryCodes = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final codes = await context.read<OutboundRepo>().getAllCountryCodes();
      if (mounted) setState(() => _countryCodes = codes);
    } catch (e) {
      logger.e('Error loading country codes', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SubmenuButton(
      leadingIcon: _CheckIcon(widget.selected.isNotEmpty),
      menuChildren: [
        for (final code in _countryCodes)
          _CheckMenuItem(
            icon: getCountryIcon(code),
            checked: widget.selected.contains(code),
            onChanged: (selected) => widget.onChanged(code, selected),
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(code),
            ),
          ),
      ],
      child: Text(AppLocalizations.of(context)!.area),
    );
  }
}

/// Edits a node chain. Never mutates [landHandlers]; every edit reports a new
/// list through [onChanged].
class LandHandlerSelect extends StatelessWidget {
  const LandHandlerSelect({
    super.key,
    required this.landHandlers,
    required this.onChanged,
  });

  final List<Int64> landHandlers;
  final ValueChanged<List<Int64>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 5,
      runSpacing: 5,
      children: [
        for (final (index, handlerId) in landHandlers.indexed)
          _LandHandlerChip(
            key: ValueKey((index, handlerId)),
            handlerId: handlerId.toInt(),
            onRemove: () => onChanged(List.of(landHandlers)..removeAt(index)),
            onReplace: (newId) =>
                onChanged(List.of(landHandlers)..[index] = Int64(newId)),
          ),
        HandlerPicker(
          onPick: (handler) => onChanged([...landHandlers, Int64(handler.id)]),
        ),
      ],
    );
  }
}

class _LandHandlerChip extends StatefulWidget {
  const _LandHandlerChip({
    super.key,
    required this.handlerId,
    required this.onRemove,
    required this.onReplace,
  });

  final int handlerId;
  final VoidCallback onRemove;
  final ValueChanged<int> onReplace;

  @override
  State<_LandHandlerChip> createState() => _LandHandlerChipState();
}

class _LandHandlerChipState extends State<_LandHandlerChip> {
  static const _menuOffset = Offset(0, 26);

  bool _loading = true;
  OutboundHandler? _handler;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(_LandHandlerChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.handlerId != widget.handlerId) _load();
  }

  Future<void> _load() async {
    final handler = await context.read<OutboundRepo>().getHandlerById(
      widget.handlerId,
    );
    if (!mounted) return;
    setState(() {
      _handler = handler;
      _loading = false;
    });
  }

  void _toggle(MenuController controller) => controller.isOpen
      ? controller.close()
      : controller.open(position: _menuOffset);

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 32, width: 100);
    final handler = _handler;
    final groups = context.watch<OutboundBloc>().state.groups;
    final replaceMenu = MenuAnchor(
      menuChildren: [
        for (final group in groups)
          _GroupHandlersSubmenu(
            group: group,
            itemBuilder: (h) => MenuItemButton(
              onPressed: () => widget.onReplace(h.id),
              child: Text(h.name),
            ),
          ),
      ],
      builder: (context, controller, child) => GestureDetector(
        onTap: () => _toggle(controller),
        child: handler == null
            ? Chip(
                avatar: Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                label: Text(AppLocalizations.of(context)!.deletedNode),
              )
            : Chip(
                deleteButtonTooltipMessage: '',
                onDeleted: () => _toggle(controller),
                deleteIcon: Icon(
                  controller.isOpen
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                ),
                avatar: handler.countryIcon,
                label: Text(handler.name),
              ),
      ),
    );
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          onPressed: widget.onRemove,
          child: Text(AppLocalizations.of(context)!.delete),
        ),
      ],
      builder: (context, controller, child) => GestureDetector(
        onSecondaryTapDown: (details) =>
            controller.open(position: details.localPosition),
        onLongPress: controller.open,
        child: child,
      ),
      child: replaceMenu,
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
