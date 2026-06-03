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

import 'package:ads/ad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vx/app/blocs/inbound.dart';
import 'package:vx/app/home/home.dart';
import 'package:vx/app/routing/default.dart';
import 'package:vx/app/routing/selector_being_used.dart';
import 'package:vx/app/routing/selector_test_fields_form.dart';
import 'package:vx/app/routing/routing_page.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/app/routing/repo.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:tm/protos/vx/router/router.pb.dart';
import 'package:tm/protos/vx/router/router.pbenum.dart';
import 'package:vx/app/outbound/outbounds_bloc.dart';
import 'package:vx/app/outbound/outbound_repo.dart';
import 'package:vx/app/blocs/proxy_selector/proxy_selector_bloc.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/common/common.dart';
import 'package:vx/data/database.dart';
import 'package:vx/main.dart';
import 'package:vx/app/routing/selector_widget.dart';
import 'package:vx/theme.dart';
import 'package:vx/widgets/info_widget.dart';
import 'package:vx/widgets/pro_promotion.dart';

enum ProxySelectorManualNodeSelectionMode {
  single,
  multiple;

  String toLocalString(BuildContext ctx) {
    switch (this) {
      case ProxySelectorManualNodeSelectionMode.single:
        return AppLocalizations.of(ctx)!.singleNode;
      case ProxySelectorManualNodeSelectionMode.multiple:
        return AppLocalizations.of(ctx)!.multipleNodes;
    }
  }
}

class ControlDrawer extends StatelessWidget {
  const ControlDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      backgroundColor: Platform.isWindows
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.surface,
      children: const [Padding(padding: EdgeInsets.all(10), child: Control())],
    );
  }
}

class Control extends StatelessWidget {
  const Control({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Route(),
        if (desktopPlatforms) const Inbound(),
        const ProxySelector(),
        const FakeDns(),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return InfoDialog(
                    children: [
                      AppLocalizations.of(context)!.routeDesc,
                      if (desktopPlatforms)
                        AppLocalizations.of(context)!.inboundDesc1,
                      if (desktopPlatforms)
                        AppLocalizations.of(context)!.inboundDesc2,
                      AppLocalizations.of(context)!.fakeDnsDesc,
                      AppLocalizations.of(context)!.selectorDesc1,
                      AppLocalizations.of(context)!.selectorDesc2,
                      AppLocalizations.of(context)!.balanceStrategyDesc,
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.help_outline_rounded),
          ),
        ),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state.proUser) {
              return const SizedBox.shrink();
            }
            return const BannerAdWidget();
          },
        ),
      ],
    );
  }
}

class Route extends StatefulWidget {
  const Route({super.key});

  @override
  State<Route> createState() => _RouteState();
}

class _RouteState extends State<Route> {
  List<CustomRouteMode> _configs = [];

  @override
  void initState() {
    super.initState();
    Provider.of<RouteRepo>(
      context,
      listen: false,
    ).getAllCustomRouteModes().then((value) {
      if (value.isNotEmpty) {
        setState(() {
          _configs = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.routing,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(5),
            BlocSelector<ProxySelectorBloc, ProxySelectorState, String?>(
              selector: (state) => state.routeMode,
              builder: (context, routeMode) {
                return Wrap(
                  crossAxisAlignment: WrapCrossAlignment.start,
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    ..._configs.map(
                      (e) => ChoiceChip(
                        tooltip: isDefaultRouteMode(e.name, context)
                            ? DefaultRouteMode.values
                                  .firstWhereOrNull((defaultMode) {
                                    return defaultMode.toLocalString(
                                          AppLocalizations.of(context)!,
                                        ) ==
                                        e.name;
                                  })
                                  ?.description(context)
                            : null,
                        label: Text(e.name),
                        selected: (routeMode == e.name),
                        onSelected: (value) {
                          if (routeMode == e.name) {
                            return;
                          }
                          context.read<ProxySelectorBloc>().add(
                            RoutingModeSelectionChangeEvent(e),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Inbound extends StatelessWidget {
  const Inbound({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        child: BlocBuilder<InboundCubit, InboundMode>(
          builder: (ctx, mode) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.inbound,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(5),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    ChoiceChip(
                      label: Text(InboundMode.tun.toLocalString(context)),
                      selected: mode == InboundMode.tun,
                      onSelected: (value) => context
                          .read<InboundCubit>()
                          .setInboundMode(InboundMode.tun),
                    ),
                    ChoiceChip(
                      label: Text(
                        InboundMode.systemProxy.toLocalString(context),
                      ),
                      selected: mode == InboundMode.systemProxy,
                      onSelected: (value) => context
                          .read<InboundCubit>()
                          .setInboundMode(InboundMode.systemProxy),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ProxySelector extends StatelessWidget {
  const ProxySelector({super.key, this.home = false});
  final bool home;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProxySelectorBloc, ProxySelectorState, (bool?, bool)>(
      selector: (state) =>
          (state.showProxySelector, state.proxySelectorEnabled),
      builder: (context, t2) {
        if (t2.$1 ?? false) {
          if (t2.$2) {
            return home
                ? const ProxySelectorHome()
                : const DefaultProxySelectorControl();
          }
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              showProPromotionDialog(context);
            },
            child: Stack(
              children: [
                Opacity(
                  opacity: 1,
                  child: IgnorePointer(
                    child: home
                        ? const ProxySelectorHome()
                        : const DefaultProxySelectorControl(showEdit: false),
                  ),
                ),
                const Positioned(
                  top: 10,
                  right: 10,
                  child: Icon(Icons.stars_rounded, color: XBlue),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class DefaultProxySelector extends StatelessWidget {
  const DefaultProxySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProxySelectorBloc, ProxySelectorState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.nodeSelection,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(5),
            Row(
              children: [
                ChoiceChip(
                  label: Text(ProxySelectorMode.auto.toLocalString(context)),
                  selected: state.proxySelectorMode == ProxySelectorMode.auto,
                  onSelected: (value) {
                    context.read<ProxySelectorBloc>().add(
                      const ProxySelectorModeChangeEvent(
                        ProxySelectorMode.auto,
                      ),
                    );
                  },
                ),
                const Gap(5),
                ChoiceChip(
                  label: Text(ProxySelectorMode.manual.toLocalString(context)),
                  selected: state.proxySelectorMode == ProxySelectorMode.manual,
                  onSelected: (value) {
                    context.read<ProxySelectorBloc>().add(
                      const ProxySelectorModeChangeEvent(
                        ProxySelectorMode.manual,
                      ),
                    );
                    context.read<OutboundBloc>().add(
                      const OutboundModeSwitchEvent(ProxySelectorMode.manual),
                    );
                  },
                ),
              ],
            ),
            const Gap(10),
            if (state.proxySelectorMode == ProxySelectorMode.manual)
              const ManualModeCard(),
            if (state.proxySelectorMode == ProxySelectorMode.auto &&
                state.autoNodeSetting != null)
              SelectorConfigWidget(
                config: state.autoNodeSetting!,
                onFilterChange: () {
                  context.read<ProxySelectorBloc>().add(
                    const AutoNodeSelectorConfigChangeEvent(
                      filterLandHandlers: true,
                    ),
                  );
                },
                onBalanceStrategyChange: () {
                  context.read<ProxySelectorBloc>().add(
                    const AutoNodeSelectorConfigChangeEvent(
                      balancingStragegy: true,
                    ),
                  );
                },
                onStrategyOrLandHandlersChange: () {
                  context.read<ProxySelectorBloc>().add(
                    const AutoNodeSelectorConfigChangeEvent(
                      selectorStrategyOrLandHandlers: true,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class DefaultProxySelectorControl extends StatefulWidget {
  const DefaultProxySelectorControl({
    super.key,
    this.showName = true,
    this.showEdit = true,
  });

  final bool showName;
  final bool showEdit;

  @override
  State<DefaultProxySelectorControl> createState() =>
      _DefaultProxySelectorControlState();
}

class _DefaultProxySelectorControlState
    extends State<DefaultProxySelectorControl> {
  late final SelectorBeingUsedCubit _proxySelectorBeingUsedCubit;

  Future<void> _editDefaultProxySelector() async {
    final state = context.read<ProxySelectorBloc>().state;
    final config = state.autoNodeSetting;
    if (config == null) return;
    final edited = await showSelectorTestFieldsForm(context, config);
    if (edited == null || !mounted) return;
    context.read<ProxySelectorBloc>().add(
      TestParametersChangeEvent(config: edited),
    );
  }

  @override
  void initState() {
    super.initState();
    _proxySelectorBeingUsedCubit = SelectorBeingUsedCubit(
      selectorTag: defaultProxySelectorTag,
      xController: context.read<XController>(),
      outboundRepo: context.read<OutboundRepo>(),
      clearWhenSelectorEmpty: true,
    );
  }

  @override
  void dispose() {
    _proxySelectorBeingUsedCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showName)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.proxy,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const Gap(5),
                        BlocProvider.value(
                          value: _proxySelectorBeingUsedCubit,
                          child: const SelectorBeingUsedView(),
                        ),
                      ],
                    ),
                  ),
                if (!widget.showName)
                  BlocProvider.value(
                    value: _proxySelectorBeingUsedCubit,
                    child: const Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: SelectorBeingUsedView(),
                    ),
                  ),
                const DefaultProxySelector(),
              ],
            ),
          ),
          if (widget.showEdit)
            Positioned(
              right: 5,
              top: 5,
              child: MenuAnchor(
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.edit_outlined),
                    onPressed: _editDefaultProxySelector,
                    child: const Text('Edit'),
                  ),
                ],
                builder: (context, controller, child) => IconButton(
                  onPressed: () {
                    controller.isOpen ? controller.close() : controller.open();
                  },
                  icon: const Icon(Icons.more_vert),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
class ManualModeCard extends StatelessWidget {
  const ManualModeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      ProxySelectorBloc,
      ProxySelectorState,
      ManualNodeSetting
    >(
      selector: (state) => state.manualNodeSetting,
      builder: (context, r) {
        logger.d("manualNodeSetting: $r");
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.manualNodeMode,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(5),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                ChoiceChip(
                  label: Text(
                    ProxySelectorManualNodeSelectionMode.single.toLocalString(
                      context,
                    ),
                    // style: Theme.of(context).textTheme.bodySmall,
                  ),
                  selected:
                      r.nodeMode == ProxySelectorManualNodeSelectionMode.single,
                  onSelected: (value) {
                    context.read<ProxySelectorBloc>().add(
                      const ManualSelectionModeChangeEvent(
                        ProxySelectorManualNodeSelectionMode.single,
                      ),
                    );
                    context.read<OutboundBloc>().add(
                      const ManuualSingleSelectionEvent(),
                    );
                  },
                ),
                ChoiceChip(
                  label: Text(
                    ProxySelectorManualNodeSelectionMode.multiple.toLocalString(
                      context,
                    ),
                    // style: Theme.of(context).textTheme.bodySmall,
                  ),
                  selected:
                      r.nodeMode ==
                      ProxySelectorManualNodeSelectionMode.multiple,
                  onSelected: (value) {
                    context.read<ProxySelectorBloc>().add(
                      const ManualSelectionModeChangeEvent(
                        ProxySelectorManualNodeSelectionMode.multiple,
                      ),
                    );
                  },
                ),
              ],
            ),
            if (r.nodeMode == ProxySelectorManualNodeSelectionMode.multiple)
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
                            r.balanceStrategy ==
                            SelectorConfig_BalanceStrategy.RANDOM,
                        onSelected: (value) {
                          context.read<ProxySelectorBloc>().add(
                            const ManualNodeBalanceStrategyChangeEvent(
                              SelectorConfig_BalanceStrategy.RANDOM,
                            ),
                          );
                        },
                      ),
                      const Gap(5),
                      ChoiceChip(
                        label: Text(
                          SelectorConfig_BalanceStrategy.MEMORY.toLocalString(
                            context,
                          ),
                          // style: Theme.of(context).textTheme.bodySmall,
                        ),
                        selected:
                            r.balanceStrategy ==
                            SelectorConfig_BalanceStrategy.MEMORY,
                        onSelected: (value) {
                          context.read<ProxySelectorBloc>().add(
                            const ManualNodeBalanceStrategyChangeEvent(
                              SelectorConfig_BalanceStrategy.MEMORY,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            const Gap(10),
            Tooltip(
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
              landHandlers: r.landHandlers,
              onAdd: (handlerId) {
                context.read<ProxySelectorBloc>().add(
                  const ManualModeLandHandlersChangeEvent(
                    // [...r.landHandlers, handlerId]
                  ),
                );
              },
              onRemove: (handlerId) {
                context.read<ProxySelectorBloc>().add(
                  const ManualModeLandHandlersChangeEvent(
                    // r.landHandlers.where((e) => e != handlerId).toList()
                  ),
                );
              },
              onReplace: (p0, p1) {
                context.read<ProxySelectorBloc>().add(
                  const ManualModeLandHandlersChangeEvent(
                    // r.landHandlers.map((e) => e == p0 ? p1 : e).toList()
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class FakeDns extends StatelessWidget {
  const FakeDns({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InboundCubit, InboundMode>(
      builder: (context, value) {
        return value == InboundMode.tun
            ? Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Text(
                        'Fake DNS',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const Expanded(child: SizedBox()),
                      Transform.scale(
                        scale: 0.8,
                        child: StatefulBuilder(
                          builder: (ctx, setState) {
                            return Switch(
                              value: context.read<SharedPreferences>().fakeDns,
                              onChanged: (value) async {
                                setState(() {
                                  context.read<SharedPreferences>().setFakeDns(
                                    value,
                                  );
                                });
                                try {
                                  await context.read<XController>().setFakeDns(
                                    value,
                                  );
                                } catch (e) {
                                  logger.e('setFakeDns error', error: e);
                                  snack(
                                    rootLocalizations()?.failedToChangeFakeDns,
                                  );
                                  // await reportError(e, StackTrace.current);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }
}
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:gap/gap.dart';
// import 'package:vx/l10n/app_localizations.dart';
// import 'package:tm/protos/vx/router/router.pbenum.dart';
// import 'package:vx/app/log/log_bloc.dart';
// import 'package:vx/app/outbound/outbounds_bloc.dart';
// import 'package:vx/app/x_bloc.dart';
// import 'package:vx/common/common.dart';
// import 'package:vx/main.dart';
// import 'package:vx/theme.dart';

// enum ManualNodeSelectionMode {
//   single,
//   multiple;

//   String toLocalString(BuildContext ctx) {
//     switch (this) {
//       case ManualNodeSelectionMode.single:
//         return AppLocalizations.of(ctx)!.singleNode;
//       case ManualNodeSelectionMode.multiple:
//         return AppLocalizations.of(ctx)!.multipleNodes;
//     }
//   }
// }

// class ControlDrawer extends StatelessWidget {
//   const ControlDrawer({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return NavigationDrawer(
//       backgroundColor:
//           Platform.isWindows ? Theme.of(context).colorScheme.surface : null,
//       children: const [
//         Padding(
//           padding: EdgeInsets.all(20),
//           child: Control(),
//         )
//       ],
//     );
//   }
// }

// class Control extends StatelessWidget {
//   const Control({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Route(),
//         const Gap(10),
//         if (desktopPlatforms) const Inbound(),
//         const Gap(10),
//         const Outbound(),
//         const Gap(10),
//         const FakeDns()

//         // const Inbound(),
//         // Gap(10),
//       ],
//     );
//   }
// }

// class Route extends StatelessWidget {
//   const Route({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final bloc = context.read<XBloc>();
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           AppLocalizations.of(context)!.routing,
//           style: Theme.of(context).textTheme.labelLarge,
//         ),
//         const Gap(5),
//         BlocSelector<XBloc, XState, int>(
//             selector: (state) => state.routeMode.index,
//             builder: (context, routeModeIdx) {
//               return Wrap(
//                 crossAxisAlignment: WrapCrossAlignment.start,
//                 spacing: 5,
//                 runSpacing: 5,
//                 children: [
//                   ChoiceChip(
//                     label: Text(AppLocalizations.of(context)!.blackList),
//                     selected: routeModeIdx == RouteMode.black.index,
//                     onSelected: (value) => bloc
//                         .add(const RoutingModeChangeEvent(RouteMode.black)),
//                   ),
//                   ChoiceChip(
//                     label: Text(AppLocalizations.of(context)!.whileList),
//                     selected: routeModeIdx == RouteMode.white.index,
//                     onSelected: (value) => bloc
//                         .add(const RoutingModeChangeEvent(RouteMode.white)),
//                   ),
//                   ChoiceChip(
//                     label: Text(AppLocalizations.of(context)!.proxyAll),
//                     selected: routeModeIdx == RouteMode.proxyAll.index,
//                     onSelected: (value) => bloc.add(
//                         const RoutingModeChangeEvent(RouteMode.proxyAll)),
//                   ),
//                 ],
//               );
//             }),
//       ],
//     );
//   }
// }

// class Inbound extends StatelessWidget {
//   const Inbound({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocSelector<XBloc, XState, InboundMode>(
//         selector: (state) => state.inboundMode,
//         builder: (ctx, mode) {
//           return Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 AppLocalizations.of(context)!.inbound,
//                 style: Theme.of(context).textTheme.labelLarge,
//               ),
//               const Gap(5),
//               Wrap(
//                 spacing: 5,
//                 runSpacing: 5,
//                 children: [
//                   for (var i = 0; i < InboundMode.values.length; i++)
//                     ChoiceChip(
//                       label: Text(InboundMode.values[i].toLocalString(context)),
//                       selected: mode == InboundMode.values[i],
//                       onSelected: (InboundMode.values[i] == InboundMode.tun &&
//                               Platform.isWindows &&
//                               !isRunningAsAdmin)
//                           ? null
//                           : (value) => context.read<XBloc>().add(
//                               InboundModeChangeEvent(InboundMode.values[i])),
//                     ),
//                 ],
//               ),
//               if (Platform.isWindows && !isRunningAsAdmin)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 5),
//                   child: Text(AppLocalizations.of(context)!.tunNeedAdmin,
//                       style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                             color:
//                                 Theme.of(context).colorScheme.onSurfaceVariant,
//                           )),
//                 ),
//             ],
//           );
//         });
//   }
// }

// class Outbound extends StatelessWidget {
//   const Outbound({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocSelector<XBloc, XState, OutboundMode>(
//         selector: (state) => state.outboundMode,
//         builder: (context, r) {
//           return Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 AppLocalizations.of(context)!.nodeSelection,
//                 style: Theme.of(context).textTheme.labelLarge,
//               ),
//               const Gap(5),
//               Row(
//                 children: [
//                   ChoiceChip(
//                     label: Text(OutboundMode.auto.toLocalString(context)),
//                     selected: r == OutboundMode.auto,
//                     onSelected: (value) {
//                       context.read<XBloc>().add(
//                           const OutboundModeChangeEvent(OutboundMode.auto));
//                     },
//                   ),
//                   const Gap(5),
//                   ChoiceChip(
//                     label: Text(OutboundMode.manual.toLocalString(context)),
//                     selected: r == OutboundMode.manual,
//                     onSelected: (value) {
//                       context.read<XBloc>().add(
//                           const OutboundModeChangeEvent(OutboundMode.manual));
//                       context.read<OutboundBloc>().add(
//                           const OutboundModeSwitchEvent(OutboundMode.manual));
//                     },
//                   ),
//                 ],
//               ),
//               Gap(10),
//               if (r == OutboundMode.manual) const ManualModeCard(),
//               if (r == OutboundMode.auto) const AutoModeCard(),
//             ],
//           );
//         });
//   }
// }

// class AutoModeCard extends StatelessWidget {
//   const AutoModeCard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.zero,
//       elevation: 0,
//       color: Theme.of(context).colorScheme.surfaceContainer,
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: BlocSelector<XBloc, XState, AutoNodeSetting>(
//             selector: (state) => state.autoNodeSetting,
//             builder: (context, r) {
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(AppLocalizations.of(context)!.selectingStrategy,
//                       style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                             color:
//                                 Theme.of(context).colorScheme.onSurfaceVariant,
//                           )),
//                   const Gap(5),
//                   Row(
//                     children: [
//                       ChoiceChip(
//                         label: Text(
//                           SelectorConfig_SelectingStrategy.MOST_THROUGHPUT
//                               .toLocalString(context),
//                           style: Theme.of(context).textTheme.bodySmall,
//                         ),
//                         selected: r.selectingStrategy ==
//                             SelectorConfig_SelectingStrategy.MOST_THROUGHPUT,
//                         onSelected: (value) {
//                           context.read<XBloc>().add(
//                               AutoNodeSelectingStrategyChangeEvent(
//                                   SelectorConfig_SelectingStrategy
//                                       .MOST_THROUGHPUT));
//                         },
//                       ),
//                       const Gap(5),
//                       ChoiceChip(
//                         label: Text(
//                           SelectorConfig_SelectingStrategy.ALL_OK
//                               .toLocalString(context),
//                           style: Theme.of(context).textTheme.bodySmall,
//                         ),
//                         selected: r.selectingStrategy ==
//                             SelectorConfig_SelectingStrategy.ALL_OK,
//                         onSelected: (value) {
//                           context.read<XBloc>().add(
//                               AutoNodeSelectingStrategyChangeEvent(
//                                   SelectorConfig_SelectingStrategy.ALL_OK));
//                         },
//                       ),
//                     ],
//                   ),
//                   if (r.selectingStrategy ==
//                       SelectorConfig_SelectingStrategy.ALL_OK)
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Gap(10),
//                         Text(AppLocalizations.of(context)!.balanceStrategy,
//                             style: Theme.of(context)
//                                 .textTheme
//                                 .labelSmall
//                                 ?.copyWith(
//                                   color: Theme.of(context)
//                                       .colorScheme
//                                       .onSurfaceVariant,
//                                 )),
//                         const Gap(5),
//                         Row(
//                           children: [
//                             ChoiceChip(
//                               label: Text(
//                                 SelectorConfig_BalanceStrategy.RANDOM
//                                     .toLocalString(context),
//                                 style: Theme.of(context).textTheme.bodySmall,
//                               ),
//                               selected: r.balanceStrategy ==
//                                   SelectorConfig_BalanceStrategy.RANDOM,
//                               onSelected: (value) {
//                                 context.read<XBloc>().add(
//                                     AutoNodeBalanceStrategyChangeEvent(
//                                         SelectorConfig_BalanceStrategy.RANDOM));
//                               },
//                             ),
//                             const Gap(5),
//                             ChoiceChip(
//                               label: Text(
//                                 SelectorConfig_BalanceStrategy.MEMORY
//                                     .toLocalString(context),
//                                 style: Theme.of(context).textTheme.bodySmall,
//                               ),
//                               selected: r.balanceStrategy ==
//                                   SelectorConfig_BalanceStrategy.MEMORY,
//                               onSelected: (value) {
//                                 context.read<XBloc>().add(
//                                     AutoNodeBalanceStrategyChangeEvent(
//                                         SelectorConfig_BalanceStrategy.MEMORY));
//                               },
//                             ),
//                           ],
//                         )
//                       ],
//                     )
//                 ],
//               );
//             }),
//       ),
//     );
//   }
// }

// class ManualModeCard extends StatelessWidget {
//   const ManualModeCard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.zero,
//       elevation: 0,
//       color: Theme.of(context).colorScheme.surfaceContainer,
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: BlocSelector<XBloc, XState, ManualNodeSetting>(
//             selector: (state) => state.manualNodeSetting,
//             builder: (context, r) {
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     AppLocalizations.of(context)!.manualNodeMode,
//                     style: Theme.of(context).textTheme.labelSmall?.copyWith(
//                           color: Theme.of(context).colorScheme.onSurfaceVariant,
//                         ),
//                   ),
//                   const Gap(5),
//                   Row(
//                     children: [
//                       ChoiceChip(
//                         label: Text(
//                           ManualNodeSelectionMode.single.toLocalString(context),
//                           style: Theme.of(context).textTheme.bodySmall,
//                         ),
//                         selected: r.nodeMode == ManualNodeSelectionMode.single,
//                         onSelected: (value) {
//                           context.read<XBloc>().add(
//                               ManualSelectionModeChangeEvent(
//                                   ManualNodeSelectionMode.single));
//                           context
//                               .read<OutboundBloc>()
//                               .add(const ManuualSingleSelectionEvent());
//                         },
//                       ),
//                       const Gap(5),
//                       ChoiceChip(
//                         label: Text(
//                           ManualNodeSelectionMode.multiple
//                               .toLocalString(context),
//                           style: Theme.of(context).textTheme.bodySmall,
//                         ),
//                         selected:
//                             r.nodeMode == ManualNodeSelectionMode.multiple,
//                         onSelected: (value) {
//                           context.read<XBloc>().add(
//                               ManualSelectionModeChangeEvent(
//                                   ManualNodeSelectionMode.multiple));
//                         },
//                       ),
//                     ],
//                   ),
//                   if (r.nodeMode == ManualNodeSelectionMode.multiple)
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Gap(10),
//                         Text(
//                           AppLocalizations.of(context)!.balanceStrategy,
//                           style:
//                               Theme.of(context).textTheme.labelSmall?.copyWith(
//                                     color: Theme.of(context)
//                                         .colorScheme
//                                         .onSurfaceVariant,
//                                   ),
//                         ),
//                         const Gap(5),
//                         Row(
//                           children: [
//                             ChoiceChip(
//                               label: Text(
//                                 SelectorConfig_BalanceStrategy.RANDOM
//                                     .toLocalString(context),
//                                 style: Theme.of(context).textTheme.bodySmall,
//                               ),
//                               selected: r.balanceStrategy ==
//                                   SelectorConfig_BalanceStrategy.RANDOM,
//                               onSelected: (value) {
//                                 context.read<XBloc>().add(
//                                     ManualNodeBalanceStrategyChangeEvent(
//                                         SelectorConfig_BalanceStrategy.RANDOM));
//                               },
//                             ),
//                             const Gap(5),
//                             ChoiceChip(
//                               label: Text(
//                                 SelectorConfig_BalanceStrategy.MEMORY
//                                     .toLocalString(context),
//                                 style: Theme.of(context).textTheme.bodySmall,
//                               ),
//                               selected: r.balanceStrategy ==
//                                   SelectorConfig_BalanceStrategy.MEMORY,
//                               onSelected: (value) {
//                                 context.read<XBloc>().add(
//                                     ManualNodeBalanceStrategyChangeEvent(
//                                         SelectorConfig_BalanceStrategy.MEMORY));
//                               },
//                             ),
//                           ],
//                         ),
//                       ],
//                     )
//                 ],
//               );
//             }),
//       ),
//     );
//   }
// }

// extension on SelectorConfig_BalanceStrategy {
//   String toLocalString(BuildContext context) {
//     switch (this) {
//       case SelectorConfig_BalanceStrategy.RANDOM:
//         return AppLocalizations.of(context)!.random;
//       case SelectorConfig_BalanceStrategy.MEMORY:
//         return AppLocalizations.of(context)!.balanceStrategyMemory;
//       default:
//         return '';
//     }
//   }
// }

// extension on SelectorConfig_SelectingStrategy {
//   String toLocalString(BuildContext context) {
//     switch (this) {
//       case SelectorConfig_SelectingStrategy.MOST_THROUGHPUT:
//         return AppLocalizations.of(context)!.mostThroughput;
//       case SelectorConfig_SelectingStrategy.ALL_OK:
//         return AppLocalizations.of(context)!.allOk;
//       default:
//         return '';
//     }
//   }
// }

// class Log extends StatelessWidget {
//   const Log({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocSelector<LogBloc, LogState, bool>(
//         selector: (state) => state.enableLog,
//         builder: (context, logLevel) {
//           return Row(
//             children: [
//               Text(AppLocalizations.of(context)!.log,
//                   style: Theme.of(context).textTheme.labelLarge),
//               const Expanded(child: SizedBox()),
//               Switch(
//                 value: logLevel,
//                 onChanged: (value) =>
//                     context.read<LogBloc>().add(LogSwitchPressedEvent(value)),
//               ),
//             ],
//           );
//         });
//   }
// }

// class FakeDns extends StatelessWidget {
//   const FakeDns({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<XBloc, XState>(
//       builder: (context, value) {
//         return value.inboundMode == InboundMode.tun
//             ? Row(
//                 children: [
//                   Text('Fake DNS',
//                       style: Theme.of(context).textTheme.labelLarge?.copyWith(
//                             fontWeight: FontWeight.w400,
//                           )),
//                   const Expanded(child: SizedBox()),
//                   Transform.scale(
//                     scale: 0.8,
//                     child: Switch(
//                         value: value.fakeDns,
//                         onChanged: (value) =>
//                             context.read<XBloc>().add(SetFakeDnsEvent(value))),
//                   ),
//                 ],
//               )
//             : const SizedBox.shrink();
//       },
//     );
//   }
// }
