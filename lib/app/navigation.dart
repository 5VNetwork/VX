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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vx/app/start_close_button.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/data/sync.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/common/common.dart';
import 'package:vx/utils/debug.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/path.dart';
import 'package:vx/widgets/circular_progress_indicator.dart';

final destination = <_Destination>[
  _Destination(
    path: '/home',
    outlinedIcon: const ImageIcon(AssetImage('assets/icons/home_outline.png')),
    filledIcon: const Icon(Icons.home_rounded),
    label: (ctx) => AppLocalizations.of(ctx)!.home,
  ),
  _Destination(
    path: '/node',
    outlinedIcon: const Icon(Icons.outbond_outlined),
    filledIcon: const Icon(Icons.outbond_rounded),
    label: (ctx) => AppLocalizations.of(ctx)!.node,
  ),
  _Destination(
    path: '/log',
    outlinedIcon: const ImageIcon(AssetImage('assets/icons/log_outline.png')),
    filledIcon: const ImageIcon(AssetImage('assets/icons/log_fill.png')),
    label: (ctx) => AppLocalizations.of(ctx)!.log,
  ),
  _Destination(
    path: '/route',
    outlinedIcon: const Icon(Icons.alt_route_outlined),
    filledIcon: const Icon(Icons.alt_route_rounded),
    label: (ctx) => AppLocalizations.of(ctx)!.routing,
  ),
  _Destination(
    path: '/server',
    outlinedIcon: const Icon(Icons.cloud_done_outlined),
    filledIcon: const Icon(Icons.cloud_done_rounded),
    label: (ctx) => AppLocalizations.of(ctx)!.server,
  ),
  _Destination(
    path: '/setting',
    outlinedIcon: const Icon(Icons.settings_outlined),
    filledIcon: const Icon(Icons.settings_rounded),
    label: (ctx) => AppLocalizations.of(ctx)!.settings,
  ),
  // _Destination(
  //   path: '/guide',
  //   outlinedIcon: Icon(Icons.explore_outlined),
  //   filledIcon: Icon(Icons.explore_rounded),
  //   label: (ctx) => AppLocalizations.of(ctx)!.compass,
  // ),
  // _Destination(
  //   path: '/ad',
  //   outlinedIcon: Icon(
  //     Icons.campaign_outlined,
  //     size: 24,
  //   ),
  //   filledIcon: Icon(
  //     Icons.campaign_rounded,
  //     size: 24,
  //   ),
  //   label: (ctx) => 'AD',
  // ),
];

enum NaviDestination {
  home(prefix: '/home'),
  outbound(prefix: '/node'),
  log(prefix: '/log'),
  route(prefix: '/route'),
  server(prefix: '/server'),
  settings(prefix: '/setting')
  // compass(prefix: '/guide'),
  // ad(prefix: '/ad')
  ;

  static NaviDestination? fromPath(String? path) {
    if (path == null) {
      return null;
    }
    // if (path == '/') {
    //   return NaviDestination.home;
    // }
    for (var e in NaviDestination.values) {
      // if (e.prefix == '/') {
      //   continue;
      // }
      if (path.startsWith(e.prefix)) {
        return e;
      }
    }
    return null;
  }

  const NaviDestination({required this.prefix});
  final String prefix;
}

class MyNavigationRail extends StatefulWidget {
  const MyNavigationRail({super.key, required this.naviDestination});
  final NaviDestination? naviDestination;

  @override
  State<MyNavigationRail> createState() => _MyNavigationRailState();
}

class _MyNavigationRailState extends State<MyNavigationRail> {
  late Widget _leading;
  late List<NavigationRailDestination> _railChildren;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _railChildren = destination
        .map(
          (e) => NavigationRailDestination(
            icon: e.outlinedIcon,
            selectedIcon: e.filledIcon,
            label: Text(e.label(context)),
          ),
        )
        .toList();
    _leading = Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 0),
      child: StartCloseButton(
        size: desktopPlatforms
            ? StartCloseButtonSize.small
            : StartCloseButtonSize.middle,
        floating: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      trailing: (Platform.isIOS && !isProduction())
          ? Column(
              children: [
                const IconButton(
                  onPressed: saveLogToApplicationDocumentsDir,
                  icon: Icon(Icons.file_copy),
                ),
                IconButton(
                  onPressed: () async {
                    (getTunnelLogDir()).delete(recursive: true);
                  },
                  icon: const Icon(Icons.delete),
                ),
              ],
            )
          : Platform.isMacOS
          ? const SyncButton()
          : null,
      leading: _leading,
      backgroundColor: Theme.of(context).colorScheme.surface,
      labelType: NavigationRailLabelType.all,
      destinations: _railChildren,
      selectedIndex: widget.naviDestination?.index,
      onDestinationSelected: (int index) {
        context.go(destination[index].path);
      },
    );
  }
}

class SyncButton extends StatefulWidget {
  const SyncButton({super.key});

  @override
  State<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton> {
  bool syncing = false;
  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isPro = authState.proUser && authState.isAuthenticated;
    final syncService = context.read<SyncService>();
    return isPro && syncService.enable
        ? IconButton(
            onPressed: () async {
              setState(() {
                syncing = true;
              });
              await context.read<SyncService>().sync();
              setState(() {
                syncing = false;
              });
            },
            icon: syncing
                ? smallCircularProgressIndicator
                : const Icon(Icons.sync_rounded),
          )
        : const SizedBox.shrink();
  }
}

class MyNavigationDrawer extends StatelessWidget {
  const MyNavigationDrawer({
    super.key,
    required this.naviDestination,
    this.showButton = false,
  });
  final NaviDestination? naviDestination;
  final bool showButton;
  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      selectedIndex: naviDestination?.index,
      onDestinationSelected: (index) {
        context.go(destination[index].path);
        // pop drawer
        // showButton is false on small screen
        if (!showButton) {
          Navigator.of(context).pop();
        }
      },
      children: [
        Platform.isWindows || Platform.isLinux
            ? Padding(
                padding: const EdgeInsets.only(left: 25, top: 20, bottom: 15),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/icons/V.png',
                    width: 32,
                    height: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              )
            : const SizedBox(height: 50),
        if (showButton)
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 0, 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: StartCloseButton(
                floating: false,
                size: StartCloseButtonSize.large,
              ),
            ),
          ),
        ...destination.map(
          (e) => NavigationDrawerDestination(
            icon: e.outlinedIcon,
            label: Text(e.label(context)),
            selectedIcon: e.filledIcon,
          ),
        ),
      ],
    );
  }
}

class _Destination {
  const _Destination({
    required this.path,
    required this.label,
    required this.outlinedIcon,
    required this.filledIcon,
  });
  final String path;
  final Widget outlinedIcon;
  final Widget filledIcon;
  final String Function(BuildContext) label;
}
