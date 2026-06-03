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

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' hide context;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vx/app/home/home.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/app/control.dart';

import 'package:vx/app/start_close_button.dart';
import 'package:vx/app/top_bar.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/common/extension.dart';
import 'package:vx/app/navigation.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/main.dart';
import 'package:vx/widgets/divider.dart';
import 'package:vx/widgets/no_node.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key, required this.child, required this.state});

  final Widget child;
  final GoRouterState state;

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  NaviDestination? naviDestination;
  Widget? cache;

  @override
  void initState() {
    super.initState();
    if (!context.read<SharedPreferences>().welcomeShown) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (Platform.isWindows &&
            File(join(resourceDirectory.parent.path, 'vproxy')).existsSync()) {
          //[C:\\Users\\YOUR USER NAME\\AppData\\Roaming\\com.5vnetwork\\vproxy]
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.windowsUpdateNotice1,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(10),
                    Text(join(resourceDirectory.parent.path, 'vproxy')),
                    const Gap(10),
                    const Icon(Icons.arrow_downward),
                    const Gap(10),
                    Text(resourceDirectory.path),
                    const Gap(10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppLocalizations.of(context)!.windowsUpdateNotice2,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Pasteboard.writeText(resourceDirectory.parent.path);
                  },
                  child: Text(AppLocalizations.of(context)!.copyPath),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.close),
                ),
              ],
            ),
          );
        }
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Center(
              child: Text(
                AppLocalizations.of(context)!.welcome,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            content: const Welcome(),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
        );
        context.read<SharedPreferences>().setWelcomeShown(true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final newNaviDestination = NaviDestination.fromPath(widget.state.fullPath);
    if (cache != null && newNaviDestination == naviDestination) {
      return cache!;
    }
    naviDestination = newNaviDestination;
    cache = LayoutBuilder(
      builder: (ctx, c) {
        if (c.isSuperLarge) {
          Widget body = Row(
            children: [
              Container(
                color: Theme.of(context).colorScheme.surface,
                child: MyNavigationDrawer(
                  naviDestination: naviDestination,
                  showButton: true,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: widget.child,
                ),
              ),
              const ControlDrawer(),
            ],
          );
          if (Platform.isWindows || Platform.isLinux) {
            body = Row(
              children: [
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: MyNavigationDrawer(
                    naviDestination: naviDestination,
                    showButton: true,
                  ),
                ),
                verticalDivider,
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 48,
                        child: MoveWindow(
                          child: const Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: WindowButtons(),
                            ),
                          ),
                        ),
                      ),
                      divider,
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: widget.child,
                              ),
                            ),
                            verticalDivider,
                            const ControlDrawer(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return Scaffold(body: body);
        } else if (c.isMedium || c.isExpanded || c.isLarge) {
          if (Platform.isAndroid) {
            return Scaffold(
              endDrawer: const ControlDrawer(),
              appBar: AppBar(
                leading: Padding(
                  padding: const EdgeInsets.only(left: 24.0),
                  child: GlobalQuicActionMenuAnchor(
                    child: Center(
                      child: Image.asset(
                        'assets/icons/V.png',
                        width: 24,
                        height: 24,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (widget.state.fullPath == '/home') const HomeEditButton(),

                  Builder(
                    builder: (context) {
                      return IconButton(
                        onPressed: () {
                          Scaffold.of(context).openEndDrawer();
                        },
                        icon: const Icon(Icons.tune_rounded),
                      );
                    },
                  ),
                ],
              ),
              body: Row(
                children: [
                  MyNavigationRail(naviDestination: naviDestination),
                  Expanded(child: widget.child),
                ],
              ),
            );
          }
          return Scaffold(
            endDrawer: const ControlDrawer(),
            body: SafeArea(
              child: Column(
                children: [
                  TopBar(isHomeRoute: widget.state.fullPath == '/home'),
                  Expanded(
                    child: Row(
                      children: [
                        MyNavigationRail(naviDestination: naviDestination),
                        // VerticalDivider(),
                        Expanded(child: widget.child),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // compact
          // Widget? title;
          // bool showingAd = false;
          // if (!isPro && (Platform.isAndroid || Platform.isIOS)) {
          //   showingAd = true;
          //   title = MyBannderAdWidget(adSize: AdSize.banner);
          // }
          Widget? leading;
          if (Platform.isWindows || (!Platform.isMacOS)) {
            leading = GlobalQuicActionMenuAnchor(
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Image.asset(
                    'assets/icons/V.png',
                    width: 20,
                    height: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            );
          }

          return Scaffold(
            // drawer: MyNavigationDrawer(naviDestination: naviDestination),
            endDrawer: const ControlDrawer(),
            appBar: Platform.isWindows
                ? null
                : AppBar(
                    forceMaterialTransparency: true,
                    leading: leading,
                    actions: [
                      if (widget.state.fullPath == '/home')
                        const HomeEditButton(),
                      IconButton(
                        onPressed: () {
                          context.push('/setting');
                        },
                        icon: const Icon(Icons.settings_rounded),
                      ),
                      if (Platform.isMacOS) const SyncButton(),
                      Builder(
                        builder: (context) {
                          return IconButton(
                            onPressed: () {
                              Scaffold.of(context).openEndDrawer();
                            },
                            icon: const Icon(Icons.tune_rounded),
                          );
                        },
                      ),
                    ],
                  ),

            bottomNavigationBar: NavigationBar(
              selectedIndex: naviDestination?.index ?? 0,
              onDestinationSelected: (index) {
                context.go(destination[index].path);
              },
              destinations: destination
                  .sublist(0, destination.length - 1)
                  .map(
                    (e) => NavigationDestination(
                      icon: e.outlinedIcon,
                      selectedIcon: e.filledIcon,
                      label: e.label(context),
                    ),
                  )
                  .toList(),
            ),
            floatingActionButton: const StartCloseButton(
              size: StartCloseButtonSize.middle,
              floating: true,
            ),
            body: Platform.isWindows
                ? Column(
                    children: [
                      TopBar(isHomeRoute: widget.state.fullPath == '/home'),
                      Expanded(child: widget.child),
                    ],
                  )
                : widget.child,
          );
        }
      },
    );
    return cache!;
  }
}
