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

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tm/protos/vx/geo/geo.pb.dart';
import 'package:vx/app/routing/default.dart';
import 'package:vx/app/routing/mode_widget.dart';
import 'package:vx/app/routing/repo.dart';
import 'package:vx/app/routing/routing_page.dart';
import 'package:vx/app/routing/set_form.dart';
import 'package:vx/common/common.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/data/database.dart';
import 'package:vx/main.dart';
import 'package:vx/utils/geodata.dart';
import 'package:vx/widgets/form_dialog.dart';
import 'package:vx/widgets/info_widget.dart';
import 'package:vx/widgets/text_divider.dart';

class SetWidget extends StatefulWidget {
  const SetWidget({super.key, this.switchModeButton});
  final Widget? switchModeButton;
  @override
  State<SetWidget> createState() => _SetWidgetState();
}

class _SetWidgetState extends State<SetWidget>
    with AutomaticKeepAliveClientMixin<SetWidget> {
  RouteCategory _category = RouteCategory.domain;
  bool get showApp => desktopPlatforms || Platform.isAndroid;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 70),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                const Gap(5),
                MenuAnchor(
                  menuChildren: [
                    MenuItemButton(
                      leadingIcon: const Icon(Icons.add_rounded, size: 18),
                      onPressed: () async {
                        final k = GlobalKey();
                        final repo = context.read<SetRepo>();
                        final formData = await showMyAdaptiveDialog(
                          context,
                          ClashRuleSet(key: k),
                          title: AppLocalizations.of(
                            context,
                          )!.addDomainIpAppSet,
                          onSave: (p0) {
                            final formData =
                                (k.currentState as FormDataGetter).formData;
                            if (formData != null) {
                              context.pop(formData);
                            }
                          },
                        );
                        if (formData != null) {
                          final setName = formData.name;
                          final clashRuleUrls = formData.clashRuleUrls;
                          try {
                            await repo.addAppSet(
                              AppSet(
                                name: setName,
                                clashRuleUrls: clashRuleUrls,
                              ),
                            );
                            await repo.addAtomicDomainSet(
                              AtomicDomainSet(
                                useBloomFilter: false,
                                name: setName,
                                clashRuleUrls: clashRuleUrls,
                              ),
                            );
                            await repo.addAtomicIpSet(
                              AtomicIpSet(
                                name: setName,
                                inverse: false,
                                clashRuleUrls: clashRuleUrls,
                              ),
                            );
                            context
                                .read<GeoDataHelper>()
                                .makeGeoDataAvailable();
                          } catch (e) {
                            snack(e.toString());
                          }
                        }
                      },
                      child: Text(AppLocalizations.of(context)!.addSet),
                    ),
                    MenuItemButton(
                      leadingIcon: const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                      ),
                      onPressed: () async {
                        showDialog(
                          context: context,
                          builder: (context) => InfoDialog(
                            children: [
                              AppLocalizations.of(
                                context,
                              )!.greatSetDescription1,
                              AppLocalizations.of(
                                context,
                              )!.greatSetDescription2,
                              AppLocalizations.of(context)!.directAppSetDesc,
                            ],
                          ),
                        );
                      },
                      child: Text(AppLocalizations.of(context)!.info),
                    ),
                  ],
                  builder: (context, controller, child) {
                    return IconButton(
                      onPressed: () {
                        controller.open();
                      },
                      icon: const Icon(Icons.more_vert, size: 18),
                    );
                  },
                ),
                const Expanded(child: SizedBox()),
                widget.switchModeButton ?? const SizedBox.shrink(),
              ],
            ),
            const Gap(10),
            if (_category == RouteCategory.domain) const DomainSetWidget(),
            if (_category == RouteCategory.ip) const IPSetWidget(),
            if (_category == RouteCategory.app) const AppSetWidget(),
          ],
        ),
      ),
    );
  }
}

class AppSetWidget extends StatefulWidget {
  const AppSetWidget({super.key});

  @override
  State<AppSetWidget> createState() => _AppSetWidgetState();
}

class _AppSetWidgetState extends State<AppSetWidget> {
  List<AppSet> _appSets = [];
  AppSet? _selectedAppSet;
  late StreamSubscription _appSetSubscription;
  late SetRepo _setRepo;

  @override
  void initState() {
    super.initState();
    _setRepo = context.read<SetRepo>();
    _appSetSubscription = _setRepo.getAppSetsStream().listen((value) {
      _appSets = value;
      if (_appSets.isNotEmpty && _selectedAppSet == null) {
        _selectedAppSet = _appSets.first;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _appSetSubscription.cancel();
    super.dispose();
  }

  void _onAppSetTap(AppSet? appSet) async {
    final repo = context.read<SetRepo>();
    final newAppSet = await showDialog<AppSet>(
      context: context,
      builder: (context) => AppSetForm(
        appSet: appSet,
        title: appSet == null
            ? AppLocalizations.of(context)!.addAppSet
            : AppLocalizations.of(context)!.editAppSet,
      ),
    );
    if (newAppSet != null) {
      final nameTaken = _appSets.any(
        (e) =>
            e.name == newAppSet.name &&
            (appSet == null || e.name != appSet.name),
      );
      if (nameTaken) {
        snack(AppLocalizations.of(context)!.setNameDuplicate);
        return;
      }
      try {
        if (appSet == null) {
          await repo.addAppSet(newAppSet);
        } else {
          await repo.updateAppSet(
            appSet.name,
            clashRuleUrls: newAppSet.clashRuleUrls,
            newName: newAppSet.name != appSet.name ? newAppSet.name : null,
          );
          if (mounted && _selectedAppSet?.name == appSet.name) {
            setState(() {
              _selectedAppSet = newAppSet;
            });
          }
        }
        if (mounted) {
          context.read<GeoDataHelper>().makeGeoDataAvailable();
        }
      } catch (e) {
        snack(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 5,
          runSpacing: desktopPlatforms ? 5 : 0,
          children: [
            ..._appSets.map((e) {
              final isDefault =
                  e.name == getProxySetName(context) ||
                  e.name == getDirectSetName(context);
              return WrapChoiceChip(
                text: localizedSetName(context, e.name),
                labelStyle: Theme.of(context).textTheme.bodySmall,
                selected: e.name == _selectedAppSet?.name,
                onEdit: isDefault
                    ? null
                    : () {
                        _onAppSetTap(e);
                      },
                onDelete: isDefault
                    ? null
                    : () async {
                        setState(() {
                          _appSets.remove(e);
                        });
                        context.read<SetRepo>().removeAppSet(e.name);
                      },
                onTap: (value) {
                  setState(() {
                    _selectedAppSet = e;
                  });
                },
              );
            }),
            FilledButton.tonal(
              onPressed: () {
                _onAppSetTap(null);
              },
              style: FilledButton.styleFrom(minimumSize: const Size(36, 36)),
              child: Text(AppLocalizations.of(context)!.addAppSet),
            ),
          ],
        ),
        if (_selectedAppSet != null)
          SizedBox(
            height: 400,
            child: AppWidget(
              appSetName: _selectedAppSet!.name,
              addButtonInWrap: true,
            ),
          ),
      ],
    );
  }
}

class DomainSetWidget extends StatefulWidget {
  const DomainSetWidget({super.key});

  @override
  State<DomainSetWidget> createState() => _DomainSetWidgetState();
}

class _DomainSetWidgetState extends State<DomainSetWidget> {
  List<GreatDomainSet> _domainSets = [];
  List<AtomicDomainSet> _atomicDomainSets = [];
  AtomicDomainSet? _selectedAtomicDomainSet;
  late SetRepo _setRepo;
  late StreamSubscription _domainSetSubscription;
  late StreamSubscription _atomicDomainSetSubscription;
  @override
  void initState() {
    super.initState();
    _setRepo = context.read<SetRepo>();
    // Future.wait([
    //   database.managers.greatDomainSets.get().then((value) {
    //     _domainSets = value;
    //   }),
    //   database.managers.atomicDomainSets.get().then((value) {
    //     _atomicDomainSets = value;
    //     if (_atomicDomainSets.isNotEmpty) {
    //       _selectedAtomicDomainSet = _atomicDomainSets.first;
    //     }
    //   }),
    // ]).then((value) {
    //   setState(() {});
    // });
    _domainSetSubscription = _setRepo.getGreatDomainSetsStream().listen((
      value,
    ) {
      _domainSets = value;
      setState(() {});
    });
    _atomicDomainSetSubscription = _setRepo.getAtomicDomainSetsStream().listen((
      value,
    ) {
      _atomicDomainSets = value;
      if (_atomicDomainSets.isNotEmpty && _selectedAtomicDomainSet == null) {
        _selectedAtomicDomainSet = _atomicDomainSets.first;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _domainSetSubscription.cancel();
    _atomicDomainSetSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Tooltip(
              preferBelow: false,
              message:
                  '${AppLocalizations.of(context)!.greatSetDescription1}\n${AppLocalizations.of(context)!.greatSetDescription2}',
              child: Text(
                AppLocalizations.of(context)!.greatDomainSet,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Gap(5),
            IconButton.filledTonal(
              onPressed: () {
                _onGreatDomainSetTap(null);
              },
              padding: const EdgeInsets.all(0),
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
              icon: const Icon(Icons.add_rounded, size: 18),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ..._domainSets.map((e) {
                const cannotDelete = false /* e.name == blackListProxy ||
                    e.name == whiteListDirect ||
                    e.name == proxyAllDirect ||
                    e.name == gfwWithoutCustomDirect */;
                return MenuAnchor(
                  menuChildren: [
                    MenuItemButton(
                      onPressed: () async {
                        try {
                          await context.read<SetRepo>().removeGreatDomainSet(
                            e.name,
                          );
                        } catch (err) {
                          snack(err.toString());
                        }
                      },
                      child: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ],
                  builder: (context, controller, child) {
                    return GestureDetector(
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
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: ListTile(
                      visualDensity: VisualDensity.compact,
                      dense: true,
                      title: RichText(
                        text: TextSpan(
                          text: localizedSetName(context, e.name),
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            if (e.set.oppositeName.isNotEmpty)
                              TextSpan(
                                text:
                                    ' ↔ ${localizedSetName(context, e.set.oppositeName)}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      onTap: cannotDelete
                          ? null
                          : () => _onGreatDomainSetTap(e),
                      // tileColor:
                      //     Theme.of(context).colorScheme.surfaceContainerLow,
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Text('互斥：${e.set.oppositeName}',
                          //     style: Theme.of(context)
                          //         .textTheme
                          //         .bodySmall
                          //         ?.copyWith(
                          //             color: Theme.of(context)
                          //                 .colorScheme
                          //                 .onSurfaceVariant)),
                          Text(
                            '${AppLocalizations.of(context)!.include}：${e.set.inNames.map((e) => localizedSetName(context, e)).join(', ')}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          Text(
                            '${AppLocalizations.of(context)!.exclude}：${e.set.exNames.map((e) => localizedSetName(context, e)).join(', ')}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context)!.atmoicDomainSet,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Gap(5),
              IconButton.filledTonal(
                onPressed: () {
                  _onAtomicDomainSetTap(null, true);
                },
                padding: const EdgeInsets.all(0),
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
                icon: const Icon(Icons.add_rounded, size: 18),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            spacing: 5,
            runSpacing: desktopPlatforms ? 5 : 0,
            children: [
              ..._atomicDomainSets.map((e) {
                final cannotDelete =
                    e.name == getCustomDirect(context) ||
                    e.name ==
                        getCustomProxy(context) /* ||
                    e.name == gfw ||
                    e.name == cn ||
                    e.name == cnGames ||
                    e.name == private */;
                return WrapChoiceChip(
                  text: localizedSetName(context, e.name),
                  labelStyle: Theme.of(context).textTheme.bodySmall,
                  selected: e.name == _selectedAtomicDomainSet?.name,
                  onDelete: cannotDelete
                      ? null
                      : () async {
                          try {
                            await context.read<SetRepo>().removeAtomicDomainSet(
                              e.name,
                            );
                          } catch (err) {
                            snack(err.toString());
                          }
                        },
                  onEdit: () {
                    _onAtomicDomainSetTap(e, !cannotDelete);
                  },
                  onTap: (value) {
                    setState(() {
                      _selectedAtomicDomainSet = e;
                    });
                  },
                );
              }),
            ],
          ),
        ),
        if (_selectedAtomicDomainSet != null)
          SizedBox(
            height: 400,
            child: AtomicDomainSetWidget(
              addButtonInWrap: true,
              domainSetName: _selectedAtomicDomainSet!.name,
            ),
          ),
      ],
    );
  }

  void _onGreatDomainSetTap(GreatDomainSet? set) async {
    final repo = context.read<SetRepo>();
    final k = GlobalKey();
    final config = await showMyAdaptiveDialog<GreatDomainSetConfig?>(
      context,
      GreatDomainSetForm(key: k, domainSetConfig: set?.set),
      title: set == null
          ? AppLocalizations.of(context)!.createGreatDomainSet
          : AppLocalizations.of(context)!.editGreatDomainSet,
      onSave: (BuildContext context) {
        final formData = (k.currentState as FormDataGetter).formData;
        if (formData != null) {
          context.pop(formData);
        }
      },
    );
    if (config != null) {
      if (set?.name != config.name &&
          (_atomicDomainSets.any((e) => e.name == config.name) ||
              _domainSets.any(
                (e) =>
                    e.name == config.name || e.set.oppositeName == config.name,
              ))) {
        snack(AppLocalizations.of(context)!.setNameDuplicate);
        return;
      }
      // setState(() {
      //   if (set == null) {
      //     _domainSets.add(GreatDomainSet(
      //         name: config.name,
      //         oppositeName: config.oppositeName,
      //         set: config));
      //   } else {
      //     final index = _domainSets.indexWhere((e) => e.name == set.name);
      //     if (index != -1) {
      //       _domainSets[index] = set.copyWith(
      //           name: config.name,
      //           oppositeName: Value(config.oppositeName),
      //           set: config);
      //     }
      //   }
      // });
      if (set == null) {
        await repo.addGreatDomainSet(config);
      } else {
        await repo.updateGreateDomainSet(
          set.name,
          greatDomainSet: config,
          newName: config.name,
        );
      }
    }
  }

  void _onAtomicDomainSetTap(AtomicDomainSet? set, bool editable) async {
    final repo = context.read<SetRepo>();
    final k = GlobalKey();
    final config = await showMyAdaptiveDialog<AtomicDomainSet?>(
      context,
      SmallDomainSetForm(key: k, atomicDomainSet: set),
      title: set == null
          ? AppLocalizations.of(context)!.createSmallDomainSet
          : AppLocalizations.of(context)!.editSmallDomainSet,
      editable: editable,
      onSave: (BuildContext context) {
        final formData = (k.currentState as FormDataGetter).formData;
        if (formData != null) {
          context.pop(formData);
        }
      },
    );
    if (config != null) {
      if (set?.name != config.name &&
          (_atomicDomainSets.any((e) => e.name == config.name) ||
              _domainSets.any((e) => e.name == config.name))) {
        snack(AppLocalizations.of(context)!.setNameDuplicate);
        return;
      }
      if (set == null) {
        await repo.addAtomicDomainSet(config);
      } else {
        await repo.updateAtomicDomainSet(
          set.name,
          newName: config.name,
          inverse: config.inverse,
          geositeConfig: config.geositeConfig,
          clashRuleUrls: config.clashRuleUrls,
          useBloomFilter: config.useBloomFilter,
          geoUrl: config.geoUrl,
        );
      }
      // setState(() {
      //   if (set == null) {
      //     _atomicDomainSets.add(config);
      //   } else {
      //     final index = _atomicDomainSets.indexWhere((e) => e.name == set.name);
      //     if (index != -1) {
      //       _atomicDomainSets[index] = config;
      //     }
      //   }
      // });
      context.read<GeoDataHelper>().makeGeoDataAvailable();
    }
  }
}

class IPSetWidget extends StatefulWidget {
  const IPSetWidget({super.key});

  @override
  State<IPSetWidget> createState() => _IPSetWidgetState();
}

class _IPSetWidgetState extends State<IPSetWidget> {
  List<GreatIpSet> _ipSets = [];
  List<AtomicIpSet> _atomicIpSets = [];
  AtomicIpSet? _selectedAtomicIpSet;
  late SetRepo _setRepo;
  late StreamSubscription _ipSetSubscription;
  late StreamSubscription _atomicIpSetSubscription;
  @override
  void initState() {
    super.initState();
    _setRepo = context.read<SetRepo>();
    // Future.wait([
    //   database.managers.greatIpSets.get().then((value) {
    //     _ipSets = value;
    //   }),
    //   database.managers.atomicIpSets.get().then((value) {
    //     _atomicIpSets = value;
    //     if (_atomicIpSets.isNotEmpty) {
    //       _selectedAtomicIpSet = _atomicIpSets.first;
    //     }
    //   }),
    // ]).then((value) {
    //   setState(() {});
    // });
    _ipSetSubscription = _setRepo.getGreatIpSetsStream().listen((value) {
      _ipSets = value;
      setState(() {});
    });
    _atomicIpSetSubscription = _setRepo.getAtomicIpSetsStream().listen((value) {
      _atomicIpSets = value;
      if (_atomicIpSets.isNotEmpty && _selectedAtomicIpSet == null) {
        _selectedAtomicIpSet = _atomicIpSets.first;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ipSetSubscription.cancel();
    _atomicIpSetSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Tooltip(
              preferBelow: false,
              message:
                  '${AppLocalizations.of(context)!.greatSetDescription1}\n${AppLocalizations.of(context)!.greatSetDescription2}',
              child: Text(
                AppLocalizations.of(context)!.greatIpSet,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Gap(5),
            IconButton.filledTonal(
              onPressed: () {
                _onGreatIpSetTap(null);
              },
              padding: const EdgeInsets.all(0),
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
              icon: const Icon(Icons.add_rounded, size: 18),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              ..._ipSets.map((e) {
                const cannotDel = false /* e.name == blackListProxy ||
                    e.name == whiteListDirect ||
                    e.name == proxyAllDirect */;
                return MenuAnchor(
                  menuChildren: [
                    MenuItemButton(
                      onPressed: () async {
                        try {
                          await context.read<SetRepo>().removeGreatIpSet(
                            e.name,
                          );
                        } catch (err) {
                          snack(err.toString());
                        }
                      },
                      child: Text(AppLocalizations.of(context)!.delete),
                    ),
                  ],
                  builder: (context, controller, child) {
                    return GestureDetector(
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
                      child: child,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: ListTile(
                      visualDensity: VisualDensity.compact,
                      dense: true,
                      title: RichText(
                        text: TextSpan(
                          text: localizedSetName(context, e.name),
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            if (e.greatIpSetConfig.oppositeName.isNotEmpty)
                              TextSpan(
                                text:
                                    ' ↔ ${localizedSetName(context, e.greatIpSetConfig.oppositeName)}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                          ],
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      onTap: () => _onGreatIpSetTap(e),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.include}：${e.greatIpSetConfig.inNames.map((e) => localizedSetName(context, e)).join(', ')}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          Text(
                            '${AppLocalizations.of(context)!.exclude}：${e.greatIpSetConfig.exNames.map((e) => localizedSetName(context, e)).join(', ')}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context)!.atmoicIpSet,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Gap(5),
              IconButton.filledTonal(
                onPressed: () {
                  _onAtomicIpSetTap(null, true);
                },
                padding: const EdgeInsets.all(0),
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(minimumSize: const Size(36, 36)),
                icon: const Icon(Icons.add_rounded, size: 18),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Wrap(
            spacing: 5,
            runSpacing: desktopPlatforms ? 5 : 0,
            children: [
              ..._atomicIpSets.map((e) {
                final cannotDelete =
                    e.name == getCustomDirect(context) ||
                    e.name ==
                        getCustomProxy(context) /* ||
                    e.name == gfw ||
                    e.name == cn ||
                    e.name == private */;
                return WrapChoiceChip(
                  text: localizedSetName(context, e.name),
                  selected: e.name == _selectedAtomicIpSet?.name,
                  labelStyle: Theme.of(context).textTheme.bodySmall,
                  onDelete: cannotDelete
                      ? null
                      : () async {
                          try {
                            await context.read<SetRepo>().removeAtomicIpSet(
                              e.name,
                            );
                          } catch (err) {
                            snack(err.toString());
                          }
                        },
                  onEdit: () {
                    _onAtomicIpSetTap(e, !cannotDelete);
                  },
                  onTap: (value) {
                    setState(() {
                      _selectedAtomicIpSet = e;
                    });
                  },
                );
              }),
            ],
          ),
        ),
        if (_selectedAtomicIpSet != null)
          IPWidget(
            ipSetName: _selectedAtomicIpSet!.name,
            addButtonInWrap: true,
          ),
      ],
    );
  }

  void _onGreatIpSetTap(GreatIpSet? set) async {
    final repo = context.read<SetRepo>();
    final k = GlobalKey();
    final config = await showMyAdaptiveDialog<GreatIPSetConfig?>(
      context,
      GreatIpSetForm(key: k, ipSetConfig: set?.greatIpSetConfig),
      title: set == null
          ? AppLocalizations.of(context)!.createGreatIpSet
          : AppLocalizations.of(context)!.editGreatIpSet,
      onSave: (BuildContext context) {
        final formData = (k.currentState as FormDataGetter).formData;
        if (formData != null) {
          context.pop(formData);
        }
      },
    );
    if (config != null) {
      if (set?.name != config.name &&
          (_atomicIpSets.any((e) => e.name == config.name) ||
              _ipSets.any(
                (e) =>
                    e.name == config.name ||
                    e.greatIpSetConfig.oppositeName == config.name,
              ))) {
        snack(AppLocalizations.of(context)!.setNameDuplicate);
        return;
      }
      // setState(() {
      //   if (set == null) {
      //     _ipSets.add(GreatIpSet(name: config.name, greatIpSetConfig: config));
      //   } else {
      //     final index = _ipSets.indexWhere((e) => e.name == set.name);
      //     if (index != -1) {
      //       _ipSets[index] =
      //           set.copyWith(name: config.name, greatIpSetConfig: config);
      //     }
      //   }
      // });
      if (set == null) {
        await repo.addGreatIpSet(config);
      } else {
        await repo.updateGreatIpSet(
          set.name,
          greatIpSet: config,
          newName: config.name,
        );
      }
    }
  }

  void _onAtomicIpSetTap(AtomicIpSet? set, bool editable) async {
    final repo = context.read<SetRepo>();
    final k = GlobalKey();
    final config = await showMyAdaptiveDialog<AtomicIpSet?>(
      context,
      SmallIpSetForm(key: k, atomicIpSet: set),
      title: set == null
          ? AppLocalizations.of(context)!.createIpSmallSet
          : AppLocalizations.of(context)!.editIpSmallSet,
      editable: editable,
      onSave: (BuildContext context) {
        final formData = (k.currentState as FormDataGetter).formData;
        if (formData != null) {
          context.pop(formData);
        }
      },
    );
    if (config != null) {
      if (set?.name != config.name &&
          (_atomicIpSets.any((e) => e.name == config.name) ||
              _ipSets.any((e) => e.name == config.name))) {
        snack(AppLocalizations.of(context)!.setNameDuplicate);
        return;
      }
      if (set == null) {
        await repo.addAtomicIpSet(config);
      } else {
        await repo.updateAtomicIpSet(
          set.name,
          newName: config.name,
          geoIpConfig: config.geoIpConfig,
          clashRuleUrls: config.clashRuleUrls,
          geoUrl: config.geoUrl,
          inverse: config.inverse,
        );
      }
      context.read<GeoDataHelper>().makeGeoDataAvailable();
    }
  }
}

class WrapChoiceChip extends StatelessWidget {
  const WrapChoiceChip({
    super.key,
    required this.text,
    this.onDelete,
    this.onEdit,
    required this.onTap,
    this.selected = false,
    this.labelStyle,
  });
  final String text;
  final Function()? onDelete;
  final Function(bool) onTap;
  final Function()? onEdit;
  final bool selected;
  final TextStyle? labelStyle;
  @override
  Widget build(BuildContext context) {
    final chip = MenuAnchor(
      menuChildren: [
        if (onEdit != null)
          MenuItemButton(
            onPressed: onEdit,
            child: Text(AppLocalizations.of(context)!.edit),
          ),
        if (onDelete != null && onEdit != null) const Divider(),
        if (onDelete != null)
          MenuItemButton(
            onPressed: onDelete,
            child: Text(AppLocalizations.of(context)!.delete),
          ),
      ],
      builder: (context, controller, child) {
        return GestureDetector(
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
          child: ChoiceChip(
            selected: selected,
            onSelected: onTap,
            label: Text(text, style: labelStyle),
          ),
        );
      },
    );
    return chip;
  }
}

class GreatSetCard extends StatelessWidget {
  const GreatSetCard({
    super.key,
    required this.name,
    required this.include,
    required this.exclude,
  });
  final String name;
  final List<String> include;
  final List<String> exclude;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: Theme.of(context).textTheme.titleSmall),
            const Gap(5),
            Text(
              AppLocalizations.of(context)!.include,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const Gap(5),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: include
                  .map(
                    (e) => Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        e,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const Gap(5),
            Text(
              AppLocalizations.of(context)!.exclude,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const Gap(5),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: exclude
                  .map(
                    (e) => Chip(
                      visualDensity: VisualDensity.compact,
                      label: Text(
                        e,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class AppSetForm extends StatefulWidget {
  const AppSetForm({super.key, this.appSet, this.title});
  final AppSet? appSet;
  final String? title;

  @override
  State<AppSetForm> createState() => _AppSetFormState();
}

class _AppSetFormState extends State<AppSetForm> {
  final _nameController = TextEditingController();
  final List<String> _clashRuleUrls = [];

  @override
  void initState() {
    super.initState();
    if (widget.appSet != null) {
      _nameController.text = widget.appSet!.name;
      _clashRuleUrls.addAll(widget.appSet!.clashRuleUrls ?? []);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title != null ? Text(widget.title!) : null,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              helperText: AppLocalizations.of(context)!.setNameDuplicate,
              helperStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              labelText: AppLocalizations.of(context)!.name,
              border: const OutlineInputBorder(),
            ),
          ),
          const Gap(5),
          const TextDivider(text: 'Clash Rules'),
          const Gap(5),
          ClashRule(clashRuleUrls: _clashRuleUrls),
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
              Navigator.pop(
                context,
                AppSet(
                  name: _nameController.text,
                  clashRuleUrls: _clashRuleUrls,
                ),
              );
            }
          },
          child: Text(AppLocalizations.of(context)!.confirm),
        ),
      ],
    );
  }
}
