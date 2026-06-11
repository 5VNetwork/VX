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
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:installed_apps/index.dart';
import 'package:protobuf/protobuf.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/vx/common/geo/geo.pb.dart';
import 'package:tm/protos/vx/router/router.pb.dart';
import 'package:vx/app/log/log_page.dart';
import 'package:vx/app/routing/add_dialog.dart';
import 'package:vx/app/routing/default.dart';
import 'package:vx/app/routing/dns.dart';
import 'package:vx/app/routing/mode_widget.dart';
import 'package:vx/app/routing/repo.dart';
import 'package:vx/app/routing/selector_widget.dart';
import 'package:vx/app/routing/set_widget.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/common/common.dart';
import 'package:vx/common/config.dart';
import 'package:vx/common/extension.dart';
import 'package:vx/data/database.dart';
import 'package:vx/main.dart' hide App;
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/cn_direct_apps_upload.dart';
import 'package:vx/utils/desktop_installed_apps.dart';
import 'package:vx/utils/xapi_client.dart';

part 'ip.dart';

part 'domain.dart';

part 'app.dart';

const proxy = '代理';
const _direct = '直连';
const directAppSetName = _direct;
const block = '阻止';

const defaultProxySelectorTag = proxy;

const node = '__node__';
const internalProxySetName = '__internal_proxy__';

// name of the default proxy selector
const proxyEN = 'proxy';
// name of the direct handler
const directEN = 'direct';
const directHandlerTag = directEN;

class RoutePage extends StatefulWidget {
  const RoutePage({super.key});

  @override
  State<RoutePage> createState() => _RoutePageState();
}

enum SimpleRoutePageSegment { proxy, direct }

enum AdvancedRoutePageSegment { mode, set, selector, dns }

class _RoutePageState extends State<RoutePage> with TickerProviderStateMixin {
  bool _advancedMode = false;
  SimpleRoutePageSegment _segment = SimpleRoutePageSegment.proxy;
  AdvancedRoutePageSegment _advancedSegment = AdvancedRoutePageSegment.mode;
  late final TabController _tabController;
  @override
  void initState() {
    super.initState();
    _advancedMode = context.read<SharedPreferences>().advanceRouteMode;
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTap() {
    setState(() {
      _advancedMode = !_advancedMode;
    });
    context.read<SharedPreferences>().setAdvanceRouteMode(_advancedMode);
  }

  @override
  Widget build(BuildContext context) {
    // if (!context.watch<AuthBloc>().state.pro) {
    //   return Center(
    //       child: Padding(
    //     padding: const EdgeInsets.all(16.0),
    //     child: useStripe ? const ProPromotion() : const IAPPurchase(),
    //   ));
    // }

    final size = MediaQuery.of(context).size;
    final switchModeButton = Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        label: Text(
          _advancedMode
              ? AppLocalizations.of(context)!.simple
              : AppLocalizations.of(context)!.advanced,
        ),
        onPressed: () => _onTap(),
      ),
    );

    if (_advancedMode) {
      if (!desktopPlatforms) {
        return Scaffold(
          body: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.mode),
                  Tab(text: AppLocalizations.of(context)!.set),
                  Tab(text: AppLocalizations.of(context)!.selector),
                  const Tab(text: 'DNS'),
                ],
              ),
              const Gap(10),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ModeWidget(switchModeButton: switchModeButton),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: SetWidget(switchModeButton: switchModeButton),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: SelectorsWidget(),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: DnsServersWidget(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Expanded(child: SizedBox()),
                    SegmentedButton<AdvancedRoutePageSegment>(
                      style: SegmentedButton.styleFrom(
                        visualDensity: desktopPlatforms
                            ? VisualDensity.compact
                            : null,
                      ),
                      segments: [
                        ButtonSegment(
                          value: AdvancedRoutePageSegment.mode,
                          label: Text(AppLocalizations.of(context)!.mode),
                        ),
                        ButtonSegment(
                          value: AdvancedRoutePageSegment.set,
                          label: Text(AppLocalizations.of(context)!.set),
                        ),
                        ButtonSegment(
                          value: AdvancedRoutePageSegment.selector,
                          label: Text(AppLocalizations.of(context)!.selector),
                        ),
                        const ButtonSegment(
                          value: AdvancedRoutePageSegment.dns,
                          label: Text('DNS'),
                        ),
                      ],
                      selected: {_advancedSegment},
                      onSelectionChanged: (Set<AdvancedRoutePageSegment> set) =>
                          setState(() {
                            _advancedSegment = set.first;
                          }),
                    ),
                    Expanded(child: switchModeButton),
                  ],
                ),
                const Gap(15),
                Expanded(
                  child: IndexedStack(
                    index: _advancedSegment.index,
                    children: const [
                      ModeWidget(),
                      SetWidget(),
                      SelectorsWidget(),
                      DnsServersWidget(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!desktopPlatforms) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          body: Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.proxy),
                  Tab(text: AppLocalizations.of(context)!.direct),
                ],
              ),
              const Gap(10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TabBarView(
                    children: [
                      _TabView(
                        segment: SimpleRoutePageSegment.proxy,
                        switchModeButton: switchModeButton,
                      ),
                      _TabView(
                        segment: SimpleRoutePageSegment.direct,
                        switchModeButton: switchModeButton,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Expanded(child: SizedBox()),
                  SegmentedButton<SimpleRoutePageSegment>(
                    style: SegmentedButton.styleFrom(
                      visualDensity: desktopPlatforms
                          ? VisualDensity.compact
                          : null,
                    ),
                    segments: [
                      ButtonSegment(
                        value: SimpleRoutePageSegment.proxy,
                        label: Text(AppLocalizations.of(context)!.proxy),
                      ),
                      ButtonSegment(
                        value: SimpleRoutePageSegment.direct,
                        label: Text(AppLocalizations.of(context)!.direct),
                      ),
                    ],
                    selected: {_segment},
                    onSelectionChanged: (Set<SimpleRoutePageSegment> set) =>
                        setState(() {
                          _segment = set.first;
                        }),
                  ),
                  Expanded(child: switchModeButton),
                ],
              ),
              const Gap(15),
              Expanded(
                child: size.isCompact
                    ? _TabView(
                        segment: _segment,
                        switchModeButton: switchModeButton,
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            flex: 2,
                            child: AtomicDomainSetWidget(
                              domainSetName:
                                  _segment == SimpleRoutePageSegment.proxy
                                  ? getCustomProxy(context)
                                  : getCustomDirect(context),
                            ),
                          ),
                          const Gap(10),
                          if (desktopPlatforms || Platform.isAndroid)
                            Flexible(
                              flex: 2,
                              child: AppWidget(
                                appSetName:
                                    _segment == SimpleRoutePageSegment.proxy
                                    ? getProxySetName(context)
                                    : getDirectSetName(context),
                              ),
                            ),
                          const Gap(10),
                          Expanded(
                            child: IPWidget(
                              ipSetName:
                                  _segment == SimpleRoutePageSegment.proxy
                                  ? getCustomProxy(context)
                                  : getCustomDirect(context),
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

class _TabView extends StatefulWidget {
  const _TabView({required this.segment, required this.switchModeButton});
  final SimpleRoutePageSegment segment;
  final Widget switchModeButton;
  @override
  State<_TabView> createState() => __TabViewState();
}

enum RouteCategory { domain, app, ip }

class __TabViewState extends State<_TabView> with TickerProviderStateMixin {
  RouteCategory _category = RouteCategory.domain;
  bool get showApp => desktopPlatforms || Platform.isAndroid;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(_category.index);
    return Column(
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5.0),
              child: ChoiceChip(
                label: Text(AppLocalizations.of(context)!.domain),
                selected: _category == RouteCategory.domain,
                onSelected: (value) {
                  setState(() {
                    _category = RouteCategory.domain;
                  });
                },
              ),
            ),
            if (showApp)
              Padding(
                padding: const EdgeInsets.only(right: 5.0),
                child: ChoiceChip(
                  label: Text(AppLocalizations.of(context)!.app),
                  selected: _category == RouteCategory.app,
                  onSelected: (value) {
                    setState(() {
                      _category = RouteCategory.app;
                    });
                  },
                ),
              ),
            ChoiceChip(
              label: const Text('IP'),
              selected: _category == RouteCategory.ip,
              onSelected: (value) {
                setState(() {
                  _category = RouteCategory.ip;
                });
              },
            ),
            if (!desktopPlatforms)
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: widget.switchModeButton,
                ),
              ),
          ],
        ),
        const Gap(10),
        Expanded(
          child: IndexedStack(
            index: _category.index,
            children: [
              AtomicDomainSetWidget(
                domainSetName: widget.segment == SimpleRoutePageSegment.proxy
                    ? getCustomProxy(context)
                    : getCustomDirect(context),
                showLabel: false,
              ),
              showApp
                  ? AppWidget(
                      appSetName: widget.segment == SimpleRoutePageSegment.proxy
                          ? getProxySetName(context)
                          : getDirectSetName(context),
                      showLabel: false,
                    )
                  : const SizedBox(),
              IPWidget(
                ipSetName: widget.segment == SimpleRoutePageSegment.proxy
                    ? getCustomProxy(context)
                    : getCustomDirect(context),
                showLabel: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WrapChild extends StatelessWidget {
  const WrapChild({
    super.key,
    required this.text,
    this.backgroundColor,
    this.foregroundColor,
    this.outline = false,
    this.onDelete,
    this.shape,
  });
  final String text;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool outline;
  final Function()? onDelete;
  final OutlinedBorder? shape;

  @override
  Widget build(BuildContext context) {
    final chip = MenuAnchor(
      menuChildren: [
        if (onDelete != null)
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
          child: Chip(
            side: BorderSide(
              color: outline
                  ? Theme.of(context).colorScheme.outlineVariant
                  : Colors.transparent,
            ),
            shape: shape,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            backgroundColor: backgroundColor,
            label: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: foregroundColor),
            ),
          ),
        );
      },
    );
    return chip;
  }
}
