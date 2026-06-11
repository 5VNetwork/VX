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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide RouterConfig;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/vx/dns/dns.pb.dart';
import 'package:vx/app/layout_provider.dart';
import 'package:vx/app/log/log_page.dart';
import 'package:vx/app/outbound/outbound_repo.dart';
import 'package:vx/app/routing/add_dialog.dart';
import 'package:vx/app/routing/default.dart';
import 'package:vx/app/routing/default_mode_dialog.dart';
import 'package:vx/app/routing/repo.dart';
import 'package:vx/app/routing/selector_widget.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/data/database_provider.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:tm/protos/vx/router/router.pb.dart';
import 'package:vx/app/routing/routing_page.dart';
import 'package:vx/app/routing/mode_form.dart' hide Condition;
import 'package:vx/app/routing/set_widget.dart';
import 'package:vx/app/blocs/proxy_selector/proxy_selector_bloc.dart';
import 'package:vx/common/config.dart';
import 'package:vx/data/database.dart';
import 'package:vx/main.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/random.dart';
import 'package:vx/utils/ui.dart';
import 'package:vx/widgets/form_dialog.dart';
import 'package:vx/widgets/info_widget.dart';
import 'package:vx/widgets/pro_icon.dart';
import 'package:vx/widgets/pro_promotion.dart';

class ModeWidget extends StatefulWidget {
  const ModeWidget({super.key, this.switchModeButton});
  final Widget? switchModeButton;
  @override
  State<ModeWidget> createState() => _ModeWidgetState();
}

class _ModeWidgetState extends State<ModeWidget>
    with AutomaticKeepAliveClientMixin<ModeWidget> {
  List<CustomRouteMode> _customRouteModes = [];
  // final List<DefaultRouteMode> _stdRouteModes = [
  //   DefaultRouteMode.black,
  //   DefaultRouteMode.white,
  //   DefaultRouteMode.proxyAll
  // ];
  CustomRouteMode? _selected;
  // late Future _getCustomRouteModesFuture;
  late RouteRepo _routeRepo;
  StreamSubscription? _customRouteModesSubscription;
  late final ScrollController _scrollController;
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeRepo = context.watch<RouteRepo>();
    _customRouteModesSubscription?.cancel();
    _customRouteModesSubscription = _routeRepo
        .getCustomRouteModesStream()
        .listen((value) {
          _loading = false;
          _customRouteModes = value;
          if (_selected == null) {
            _selected = _customRouteModes
                .where(
                  (e) =>
                      e.name == context.read<SharedPreferences>().routingMode,
                )
                .firstOrNull;
            _selected ??= _customRouteModes.firstOrNull;
          } else {
            _selected = _customRouteModes
                .where((e) => e.name == _selected!.name)
                .firstOrNull;
          }
          setState(() {});
        });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _customRouteModesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onDefaultRouteModeTap() async {
    final al = AppLocalizations.of(context)!;
    final dp = context.read<DatabaseProvider>();
    final selectedMode = await showDefaultRouteModeDialog(context);
    if (selectedMode != null) {
      // Insert the selected default route mode
      await insertDefaultRouteMode(al, selectedMode, dp.database);
    }
  }

  Future<void> _onTap() async {
    final dp = context.read<DatabaseProvider>();
    final al = AppLocalizations.of(context)!;
    final name = await showDialog<(String, DefaultRouteMode?)?>(
      context: context,
      builder: (context) => const RouteConfigForm(),
    );
    if (name != null && name.$1.isNotEmpty) {
      final config = CustomRouteMode(
        id: SnowflakeId.generate(),
        name: name.$1,
        routerConfig: RouterConfig(),
        dnsRules: DnsRules(),
        internalDnsServers: [],
      );
      if (name.$2 != null) {
        config.routerConfig.rules.addAll(name.$2!.displayRouterRules(al: al));
        config.dnsRules.rules.addAll(name.$2!.dnsRules(al: al));
        config.internalDnsServers.addAll(name.$2!.internalDnsServers(al: al));
        insertDefaultRouteMode(al, name.$2!, dp.database, setsOnly: true);
      }
      try {
        await _routeRepo.addCustomRouteMode(config);
      } catch (e) {
        snack(e.toString());
      }
    }
  }

  Future<void> _onDelete(CustomRouteMode e) async {
    final bloc = context.read<ProxySelectorBloc>();
    await context.read<RouteRepo>().removeCustomRouteMode(e.id);
    setState(() {
      _customRouteModes.remove(e);
      if (_selected == e) {
        _selected = _customRouteModes.firstOrNull;
      }
    });
    bloc.add(CustomRouteModeDeleteEvent(e));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Provider.of<MyLayout>(context).isCompact
                        ? DropdownMenu<CustomRouteMode>(
                            requestFocusOnTap: false,
                            width: 100,
                            textStyle: Theme.of(context).textTheme.bodyMedium,
                            trailingIcon: Transform.translate(
                              offset: const Offset(-1, -1),
                              child: const Icon(Icons.arrow_drop_down),
                            ),
                            selectedTrailingIcon: Transform.translate(
                              offset: const Offset(-1, -1),
                              child: const Icon(Icons.arrow_drop_up),
                            ),
                            initialSelection: _selected,
                            inputDecorationTheme: InputDecorationTheme(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              isDense: true,
                              suffixIconConstraints: const BoxConstraints(
                                minHeight: 40,
                                maxHeight: 40,
                                minWidth: 40,
                                maxWidth: 40,
                              ),
                              filled: true,
                              fillColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerLow,
                              constraints: const BoxConstraints(
                                minHeight: 40,
                                maxHeight: 40,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                borderSide: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                            ),
                            dropdownMenuEntries:
                                [
                                  // ..._stdRouteModes,
                                  ..._customRouteModes,
                                ].map((e) {
                                  return DropdownMenuEntry(
                                    value: e,
                                    label: e.name,
                                    style: ButtonStyle(
                                      minimumSize: WidgetStateProperty.all(
                                        const Size(200, 48),
                                      ),
                                    ),
                                    trailingIcon: IconButton(
                                      onPressed: () async {
                                        await _onDelete(e);
                                      },
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  );
                                }).toList(),
                            onSelected: (CustomRouteMode? e) {
                              if (e != null) {
                                setState(() => _selected = e);
                              }
                            },
                          )
                        : Listener(
                            onPointerSignal: (pointerSignal) {
                              if (pointerSignal is PointerScrollEvent) {
                                final offset = _scrollController.offset;
                                final delta = pointerSignal.scrollDelta.dy;
                                final newOffset = (offset + delta).clamp(
                                  _scrollController.position.minScrollExtent,
                                  _scrollController.position.maxScrollExtent,
                                );
                                _scrollController.jumpTo(newOffset);
                              }
                            },
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: _scrollController,
                              child: Row(
                                children: [
                                  // ..._stdRouteModes.map((e) => Padding(
                                  //       padding:
                                  //           const EdgeInsets.only(right: 5),
                                  //       child: FilterChip(
                                  //           label: Text(
                                  //               e.toLocalString(context)),
                                  //           selected: e == _selected,
                                  //           onSelected: (bool v) {
                                  //             if (v) {
                                  //               setState(() => _selected = e);
                                  //             }
                                  //           }),
                                  //     )),
                                  ..._customRouteModes.map(
                                    (e) => Padding(
                                      padding: const EdgeInsets.only(right: 5),
                                      child: WrapChoiceChip(
                                        text: e.name,
                                        selected: e == _selected,
                                        onDelete: () async {
                                          await _onDelete(e);
                                        },
                                        onTap: (bool v) =>
                                            setState(() => _selected = e),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => InfoDialog(
                          children: [
                            AppLocalizations.of(context)!.routerRuleDescription,
                            AppLocalizations.of(context)!.dnsRuleDesc,
                            AppLocalizations.of(context)!.internalDnsDesc,
                            AppLocalizations.of(context)!.nodeSetDesc,
                            AppLocalizations.of(context)!.dnsNameDesc,
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.info_outline_rounded),
                  ),
                  const Gap(5),
                  MenuAnchor(
                    menuChildren: [
                      MenuItemButton(
                        onPressed: _onDefaultRouteModeTap,
                        child: Text(
                          AppLocalizations.of(context)!.defaultRouteModes,
                        ),
                      ),
                      MenuItemButton(
                        onPressed: _onTap,
                        child: Text(AppLocalizations.of(context)!.custom),
                      ),
                    ],
                    builder: (context, controller, child) =>
                        IconButton.filledTonal(
                          padding: const EdgeInsets.all(0),
                          tooltip: AppLocalizations.of(context)!.addRouteMode,
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(),
                          onPressed: () => controller.open(),
                          icon: const Icon(Icons.add_rounded),
                        ),
                  ),
                ],
              ),
            ),
            widget.switchModeButton ?? const SizedBox.shrink(),
          ],
        ),
        const Gap(10),
        if (_loading) const Expanded(child: SizedBox()),
        if (_selected == null && !_loading)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: Text(
                  _customRouteModes.isEmpty
                      ? AppLocalizations.of(context)!.addRouteModeNotice
                      : AppLocalizations.of(context)!.pleaseSelectARoutingMode,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        if (_selected != null)
          Expanded(
            child: Material(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 70),
                  child: isDefaultRouteMode(_selected!.name, context)
                      ? _StandardModeWidget(routeMode: _selected!)
                      : CustomRouteModeWidget(
                          routeMode: _selected!,
                          onUpdate: (updated) async {
                            final xbloc = context.read<ProxySelectorBloc>();
                            await _routeRepo.updateCustomRouteMode(
                              updated.id,
                              routerConfig: updated.routerConfig,
                              dnsRules: updated.dnsRules,
                              internalDnsServers: updated.internalDnsServers,
                            );
                            xbloc.add(CustomRouteModeChangeEvent(updated));
                          },
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String localizedSetName(BuildContext context, String name) {
  switch (name) {
    // case customDirect:
    //   return AppLocalizations.of(context)!.customDirect;
    // case customProxy:
    //   return AppLocalizations.of(context)!.customProxy;
    // case cnGames:
    //   return AppLocalizations.of(context)!.cnGames;
    // case private:
    //   return AppLocalizations.of(context)!.private;
    // case gfwWithoutCustomDirect:
    //   return AppLocalizations.of(context)!.gfwWithoutCustomDirect;
    // case proxy:
    //   return AppLocalizations.of(context)!.proxy;
    // case directAppSetName:
    //   return AppLocalizations.of(context)!.direct;
    // case block:
    //   return AppLocalizations.of(context)!.block;
    // case blackListProxy:
    //   return AppLocalizations.of(context)!.blackListProxy;
    // case blackListDirect:
    //   return AppLocalizations.of(context)!.blackListDirect;
    // case whiteListDirect:
    //   return AppLocalizations.of(context)!.whiteListDirect;
    // case whiteListProxy:
    //   return AppLocalizations.of(context)!.whiteListProxy;
    // case proxyAllDirect:
    //   return AppLocalizations.of(context)!.proxyAllDirect;
    // case proxyAllProxy:
    //   return AppLocalizations.of(context)!.proxyAllProxy;

    default:
      return name;
  }
}

class RouteConfigForm extends StatefulWidget {
  const RouteConfigForm({super.key});

  @override
  State<RouteConfigForm> createState() => _RouteConfigFormState();
}

class _RouteConfigFormState extends State<RouteConfigForm> {
  final _nameController = TextEditingController();
  DefaultRouteMode? _routeMode;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.addRouteMode),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.name,
              border: const OutlineInputBorder(),
            ),
          ),
          const Gap(10),
          DropdownMenu(
            label: Text(AppLocalizations.of(context)!.copyDefault),
            initialSelection: _routeMode,
            dropdownMenuEntries: DefaultRouteMode.values
                .map(
                  (e) => DropdownMenuEntry(
                    value: e,
                    label: e.toLocalString(AppLocalizations.of(context)!),
                  ),
                )
                .toList(),
            onSelected: (value) {
              setState(() {
                _routeMode = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty) {
              Navigator.pop(context, (_nameController.text, _routeMode));
            }
          },
          child: Text(AppLocalizations.of(context)!.confirm),
        ),
      ],
    );
  }
}

class UnmodifiableRouteConfig extends StatelessWidget {
  const UnmodifiableRouteConfig({super.key, required this.routerConfig});
  final RouterConfig routerConfig;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          preferBelow: false,
          message: AppLocalizations.of(context)!.routerRuleDescription,
          child: Text(
            AppLocalizations.of(context)!.routerRules,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Gap(5),
        Material(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: routerConfig.rules.length,
            itemBuilder: (context, index) => ExpansionTile(
              title: Text(routerConfig.rules[index].ruleName),
              leading: _getLeading(context, routerConfig.rules[index]),
              collapsedShape: index == routerConfig.rules.length - 1
                  ? null
                  : Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
              shape: index == routerConfig.rules.length - 1
                  ? const Border()
                  : Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerLow,
              collapsedBackgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerLow,
              children: routerConfig.rules[index].children(context),
              // onTap: () => _onTap(index, false),
            ),
          ),
        ),
      ],
    );
  }
}

class _StandardModeWidget extends StatelessWidget {
  const _StandardModeWidget({required this.routeMode});
  final CustomRouteMode routeMode;
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UnmodifiableRouteConfig(routerConfig: routeMode.routerConfig),
          const Gap(10),
          _StandardModeDnsRules(routeMode: routeMode),
          const Gap(10),
          _InternalDnsServers(routeMode: routeMode, editable: false),
        ],
      ),
    );
  }
}

class _StandardModeDnsRules extends StatefulWidget {
  const _StandardModeDnsRules({required this.routeMode});
  final CustomRouteMode routeMode;
  @override
  State<_StandardModeDnsRules> createState() => _StandardModeDnsRulesState();
}

class _StandardModeDnsRulesState extends State<_StandardModeDnsRules> {
  List<DnsRuleConfig> _rules = [];

  @override
  void initState() {
    super.initState();
    _rules = widget.routeMode.dnsRules.rules;
  }

  @override
  void didUpdateWidget(covariant _StandardModeDnsRules oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeMode != widget.routeMode) {
      _rules = widget.routeMode.dnsRules.rules;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            preferBelow: false,
            message: AppLocalizations.of(context)!.dnsRuleDesc,
            child: Text(
              AppLocalizations.of(context)!.dnsRule,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Gap(5),
          Material(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _rules.length,
              itemBuilder: (context, index) => ExpansionTile(
                title: Text(_rules[index].ruleName),
                leading: isCompact(context)
                    ? null
                    : _getLeadingDnsRule(context, _rules[index]),
                subtitle: isCompact(context)
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: _getLeadingDnsRule(context, _rules[index]),
                        ),
                      )
                    : null,
                collapsedShape: index == _rules.length - 1
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                shape: index == _rules.length - 1
                    ? const Border()
                    : Border(
                        bottom: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerLow,
                collapsedBackgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerLow,
                children: _rules[index].children(context),
                // onTap: () => _onTap(index, false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const ruleNameVXTestNode = 'VX测节点';
const ruleNameInternalDnsProxyGoProxy = '内部DNS CF';
const ruleNameInternalDnsDirectGoDirect = '内部DNS 阿里云&CF';
const ruleNameProxyDnsServerGoProxy = '代理DNS服务器';
const ruleNameDirectDnsServerGoDirect = '直连DNS服务器';
const ruleNameCustomDirectDomain = '自定义直连域名';
const ruleNameCustomDirectIp = '自定义直连IP';
const ruleNameCustomProxyDomain = '自定义代理域名';
const ruleNameCustomProxyIp = '自定义代理IP';
const ruleNameProxyApp = '代理应用';
const ruleNameDirectApp = '直连应用';
const ruleNameCnDirectIp = 'CN模式直连IP';
const ruleNameDefaultProxy = '默认代理';
const ruleNameCnDirectDomain = 'CN模式直连域名';
const ruleNameGfwProxyDomain = 'GFW模式代理域名';
const ruleNameGfwProxyIp = 'GFW模式代理IP';
const ruleNameDefaultDirect = '默认直连';
const ruleNameGlobalDirectDomain = '全局模式直连域名';
const ruleNameGlobalDirectIp = '全局模式直连IP';
const ruleNameRuBlockProxyDomain = 'RU-Block模式代理域名';
const ruleNameRuBlockProxyIp = 'RU-Block模式代理IP';
const ruleNameRuBlockAllProxyDomain = 'RU-Block(All)模式代理域名';
const ruleNameRuBlockAllProxyIp = 'RU-Block(All)模式代理IP';

extension ConditionExtension on Condition {
  List<Widget> conditionChildren(BuildContext context) {
    final ret = <Widget>[];
    if (matchAll) {
      ret.add(
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppLocalizations.of(context)!.matchAll,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      );
    }
    if (inboundTags.isNotEmpty) {
      ret.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${AppLocalizations.of(context)!.inbound}:',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Gap(5),
              ...inboundTags.indexed.map(
                (e) => Text(
                  '${e.$2}${e.$1 == inboundTags.length - 1 ? '' : ', '}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (fakeIp) {
      ret.add(
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Fake IP',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      );
    }
    if (hasNoDomain) {
      ret.add(
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppLocalizations.of(context)!.hasNoDomain,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      );
    }
    if (domainTags.isNotEmpty) {
      ret.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${AppLocalizations.of(context)!.domainSet}:',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Gap(5),
              ...domainTags.map(
                (e) => Text(e, style: Theme.of(context).textTheme.labelSmall),
              ),
            ],
          ),
        ),
      );
    }
    if (geoDomains.isNotEmpty) {
      ret.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${AppLocalizations.of(context)!.domain}:',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Gap(5),
              ...geoDomains.map(
                (e) => Text(
                  '(${e.type.toLocalString(context)})${e.value} ',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (appTags.isNotEmpty) {
      ret.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${AppLocalizations.of(context)!.appSet}:',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Gap(5),
              ...appTags.map(
                (e) => Text(e, style: Theme.of(context).textTheme.labelSmall),
              ),
            ],
          ),
        ),
      );
    }
    if (appIds.isNotEmpty) {
      ret.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${AppLocalizations.of(context)!.app}:',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Gap(5),
              ...appIds.map(
                (e) => Text(
                  '(${e.type.toLocalString(context)})${e.value}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (dstIpTags.isNotEmpty) {
      ret.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${AppLocalizations.of(context)!.dstIpSet}:',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Gap(5),
              ...dstIpTags.map(
                (e) => Text(e, style: Theme.of(context).textTheme.labelSmall),
              ),
            ],
          ),
        ),
      );
    }
    if (allTags.isNotEmpty) {
      ret.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${AppLocalizations.of(context)!.domain}/IP:',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Gap(5),
              ...allTags.map(
                (e) => Text(e, style: Theme.of(context).textTheme.labelSmall),
              ),
            ],
          ),
        ),
      );
    }
    return ret;
  }
}

extension RuleConfigExtension on RuleConfig {
  Condition get _displayCondition {
    if (hasCondition()) {
      return condition;
    }
    return Condition(
      inboundTags: inboundTags,
      fakeIp: fakeIp,
      domainTags: domainTags,
      geoDomains: geoDomains,
      appTags: appTags,
      appIds: appIds,
      dstIpTags: dstIpTags,
      allTags: allTags,
      matchAll: matchAll,
    );
  }

  // String localizedName(BuildContext context) {
  //   switch (ruleName) {
  //     case ruleNameInternalDnsProxyGoProxy:
  //       return AppLocalizations.of(context)!.ruleNameInternalDnsProxyGoProxy;
  //     case ruleNameInternalDnsDirectGoDirect:
  //       return AppLocalizations.of(context)!.ruleNameInternalDnsDirectGoDirect;
  //     case ruleNameProxyDnsServerGoProxy:
  //       return AppLocalizations.of(context)!.ruleNameProxyDnsServerGoProxy;
  //     case ruleNameDirectDnsServerGoDirect:
  //       return AppLocalizations.of(context)!.ruleNameDirectDnsServerGoDirect;
  //     case ruleNameVXTestNode:
  //       return AppLocalizations.of(context)!.ruleNameVXTestNodes;
  //     case ruleNameCustomDirectDomain:
  //       return AppLocalizations.of(context)!.ruleNameCustomDirectDomain;
  //     case ruleNameCustomDirectIp:
  //       return AppLocalizations.of(context)!.ruleNameCustomDirectIp;
  //     case ruleNameCustomProxyDomain:
  //       return AppLocalizations.of(context)!.ruleNameCustomProxyDomain;
  //     case ruleNameCustomProxyIp:
  //       return AppLocalizations.of(context)!.ruleNameCustomProxyIp;
  //     case ruleNameProxyApp:
  //       return AppLocalizations.of(context)!.ruleNameProxyApp;
  //     case ruleNameDirectApp:
  //       return AppLocalizations.of(context)!.ruleNameDirectApp;
  //     case ruleNameCnModeDirectIp:
  //       return AppLocalizations.of(context)!.ruleNameCnDirectIp;
  //     case ruleNameDefaultProxy:
  //       return AppLocalizations.of(context)!.ruleNameDefaultProxy;
  //     case ruleNameCnModeDirectDomain:
  //       return AppLocalizations.of(context)!.ruleNameCnDirectDomain;
  //     case ruleNameGfwModeProxyDomain:
  //       return AppLocalizations.of(context)!.ruleNameGfwProxyDomain;
  //     case ruleNameGfwModeProxyIp:
  //       return AppLocalizations.of(context)!.ruleNameGfwProxyIp;
  //     case ruleNameDefaultDirect:
  //       return AppLocalizations.of(context)!.ruleNameDefaultDirect;
  //     case ruleNameGlobalDirectDomain:
  //       return AppLocalizations.of(context)!.ruleNameGlobalDirectDomain;
  //     case ruleNameGlobalDirectIp:
  //       return AppLocalizations.of(context)!.ruleNameGlobalDirectIp;
  //     default:
  //       return ruleName;
  //   }
  // }

  List<Widget> children(BuildContext context) {
    final ret = <Widget>[const Gap(10)];
    ret.addAll(_displayCondition.conditionChildren(context));
    if (fallbacks.isNotEmpty) {
      ret.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${AppLocalizations.of(context)!.fallback}:',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              ...fallbacks.map(
                (e) => e.selectorTag.isNotEmpty
                    ? Text(
                        '${localizedSelectorName(context, e.selectorTag)} ',
                        style: Theme.of(context).textTheme.labelSmall,
                      )
                    : (e.outboundTag != directHandlerTag
                          ? HandlerLabel(
                              handlerIdString: e.outboundTag,
                              style: Theme.of(context).textTheme.labelSmall,
                            )
                          : Text(
                              AppLocalizations.of(context)!.direct,
                              style: Theme.of(context).textTheme.labelSmall,
                            )),
              ),
            ],
          ),
        ),
      );
    }
    ret.add(const Gap(10));
    return ret;
  }
}

// const dnsRuleNameDefaultDirect = '直连域名';
// const dnsRuleNameGfwProxyFake = 'GFW模式代理域名A/AAAA';
// const dnsRuleNameGfwProxy = 'GFW模式代理域名';
// const dnsRuleNameRuBlockProxyFake = 'RU-Block Mode Proxy Domains(A/AAAA)';
// const dnsRuleNameRuBlockProxy = 'RU-Block Mode Proxy Domains';
// const dnsRuleNameRuBlockAllProxyFake =
//     'RU-Block(All) Mode Proxy Domains(A/AAAA)';
// const dnsRuleNameRuBlockAllProxy = 'RU-Block(All) Mode Proxy Domains';
// const dnsRuleNameCnProxyFake = 'CN模式代理域名A/AAAA';
// const dnsRuleNameCnProxy = 'CN模式代理域名';
// const dnsRuleNameProxyAllProxyFake = '全局模式代理域名A/AAAA';
// const dnsRuleNameProxyAllProxy = '全局模式代理域名';

extension DnsRuleConfigExtension on DnsRuleConfig {
  List<Widget> children(BuildContext context) {
    final ret = <Widget>[const Gap(10)];
    if (domains.isEmpty && domainTags.isEmpty && includedTypes.isEmpty) {
      ret.add(
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppLocalizations.of(context)!.matchAll,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
      );
    }
    // if (fakeEnabled) {
    //   ret.add(Align(
    //     alignment: Alignment.centerLeft,
    //     child: Padding(
    //       padding: const EdgeInsets.symmetric(horizontal: 16),
    //       child: Text('Fake IP', style: Theme.of(context).textTheme.labelSmall),
    //     ),
    //   ));
    // }
    if (domainTags.isNotEmpty) {
      ret.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${AppLocalizations.of(context)!.domainSet}:',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Gap(5),
              Text(
                domainTags.join(', '),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      );
    }
    if (includedTypes.isNotEmpty) {
      ret.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                '${AppLocalizations.of(context)!.type}:',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Gap(5),
              ...includedTypes.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    e.name,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    ret.add(const Gap(10));
    return ret;
  }
}

Widget _getLeading(BuildContext context, RuleConfig rule) {
  if (rule.outboundTag == directHandlerTag) {
    return Chip(
      side: const BorderSide(color: Colors.transparent),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 0),
      backgroundColor: pinkColorTheme.secondaryContainer,
      label: Text(
        AppLocalizations.of(context)!.direct,
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
          fontWeight: FontWeight.w500,
          color: pinkColorTheme.onSecondaryContainer,
        ),
      ),
    );
  }
  if (rule.outboundTag == '' && rule.selectorTag == '') {
    return Chip(
      side: const BorderSide(color: Colors.transparent),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 0),
      backgroundColor: Theme.of(context).colorScheme.error,
      label: Text(
        AppLocalizations.of(context)!.block,
        style: Theme.of(context).textTheme.labelLarge!.copyWith(
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
    );
  }

  return Chip(
    side: const BorderSide(color: Colors.transparent),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(5)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 0),
    backgroundColor: rule.outboundTag.isNotEmpty
        ? Theme.of(context).colorScheme.secondaryContainer
        : greenColorTheme.secondaryContainer,
    label: rule.outboundTag.isNotEmpty
        ? HandlerLabel(handlerIdString: rule.outboundTag)
        : Text(
            selectorTagLocalized(context, rule.selectorTag),
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              fontWeight: FontWeight.w500,
              color: greenColorTheme.onSecondaryContainer,
            ),
          ),
  );
}

Widget _getLeadingDnsRule(BuildContext context, DnsRuleConfig rule) {
  return Chip(
    side: const BorderSide(color: Colors.transparent),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(5)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 0),
    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    label: Text(
      rule.dnsServerName,
      style: Theme.of(context).textTheme.labelLarge!.copyWith(
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    ),
  );
}

// String localizedDnsServerName(BuildContext context, String name) {
//   switch (name) {
//     case XConfigHelper.dnsServerFake:
//       return 'FakeDNS';
//     case XConfigHelper.dnsServerProxy:
//       return AppLocalizations.of(context)!.proxyDnsServer;
//     case XConfigHelper.dnsServerDirect:
//       return AppLocalizations.of(context)!.directDnsServer;
//     default:
//       return name;
//   }
// }

class CustomRouteModeWidget extends StatefulWidget {
  const CustomRouteModeWidget({
    super.key,
    required this.routeMode,
    required this.onUpdate,
  });
  final CustomRouteMode routeMode;
  final Function(CustomRouteMode) onUpdate;
  @override
  State<CustomRouteModeWidget> createState() => _CustomRouteModeWidgetState();
}

class _CustomRouteModeWidgetState extends State<CustomRouteModeWidget> {
  late CustomRouteMode _routeConfig;

  @override
  void initState() {
    super.initState();
    _routeConfig = widget.routeMode;
  }

  @override
  void didUpdateWidget(covariant CustomRouteModeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _routeConfig = widget.routeMode;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RouterConfigWidget(
          routerConfig: _routeConfig.routerConfig,
          onUpdate: (p0) {
            widget.onUpdate(_routeConfig);
          },
        ),
        const Gap(10),
        _CustomModeDnsRules(
          routeMode: _routeConfig,
          onUpdate: (p0) {
            widget.onUpdate(_routeConfig);
          },
        ),
        const Gap(10),
        _InternalDnsServers(
          routeMode: _routeConfig,
          editable: true,
          onUpdate: (p0) {
            widget.onUpdate(_routeConfig);
          },
        ),
      ],
    );
  }
}

class _InternalDnsServers extends StatefulWidget {
  const _InternalDnsServers({
    super.key,
    required this.routeMode,
    required this.editable,
    this.onUpdate,
  });
  final CustomRouteMode routeMode;
  final bool editable;
  final Function(CustomRouteMode)? onUpdate;
  @override
  State<_InternalDnsServers> createState() => __InternalDnsServersState();
}

class __InternalDnsServersState extends State<_InternalDnsServers> {
  late CustomRouteMode _routeConfig;

  @override
  void initState() {
    super.initState();
    _routeConfig = widget.routeMode;
  }

  @override
  void didUpdateWidget(covariant _InternalDnsServers oldWidget) {
    super.didUpdateWidget(oldWidget);
    _routeConfig = widget.routeMode;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: AppLocalizations.of(context)!.internalDnsDesc,
          child: Text(
            AppLocalizations.of(context)!.internalDns,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Gap(5),
        Wrap(
          spacing: 10,
          runSpacing: 5,
          children:
              _routeConfig.internalDnsServers
                  .map<Widget>(
                    (e) => WrapChild(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSecondaryContainer,
                      shape: chipBorderRadius,
                      text: e,
                      onDelete: widget.editable
                          ? () => setState(() {
                              _routeConfig.internalDnsServers.remove(e);
                              widget.onUpdate!(_routeConfig);
                            })
                          : null,
                    ),
                  )
                  .toList()
                ..add(
                  widget.editable
                      ? _DnsServerPicker(
                          onPick: (e) {
                            setState(() {
                              _routeConfig.internalDnsServers.add(e);
                              widget.onUpdate!(_routeConfig);
                            });
                          },
                        )
                      : const SizedBox.shrink(),
                ),
        ),
      ],
    );
  }
}

class _DnsServerPicker extends StatefulWidget {
  const _DnsServerPicker({super.key, required this.onPick});
  final Function(String) onPick;

  @override
  State<_DnsServerPicker> createState() => __DnsServerPickerState();
}

class __DnsServerPickerState extends State<_DnsServerPicker> {
  List<String> _dnsServers = [];

  @override
  void initState() {
    super.initState();
    context.read<DnsRepo>().getDnsServers().then((value) {
      setState(() {
        _dnsServers = value.map((e) => e.name).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        ..._dnsServers.map(
          (e) => MenuItemButton(
            onPressed: () {
              widget.onPick(e);
            },
            child: Text(e),
          ),
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

/// [routerConfig] will be mutated, and once it happens, [onUpdate] will be called.
class RouterConfigWidget extends StatefulWidget {
  const RouterConfigWidget({
    super.key,
    required this.routerConfig,
    required this.onUpdate,
  });
  final RouterConfig routerConfig;
  final Function(RouterConfig) onUpdate;

  @override
  State<RouterConfigWidget> createState() => _RouterConfigWidgetState();
}

class _RouterConfigWidgetState extends State<RouterConfigWidget> {
  late RouterConfig _routeConfig;

  @override
  void initState() {
    super.initState();
    _routeConfig = widget.routerConfig;
  }

  @override
  void didUpdateWidget(covariant RouterConfigWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _routeConfig = widget.routerConfig;
  }

  Future<void> _onAdd() async {
    final k = GlobalKey();
    final config = await showMyAdaptiveDialog<RuleConfig?>(
      context,
      RouteRuleForm(key: k, ruleConfig: null),
      title: AppLocalizations.of(context)!.addRouterRule,
      onSave: (BuildContext context) {
        final formData = (k.currentState as FormDataGetter).formData;
        if (formData != null) {
          context.pop(formData);
        }
      },
    );
    if (config != null) {
      setState(() {
        _routeConfig.rules.insert(0, config);
        widget.onUpdate(_routeConfig);
      });
    }
  }

  Future<void> _onTap(int index, bool updateable) async {
    final k = GlobalKey();
    final config = await showMyAdaptiveDialog<RuleConfig?>(
      context,
      RouteRuleForm(key: k, ruleConfig: _routeConfig.rules[index]),
      title: AppLocalizations.of(context)!.editRule,
      onSave: (BuildContext context) {
        final formData = (k.currentState as FormDataGetter).formData;
        if (formData != null) {
          context.pop(formData);
        }
      },
    );
    if (config != null) {
      setState(() {
        _routeConfig.rules[index] = config;
        widget.onUpdate(_routeConfig);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.tonal(
          onPressed: () {
            _onAdd();
          },
          child: Text(AppLocalizations.of(context)!.addRouterRule),
        ),
        const SizedBox(height: 10, width: double.infinity),
        if (_routeConfig.rules.isNotEmpty)
          Material(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            child: ReorderableListView(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: _routeConfig.rules.indexed
                  .map(
                    (e) => ExpansionTile(
                      key: ObjectKey(e.$2),
                      title: Text(e.$2.ruleName),
                      leading: _getLeading(context, e.$2),
                      showTrailingIcon: false,
                      shape: e.$1 == _routeConfig.rules.length - 1
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                      collapsedShape: e.$1 == _routeConfig.rules.length - 1
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                      collapsedBackgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      children: e.$2.children(context)
                        ..add(
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 8),
                            child: Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _onTap(e.$1, true);
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.edit,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _routeConfig.rules.removeAt(e.$1);
                                      widget.onUpdate(_routeConfig);
                                    });
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.delete,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ),
                  )
                  .toList(),
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final RuleConfig item = _routeConfig.rules.removeAt(oldIndex);
                  _routeConfig.rules.insert(newIndex, item);
                  widget.onUpdate(_routeConfig);
                });
              },
            ),
          ),
      ],
    );
  }
}

class _CustomModeDnsRules extends StatefulWidget {
  const _CustomModeDnsRules({required this.routeMode, required this.onUpdate});
  final CustomRouteMode routeMode;
  final Function(CustomRouteMode) onUpdate;
  @override
  State<_CustomModeDnsRules> createState() => _CustomModeDnsRulesState();
}

class _CustomModeDnsRulesState extends State<_CustomModeDnsRules> {
  late CustomRouteMode _routeConfig;

  @override
  void initState() {
    super.initState();
    _routeConfig = widget.routeMode;
  }

  @override
  void didUpdateWidget(covariant _CustomModeDnsRules oldWidget) {
    super.didUpdateWidget(oldWidget);
    _routeConfig = widget.routeMode;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _onAdd() async {
    final k = GlobalKey();
    final config = await showMyAdaptiveDialog<DnsRuleConfig?>(
      context,
      DnsRuleForm(key: k, ruleConfig: null),
      title: AppLocalizations.of(context)!.addDnsRule,
      onSave: (BuildContext context) {
        final formData = (k.currentState as FormDataGetter).formData;
        if (formData != null) {
          context.pop(formData);
        }
      },
    );
    if (config != null) {
      setState(() {
        _routeConfig.dnsRules.rules.insert(0, config);
        widget.onUpdate(_routeConfig);
      });
    }
  }

  Future<void> _onTap(int index, bool updateable) async {
    final k = GlobalKey();
    final config = await showMyAdaptiveDialog<DnsRuleConfig?>(
      context,
      DnsRuleForm(key: k, ruleConfig: _routeConfig.dnsRules.rules[index]),
      title: AppLocalizations.of(context)!.editRule,
      onSave: (BuildContext context) {
        final formData = (k.currentState as FormDataGetter).formData;
        if (formData != null) {
          context.pop(formData);
        }
      },
    );
    if (config != null) {
      setState(() {
        _routeConfig.dnsRules.rules[index] = config;
        widget.onUpdate(_routeConfig);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.tonal(
          onPressed: () {
            _onAdd();
          },
          child: Text(AppLocalizations.of(context)!.addDnsRule),
        ),
        const SizedBox(height: 10, width: double.infinity),
        if (_routeConfig.dnsRules.rules.isNotEmpty)
          Material(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
            child: ReorderableListView(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: _routeConfig.dnsRules.rules.indexed
                  .map(
                    (e) => ExpansionTile(
                      key: ObjectKey(e.$2),
                      title: Text(e.$2.ruleName),
                      leading: isCompact(context)
                          ? null
                          : _getLeadingDnsRule(context, e.$2),
                      subtitle: isCompact(context)
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: _getLeadingDnsRule(context, e.$2),
                              ),
                            )
                          : null,
                      showTrailingIcon: false,
                      // trailing: Row(
                      //   mainAxisSize: MainAxisSize.min,
                      //   children: [
                      //     Padding(
                      //       padding: desktopPlatforms
                      //           ? const EdgeInsets.only(right: 10)
                      //           : const EdgeInsets.all(0),
                      //       child: IconButton(
                      //           onPressed: () {
                      //             setState(() {
                      //               _routeConfig.dnsRules.rules
                      //                   .removeAt(e.$1);
                      //               widget.onUpdate(_routeConfig);
                      //             });
                      //           },
                      //           icon: const Icon(Icons.delete_rounded)),
                      //     ),
                      //     if (!desktopPlatforms)
                      //       Icon(Icons.drag_indicator)
                      //   ],
                      // ),
                      collapsedShape:
                          e.$1 == _routeConfig.dnsRules.rules.length - 1
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                      shape: e.$1 == _routeConfig.dnsRules.rules.length - 1
                          ? null
                          : Border(
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      collapsedBackgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLow,
                      children: e.$2.children(context)
                        ..add(
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 8),
                            child: Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _onTap(e.$1, true);
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.edit,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _routeConfig.dnsRules.rules.removeAt(
                                        e.$1,
                                      );
                                      widget.onUpdate(_routeConfig);
                                    });
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!.delete,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      // tileColor: Theme.of(context)
                      //     .colorScheme
                      //     .surfaceContainerLow,
                      // onTap: () => _onTap(e.$1, true),
                    ),
                  )
                  .toList(),
              onReorder: (int oldIndex, int newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final DnsRuleConfig item = _routeConfig.dnsRules.rules
                      .removeAt(oldIndex);
                  _routeConfig.dnsRules.rules.insert(newIndex, item);
                  widget.onUpdate(_routeConfig);
                });
              },
            ),
          ),
      ],
    );
  }
}

class HandlerLabel extends StatefulWidget {
  const HandlerLabel({super.key, required this.handlerIdString, this.style});
  final String handlerIdString;
  final TextStyle? style;
  @override
  State<HandlerLabel> createState() => _HandlerLabelState();
}

class _HandlerLabelState extends State<HandlerLabel> {
  String _tag = '';

  @override
  void initState() {
    super.initState();
    context
        .read<OutboundRepo>()
        .getHandlerById(int.parse(widget.handlerIdString))
        .then((value) {
          setState(() => _tag = value?.name ?? '');
        });
  }

  @override
  void didUpdateWidget(covariant HandlerLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.handlerIdString != oldWidget.handlerIdString) {
      context
          .read<OutboundRepo>()
          .getHandlerById(int.parse(widget.handlerIdString))
          .then((value) {
            setState(() => _tag = value?.name ?? '');
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _tag,
      style:
          widget.style ??
          Theme.of(context).textTheme.labelLarge!.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
    );
  }
}

String selectorTagLocalized(BuildContext context, String selectorTag) {
  if (selectorTag == defaultProxySelectorTag) {
    return AppLocalizations.of(context)!.proxy;
  }
  return selectorTag;
}
