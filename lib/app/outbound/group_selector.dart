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

part of 'outbound_page.dart';

String groupNametoLocalizedName(BuildContext context, String name) {
  switch (name) {
    case defaultGroupName:
      return AppLocalizations.of(context)!.default0;
    case freeGroupName:
      return AppLocalizations.of(context)!.free;
    case 'all':
      return AppLocalizations.of(context)!.all;
    default:
      return name;
  }
}

class GroupSelector extends StatefulWidget {
  const GroupSelector({super.key});

  @override
  State<GroupSelector> createState() => _GroupSelectorState();
}

class _GroupSelectorState extends State<GroupSelector> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child:
          BlocSelector<
            OutboundBloc,
            OutboundState,
            ({NodeGroup? selected, List<NodeGroup> groups})
          >(
            selector: (state) {
              return (selected: state.selected, groups: state.groups);
            },
            builder: (ctx, r) {
              if (Provider.of<MyLayout>(context).isCompact) {
                return DropdownMenu<NodeGroup>(
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
                  initialSelection: r.selected ?? allGroup,
                  inputDecorationTheme: InputDecorationTheme(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  menuStyle: MenuStyle(
                    maximumSize: WidgetStateProperty.all(
                      const Size.fromWidth(100),
                    ),
                  ),
                  dropdownMenuEntries: [allGroup, ...r.groups].map((e) {
                    return DropdownMenuEntry(
                      value: e,
                      label: groupNametoLocalizedName(context, e.name),
                    );
                  }).toList(),
                  onSelected: (value) => ctx.read<OutboundBloc>().add(
                    SelectedGroupChangeEvent(value),
                  ),
                );
              }
              // print('2222222${r.selected?.name}');

              return Listener(
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
                child: ListView(
                  controller: _scrollController,
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  children: r.groups.map<Widget>((e) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: MenuAnchor(
                        menuChildren: [
                          MenuItemButton(
                            leadingIcon: const Icon(Icons.arrow_upward),
                            onPressed: () {
                              ctx.read<OutboundBloc>().add(
                                e is MySubscription
                                    ? SubscriptionPlaceOnTopEvent(e)
                                    : OutboundHandlerGroupPlaceOnTopEvent(
                                        e as OutboundHandlerGroup,
                                      ),
                              );
                            },
                            child: Text(
                              e.placeOnTop
                                  ? AppLocalizations.of(context)!.stopPlaceOnTop
                                  : AppLocalizations.of(context)!.placeOnTop,
                            ),
                          ),
                          if (e.name != defaultGroupName)
                            Column(
                              children: [
                                const Divider(),
                                MenuItemButton(
                                  leadingIcon: const Icon(Icons.delete),
                                  onPressed: () {
                                    ctx.read<OutboundBloc>().add(
                                      e is MySubscription
                                          ? SubscriptionDeleteEvent(e)
                                          : DeleteGroupEvent(
                                              e as OutboundHandlerGroup,
                                            ),
                                    );
                                  },
                                  child: Text(
                                    e is MySubscription
                                        ? AppLocalizations.of(context)!.delete
                                        : AppLocalizations.of(
                                            context,
                                          )!.deleteGroup,
                                  ),
                                ),
                                if (e is OutboundHandlerGroup)
                                  MenuItemButton(
                                    leadingIcon: const Icon(
                                      Icons.delete_forever,
                                    ),
                                    onPressed: () {
                                      ctx.read<OutboundBloc>().add(
                                        DeleteGroupAndNodesEvent(e),
                                      );
                                    },
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.deleteGroupAndNodes,
                                    ),
                                  ),
                              ],
                            ),
                        ],
                        builder: (context, controller, child) {
                          return GestureDetector(
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
                            child: child!,
                          );
                        },
                        child: FilterChip(
                          visualDensity: (Platform.isAndroid || Platform.isIOS)
                              ? VisualDensity.compact
                              : null,
                          label: Text(
                            groupNametoLocalizedName(context, e.name),
                          ),
                          selected: r.selected?.name == e.name,
                          onSelected: (bool v) {
                            print('onSelected: $v');
                            ctx.read<OutboundBloc>().add(
                              SelectedGroupChangeEvent(v ? e : null),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
    );
  }
}
