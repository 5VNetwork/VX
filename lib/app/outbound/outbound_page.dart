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

import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:ads/ad.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/vx/outbound/outbound.pb.dart';
import 'package:vx/app/outbound/add.dart';
import 'package:vx/app/outbound/add_chain_handler.dart';
import 'package:vx/app/outbound/edit_outbound.dart';
import 'package:vx/app/outbound/outbounds_bloc.dart';
import 'package:vx/app/outbound/subscription.dart';
import 'package:vx/app/outbound/subscription_page.dart';
import 'package:vx/app/start_close_button.dart';
import 'package:vx/app/blocs/proxy_selector/proxy_selector_bloc.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/common/common.dart';
import 'package:vx/common/extension.dart';
import 'package:vx/data/database.dart';
import 'package:vx/app/layout_provider.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/theme.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/qr.dart';
import 'package:vx/utils/xapi_client.dart';
import 'package:vx/widgets/form_dialog.dart';
import 'package:vx/app/outbound/outbound_handler_card.dart';

part 'action_menu_anchor.dart';
part 'group_selector.dart';

final AllGroup allGroup = AllGroup();

class NodePageExtra {
  final int? initialHandlerId;
  final int requestToken;

  NodePageExtra({required this.initialHandlerId})
    : requestToken = DateTime.now().microsecondsSinceEpoch;
}

class OutboundPage extends StatefulWidget {
  final NodePageExtra? extra;

  const OutboundPage({super.key, this.extra});

  @override
  State<OutboundPage> createState() => _OutboundPageState();
}

enum OutboundPageSegment { nodes, subscriptions }

class _OutboundPageState extends State<OutboundPage> {
  OutboundPageSegment _segment = OutboundPageSegment.nodes;
  int? _lastHandledRequestToken;

  @override
  void initState() {
    super.initState();
    _scheduleInitialHandlerJump();
  }

  @override
  void didUpdateWidget(covariant OutboundPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.extra?.requestToken != widget.extra?.requestToken) {
      _scheduleInitialHandlerJump();
    }
  }

  void _scheduleInitialHandlerJump({int remainingAttempts = 8}) {
    final extra = widget.extra;
    if (extra == null || extra.initialHandlerId == null) return;
    if (_lastHandledRequestToken == extra.requestToken) return;

    if (_segment != OutboundPageSegment.nodes) {
      setState(() {
        _segment = OutboundPageSegment.nodes;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final targetHandlerId = extra.initialHandlerId!;
      final state = context.read<OutboundBloc>().state;
      final isHandlerVisible = state.handlers.any((h) => h.id == targetHandlerId);
      if (!isHandlerVisible) {
        context
            .read<OutboundBloc>()
            .add(SelectGroupContainingHandlerEvent(targetHandlerId));
      }

      final scrolled =
          outboundTableKey.currentState?.scrollToHandler(targetHandlerId) ?? false;
      if (scrolled) {
        _lastHandledRequestToken = extra.requestToken;
        return;
      }

      if (remainingAttempts > 0) {
        _scheduleInitialHandlerJump(remainingAttempts: remainingAttempts - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!desktopPlatforms) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          body: Column(
            children: [
              TabBar(
                tabs: <Widget>[
                  Tab(text: AppLocalizations.of(context)!.node),
                  Tab(text: AppLocalizations.of(context)!.subscription),
                ],
              ),
              const Gap(5),
              Expanded(
                child: TabBarView(
                  children: [
                    OutboundTable(key: outboundTableKey),
                    const SubscriptionPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SegmentedButton<OutboundPageSegment>(
              segments: [
                ButtonSegment(
                  value: OutboundPageSegment.nodes,
                  label: Text(AppLocalizations.of(context)!.node),
                ),
                ButtonSegment(
                  value: OutboundPageSegment.subscriptions,
                  label: Text(AppLocalizations.of(context)!.subscription),
                ),
              ],
              selected: {_segment},
              onSelectionChanged: (Set<OutboundPageSegment> set) =>
                  setState(() {
                    _segment = set.first;
                  }),
            ),
            Expanded(
              child: _segment == OutboundPageSegment.nodes
                  ? OutboundTable(key: outboundTableKey)
                  : const SubscriptionPage(),
            ),
          ],
        ),
      ),
    );
  }
}

final outboundTableKey = GlobalKey<OutboundTableState>();

class OutboundTable extends StatefulWidget {
  const OutboundTable({super.key});

  @override
  State<OutboundTable> createState() => OutboundTableState();
}

class OutboundTableState extends State<OutboundTable> {
  final _scrollController = ScrollController();
  Timer? _highlightResetTimer;
  int? _highlightedHandlerId;

  @override
  void dispose() {
    _highlightResetTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  bool scrollToTop() {
    if (!_scrollController.hasClients) return false;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    return true;
  }

  bool scrollToHandler(int handlerId) {
    if (!_scrollController.hasClients) return false;
    final state = context.read<OutboundBloc>().state;
    final handlers = state.handlers;
    final index = handlers.indexWhere((h) => h.id == handlerId);
    if (index == -1) return false;

    final viewMode = state.viewMode;
    double offset = 0;
    if (viewMode == OutboundViewMode.list) {
      // itemExtent for list view is 50
      offset = index * 50.0;
    } else {
      final width = MediaQuery.sizeOf(context).width;
      final crossAxisCount = _getGridCrossAxisCount(width);
      const itemExtent = 150.0;
      final row = index ~/ crossAxisCount;
      offset = row * itemExtent;
    }

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _highlightHandler(handlerId);
    return true;
  }

  void _highlightHandler(int handlerId) {
    _highlightResetTimer?.cancel();
    if (mounted) {
      setState(() {
        _highlightedHandlerId = handlerId;
      });
    }
    _highlightResetTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        if (_highlightedHandlerId == handlerId) {
          _highlightedHandlerId = null;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Material(
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(child: GroupSelector()),
                BlocSelector<OutboundBloc, OutboundState, NodeGroup?>(
                  selector: (state) {
                    return state.selected;
                  },
                  builder: (ctx, selected) {
                    if (selected == null ||
                        selected is OutboundHandlerGroup ||
                        selected.name == allGroup.name) {
                      return const SizedBox();
                    }
                    final sub = selected as Subscription;
                    return UpdateSubButton(sub: sub);
                  },
                ),
                IconButton(
                  onPressed: () =>
                      context.read<OutboundBloc>().add(const StatusTestEvent()),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                ),
                IconButton(
                  onPressed: () =>
                      context.read<OutboundBloc>().add(const SpeedTestEvent()),
                  icon: const Icon(Icons.arrow_circle_down_rounded),
                ),
                BlocSelector<
                  OutboundBloc,
                  OutboundState,
                  (OutboundViewMode, (Col, SortOrder)?)
                >(
                  selector: (state) => (state.viewMode, state.sortCol),
                  builder: (ctx, data) {
                    final viewMode = data.$1;
                    final sortCol = data.$2;

                    if (viewMode == OutboundViewMode.grid) {
                      return _GridSortButton(sortCol: sortCol);
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const AddMenuAnchor(),
                // Gap(5),
                const ActionMenuAnchor(),
              ],
            ),
            const Gap(5),
            Expanded(
              child: BlocBuilder<ProxySelectorBloc, ProxySelectorState>(
                buildWhen: (previous, current) =>
                    previous.showProxySelector != current.showProxySelector ||
                    previous.proxySelectorMode != current.proxySelectorMode,
                builder: (ctx, xstate) =>
                    BlocSelector<
                      OutboundBloc,
                      OutboundState,
                      (
                        bool,
                        OutboundTableSmallScreenPreference,
                        OutboundViewMode,
                      )
                    >(
                      selector: (state) => (
                        state.multiSelect,
                        state.smallScreenPreference,
                        state.viewMode,
                      ),
                      builder: (context, multiSelectAndPrefs) {
                        final startCloseCubit = context
                            .watch<StartCloseCubit>();
                        final authState = context.watch<AuthBloc>().state;
                        final multiSelect = multiSelectAndPrefs.$1;
                        final smallScreenPref = multiSelectAndPrefs.$2;
                        final viewMode = multiSelectAndPrefs.$3;
                        final cols = getCols(
                          MediaQuery.sizeOf(context),
                          xstate,
                          multiSelect,
                          smallScreenPref,
                          authState.pro,
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (viewMode == OutboundViewMode.list)
                              _HeaderRow(cols: cols),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (ctx, c) {
                                  return BlocListener<
                                    OutboundBloc,
                                    OutboundState
                                  >(
                                    listenWhen: (previous, current) =>
                                        previous.sortCol != current.sortCol ||
                                        previous.selected != current.selected,
                                    listener: (ctx, state) {
                                      if (_scrollController.hasClients) {
                                        _scrollController.animateTo(
                                          0,
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                                    child:
                                        BlocSelector<
                                          OutboundBloc,
                                          OutboundState,
                                          (int, List<OutboundHandler>)
                                        >(
                                          selector: (state) =>
                                              (state.using4, state.handlers),
                                          builder: (ctx, r) {
                                            if (r.$2.isEmpty) {
                                              return const Center(
                                                child: AddMenuAnchor(
                                                  elevatedButton: true,
                                                ),
                                              );
                                            }

                                            final handlers = r.$2;
                                            final showAd = !context
                                                .watch<AuthBloc>()
                                                .state
                                                .pro;
                                            if (viewMode ==
                                                OutboundViewMode.grid) {
                                              // Grid View
                                              return CustomScrollView(
                                                controller: _scrollController,
                                                physics:
                                                    const ClampingScrollPhysics(),
                                                slivers: [
                                                  SliverPadding(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    sliver: SliverGrid(
                                                      gridDelegate:
                                                          SliverGridDelegateWithFixedCrossAxisCount(
                                                            crossAxisCount:
                                                                _getGridCrossAxisCount(
                                                                  MediaQuery.sizeOf(
                                                                    context,
                                                                  ).width,
                                                                ),
                                                            mainAxisSpacing: 12,
                                                            crossAxisSpacing:
                                                                12,
                                                            mainAxisExtent: 150,
                                                          ),
                                                      delegate: SliverChildBuilderDelegate(
                                                        (ctx, index) {
                                                          assert(
                                                            index <
                                                                handlers.length,
                                                          );
                                                          return OutboundMenuAnchor(
                                                            handler:
                                                                handlers[index],
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  16,
                                                                ),
                                                            child: OutboundHandlerCard(
                                                              key: ValueKey(
                                                                handlers[index]
                                                                    .id,
                                                              ),
                                                              handler:
                                                                  handlers[index],
                                                            jumpHighlighted:
                                                                _highlightedHandlerId ==
                                                                handlers[index].id,
                                                              selectedAs4:
                                                                  r.$1 != 0 &&
                                                                  startCloseCubit
                                                                          .state ==
                                                                      XStatus
                                                                          .connected &&
                                                                  xstate.proxySelectorMode ==
                                                                      ProxySelectorMode
                                                                          .auto &&
                                                                  r.$1 ==
                                                                      handlers[index]
                                                                          .id,
                                                              proxySelectorMode:
                                                                  xstate
                                                                      .proxySelectorMode,
                                                              showAddress:
                                                                  smallScreenPref
                                                                      .showAddress,
                                                              multiSelect:
                                                                  multiSelect,
                                                            ),
                                                          );
                                                        },
                                                        childCount:
                                                            handlers.length,
                                                        findChildIndexCallback: (key) {
                                                          final index = handlers
                                                              .indexWhere(
                                                                (e) =>
                                                                    e.id ==
                                                                    (key as ValueKey)
                                                                        .value,
                                                              );
                                                          return index == -1
                                                              ? null
                                                              : index;
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  if (showAd) const Ads(),
                                                  const SliverToBoxAdapter(
                                                    child: SizedBox(height: 70),
                                                  ),
                                                ],
                                              );
                                            } else {
                                              // List View
                                              return CustomScrollView(
                                                controller: _scrollController,
                                                physics:
                                                    const ClampingScrollPhysics(),
                                                slivers: [
                                                  SliverFixedExtentList(
                                                    itemExtent: 50,
                                                    delegate: SliverChildBuilderDelegate(
                                                      (ctx, index) {
                                                        assert(
                                                          index <
                                                              handlers.length,
                                                        );
                                                        final selectedInAutoBestMode =
                                                            (r.$1 != 0 &&
                                                            startCloseCubit
                                                                    .state ==
                                                                XStatus
                                                                    .connected &&
                                                            xstate.proxySelectorMode ==
                                                                ProxySelectorMode
                                                                    .auto &&
                                                            r.$1 ==
                                                                handlers[index]
                                                                    .id);
                                                        final showDot =
                                                            selectedInAutoBestMode ||
                                                            (!smallScreenPref
                                                                    .showActive &&
                                                                xstate.proxySelectorMode ==
                                                                    ProxySelectorMode
                                                                        .manual &&
                                                                handlers[index]
                                                                    .selected &&
                                                                Provider.of<
                                                                      MyLayout
                                                                    >(
                                                                      context,
                                                                      listen:
                                                                          false,
                                                                    )
                                                                    .isCompact);
                                                        return HandlerRow(
                                                          key: ValueKey(
                                                            handlers[index].id,
                                                          ),
                                                          cols: cols,
                                                          handler:
                                                              handlers[index],
                                                          color:
                                                              _highlightedHandlerId ==
                                                                  handlers[index].id
                                                              ? Theme.of(context)
                                                                    .colorScheme
                                                                    .primaryContainer
                                                                    .withValues(
                                                                      alpha: 0.75,
                                                                    )
                                                              : null,
                                                          showDot: showDot,
                                                        );
                                                      },
                                                      childCount:
                                                          handlers.length,
                                                      findChildIndexCallback: (key) {
                                                        final index = handlers
                                                            .indexWhere(
                                                              (e) =>
                                                                  e.id ==
                                                                  (key as ValueKey)
                                                                      .value,
                                                            );
                                                        return index == -1
                                                            ? null
                                                            : index;
                                                      },
                                                    ),
                                                  ),
                                                  const SliverToBoxAdapter(
                                                    child: SizedBox(height: 10),
                                                  ),
                                                  if (showAd) const Ads(),
                                                  const SliverToBoxAdapter(
                                                    child: SizedBox(height: 70),
                                                  ),
                                                ],
                                              );
                                            }
                                          },
                                        ),
                                  );
                                },
                              ),
                            ),
                            if (multiSelect)
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    FilledButton.tonalIcon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.errorContainer,
                                        foregroundColor: Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer,
                                      ),
                                      icon: const Icon(
                                        Icons.delete_forever_outlined,
                                      ),
                                      onPressed: () {
                                        final bloc = context
                                            .read<OutboundBloc>();
                                        bloc.add(
                                          HandlersDeleteEvent(
                                            bloc.state.handlers
                                                .where(
                                                  (e) => e
                                                      .selectedInMultipleSelect,
                                                )
                                                .map((e) => e.id)
                                                .toList(),
                                          ),
                                        );
                                      },
                                      label: Text(
                                        AppLocalizations.of(context)!.delete,
                                      ),
                                    ),
                                    const Gap(10),
                                    MenuAnchor(
                                      menuChildren: context
                                          .read<OutboundBloc>()
                                          .state
                                          .groups
                                          .whereType<OutboundHandlerGroup>()
                                          .map(
                                            (e) => MenuItemButton(
                                              child: Text(
                                                groupNametoLocalizedName(
                                                  context,
                                                  e.name,
                                                ),
                                              ),
                                              onPressed: () {
                                                context.read<OutboundBloc>().add(
                                                  AddSelectedHandlersToGroupEvent(
                                                    e.name,
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                          .toList(),
                                      builder: (context, controller, child) {
                                        return FilledButton.icon(
                                          icon: const Icon(
                                            Icons.group_work_outlined,
                                          ),
                                          onPressed: () {
                                            controller.open();
                                          },
                                          label: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.addToGroup,
                                          ),
                                        );
                                      },
                                    ),
                                    const Gap(10),
                                    OutlinedButton(
                                      onPressed: () {
                                        context.read<OutboundBloc>().add(
                                          const MultiSelectEvent(false),
                                        );
                                      },
                                      child: Text(
                                        AppLocalizations.of(context)!.cancel,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HandlerRow extends StatefulWidget {
  const HandlerRow({
    super.key,
    required this.handler,
    required this.cols,
    this.showBorder = true,
    this.showDot = false,
    this.clickable = true,
    this.color,
  });

  final OutboundHandler handler;
  final List<Col> cols;
  final bool showDot;
  final bool showBorder;
  final Color? color;
  final bool clickable;
  @override
  State<HandlerRow> createState() => _HandlerRowState();
}

class _HandlerRowState extends State<HandlerRow> {
  Widget? _cache;
  bool _shouldRebuild = false;
  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant HandlerRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.handler != widget.handler ||
        oldWidget.cols != widget.cols ||
        oldWidget.showDot != widget.showDot ||
        oldWidget.color != widget.color) {
      _shouldRebuild = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<Widget> _getCells(
    BuildContext context,
    List<Col> cols,
    OutboundHandler handler,
  ) {
    final cells = <Widget>[const Gap(8)];
    for (var col in cols) {
      cells.add(col.getBodyCell(context, handler));
    }
    cells.add(const Gap(8));
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldRebuild && _cache != null) {
      // print('use cache for ${widget.handler.id}');
      return _cache!;
    }
    // print('build ${widget.handler.id}');
    _shouldRebuild = false;
    _cache = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: widget.color,
        border: widget.showBorder
            ? Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              )
            : null,
      ),
      child: OutboundMenuAnchor(
        handler: widget.handler,
        clickable: widget.clickable,
        child: Row(children: _getCells(context, widget.cols, widget.handler)),
      ),
    );
    if (widget.showDot) {
      _cache = Stack(
        children: [
          _cache!,
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, size: 8, color: XBlue),
                  Gap(2),
                ],
              ),
            ),
          ),
        ],
      );
    }
    return _cache!;
  }
}

Future<String> getQrCodeData(
  XApiClient xapiClient,
  List<OutboundHandler> handlers,
  bool isVX,
) async {
  late String qrCodeData;
  if (isVX) {
    qrCodeData = base64UrlEncode(
      HandlerConfigs(
        configs: handlers.map((e) => e.config).toList(),
      ).writeToBuffer(),
    );
  } else {
    final resposne = await xapiClient.toUrl(
      handlers
          .where((e) => e.config.hasOutbound())
          .map((e) => e.config.outbound)
          .toList(),
    );
    qrCodeData = resposne.urls.join('\r\n');
  }
  return qrCodeData;
}

void _editHandler(BuildContext context, OutboundHandler handler) async {
  final bloc = context.read<OutboundBloc>();
  OutboundHandler? newHandler;
  if (Provider.of<MyLayout>(context, listen: false).fullScreen()) {
    // TODO: move window in desktop
    if (handler.config.hasOutbound()) {
      newHandler = await Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(
          builder: (ctx) {
            return EditFullScreenDialog(handler: handler);
          },
        ),
      );
    } else {
      final config = await Navigator.of(context, rootNavigator: true)
          .push<ChainHandlerConfig?>(
            CupertinoPageRoute(
              builder: (ctx) {
                return AddEditChainHandlerDialog(
                  fullScreen: true,
                  config: handler.config.chain,
                );
              },
            ),
          );
      if (config != null) {
        newHandler = OutboundHandler(
          config: HandlerConfig(chain: config),
          id: handler.id,
          selected: handler.selected,
        );
      }
    }
  } else {
    if (handler.config.hasOutbound()) {
      newHandler = await showGeneralDialog<OutboundHandler>(
        context: context,
        barrierDismissible: false,
        barrierLabel: AppLocalizations.of(context)!.edit,
        pageBuilder: (context, animation, secondaryAnimation) =>
            EditOutboundDialog(handler: handler),
      );
    } else {
      final config = await showGeneralDialog<ChainHandlerConfig?>(
        context: context,
        barrierDismissible: false,
        barrierLabel: AppLocalizations.of(context)!.edit,
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddEditChainHandlerDialog(
              fullScreen: false,
              config: handler.config.chain,
            ),
      );
      if (config != null) {
        newHandler = OutboundHandler(
          config: HandlerConfig(chain: config),
          id: handler.id,
          selected: handler.selected,
        );
      }
    }
  }
  if (newHandler != null) {
    bloc.add(HandlerEdittedEvent(newHandler));
  }
}

class OutboundMenuAnchor extends StatelessWidget {
  const OutboundMenuAnchor({
    super.key,
    required this.handler,
    this.borderRadius,
    required this.child,
    this.color,
    this.clickable = true,
  });
  final OutboundHandler handler;
  final Widget child;
  final bool clickable;
  final BorderRadius? borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_rounded),
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(AppLocalizations.of(context)!.edit),
          ),
          onPressed: () => _editHandler(context, handler),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.copy),
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(AppLocalizations.of(context)!.copy),
          ),
          onPressed: () =>
              context.read<OutboundBloc>().add(HandlersCopyEvent(handler)),
        ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.group_work_outlined),
          menuChildren: context
              .read<OutboundBloc>()
              .state
              .groups
              .whereType<OutboundHandlerGroup>()
              .map(
                (e) => MenuItemButton(
                  child: Text(groupNametoLocalizedName(context, e.name)),
                  onPressed: () {
                    context.read<OutboundBloc>().add(
                      AddHandlerToGroupEvent(handler, e.name),
                    );
                  },
                ),
              )
              .toList(),
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(AppLocalizations.of(context)!.addToGroup),
          ),
        ),
        SubmenuButton(
          leadingIcon: const Icon(Icons.share_rounded),
          menuChildren: [
            MenuItemButton(
              leadingIcon: SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: Image.asset(
                    'assets/icons/V.png',
                    width: 16,
                    height: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(AppLocalizations.of(context)!.shareWithVXclient),
              ),
              onPressed: () async {
                final xapiClient = context.read<XApiClient>();
                final qrCodeData = await getQrCodeData(xapiClient, [
                  handler,
                ], true);
                shareQrCode(context, qrCodeData);
              },
            ),
            MenuItemButton(
              leadingIcon: const Icon(Icons.category_rounded),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  AppLocalizations.of(context)!.shareWithOtherClients,
                ),
              ),
              onPressed: () async {
                final xapiClient = context.read<XApiClient>();
                final qrCodeData = await getQrCodeData(xapiClient, [
                  handler,
                ], false);
                shareQrCode(context, qrCodeData);
              },
            ),
          ],
          child: Text(AppLocalizations.of(context)!.share),
        ),
        const Divider(),
        MenuItemButton(
          leadingIcon: const Icon(Icons.delete_outline_rounded),
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
          onPressed: () => context.read<OutboundBloc>().add(
            HandlersDeleteEvent([handler.id]),
          ),
        ),
      ],
      builder: (context, menuController, child) {
        return Material(
          color: color ?? Colors.transparent,
          child: GestureDetector(
            onLongPressStart: (details) {
              if (!desktopPlatforms) {
                menuController.open(
                  position: Offset(
                    details.localPosition.dx,
                    details.localPosition.dy,
                  ),
                );
              }
            },
            child: InkWell(
              borderRadius: borderRadius,
              onTap: clickable
                  ? () {
                      if (menuController.isOpen) {
                        menuController.close();
                      } else {
                        final bloc = context.read<OutboundBloc>();
                        if (bloc.state.multiSelect) {
                          bloc.add(MultiSelectToggleEvent(handler));
                        } else {
                          if (!context.read<AuthBloc>().state.pro ||
                              context
                                  .read<ProxySelectorBloc>()
                                  .state
                                  .enableManualSelect) {
                            bloc.add(
                              SwitchHandlerEvent(handler, !handler.selected),
                            );
                          }
                        }
                      }
                    }
                  : null,
              onSecondaryTapDown: desktopPlatforms
                  ? (TapDownDetails details) {
                      menuController.open(
                        position: Offset(
                          details.localPosition.dx,
                          details.localPosition.dy,
                        ),
                      );
                    }
                  : null,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

List<Col> getCols(
  Size size,
  ProxySelectorState xstate,
  bool multiSelect,
  OutboundTableSmallScreenPreference smallScreenPreference,
  bool isPro,
) {
  final cols = <Col>[if (multiSelect) Col.select, Col.countryIcon];

  if (size.width <= 900) {
    if (size.width < 680 && smallScreenPreference.showProtocol) {
      cols.add(Col.remarkProtocol);
    } else {
      cols.add(Col.remark);
    }
  } else {
    cols.add(Col.remark);
    cols.add(Col.address);
  }

  if (size.width >= 680) {
    cols.add(Col.protocol);
  }

  // if (size.width >= 1200) {
  //   cols.add(Col.sni);
  // }
  if (!size.isCompact || smallScreenPreference.showUsable) {
    cols.add(Col.usable);
  }

  if (smallScreenPreference.showSpeed) {
    cols.add(Col.speed);
  }

  if (!size.isCompact || smallScreenPreference.showPing) {
    cols.add(Col.ping);
  }
  if (smallScreenPreference.showActive &&
      (!isPro ||
          ((xstate.showProxySelector ?? false) &&
              xstate.proxySelectorMode == ProxySelectorMode.manual))) {
    cols.add(Col.active);
  }
  return cols;
}

class SortableHeaderCell extends StatelessWidget {
  const SortableHeaderCell({
    super.key,
    required this.col,
    this.loading = false,
    this.center = true,
    this.sortCol,
    this.padding = EdgeInsets.zero,
  });

  final Col col;
  final bool loading;
  final bool center;
  final (Col, SortOrder)? sortCol;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    late (Col, SortOrder)? newColSort;
    if (sortCol == null || sortCol!.$1 != col) {
      newColSort = (col, col.defaultAsc);
    } else {
      // sort col is this col
      if (sortCol!.$2 == col.defaultAsc) {
        if (col.defaultSortOnly) {
          newColSort = null;
        } else {
          newColSort = (col, -sortCol!.$2);
        }
      } else {
        newColSort = null;
      }
    }

    late Widget child;
    bool bold = false;
    if (loading) {
      child = const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (sortCol == null || sortCol!.$1 != col) {
      child = col.headerWidget(context);
    } else {
      bold = true;
      if (sortCol!.$2 == 1) {
        child = Row(
          // mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            col.headerWidget(context, sorting: true),
            const Icon(size: 10, Icons.north, color: XBlue),
          ],
        );
      } else {
        child = Row(
          // mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            col.headerWidget(context, sorting: true),
            const Icon(size: 10, Icons.south, color: XBlue),
          ],
        );
      }
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading
            ? null
            : () => context.read<OutboundBloc>().add(
                SortHandlersEvent(newColSort),
              ),
        child: Padding(
          padding: padding,
          child: SizedBox(
            width: col.getWidth(context),
            child: center
                ? Center(
                    child: DefaultTextStyle(
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: bold ? XBlue : null,
                        fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                      ),
                      child: child,
                    ),
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: DefaultTextStyle(
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: bold ? XBlue : null,
                        fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                      ),
                      child: child,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

typedef SortOrder = int;

enum Col {
  select(),
  countryIcon(),
  remark(),
  remarkProtocol(),
  address(),
  protocol(),
  // sni(),
  usable(defaultAsc: -1, defaultSortOnly: true),
  speed(defaultAsc: -1, defaultSortOnly: true),
  ping(defaultSortOnly: true),
  active(defaultAsc: -1, defaultSortOnly: true);

  const Col({this.defaultAsc = 1, this.defaultSortOnly = false});

  // 1 means asc, -1 means desc
  final SortOrder defaultAsc;
  final bool defaultSortOnly;

  double? getWidth(BuildContext context) {
    switch (this) {
      case Col.select:
        return 40;
      case Col.countryIcon:
        return 45;
      case Col.remark:
        return null;
      case Col.remarkProtocol:
        return null;
      case Col.address:
        return null;
      case Col.protocol:
        return 140 + 12;
      // case Col.sni:
      //   return null;
      case Col.usable:
        final size = MediaQuery.sizeOf(context);
        if (size.width <= 600) {
          return 24 + 12;
        }
        if (Localizations.localeOf(context).languageCode == 'zh') {
          return 35 + 12;
        } else {
          return 48 + 12;
        }
      case Col.speed:
        final size = MediaQuery.sizeOf(context);
        if (size.width <= 600) {
          return 35 + 12;
        }
        if (Localizations.localeOf(context).languageCode == 'zh') {
          return 35 + 12;
        } else {
          return 46 + 12;
        }
      case Col.ping:
        final size = MediaQuery.sizeOf(context);
        if (size.width <= 600) {
          return 35 + 12;
        }
        if (Localizations.localeOf(context).languageCode == 'zh') {
          return 35 + 12;
        } else {
          return 57 + 12;
        }
      case Col.active:
        final size = MediaQuery.sizeOf(context);
        if (size.width <= 600) {
          return 35 + 12;
        }
        return 52 + 12;
    }
  }

  // final String headerText;

  Widget headerWidget(BuildContext context, {bool sorting = false}) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final showIcon =
        compact ||
        (context.read<SharedPreferences>().language?.aiTranslated ?? false);
    switch (this) {
      case Col.select:
        return const SizedBox();
      case Col.countryIcon:
        return showIcon
            ? Icon(Icons.language, color: sorting ? XBlue : null)
            : Text(AppLocalizations.of(context)!.area);
      case Col.remark || remarkProtocol:
        return Text(AppLocalizations.of(context)!.remark);
      case Col.address:
        return Text(AppLocalizations.of(context)!.address);
      case Col.protocol:
        return Text(AppLocalizations.of(context)!.protocol);
      // case Col.sni:
      //   return const Text("SNI");
      case Col.usable:
        return showIcon
            ? Icon(
                Icons.check_circle_outline_rounded,
                color: sorting ? XBlue : null,
              )
            : Text(AppLocalizations.of(context)!.usable);
      case Col.speed:
        return showIcon
            ? Icon(
                Icons.arrow_circle_down_rounded,
                color: sorting ? XBlue : null,
              )
            : Text(AppLocalizations.of(context)!.speed);
      case Col.ping:
        return showIcon
            ? Icon(Icons.timer_outlined, color: sorting ? XBlue : null)
            : Text(AppLocalizations.of(context)!.latency);
      case Col.active:
        return showIcon
            ? Icon(
                Icons.toggle_on_outlined,
                size: 28,
                color: sorting ? XBlue : null,
              )
            : Text(AppLocalizations.of(context)!.selectOneOutbound);
    }
  }

  Widget getHeaderCell(
    BuildContext context,
    bool testingArea,
    (Col, SortOrder)? sort,
  ) {
    switch (this) {
      case Col.select:
        return SizedBox(
          width: 40,
          child: Center(
            child: IconButton(
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                context.read<OutboundBloc>().add(
                  const MultiSelectSelectAllEvent(true),
                );
              },
              icon: const Icon(Icons.check_box_rounded),
            ),
          ),
        );
      case Col.countryIcon:
        return SortableHeaderCell(
          col: this,
          loading: testingArea,
          sortCol: sort,
        );
      case Col.remark || Col.remarkProtocol:
        return Expanded(
          flex: 3,
          child: SortableHeaderCell(
            col: this,
            sortCol: sort,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            center: false,
          ),
        );
      case Col.address:
        return Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: headerWidget(context),
          ),
        );
      case Col.protocol:
        return SortableHeaderCell(
          col: this,
          center: false,
          padding: const EdgeInsets.only(left: 6, right: 12),
          sortCol: sort,
        );
      // case Col.sni:
      //   return Expanded(
      //       flex: 2,
      //       child: Padding(
      //         padding: const EdgeInsets.symmetric(horizontal: 6.0),
      //         child: headerWidget(context),
      //       ));
      case Col.usable:
        return SortableHeaderCell(col: this, sortCol: sort);
      case Col.speed:
        return SortableHeaderCell(col: this, sortCol: sort);
      case Col.ping:
        return SortableHeaderCell(col: this, sortCol: sort);
      case Col.active:
        return SortableHeaderCell(col: this, sortCol: sort);
    }
  }

  Widget getBodyCell(BuildContext context, OutboundHandler handler) {
    switch (this) {
      case Col.select:
        return GestureDetector(
          onVerticalDragStart: (details) {
            // print(
            //     'vertical drag start: ; local ${details.localPosition}; global ${details.globalPosition}; handler: ${handler.id}');
          },
          onVerticalDragUpdate: (details) {
            context.read<OutboundBloc>().add(
              MultiSelectVerticalDragUpdateEvent(
                handler,
                details.localPosition,
              ),
            );
            // print(
            //     'vertical drag update: delta ${details.delta}; primaryDelta ${details.primaryDelta}; local ${details.localPosition}; global ${details.globalPosition}; handler: ${handler.id}');
          },
          onVerticalDragEnd: (details) {
            // print(
            //     'vertical drag end:; local ${details.localPosition}; global ${details.globalPosition}; handler: ${handler.id}');
          },
          child: Checkbox(
            value: handler.selectedInMultipleSelect,
            onChanged: (v) {
              context.read<OutboundBloc>().add(MultiSelectToggleEvent(handler));
            },
          ),
        );
      case Col.countryIcon:
        return SizedBox(
          width: getWidth(context),
          child: Center(child: handler.countryIcon),
        );
      case Col.remarkProtocol:
        return Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 33),
                  child: AutoSizeText(
                    isProduction()
                        ? handler.name
                        : '${handler.name}(${handler.id})',
                    minFontSize: 10,
                    maxLines: 2,
                  ),
                ),
                // if (MediaQuery.sizeOf(context).width <= 680)
                Text(
                  handler.displayProtocol(),
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        );
      case Col.remark:
        return Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: AutoSizeText(
              isProduction() ? handler.name : '${handler.name}(${handler.id})',
              minFontSize: 10,
              maxLines: 2,
            ),
          ),
        );
      case Col.address:
        return Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: AutoSizeText(handler.displayAddress, minFontSize: 10),
          ),
        );
      case Col.protocol:
        return Padding(
          padding: const EdgeInsets.only(left: 6, right: 12),
          child: SizedBox(
            width: getWidth(context),
            child: AutoSizeText(
              handler.displayProtocol(),
              maxLines: 2,
              overflow: TextOverflow.clip,
            ),
          ),
        );
      // case Col.sni:
      //   return Expanded(
      //     flex: 2,
      //     child: Padding(
      //       padding: const EdgeInsets.symmetric(horizontal: 6),
      //       child: Text(handler.sni),
      //     ),
      //   );
      case Col.usable:
        return InkWell(
          onTap: () {
            context.read<OutboundBloc>().add(
              StatusTestEvent(handlers: [handler]),
            );
          },
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: SizedBox(
                width: getWidth(context),
                child: handler.usableTesting
                    ? const Center(child: _progressIndicator)
                    : _usableText(handler.ok),
              ),
            ),
          ),
        );
      case Col.speed:
        return InkWell(
          onTap: () {
            context.read<OutboundBloc>().add(
              SpeedTestEvent(handlers: [handler]),
            );
          },
          child: SizedBox(
            width: getWidth(context),
            child: Center(
              child: handler.speedTesting
                  ? _progressIndicator
                  : Text(
                      handler.ok > 0 && handler.speed > 0
                          ? handler.speed.toStringAsFixed(1)
                          : '',
                    ),
            ),
          ),
        );
      case Col.ping:
        return InkWell(
          onTap: () {
            context.read<OutboundBloc>().add(
              StatusTestEvent(handlers: [handler]),
            );
          },
          child: SizedBox(
            width: getWidth(context),
            child: Center(
              child: handler.usableTesting
                  ? _progressIndicator
                  : FittedBox(
                      child: Text(
                        handler.ok > 0 && handler.ping > 0
                            ? handler.ping.toString()
                            : '',
                      ),
                    ),
            ),
          ),
        );
      case Col.active:
        return SizedBox(
          width: getWidth(context),
          child: Transform.scale(
            scale: 0.8,
            child: Switch(
              value: handler.selected,
              onChanged: (v) {
                context.read<OutboundBloc>().add(
                  SwitchHandlerEvent(handler, v),
                );
              },
            ),
          ),
        );
    }
  }
}

const _progressIndicator = SizedBox(
  width: 12,
  height: 12,
  child: CircularProgressIndicator(strokeWidth: 2),
);

Widget _usableText(int status) {
  if (status == 0) {
    return const SizedBox();
  } else if (status > 0) {
    return const Icon(Icons.check_circle_rounded, color: Colors.green);
  } else {
    return const Icon(Icons.cancel_rounded, color: Colors.grey);
  }
}

int _getGridCrossAxisCount(double width) {
  if (width > 1400) {
    return 5;
  } else if (width > 1100) {
    return 4;
  } else if (width > 800) {
    return 3;
  } else if (width > 500) {
    return 2;
  } else {
    return 1;
  }
}

class _GridSortButton extends StatelessWidget {
  const _GridSortButton({required this.sortCol});

  final (Col, SortOrder)? sortCol;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: Icon(
            Icons.sort_by_alpha,
            color: sortCol?.$1 == Col.remark ? XBlue : null,
          ),
          onPressed: () {
            final newSort = sortCol?.$1 == Col.remark && sortCol?.$2 == 1
                ? (Col.remark, -1)
                : (Col.remark, 1);
            context.read<OutboundBloc>().add(SortHandlersEvent(newSort));
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.remark),
              if (sortCol?.$1 == Col.remark) ...[
                const Gap(4),
                Icon(
                  sortCol?.$2 == 1 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
        MenuItemButton(
          leadingIcon: Icon(
            Icons.language,
            color: sortCol?.$1 == Col.countryIcon ? XBlue : null,
          ),
          onPressed: () {
            final newSort = sortCol?.$1 == Col.countryIcon && sortCol?.$2 == 1
                ? (Col.countryIcon, -1)
                : (Col.countryIcon, 1);
            context.read<OutboundBloc>().add(SortHandlersEvent(newSort));
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.area),
              if (sortCol?.$1 == Col.countryIcon) ...[
                const Gap(4),
                Icon(
                  sortCol?.$2 == 1 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
        MenuItemButton(
          leadingIcon: Icon(
            Icons.code,
            color: sortCol?.$1 == Col.protocol ? XBlue : null,
          ),
          onPressed: () {
            final newSort = sortCol?.$1 == Col.protocol && sortCol?.$2 == 1
                ? (Col.protocol, -1)
                : (Col.protocol, 1);
            context.read<OutboundBloc>().add(SortHandlersEvent(newSort));
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.protocol),
              if (sortCol?.$1 == Col.protocol) ...[
                const Gap(4),
                Icon(
                  sortCol?.$2 == 1 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
        const Divider(),
        MenuItemButton(
          leadingIcon: Icon(
            Icons.check_circle_outline,
            color: sortCol?.$1 == Col.usable ? XBlue : null,
          ),
          onPressed: () {
            context.read<OutboundBloc>().add(
              const SortHandlersEvent((Col.usable, -1)),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.usable),
              if (sortCol?.$1 == Col.usable) ...[
                const Gap(4),
                const Icon(Icons.arrow_downward, size: 16),
              ],
            ],
          ),
        ),
        MenuItemButton(
          leadingIcon: Icon(
            Icons.arrow_circle_down,
            color: sortCol?.$1 == Col.speed ? XBlue : null,
          ),
          onPressed: () {
            context.read<OutboundBloc>().add(
              const SortHandlersEvent((Col.speed, -1)),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.speed),
              if (sortCol?.$1 == Col.speed) ...[
                const Gap(4),
                const Icon(Icons.arrow_downward, size: 16),
              ],
            ],
          ),
        ),
        MenuItemButton(
          leadingIcon: Icon(
            Icons.timer,
            color: sortCol?.$1 == Col.ping ? XBlue : null,
          ),
          onPressed: () {
            context.read<OutboundBloc>().add(
              const SortHandlersEvent((Col.ping, 1)),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.latency),
              if (sortCol?.$1 == Col.ping) ...[
                const Gap(4),
                const Icon(Icons.arrow_upward, size: 16),
              ],
            ],
          ),
        ),
        MenuItemButton(
          leadingIcon: Icon(
            Icons.toggle_on,
            color: sortCol?.$1 == Col.active ? XBlue : null,
          ),
          onPressed: () {
            context.read<OutboundBloc>().add(
              const SortHandlersEvent((Col.active, -1)),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.selectOneOutbound),
              if (sortCol?.$1 == Col.active) ...[
                const Gap(4),
                const Icon(Icons.arrow_downward, size: 16),
              ],
            ],
          ),
        ),
        const Divider(),
        MenuItemButton(
          leadingIcon: const Icon(Icons.clear),
          onPressed: () {
            context.read<OutboundBloc>().add(const SortHandlersEvent(null));
          },
          child: Text(AppLocalizations.of(context)!.clear),
        ),
      ],
      builder: (context, controller, child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          icon: Icon(Icons.sort_rounded, color: sortCol != null ? XBlue : null),
          tooltip: 'Sort',
        );
      },
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.cols});

  final List<Col> cols;

  List<Widget> _getHeaderCells(
    BuildContext context,
    List<Col> cols,
    bool testingArea,
    (Col, SortOrder)? sort,
  ) {
    final cells = <Widget>[const Gap(8)];
    for (var col in cols) {
      cells.add(col.getHeaderCell(context, testingArea, sort));
    }
    cells.add(const Gap(8));
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: DefaultTextStyle(
        style: Theme.of(
          context,
        ).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w500),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          height: 36,
          child:
              BlocSelector<
                OutboundBloc,
                OutboundState,
                (bool, (Col, SortOrder)?)
              >(
                selector: (state) => (state.testingArea, state.sortCol),
                builder: (context, r) {
                  return Row(
                    children: _getHeaderCells(context, cols, r.$1, r.$2),
                  );
                },
              ),
        ),
      ),
    );
  }
}
