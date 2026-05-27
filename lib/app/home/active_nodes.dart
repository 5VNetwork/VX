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

part of 'home.dart';

class Nodes extends StatelessWidget {
  const Nodes({super.key});

  @override
  Widget build(BuildContext context) {
    final realtime = context.watch<RealtimeSpeedNotifier>();
    final mode = context.select<ProxySelectorBloc, ProxySelectorMode>(
      (b) => b.state.proxySelectorMode,
    );
    final manual = mode == ProxySelectorMode.manual;
    if (realtime.nodeInfos.isNotEmpty) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: const ActiveNodes(),
      );
    }
    if (realtime.nodeInfos.isEmpty && manual) return const CurrentNodes();
    return const SizedBox();
  }
}

class CurrentNodes extends StatelessWidget {
  const CurrentNodes({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      title: AppLocalizations.of(context)!.currentNodes,
      icon: Icons.outbound_outlined,
      child: StreamBuilder(
        stream: context.watch<OutboundRepo>().getHandlersStream(selected: true),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data!.isEmpty) {
              return const Center(child: AddMenuAnchor(elevatedButton: true));
            }
            return ListView.separated(
              physics: const ClampingScrollPhysics(),
              shrinkWrap: true,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      GoRouter.of(context).go(
                        '/node',
                        extra: NodePageExtra(
                          initialHandlerId: snapshot.data![index].id,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: SizedBox(
                        height: 54,
                        child: _NodeListItem(
                          handler: snapshot.data![index],
                          testFuture: () =>
                              _testHandler(context, snapshot.data![index]),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
    // } else {
    //   return SizedBox();
    // }
  }
}

/// Nested [ListView] inside an outer scroll view: at min/max extent the inner
/// [Scrollable] does not register with [PointerSignalResolver], so wheel/trackpad
/// deltas would scroll the parent. This wrapper registers a no-op handler in
/// that case so scrolling stops at the inner list's edge.
class _AbsorbParentPointerScrollAtEdge extends StatefulWidget {
  const _AbsorbParentPointerScrollAtEdge({required this.builder});

  final Widget Function(BuildContext context, ScrollController controller)
  builder;

  @override
  State<_AbsorbParentPointerScrollAtEdge> createState() =>
      _AbsorbParentPointerScrollAtEdgeState();
}

class _AbsorbParentPointerScrollAtEdgeState
    extends State<_AbsorbParentPointerScrollAtEdge> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (!_controller.hasClients) return;
    final ScrollPosition position = _controller.position;
    if (!position.hasContentDimensions) return;
    if (position.minScrollExtent >= position.maxScrollExtent) return;
    if (!position.physics.shouldAcceptUserOffset(position)) return;

    final ScrollBehavior scrollBehavior = ScrollConfiguration.of(context);
    final pressed = HardwareKeyboard.instance.logicalKeysPressed;
    final flipAxes =
        pressed.any(scrollBehavior.pointerAxisModifiers.contains) &&
        event.kind == PointerDeviceKind.mouse;
    final scrollAxis = flipAxes ? flipAxis(position.axis) : position.axis;
    final double rawDelta = switch (scrollAxis) {
      Axis.horizontal => event.scrollDelta.dx,
      Axis.vertical => event.scrollDelta.dy,
    };
    final double delta = axisDirectionIsReversed(position.axisDirection)
        ? -rawDelta
        : rawDelta;

    final double target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (delta != 0.0 && target == position.pixels) {
      GestureBinding.instance.pointerSignalResolver.register(event, (_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: widget.builder(context, _controller),
    );
  }
}

class ActiveNodes extends StatelessWidget {
  const ActiveNodes({super.key});

  @override
  Widget build(BuildContext context) {
    final realtime = context.watch<RealtimeSpeedNotifier>();
    return HomeCard(
      title: AppLocalizations.of(context)!.activeNodes,
      icon: Icons.outbound,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: desktopPlatforms ? 227 : 235),
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: true),
          child: realtime.nodeInfos.isEmpty
              ? const SizedBox(
                  height: 80,
                  child: Center(child: Text('No active nodes')),
                )
              : _AbsorbParentPointerScrollAtEdge(
                  builder: (context, scrollController) => ListView.separated(
                    controller: scrollController,
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    separatorBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(
                        height: 1,
                        color: Colors.grey.withOpacity(0.1),
                      ),
                    ),
                    itemCount: realtime.nodeInfos.length,
                    itemBuilder: (context, index) {
                      final nodeInfo = realtime.nodeInfos[index];
                      return NodeCard(nodeInfo: nodeInfo);
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

enum NodesHelperSegment { fastest, lowestLatency, recent }

class NodesHelper extends StatefulWidget {
  const NodesHelper({super.key});

  @override
  State<NodesHelper> createState() => _NodesHelperState();
}

class _NodesHelperState extends State<NodesHelper> {
  late NodesHelperSegment _selectedSegment;
  List<OutboundHandler> _handlers = [];
  StreamSubscription<List<OutboundHandler>>? _handlerStream;
  StreamSubscription<HandlerBeingUsed>? _handlerBeingUsedSub;
  late OutboundRepo outboundRepo;

  static int _parseHandlerId(String tag) {
    if (tag.contains('-')) {
      return int.tryParse(tag.split('-').firstOrNull ?? '') ?? 0;
    }
    return int.tryParse(tag) ?? 0;
  }

  void _onHandlerBeingUsed(HandlerBeingUsed used) {
    // only update recently used node id if there is only one
    if (used.tags.length != 1) return;
    final pref = context.read<SharedPreferences>();
    for (final tag in used.tags) {
      final id = _parseHandlerId(tag);
      if (id > 0) pref.addRecentlyUsedNodeId(id);
    }
    if (mounted && _selectedSegment == NodesHelperSegment.recent) {
      _loadRecentHandlers();
    }
  }

  Future<void> _loadRecentHandlers() async {
    final ids = context.read<SharedPreferences>().recentlyUsedNodeIds;
    if (ids.isEmpty) {
      if (mounted) setState(() => _handlers = []);
      return;
    }
    final handlers = await outboundRepo.getHandlersByIds(ids);
    if (mounted) setState(() => _handlers = handlers);
  }

  /// Waits until [SwitchHandlerEvent] has finished writing selection to the DB,
  /// then refreshes the recent list (so toggles show the correct state).
  Future<void> _switchHandlerAndRefreshRecentIfNeeded(
    int index,
    bool selected,
  ) async {
    final handler = _handlers[index];
    if (_selectedSegment != NodesHelperSegment.recent) {
      context.read<SharedPreferences>().addRecentlyUsedNodeId(handler.id);
    }

    final whenPersisted = Completer<void>();
    context.read<OutboundBloc>().add(
      SwitchHandlerEvent(handler, selected, whenPersisted: whenPersisted),
    );
    await whenPersisted.future;
    if (!mounted) return;
    if (_selectedSegment == NodesHelperSegment.recent) {
      await _loadRecentHandlers();
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedSegment = context.read<SharedPreferences>().nodesHelperSegment;
    _handlerBeingUsedSub = context
        .read<XController>()
        .handlerBeingUsedStream()
        .listen(_onHandlerBeingUsed);
  }

  @override
  void dispose() {
    _handlerStream?.cancel();
    _handlerBeingUsedSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    outboundRepo = context.watch<OutboundRepo>();
    _loadHandlers();
  }

  void _loadHandlers() {
    _handlerStream?.cancel();
    if (_selectedSegment == NodesHelperSegment.recent) {
      _loadRecentHandlers();
      return;
    } else if (_selectedSegment == NodesHelperSegment.fastest) {
      _handlerStream = outboundRepo
          .getHandlersStream(orderBySpeed1MBDesc: true, limit: 10, usable: true)
          .listen((handlers) {
            if (mounted) {
              setState(() {
                _handlers = handlers;
              });
            }
          });
    } else if (_selectedSegment == NodesHelperSegment.lowestLatency) {
      _handlerStream = outboundRepo
          .getHandlersStream(orderByPingAsc: true, limit: 10, usable: true)
          .listen((handlers) {
            if (mounted) {
              setState(() {
                _handlers = handlers;
              });
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      title: AppLocalizations.of(context)!.recommendedNodes,
      icon: Icons.recommend_outlined,
      child: Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Segmented control
            SegmentedButton<NodesHelperSegment>(
              showSelectedIcon:
                  AppLocalizations.of(context)!.localeName == 'zh',
              segments: [
                ButtonSegment(
                  value: NodesHelperSegment.fastest,
                  label: Text(AppLocalizations.of(context)!.speed),
                  icon: AppLocalizations.of(context)!.localeName != 'zh'
                      ? null
                      : const Icon(Icons.speed, size: 16),
                ),
                ButtonSegment(
                  value: NodesHelperSegment.lowestLatency,
                  label: Text(AppLocalizations.of(context)!.latency),
                  icon: AppLocalizations.of(context)!.localeName != 'zh'
                      ? null
                      : const Icon(Icons.network_check, size: 16),
                ),
                ButtonSegment(
                  value: NodesHelperSegment.recent,
                  label: Text(AppLocalizations.of(context)!.recent),
                  icon: AppLocalizations.of(context)!.localeName != 'zh'
                      ? null
                      : const Icon(Icons.history, size: 16),
                ),
              ],
              selected: {_selectedSegment},
              onSelectionChanged: (Set<NodesHelperSegment> set) {
                setState(() {
                  _selectedSegment = set.first;
                  context.read<SharedPreferences>().setNodesHelperSegment(
                    _selectedSegment,
                  );
                  _loadHandlers();
                });
              },
            ),
            const SizedBox(height: 10),
            // Node list
            if (_handlers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: SizedBox(),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                  itemCount: context.read<MyLayout>().isCompact
                      ? min(3, _handlers.length)
                      : _handlers.length,
                  itemBuilder: (context, index) {
                    final manualSelect =
                        context
                            .watch<ProxySelectorBloc>()
                            .state
                            .proxySelectorMode ==
                        ProxySelectorMode.manual;
                    return SizedBox(
                      // height: 50,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: manualSelect
                              ? () {
                                  _switchHandlerAndRefreshRecentIfNeeded(
                                    index,
                                    !_handlers[index].selected,
                                  );
                                }
                              : null,
                          child: Row(
                            children: [
                              Expanded(
                                child: _NodeListItem(
                                  key: ValueKey(_handlers[index].id),
                                  handler: _handlers[index],
                                  testFuture: () async {
                                    final handler = _handlers[index];
                                    final (ok, ping, speed) =
                                        await _testHandler(context, handler);
                                    if (_selectedSegment ==
                                            NodesHelperSegment.recent &&
                                        mounted) {
                                      final index = _handlers.indexOf(handler);
                                      if (index != -1) {
                                        setState(() {
                                          _handlers[index] = handler.copyWith(
                                            ok: ok,
                                            ping: ping,
                                            speed: speed,
                                          );
                                        });
                                      }
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (manualSelect)
                                Transform.scale(
                                  scale: 0.8,
                                  child: Switch(
                                    value: _handlers[index].selected,
                                    onChanged: (value) {
                                      _switchHandlerAndRefreshRecentIfNeeded(
                                        index,
                                        value,
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<(int, int, double)> _testHandler(
  BuildContext context,
  OutboundHandler handler,
) async {
  final xApiClient = context.read<XApiClient>();
  final xController = context.read<XController>();
  final bloc = context.read<OutboundBloc>();
  final outboundRepo = context.read<OutboundRepo>();
  final pref = context.read<SharedPreferences>();
  // Latency test (status)
  final pingMode = pref.pingMode;
  int ok = 0;
  int ping = 0;
  double speed = 0;
  int? pingTestTime;
  int? speedTestTime;
  if (pingMode == PingMode.Real) {
    try {
      final res = await xApiClient.handlerUsable(
        api_pb.HandlerUsableRequest(handler: handler.toConfig()),
      );
      ok = res.ping > 0 ? 1 : -1;
      ping = res.ping;
      if (ok < 0) {
        speed = 0;
      }
    } catch (e) {
      logger.e('handlerUsable error', error: e);
    }
  } else {
    try {
      int port;
      String addr;
      if (handler.config.hasOutbound()) {
        addr = handler.config.outbound.address;
        port = handler.config.outbound.port;
        if (port == 0) {
          port = handler.config.outbound.ports.first.from;
        }
      } else {
        final c = handler.config.chain.handlers.first;
        addr = c.address;
        port = c.port;
        if (port == 0) {
          port = c.ports.first.from;
        }
      }
      final p = Tm.instance.state == TmStatus.connected
          ? await xController.rttTest(addr, port)
          : await xApiClient.rtt(api_pb.RttTestRequest(addr: addr, port: port));
      ok = p > 0 ? 1 : -1;
      ping = p;
      pingTestTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (ok < 0) {
        speed = 0;
      }
    } catch (e) {
      logger.e('rtt error', error: e);
    }
  }

  // Speed test
  try {
    final resStream = await xApiClient.speedTest(
      api_pb.SpeedTestRequest(
        handlers: [handler.toConfig()],
        size: pref.outboundSpeedTestBytes,
      ),
    );
    await for (final res in resStream) {
      ok = res.down > 0 ? 1 : -1;
      speed = bytesToMbps(res.down.toInt());
      if (ok < 0) {
        ping = 0;
      }
      speedTestTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      xController.updateHandlerSpeed(res.tag, res.down.toInt());
    }
  } catch (e) {
    logger.e('speedTest error', error: e);
  }
  bloc.add(HandlerUpdatedEvent(handler.id));
  await outboundRepo.updateHandler(
    handler.id,
    ok: ok,
    ping: ping,
    pingTestTime: pingTestTime,
    speed: speed,
    speedTestTime: speedTestTime,
  );
  return (ok, ping, speed);
}

class _NodeListItem extends StatefulWidget {
  const _NodeListItem({required this.handler, this.testFuture, super.key});

  final OutboundHandler handler;
  final Future<void> Function()? testFuture;

  @override
  State<_NodeListItem> createState() => _NodeListItemState();
}

class _NodeListItemState extends State<_NodeListItem> {
  bool _isTesting = false;

  Future<void> _runTests() async {
    if (_isTesting) return;
    setState(() => _isTesting = true);
    try {
      await widget.testFuture?.call();
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final handler = widget.handler;
    final speedText = handler.speed > 0
        ? '${handler.speed.toStringAsFixed(1)} Mbps'
        : '--';
    final latencyText = handler.ping > 0 ? '${handler.ping}ms' : '--';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Country flag
          Container(
            padding: const EdgeInsets.all(4),
            child: handler.countryIcon,
          ),
          const SizedBox(width: 10),
          // Node info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(handler.name, minFontSize: 10, maxLines: 1),
                Text(
                  handler.displayProtocol(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Stats (tap to run speed + latency test)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isTesting ? null : _runTests,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _isTesting
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: smallCircularProgressIndicator,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.speed, size: 14, color: XBlue),
                              const SizedBox(width: 4),
                              Text(
                                speedText,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: XBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.network_check_rounded,
                                size: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                latencyText,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
