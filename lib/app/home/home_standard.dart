part of 'home.dart';

class StandardHomePage extends StatelessWidget {
  const StandardHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final visibility = context.watch<StandardHomeWidgetVisibilityNotifier>();
    final hidden = visibility.hiddenIds;
    final anyStatsVisible = _statsWidgetIds.any((id) => !hidden.contains(id));
    context.read<RealtimeSpeedNotifier>().setStatsWidgetsVisible(
      anyStatsVisible,
    );
    final showRealm = !hidden.contains(HomeWidgetId.realmServer.id);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: const Stats(),
          ),
          Expanded(
            child: Builder(
              builder: (ctx) {
                final mode = ctx.select<ProxySelectorBloc, ProxySelectorMode>(
                  (b) => b.state.proxySelectorMode,
                );
                final size = MediaQuery.of(context).size;
                if (size.isCompact) {
                  return ListView(
                    children: [
                      if (!hidden.contains(HomeWidgetId.nodes.id))
                        const Nodes(),
                      if (mode == ProxySelectorMode.manual &&
                          !hidden.contains(HomeWidgetId.nodesHelper.id))
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 294),
                          child: const NodesHelper(),
                        ),
                      if (!hidden.contains(HomeWidgetId.route.id))
                        const _Route(),
                      if (!hidden.contains(HomeWidgetId.proxySelector.id))
                        const ProxySelector(home: true),
                      if (desktopPlatforms &&
                          !hidden.contains(HomeWidgetId.inbound.id))
                        const _Inbound(),
                      if (!hidden.contains(HomeWidgetId.subscription.id))
                        const _Subscription(),
                      if (showRealm &&
                          ctx.watch<StartCloseCubit>().state.status ==
                              XStatus.connected)
                        _RealmServerCard(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            if (state.proUser) {
                              return const SizedBox.shrink();
                            }
                            return const BannerAdWidget();
                          },
                        ),
                      ),
                      const Gap(60),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (ctx, c) {
                          return ScrollConfiguration(
                            behavior: ScrollConfiguration.of(
                              context,
                            ).copyWith(scrollbars: false),
                            child: ListView(
                              children: [
                                if (!hidden.contains(HomeWidgetId.route.id))
                                  const _Route(),
                                if (!hidden.contains(
                                  HomeWidgetId.proxySelector.id,
                                ))
                                  const ProxySelector(home: true),
                                if (desktopPlatforms &&
                                    !hidden.contains(HomeWidgetId.inbound.id))
                                  const _Inbound(),
                                if (!hidden.contains(
                                  HomeWidgetId.subscription.id,
                                ))
                                  const _Subscription(),
                                if (showRealm &&
                                    ctx.watch<StartCloseCubit>().state.status ==
                                        XStatus.connected)
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 10),
                                    child: _RealmServerCard(),
                                  ),
                                BlocBuilder<AuthBloc, AuthState>(
                                  builder: (context, state) {
                                    if (state.proUser) {
                                      return const SizedBox.shrink();
                                    }
                                    return ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxHeight: c.maxHeight,
                                      ),
                                      child: const BannerAdWidget(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!hidden.contains(HomeWidgetId.nodes.id))
                            const Nodes(),
                          if (!hidden.contains(HomeWidgetId.nodesHelper.id))
                            Expanded(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 613,
                                  ),
                                  child: const NodesHelper(),
                                ),
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
        ],
      ),
    );
  }
}

/// Notifier for home widget visibility. When [hide] is called, updates prefs
/// and notifies so [HomePage] can rebuild.
class StandardHomeWidgetVisibilityNotifier extends ChangeNotifier {
  StandardHomeWidgetVisibilityNotifier(this._prefs);

  final SharedPreferences _prefs;

  Set<String> get hiddenIds => _prefs.hiddenHomeWidgetIds;

  void hide(String widgetId) {
    final next = Set<String>.from(hiddenIds)..add(widgetId);
    _prefs.setHiddenHomeWidgetIds(next);
    notifyListeners();
  }

  void show(String widgetId) {
    final next = Set<String>.from(hiddenIds)..remove(widgetId);
    _prefs.setHiddenHomeWidgetIds(next);
    notifyListeners();
  }
}

class _StandardHomeWidgetSetting extends StatelessWidget {
  const _StandardHomeWidgetSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StandardHomeWidgetVisibilityNotifier>(
      builder: (context, visibility, child) {
        return ListView(
          shrinkWrap: true,
          children: HomeWidgetId.values.map((id) {
            final hidden = visibility.hiddenIds.contains(id.id);
            return CheckboxListTile(
              title: Text(id.label(context)),
              value: !hidden,
              onChanged: (value) {
                if (value == null) return;
                if (value) {
                  visibility.show(id.id);
                } else {
                  visibility.hide(id.id);
                }
              },
            );
          }).toList(),
        );
      },
    );
  }
}
