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

class HomeLayoutRepo extends ChangeNotifier {
  HomeLayoutRepo(this._prefs) {}

  Map<HomeLayoutPreset, HomeLayout> _homeWidgetRows = {};

  final SharedPreferences _prefs;

  HomeLayout getHomeWidgets(HomeLayoutPreset preset) {
    HomeLayout? layout = _homeWidgetRows[preset];
    if (layout == null) {
      layout =
          _prefs.getHomeWidgetRows(preset) ?? defaultHomeWidgetRows(preset);
      _homeWidgetRows[preset] = layout;
    }
    return layout;
  }

  void setHomeWidgets(HomeLayoutPreset preset, HomeLayout layout) {
    _homeWidgetRows[preset] = layout;
    _prefs.setHomeWidgetRows(preset, layout);
    notifyListeners();
  }

  void clearHomeWidgets(HomeLayoutPreset preset) {
    _homeWidgetRows.remove(preset);
    _prefs.clearHomeWidgetRows(preset);
    notifyListeners();
  }

  /// Appends a widget id (e.g. SUBSCRIPTION_42) to column 0 of the home
  /// layout for all presets. Used when user adds a subscription to home (Pro).
  void addWidgetIdToHome(String widgetId) {
    for (final preset in HomeLayoutPreset.values) {
      final layout = getHomeWidgets(preset);
      final updated = layout.copyAppendingToColumn(0, [widgetId]);
      setHomeWidgets(preset, updated);
    }
  }
}

class CustomHomePageLayoutProvider extends ChangeNotifier {
  CustomHomePageLayoutProvider(this._repo) {
    _repo.addListener(notifyListeners);
  }

  final HomeLayoutRepo _repo;

  @override
  void dispose() {
    _repo.removeListener(notifyListeners);
    super.dispose();
  }

  HomeLayout getHomeWidgets(HomeLayoutPreset preset) {
    return _repo.getHomeWidgets(preset);
  }
}

class HomeLayout {
  HomeLayout(this._layout);
  Map<int, List<List<String>>> _layout;

  // to json
  String toJson() {
    return jsonEncode(
      _layout.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  // from json
  static HomeLayout fromJson(String json) {
    final decoded = jsonDecode(json);
    if (decoded is Map<String, dynamic>) {
      return HomeLayout(
        decoded.map((key, value) {
          final rows = value as List<dynamic>?;
          if (rows == null) {
            return MapEntry(int.parse(key), <List<String>>[]);
          }
          final list = rows
              .map((row) => List<String>.from(row as List))
              .toList();
          return MapEntry(int.parse(key), list);
        }),
      );
    }
    throw Exception('Invalid JSON');
  }

  Set<String> allIds() {
    final set = <String>{};
    for (final row in _layout.values) {
      for (final item in row) {
        for (final id in item) {
          set.add(id);
        }
      }
    }
    return set;
  }

  int get columns => _layout.keys.length;

  List<List<String>> getColumn(int column) {
    return _layout[column]!;
  }

  List<String>? getId(int column, int row) {
    if (!_layout.containsKey(column) || _layout[column]!.length <= row) {
      return null;
    }
    return _layout[column]![row];
  }

  /// Returns a new layout with [row] appended to [columnIndex].
  HomeLayout copyAppendingToColumn(int columnIndex, List<String> row) {
    final newMap = <int, List<List<String>>>{};
    for (final e in _layout.entries) {
      newMap[e.key] = e.value.map((r) => List<String>.from(r)).toList();
    }
    final col = newMap[columnIndex] ?? [];
    newMap[columnIndex] = [...col, List<String>.from(row)];
    return HomeLayout(newMap);
  }
}

class CustomizableHomePage extends StatelessWidget {
  const CustomizableHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final preset = MediaQuery.sizeOf(context).homeLayoutPreset;
    final visibility = context
        .watch<CustomHomePageLayoutProvider>()
        .getHomeWidgets(preset);
    // when no stats component is visible, stop RealtimeSpeedNotifier
    final all = visibility.allIds();
    final anyStatsVisible = _statsWidgetIds.any((id) => all.contains(id));
    context.read<RealtimeSpeedNotifier>().setStatsWidgetsVisible(
      anyStatsVisible,
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var column = 0; column < preset.columns; column++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: column == preset.columns - 1 ? 0 : 10,
                    ),
                    child: Column(
                      children: visibility.getColumn(column).map((item) {
                        if (item.length == 2) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _getWidget(context, item[0], preset),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _getWidget(context, item[1], preset),
                                ),
                              ],
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _getWidget(context, item.single, preset),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _getWidget(BuildContext context, String id, HomeLayoutPreset preset) {
  if (HomeWidgetId.fromId(id) != null) {
    return HomeWidgetId.fromId(id)!.buildWidget(context, preset);
  }
  // custom subscriptions
  if (id.startsWith('SUBSCRIPTION_')) {
    final int? subId = int.tryParse(id.substring(13));
    if (subId == null) {
      return const SizedBox();
    }
    return _SubScriptionById(id: subId);
  }
  // custom selectors (Pro)
  if (id.startsWith('SELECTOR_')) {
    final tag = id.substring(9);
    if (tag.isEmpty) return const SizedBox();
    return _SelectorByTag(tag: tag);
  }
  return const SizedBox();
}

class _SelectorByTag extends StatelessWidget {
  const _SelectorByTag({required this.tag});
  final String tag;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SelectorConfig?>(
      future: context.read<SelectorRepo>().getSelector(tag),
      builder: (ctx, snap) {
        final config = snap.data;
        if (config == null) {
          return HomeCard(
            title: tag,
            icon: Icons.filter_alt_outlined,
            child: Text(
              tag,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return HomeCard(
          title: tag,
          titleWidget: Row(
            children: [
              Text(
                tag,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              BlocProvider<SelectorBeingUsedCubit>(
                create: (context) => SelectorBeingUsedCubit(
                  selectorTag: tag,
                  xController: context.read<XController>(),
                  outboundRepo: context.read<OutboundRepo>(),
                ),
                child: const SelectorBeingUsedView(),
              ),
            ],
          ),
          icon: Icons.filter_alt_outlined,
          child: BlocProvider(
            create: (context) => SelectorBeingUsedCubit(
              selectorTag: tag,
              xController: context.read<XController>(),
              outboundRepo: context.read<OutboundRepo>(),
            ),
            child: SelectorConfigWidget(
              config: config,
              onFilterChange: () {
                context.read<XController>().selectorFilterChange(config);
              },
              onBalanceStrategyChange: () {
                context.read<XController>().selectorBalancingStrategyChange(
                  tag,
                  config.balanceStrategy,
                );
              },
              onStrategyOrLandHandlersChange: () {
                context
                    .read<XController>()
                    .selectorSelectStrategyOrLandhandlerChange(config);
              },
            ),
          ),
        );
      },
    );
  }
}

class _HomeEditDialog extends StatefulWidget {
  const _HomeEditDialog();

  @override
  State<_HomeEditDialog> createState() => _HomeEditDialogState();
}

class _HomeEditDialogState extends State<_HomeEditDialog> {
  late HomeLayoutPreset _selectedPreset;

  bool _hideInboundOnThisPlatform(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    _selectedPreset = MediaQueryData.fromView(
      WidgetsBinding.instance.platformDispatcher.views.first,
    ).size.homeLayoutPreset;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hideInbound = _hideInboundOnThisPlatform(context);
    return Consumer<CustomizeHomeWidgetNotifier>(
      builder: (context, visibility, child) {
        final layout = visibility.layoutFor(_selectedPreset);
        final hiddenIds = visibility.hiddenIdsFor(_selectedPreset);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SegmentedButton<HomeLayoutPreset>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment<HomeLayoutPreset>(
                      value: HomeLayoutPreset.compact,
                      label: Text(AppLocalizations.of(context)!.compact),
                    ),
                    ButtonSegment<HomeLayoutPreset>(
                      value: HomeLayoutPreset.medium,
                      label: Text(AppLocalizations.of(context)!.medium),
                    ),
                    ButtonSegment<HomeLayoutPreset>(
                      value: HomeLayoutPreset.large,
                      label: Text(AppLocalizations.of(context)!.large),
                    ),
                  ],
                  selected: {_selectedPreset},
                  onSelectionChanged: (value) {
                    setState(() {
                      _selectedPreset = value.first;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.homeCustomizeDragHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    visibility.resetLayout(_selectedPreset);
                  },
                  child: Text(
                    AppLocalizations.of(context)!.homeCustomizeResetOrder,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (
                            var column = 0;
                            column < layout.columns;
                            column++
                          )
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: column == layout.columns - 1 ? 0 : 10,
                                ),
                                child: Column(
                                  children: [
                                    ...layout.getColumn(column).map((item) {
                                      if (item.length == 2) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: _GroupedEditableHomeWidgetTile(
                                            widgetIds: item,
                                            preset: _selectedPreset,
                                            visibility: visibility,
                                          ),
                                        );
                                      }
                                      final rawId = item.single;
                                      final enumId = HomeWidgetId.fromId(rawId);
                                      // Never show the built-in subscription tile
                                      // in the customizable home editor.
                                      if (enumId == HomeWidgetId.subscription) {
                                        return const SizedBox.shrink();
                                      }
                                      if (hideInbound &&
                                          enumId == HomeWidgetId.inbound) {
                                        return const SizedBox.shrink();
                                      }
                                      if (enumId != null) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: _EditableHomeWidgetTile(
                                            widgetId: enumId,
                                            preset: _selectedPreset,
                                            hidden: false,
                                            visibility: visibility,
                                          ),
                                        );
                                      }
                                      // Generic editable tile for any custom widget id
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: _EditableCustomHomeWidgetTile(
                                          id: rawId,
                                          preset: _selectedPreset,
                                          visibility: visibility,
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 4),
                                    _ColumnBottomDropTarget(
                                      preset: _selectedPreset,
                                      columnIndex: column,
                                      visibility: visibility,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (hiddenIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context)!.homeCustomizeHiddenTitle,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: hiddenIds
                        .map(HomeWidgetId.fromId)
                        .whereType<HomeWidgetId>()
                        // Also hide the built-in subscription tile from the
                        // hidden section when editing the customizable home.
                        .where((id) => id != HomeWidgetId.subscription)
                        .where(
                          (id) => !(hideInbound && id == HomeWidgetId.inbound),
                        )
                        .map(
                          (id) => SizedBox(
                            width: _previewWidthForPreset(_selectedPreset),
                            child: _EditableHomeWidgetTile(
                              widgetId: id,
                              preset: _selectedPreset,
                              hidden: true,
                              canAcceptDrop: false,
                              visibility: visibility,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _EditDragData {
  const _EditDragData({required this.widgetIds, required this.hidden});

  final List<String> widgetIds;
  final bool hidden;
}

class _ColumnBottomDropTarget extends StatelessWidget {
  const _ColumnBottomDropTarget({
    required this.preset,
    required this.columnIndex,
    required this.visibility,
  });

  final HomeLayoutPreset preset;
  final int columnIndex;
  final CustomizeHomeWidgetNotifier visibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DragTarget<_EditDragData>(
      onWillAcceptWithDetails: (details) {
        // Always allow drop; validation is handled in the notifier logic.
        return true;
      },
      onAcceptWithDetails: (details) {
        final layout = visibility.layoutFor(preset);
        final layoutMap = Map<int, List<List<String>>>.from(layout._layout);
        final column = List<List<String>>.from(
          layoutMap[columnIndex] ?? const [],
        ).map((row) => List<String>.from(row)).toList();

        // Drop adds each widget as its own row at the bottom of this column.
        for (final id in details.data.widgetIds) {
          final allowed =
              homeWidgetIds.contains(id) ||
              id.startsWith('SUBSCRIPTION_') ||
              id.startsWith('SELECTOR_');
          if (!allowed) continue;
          // If it already exists somewhere, remove it first.
          for (final entry in layoutMap.entries) {
            final rows = entry.value;
            for (var i = 0; i < rows.length; i++) {
              rows[i] = rows[i].where((w) => w != id).toList();
            }
            rows.removeWhere((row) => row.isEmpty);
          }
          column.add([id]);
        }

        layoutMap[columnIndex] = column;
        visibility.setLayout(preset: preset, layout: HomeLayout(layoutMap));
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(top: 4, bottom: 2),
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          alignment: Alignment.center,
          child: Text(
            AppLocalizations.of(context)!.homeCustomizeDropHere,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}

class _GroupedEditableHomeWidgetTile extends StatelessWidget {
  const _GroupedEditableHomeWidgetTile({
    required this.widgetIds,
    required this.preset,
    required this.visibility,
  });

  final List<String> widgetIds;
  final HomeLayoutPreset preset;
  final CustomizeHomeWidgetNotifier visibility;

  @override
  Widget build(BuildContext context) {
    final ids = widgetIds
        .map(HomeWidgetId.fromId)
        .whereType<HomeWidgetId>()
        .toList();
    if (ids.length != 2) {
      return const SizedBox.shrink();
    }

    final payload = _EditDragData(widgetIds: widgetIds, hidden: false);
    final child = _GroupedHomeWidgetPreviewCard(
      widgetIds: ids,
      preset: preset,
      visibility: visibility,
      dragging: false,
    );
    final feedback = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: _previewWidthForPreset(preset),
        child: _GroupedHomeWidgetPreviewCard(
          widgetIds: ids,
          preset: preset,
          visibility: visibility,
          dragging: true,
        ),
      ),
    );
    final childWhenDragging = Opacity(opacity: 0.35, child: child);
    final platform = Theme.of(context).platform;
    final desktopDrag =
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS;

    Widget buildDraggable(Widget draggableChild) {
      if (desktopDrag) {
        return Draggable<_EditDragData>(
          data: payload,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: feedback,
          childWhenDragging: childWhenDragging,
          child: draggableChild,
        );
      }

      return LongPressDraggable<_EditDragData>(
        data: payload,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: feedback,
        childWhenDragging: childWhenDragging,
        child: draggableChild,
      );
    }

    return DragTarget<_EditDragData>(
      onWillAcceptWithDetails: (details) =>
          !details.data.widgetIds.any(widgetIds.contains),
      onAcceptWithDetails: (details) {
        if (details.data.hidden) {
          visibility.showItemsBefore(
            preset: preset,
            widgetIds: details.data.widgetIds,
            targetId: widgetIds.first,
          );
        } else {
          visibility.moveItemsBefore(
            preset: preset,
            widgetIds: details.data.widgetIds,
            targetId: widgetIds.first,
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isTargeted = candidateData.isNotEmpty;
        final decoratedChild = AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: isTargeted
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: child,
        );
        return buildDraggable(decoratedChild);
      },
    );
  }
}

class _EditableHomeWidgetTile extends StatelessWidget {
  const _EditableHomeWidgetTile({
    required this.widgetId,
    required this.preset,
    required this.hidden,
    this.canAcceptDrop = true,
    required this.visibility,
  });

  final HomeWidgetId widgetId;
  final HomeLayoutPreset preset;
  final bool hidden;
  final bool canAcceptDrop;
  final CustomizeHomeWidgetNotifier visibility;

  @override
  Widget build(BuildContext context) {
    final payload = _EditDragData(widgetIds: [widgetId.id], hidden: hidden);
    final child = _HomeWidgetPreviewCard(
      widgetId: widgetId,
      preset: preset,
      visibility: visibility,
      hidden: hidden,
      showMergeButton: !hidden && compactHomeWidgetIds.contains(widgetId.id),
    );

    final feedback = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: _previewWidthForPreset(preset),
        child: _HomeWidgetPreviewCard(
          widgetId: widgetId,
          preset: preset,
          visibility: visibility,
          hidden: hidden,
          dragging: true,
        ),
      ),
    );
    final childWhenDragging = Opacity(opacity: 0.35, child: child);
    final platform = Theme.of(context).platform;
    final desktopDrag =
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS;

    Widget buildDraggable(Widget draggableChild) {
      if (desktopDrag) {
        return Draggable<_EditDragData>(
          data: payload,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: feedback,
          childWhenDragging: childWhenDragging,
          child: draggableChild,
        );
      }

      return LongPressDraggable<_EditDragData>(
        data: payload,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: feedback,
        childWhenDragging: childWhenDragging,
        child: draggableChild,
      );
    }

    if (!canAcceptDrop) {
      return buildDraggable(child);
    }

    return DragTarget<_EditDragData>(
      onWillAcceptWithDetails: (details) =>
          !details.data.widgetIds.contains(widgetId.id),
      onAcceptWithDetails: (details) {
        if (details.data.hidden) {
          visibility.showItemsBefore(
            preset: preset,
            widgetIds: details.data.widgetIds,
            targetId: widgetId.id,
          );
        } else {
          visibility.moveItemsBefore(
            preset: preset,
            widgetIds: details.data.widgetIds,
            targetId: widgetId.id,
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isTargeted = candidateData.isNotEmpty;
        final decoratedChild = AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: isTargeted
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: child,
        );
        return buildDraggable(decoratedChild);
      },
    );
  }
}

/// Generic editable tile for custom home widgets (ids not in [HomeWidgetId]).
///
/// Currently supports subscription tiles with ids like `SUBSCRIPTION_42`, but
/// can be extended to handle other custom ids in the future.
class _EditableCustomHomeWidgetTile extends StatelessWidget {
  const _EditableCustomHomeWidgetTile({
    required this.id,
    required this.preset,
    required this.visibility,
  });

  final String id;
  final HomeLayoutPreset preset;
  final CustomizeHomeWidgetNotifier visibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final int? subId = id.startsWith('SUBSCRIPTION_')
        ? int.tryParse(id.substring(13))
        : null;
    final String? selectorTag = id.startsWith('SELECTOR_')
        ? id.substring(9)
        : null;
    final payload = _EditDragData(widgetIds: [id], hidden: false);
    final child = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: subId != null
                ? FutureBuilder<Subscription?>(
                    future: context.read<OutboundRepo>().getSubById(subId),
                    builder: (ctx, snap) {
                      final name = snap.data?.name ?? id;
                      return Text(
                        name,
                        style: theme.textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  )
                : selectorTag != null && selectorTag.isNotEmpty
                ? Text(
                    selectorTag,
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : Text(
                    id,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          IconButton(
            onPressed: () => visibility.hide(preset: preset, widgetId: id),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.visibility_off_rounded, size: 18),
          ),
          const Icon(Icons.drag_indicator_rounded, size: 18),
        ],
      ),
    );
    final feedback = Material(
      color: Colors.transparent,
      child: SizedBox(width: _previewWidthForPreset(preset), child: child),
    );
    final childWhenDragging = Opacity(opacity: 0.35, child: child);
    final platform = Theme.of(context).platform;
    final desktopDrag =
        platform == TargetPlatform.windows ||
        platform == TargetPlatform.linux ||
        platform == TargetPlatform.macOS;
    Widget buildDraggable(Widget w) {
      if (desktopDrag) {
        return Draggable<_EditDragData>(
          data: payload,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: feedback,
          childWhenDragging: childWhenDragging,
          child: w,
        );
      }
      return LongPressDraggable<_EditDragData>(
        data: payload,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: feedback,
        childWhenDragging: childWhenDragging,
        child: w,
      );
    }

    return DragTarget<_EditDragData>(
      onWillAcceptWithDetails: (d) => !d.data.widgetIds.contains(id),
      onAcceptWithDetails: (details) {
        if (details.data.hidden) {
          visibility.showItemsBefore(
            preset: preset,
            widgetIds: details.data.widgetIds,
            targetId: id,
          );
        } else {
          visibility.moveItemsBefore(
            preset: preset,
            widgetIds: details.data.widgetIds,
            targetId: id,
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isTargeted = candidateData.isNotEmpty;
        return buildDraggable(
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: isTargeted
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _GroupedHomeWidgetPreviewCard extends StatelessWidget {
  const _GroupedHomeWidgetPreviewCard({
    required this.widgetIds,
    required this.preset,
    required this.visibility,
    this.dragging = false,
  });

  final List<HomeWidgetId> widgetIds;
  final HomeLayoutPreset preset;
  final CustomizeHomeWidgetNotifier visibility;
  final bool dragging;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: _previewHeight(widgetIds.first),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
        boxShadow: dragging
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: _GroupedHomeWidgetPart(
              widgetId: widgetIds[0],
              preset: preset,
              visibility: visibility,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => visibility.splitBefore(
                    preset: preset,
                    widgetId: widgetIds[1].id,
                  ),
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.call_split_rounded, size: 18),
                  tooltip: 'Separate',
                ),
                const Icon(Icons.drag_indicator_rounded, size: 18),
              ],
            ),
          ),
          Expanded(
            child: _GroupedHomeWidgetPart(
              widgetId: widgetIds[1],
              preset: preset,
              visibility: visibility,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedHomeWidgetPart extends StatelessWidget {
  const _GroupedHomeWidgetPart({
    required this.widgetId,
    required this.preset,
    required this.visibility,
  });

  final HomeWidgetId widgetId;
  final HomeLayoutPreset preset;
  final CustomizeHomeWidgetNotifier visibility;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widgetId.label(context),
              style: theme.textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () =>
                visibility.hide(preset: preset, widgetId: widgetId.id),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.visibility_off_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _HomeWidgetPreviewCard extends StatelessWidget {
  const _HomeWidgetPreviewCard({
    required this.widgetId,
    required this.preset,
    required this.visibility,
    required this.hidden,
    this.dragging = false,
    this.showMergeButton = false,
  });

  final HomeWidgetId widgetId;
  final HomeLayoutPreset preset;
  final CustomizeHomeWidgetNotifier visibility;
  final bool hidden;
  final bool dragging;
  final bool showMergeButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: hidden ? 0.55 : 1,
      child: Container(
        height: _previewHeight(widgetId),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: dragging
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widgetId.label(context),
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      visibility.toggle(preset: preset, widgetId: widgetId.id),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    hidden
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 18,
                  ),
                ),
                if (showMergeButton)
                  _MergeMenuButton(
                    sourceId: widgetId.id,
                    preset: preset,
                    visibility: visibility,
                  ),
                const Icon(Icons.drag_indicator_rounded, size: 18),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MergeMenuButton extends StatelessWidget {
  const _MergeMenuButton({
    required this.sourceId,
    required this.preset,
    required this.visibility,
  });

  final String sourceId;
  final HomeLayoutPreset preset;
  final CustomizeHomeWidgetNotifier visibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = visibility.layoutFor(preset);
    final candidates = layout
        .allIds()
        .where((id) => id != sourceId && compactHomeWidgetIds.contains(id))
        .toList();

    return MenuAnchor(
      builder: (context, controller, child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          visualDensity: VisualDensity.compact,
          tooltip: AppLocalizations.of(context)!.homeCustomizeMergeWith,
          icon: Icon(
            Icons.merge_type_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
      },
      menuChildren: candidates.isEmpty
          ? [
              MenuItemButton(
                child: Text(
                  AppLocalizations.of(context)!.homeCustomizeNoMergeTargets,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ]
          : candidates.map((id) {
              final widgetId = HomeWidgetId.fromId(id);
              final label = widgetId?.label(context) ?? id;
              return MenuItemButton(
                onPressed: () {
                  visibility.mergeItems(
                    preset: preset,
                    firstWidgetId: sourceId,
                    secondWidgetId: id,
                  );
                },
                child: Text(label),
              );
            }).toList(),
    );
  }
}

double _previewWidthForPreset(HomeLayoutPreset preset) {
  switch (preset) {
    case HomeLayoutPreset.compact:
      return 320;
    case HomeLayoutPreset.medium:
      return 240;
    case HomeLayoutPreset.large:
      return 200;
  }
}

double _previewHeight(HomeWidgetId id) {
  switch (id) {
    case HomeWidgetId.upload:
    case HomeWidgetId.download:
    case HomeWidgetId.memory:
    case HomeWidgetId.connections:
      return 110;
    case HomeWidgetId.route:
    case HomeWidgetId.inbound:
    case HomeWidgetId.proxySelector:
      return 220;
    case HomeWidgetId.nodes:
      return 200;
    case HomeWidgetId.nodesHelper:
      return 260;
    default:
      return 140;
  }
}

// subscription is not included
const List<String> homeWidgetIds = [
  'upload',
  'download',
  'memory',
  'connections',
  'route',
  'nodes',
  'proxySelector',
  'nodesHelper',
  'inbound',
];

const Set<String> compactHomeWidgetIds = {
  'upload',
  'download',
  'memory',
  'connections',
};

enum HomeLayoutPreset {
  compact('compact', 1),
  medium('medium', 2),
  large('large', 3);

  const HomeLayoutPreset(this.storageKey, this.columns);

  final String storageKey;
  final int columns;
}

extension HomeLayoutPresetSizeX on Size {
  HomeLayoutPreset get homeLayoutPreset {
    if (isCompact) return HomeLayoutPreset.compact;
    if (!isSuperLarge) return HomeLayoutPreset.medium;
    return HomeLayoutPreset.large;
  }
}

Map<int, List<List<String>>> defaultHomeWidgetOrder(HomeLayoutPreset preset) {
  switch (preset) {
    case HomeLayoutPreset.compact:
      return {
        0: [
          ['upload', 'download'],
          ['memory', 'connections'],
          ['nodes'],
          ['nodesHelper'],
          ['route'],
          ['proxySelector'],
          ['inbound'],
        ],
      };
    case HomeLayoutPreset.medium:
      return {
        0: [
          ['upload', 'download'],
          ['route'],
          ['proxySelector'],
          ['inbound'],
        ],
        1: [
          ['memory', 'connections'],
          ['nodes'],
          ['nodesHelper'],
        ],
      };
    case HomeLayoutPreset.large:
      return {
        0: [
          ['upload', 'download'],
          ['route'],
          ['inbound'],
        ],
        1: [
          ['memory', 'connections'],
          ['proxySelector'],
        ],
        2: [
          ['nodes'],
          ['nodesHelper'],
        ],
      };
  }
}

HomeLayout defaultHomeWidgetRows(HomeLayoutPreset preset) {
  return HomeLayout(defaultHomeWidgetOrder(preset));
}

/// Notifier for home widget visibility. When [hide] is called, updates prefs
/// and notifies so [StandardHomePage] can rebuild.
class CustomizeHomeWidgetNotifier extends ChangeNotifier {
  CustomizeHomeWidgetNotifier(this._repo) {
    _repo.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _repo.removeListener(notifyListeners);
    super.dispose();
  }

  final HomeLayoutRepo _repo;

  HomeLayout layoutFor(HomeLayoutPreset preset) {
    return _repo.getHomeWidgets(preset);
  }

  void setLayout({
    required HomeLayoutPreset preset,
    required HomeLayout layout,
  }) {
    _repo.setHomeWidgets(preset, layout);
  }

  List<List<String>> rowsFor(HomeLayoutPreset preset) {
    final layout = layoutFor(preset);
    final columns = List.generate(
      preset.columns,
      (index) => layout._layout[index] ?? const <List<String>>[],
    );
    final rowCount = columns.fold<int>(
      0,
      (maxRows, column) => max(maxRows, column.length),
    );
    final rows = <List<String>>[];
    for (var rowIndex = 0; rowIndex < rowCount; rowIndex++) {
      for (var columnIndex = 0; columnIndex < preset.columns; columnIndex++) {
        if (rowIndex < columns[columnIndex].length) {
          rows.add(List<String>.from(columns[columnIndex][rowIndex]));
        }
      }
    }
    return rows;
  }

  Set<String> hiddenIdsFor(HomeLayoutPreset preset) {
    final layout = layoutFor(preset);
    final all = layout.allIds();
    final set = <String>{};
    for (final id in homeWidgetIds) {
      if (!all.contains(id)) {
        set.add(id);
      }
    }
    return set;
  }

  void hide({required HomeLayoutPreset preset, required String widgetId}) {
    final rows = rowsFor(preset).map((row) => [...row]).toList();
    final movedRows = _extractRows(rows, [widgetId]);
    if (movedRows.isEmpty) return;
    _saveRows(preset, rows);
  }

  void show({required HomeLayoutPreset preset, required String widgetId}) {
    if (!hiddenIdsFor(preset).contains(widgetId)) return;
    showItemsAtStart(preset: preset, widgetIds: [widgetId]);
  }

  void toggle({required HomeLayoutPreset preset, required String widgetId}) {
    if (hiddenIdsFor(preset).contains(widgetId)) {
      show(preset: preset, widgetId: widgetId);
    } else {
      hide(preset: preset, widgetId: widgetId);
    }
  }

  void moveBefore({
    required HomeLayoutPreset preset,
    required String widgetId,
    required String targetId,
  }) {
    moveItemsBefore(preset: preset, widgetIds: [widgetId], targetId: targetId);
  }

  void showAndMoveBefore({
    required HomeLayoutPreset preset,
    required String widgetId,
    required String targetId,
  }) {
    showItemsBefore(preset: preset, widgetIds: [widgetId], targetId: targetId);
  }

  void showAtStart({
    required HomeLayoutPreset preset,
    required String widgetId,
  }) {
    showItemsAtStart(preset: preset, widgetIds: [widgetId]);
  }

  void moveItemsBefore({
    required HomeLayoutPreset preset,
    required List<String> widgetIds,
    required String targetId,
  }) {
    if (widgetIds.contains(targetId)) return;
    final rows = rowsFor(preset).map((row) => [...row]).toList();
    final sourceLocation = _findAnyWidget(rows, widgetIds);
    final targetLocation = _findWidget(rows, targetId);
    if (sourceLocation == null || targetLocation == null) return;
    if (sourceLocation.rowIndex == targetLocation.rowIndex) return;
    final sourceRow = rows[sourceLocation.rowIndex];
    final targetRow = rows[targetLocation.rowIndex];
    rows[sourceLocation.rowIndex] = [...targetRow];
    rows[targetLocation.rowIndex] = [...sourceRow];
    _saveRows(preset, rows);
  }

  void showItemsBefore({
    required HomeLayoutPreset preset,
    required List<String> widgetIds,
    required String targetId,
  }) {
    if (widgetIds.contains(targetId)) return;
    final rows = rowsFor(preset).map((row) => [...row]).toList();
    final movedRows = _takeOrCreateRows(rows, widgetIds);
    if (movedRows.isEmpty) return;
    final targetLocation = _findWidget(rows, targetId);
    if (targetLocation == null) return;
    _insertRowsBefore(rows, movedRows, targetLocation);
    _saveRows(preset, rows);
  }

  void showItemsAtStart({
    required HomeLayoutPreset preset,
    required List<String> widgetIds,
  }) {
    final rows = rowsFor(preset).map((row) => [...row]).toList();
    final movedRows = _takeOrCreateRows(rows, widgetIds);
    if (movedRows.isEmpty) return;
    rows.insertAll(0, movedRows);
    _saveRows(preset, rows);
  }

  void splitBefore({
    required HomeLayoutPreset preset,
    required String widgetId,
  }) {
    final rows = rowsFor(preset).map((row) => [...row]).toList();
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.length == 2 && row[1] == widgetId) {
        rows
          ..removeAt(i)
          ..insert(i, [row[1]])
          ..insert(i, [row[0]]);
        _saveRows(preset, rows);
        return;
      }
    }
  }

  void mergeItems({
    required HomeLayoutPreset preset,
    required String firstWidgetId,
    required String secondWidgetId,
  }) {
    if (firstWidgetId == secondWidgetId) return;
    if (!compactHomeWidgetIds.contains(firstWidgetId) ||
        !compactHomeWidgetIds.contains(secondWidgetId)) {
      return;
    }

    final rows = rowsFor(preset).map((row) => [...row]).toList();
    final firstLocation = _findWidget(rows, firstWidgetId);
    final secondLocation = _findWidget(rows, secondWidgetId);
    if (firstLocation == null || secondLocation == null) return;
    if (rows[firstLocation.rowIndex].length != 1 ||
        rows[secondLocation.rowIndex].length != 1) {
      return;
    }

    final firstIndex = firstLocation.rowIndex;
    final secondIndex = secondLocation.rowIndex;
    final mergedRow = [firstWidgetId, secondWidgetId];

    if (firstIndex < secondIndex) {
      rows.removeAt(secondIndex);
      rows[firstIndex] = mergedRow;
    } else {
      rows.removeAt(firstIndex);
      rows[secondIndex] = mergedRow;
    }

    _saveRows(preset, rows);
  }

  void resetLayout(HomeLayoutPreset preset) {
    _repo.clearHomeWidgets(preset);
  }

  void _saveRows(HomeLayoutPreset preset, List<List<String>> rows) {
    final columns = <int, List<List<String>>>{};
    for (var i = 0; i < preset.columns; i++) {
      columns[i] = <List<String>>[];
    }
    for (var i = 0; i < rows.length; i++) {
      columns[i % preset.columns]!.add(List<String>.from(rows[i]));
    }
    final layout = HomeLayout(columns);
    _repo.setHomeWidgets(preset, layout);
  }

  List<List<String>> _takeOrCreateRows(
    List<List<String>> rows,
    List<String> widgetIds,
  ) {
    final movedRows = _extractRows(rows, widgetIds);
    final movedIds = movedRows.expand((row) => row).toSet();
    for (final widgetId in widgetIds) {
      if (!movedIds.contains(widgetId) && homeWidgetIds.contains(widgetId)) {
        movedRows.add([widgetId]);
      }
    }
    return movedRows;
  }

  List<List<String>> _extractRows(
    List<List<String>> rows,
    List<String> widgetIds,
  ) {
    final widgetIdSet = widgetIds.toSet();
    final movedRows = <List<String>>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final moved = row.where(widgetIdSet.contains).toList();
      if (moved.isNotEmpty) {
        movedRows.add(moved);
      }
      rows[i] = row.where((id) => !widgetIdSet.contains(id)).toList();
    }
    rows.removeWhere((row) => row.isEmpty);
    return movedRows;
  }

  _WidgetLocation? _findWidget(List<List<String>> rows, String widgetId) {
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final itemIndex = rows[rowIndex].indexOf(widgetId);
      if (itemIndex >= 0) {
        return _WidgetLocation(rowIndex, itemIndex);
      }
    }
    return null;
  }

  _WidgetLocation? _findAnyWidget(
    List<List<String>> rows,
    List<String> widgetIds,
  ) {
    for (final widgetId in widgetIds) {
      final location = _findWidget(rows, widgetId);
      if (location != null) return location;
    }
    return null;
  }

  void _insertRowsBefore(
    List<List<String>> rows,
    List<List<String>> movedRows,
    _WidgetLocation target,
  ) {
    for (var i = 0; i < movedRows.length; i++) {
      _insertRowBefore(rows, movedRows[i], target.rowIndex + i);
    }
  }

  void _insertRowBefore(
    List<List<String>> rows,
    List<String> movedRow,
    int targetRowIndex,
  ) {
    final targetRow = rows[targetRowIndex];
    if (movedRow.length == 2) {
      rows.insert(targetRowIndex, movedRow);
      return;
    }
    final widgetId = movedRow.single;
    if (targetRow.length != 1) {
      rows.insert(targetRowIndex, [widgetId]);
      return;
    }
    final targetId = targetRow.single;
    if (targetRow.length == 1 &&
        compactHomeWidgetIds.contains(widgetId) &&
        compactHomeWidgetIds.contains(targetId)) {
      rows[targetRowIndex] = [widgetId, targetId];
      return;
    }
    rows.insert(targetRowIndex, [widgetId]);
  }

  List<List<String>> _normalizeRows(List<List<String>> rows) {
    final normalized = <List<String>>[];
    final seen = <String>{};
    for (final row in rows) {
      final valid = <String>[];
      for (final id in row) {
        if (homeWidgetIds.contains(id) && seen.add(id)) {
          valid.add(id);
        }
      }
      if (valid.isEmpty) continue;
      if (valid.length == 2 && valid.every(compactHomeWidgetIds.contains)) {
        normalized.add(valid);
      } else {
        for (final id in valid) {
          normalized.add([id]);
        }
      }
    }
    for (final id in homeWidgetIds) {
      if (seen.add(id)) {
        normalized.add([id]);
      }
    }
    return normalized;
  }
}

class _WidgetLocation {
  const _WidgetLocation(this.rowIndex, this.itemIndex);

  final int rowIndex;
  final int itemIndex;
}
