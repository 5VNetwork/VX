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

import 'package:ads/ad.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:vx/app/layout_provider.dart';
import 'package:vx/app/server/add_server.dart';
import 'package:vx/app/server/server_detail.dart';
import 'package:vx/app/server/server_status.dart';
import 'package:vx/app/server/ssh_keys_screen.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/common/common.dart';
import 'package:vx/data/database.dart';
import 'package:vx/data/database_provider.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/widgets/pro_promotion.dart';
import '../../main.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vector_graphics/vector_graphics.dart';

enum ServerScreenSegment { servers, keys }

class ServerScreen extends StatefulWidget {
  const ServerScreen({super.key});

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  ServerScreenSegment _segment = ServerScreenSegment.servers;
  @override
  Widget build(BuildContext context) {
    if (!desktopPlatforms) {
      return DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: AppLocalizations.of(context)!.server),
                Tab(text: AppLocalizations.of(context)!.sshKey),
              ],
            ),
            const Gap(10),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: TabBarView(children: [Servers(), SshKeys()]),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            SegmentedButton<ServerScreenSegment>(
              segments: [
                ButtonSegment(
                  value: ServerScreenSegment.servers,
                  label: Text(AppLocalizations.of(context)!.server),
                ),
                ButtonSegment(
                  value: ServerScreenSegment.keys,
                  label: Text(AppLocalizations.of(context)!.sshKey),
                ),
              ],
              selected: {_segment},
              onSelectionChanged: (Set<ServerScreenSegment> set) =>
                  setState(() {
                    _segment = set.first;
                  }),
            ),
            const Gap(10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _segment == ServerScreenSegment.servers
                    ? const Servers()
                    : const SshKeys(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Servers extends StatefulWidget {
  const Servers({super.key});

  @override
  State<Servers> createState() => _ServersState();
}

class _ServersState extends State<Servers> {
  StreamSubscription? _serverSubscription;
  List<SshServer> _servers = [];
  @override
  void initState() {
    super.initState();
  }

  void _subscribe() {
    final database = context.read<DatabaseProvider>().database;
    _serverSubscription = database.select(database.sshServers).watch().listen((
      l,
    ) {
      setState(() {
        _servers = l;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _serverSubscription?.cancel();
    _subscribe();
  }

  @override
  void dispose() {
    _serverSubscription?.cancel();
    super.dispose();
  }

  void _addServer() {
    final fullScreen = Provider.of<MyLayout>(context, listen: false).isCompact;
    if (fullScreen) {
      Navigator.of(context, rootNavigator: true).push(
        CupertinoPageRoute(
          builder: (ctx) {
            return AddEditServerDialog(fullScreen: fullScreen);
          },
        ),
      );
    } else {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => AddEditServerDialog(fullScreen: fullScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.tonalIcon(
            onPressed: _addServer,
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.add),
          ),
          const Gap(10),
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, c) {
                const cardWidth = 230;
                const cartHeight = 64;
                final count = c.maxWidth ~/ (cardWidth + 10);
                // BoxConstraints(
                //         maxWidth: (count * cardWidth + (count - 1) * 10),
                //       )
                return CustomScrollView(
                  slivers: [
                    SliverConstrainedCrossAxis(
                      maxExtent: count * cardWidth + (count - 1) * 10,
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: count,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: cardWidth / cartHeight,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          childCount: _servers.length,
                          (context, index) {
                            final server = _servers[index];
                            return Hero(
                              tag: 'server${server.id}',
                              child: ServerCard(
                                server: server,
                                onTap: () {
                                  final fullScreen = Provider.of<MyLayout>(
                                    context,
                                    listen: false,
                                  ).isCompact;
                                  Navigator.of(
                                    context,
                                    rootNavigator: fullScreen,
                                  ).push(
                                    fullScreen
                                        ? CupertinoPageRoute(
                                            builder: (ctx) {
                                              return ServerDetail(
                                                server: _servers[index],
                                                fullScreen: fullScreen,
                                              );
                                            },
                                          )
                                        : PageRouteBuilder(
                                            pageBuilder:
                                                (
                                                  ctx,
                                                  animation,
                                                  secondaryAnimation,
                                                ) {
                                                  return ServerDetail(
                                                    server: _servers[index],
                                                    fullScreen: fullScreen,
                                                  );
                                                },
                                            transitionsBuilder:
                                                (
                                                  context,
                                                  animation,
                                                  secondaryAnimation,
                                                  child,
                                                ) {
                                                  return FadeTransition(
                                                    opacity: animation,
                                                    child: child,
                                                  );
                                                },
                                          ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 10)),
                    if (!context.watch<AuthBloc>().state.proUser) const Ads(),
                    const SliverToBoxAdapter(child: SizedBox(height: 70)),
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

class ServerCard extends StatelessWidget {
  const ServerCard({
    super.key,
    required this.server,
    this.onTap,
    this.showStatus = false,
    this.serverStatusKey,
  });
  final SshServer server;
  final VoidCallback? onTap;
  final bool showStatus;
  final GlobalKey? serverStatusKey;
  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit),
          onPressed: () {
            if (Provider.of<MyLayout>(context, listen: false).isCompact) {
              Navigator.of(context, rootNavigator: true).push(
                CupertinoPageRoute(
                  builder: (ctx) {
                    return AddEditServerDialog(
                      server: server,
                      fullScreen: true,
                    );
                  },
                ),
              );
            } else {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AddEditServerDialog(server: server),
              );
            }
          },
          child: Text(AppLocalizations.of(context)!.edit),
        ),
        const Divider(),
        MenuItemButton(
          leadingIcon: const Icon(Icons.delete_outline),
          onPressed: () async {
            try {
              await context.read<FlutterSecureStorage>().delete(
                key: server.storageKey,
              );
              final database = context.read<DatabaseProvider>().database;
              await database.delete(database.sshServers).delete(server);
            } catch (e) {
              logger.d('delete server error', error: e);
              rootScaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.deleteFailed),
                ),
              );
            }
          },
          child: Text(AppLocalizations.of(context)!.delete),
        ),
      ],
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onTap: onTap,
                title: Text(server.name),
                subtitle: AutoSizeText(server.address, maxLines: 1),
                trailing: showStatus
                    ? ServerActionButtons(server: server)
                    : null,
                contentPadding: const EdgeInsets.only(left: 16, right: 8),
                leading: server.country != null && server.country!.isNotEmpty
                    ? SvgPicture(
                        height: 24,
                        width: 24,
                        AssetBytesLoader(
                          'assets/icons/flags/${server.country!.toLowerCase()}.svg.vec',
                        ),
                      )
                    : const Icon(Icons.language),
              ),
              if (showStatus)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16,
                  ),
                  child: ServerStatus(key: serverStatusKey, server: server),
                ),
            ],
          ),
        ),
      ),
      builder: (context, controller, child) => GestureDetector(
        onSecondaryTapUp: (details) {
          controller.open(position: details.localPosition);
        },
        onLongPressEnd: (details) {
          controller.open(position: details.localPosition);
        },
        child: child,
      ),
    );
  }
}
