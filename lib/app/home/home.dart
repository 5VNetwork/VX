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
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:ads/ad.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_common/auth/auth_provider.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/app/grpcservice/grpc.pbgrpc.dart';
import 'package:tm/protos/vx/router/router.pb.dart';
import 'package:vx/app/blocs/inbound.dart';
import 'package:vx/app/control.dart';
import 'package:vx/app/layout_provider.dart';
import 'package:vx/app/outbound/add.dart';
import 'package:vx/app/outbound/outbound_page.dart';
import 'package:vx/app/outbound/subscription.dart';
import 'package:vx/app/outbound/subscription_bloc.dart';
import 'package:vx/app/outbound/subscription_page.dart';
import 'package:vx/app/routing/default.dart';
import 'package:vx/app/routing/mode_form.dart';
import 'package:vx/app/routing/repo.dart';
import 'package:vx/app/routing/routing_page.dart';
import 'package:vx/app/routing/selector_being_used.dart';
import 'package:vx/app/routing/selector_widget.dart';
import 'package:vx/app/blocs/proxy_selector/proxy_selector_bloc.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/common/circuler_buffer.dart';
import 'package:vx/common/common.dart';
import 'package:vx/common/extension.dart';
import 'package:flutter_common/util/net.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/theme.dart';
import 'package:vx/app/outbound/outbound_repo.dart';
import 'package:vx/app/outbound/outbounds_bloc.dart';
import 'package:vx/data/database.dart';
import 'package:vx/main.dart';
import 'package:collection/collection.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/xapi_client.dart';
import 'package:vx/widgets/circular_progress_indicator.dart';
import 'package:vx/widgets/home_card.dart';
import 'package:tm/protos/app/api/api.pb.dart' as api_pb;
import 'package:tm/tm.dart';
import 'package:vx/widgets/pro_icon.dart';

part 'realtime_speed.dart';
part 'route.dart';
part 'active_nodes.dart';
part 'proxy_selector.dart';
part 'home_customize.dart';
part 'home_standard.dart';
part 'home_edit.dart';
part 'subscription.dart';

class HomePageCubit extends Cubit<bool> {
  HomePageCubit(this._prefs) : super(_prefs.useCustomizableHomePage);

  final SharedPreferences _prefs;

  void setUseCustomizableHomePage(bool value) {
    emit(value);
    _prefs.setUseCustomizableHomePage(value);
  }
}

/// Root home page that chooses between standard and customizable layouts.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isPro = context.select<AuthBloc, bool>((bloc) => bloc.state.pro);
    final useCustom = isPro && context.watch<HomePageCubit>().state;
    if (useCustom) {
      return const CustomizableHomePage();
    }
    return const StandardHomePage();
  }
}

/// Identifiers for home sections that the user can show/hide.
enum HomeWidgetId {
  upload('upload'),
  download('download'),
  memory('memory'),
  connections('connections'),
  nodesHelper('nodesHelper'),
  route('route'),
  proxySelector('proxySelector'),
  inbound('inbound'),
  subscription('subscription'),
  nodes('nodes');

  const HomeWidgetId(this.id);
  final String id;

  static HomeWidgetId? fromId(String id) {
    for (final v in values) {
      if (v.id == id) return v;
    }
    return null;
  }

  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case HomeWidgetId.upload:
        return l10n.upload;
      case HomeWidgetId.download:
        return l10n.download;
      case HomeWidgetId.memory:
        return l10n.memory;
      case HomeWidgetId.connections:
        return l10n.connections;
      case HomeWidgetId.nodesHelper:
        return l10n.homeWidgetNodesHelper;
      case HomeWidgetId.route:
        return l10n.routing;
      case HomeWidgetId.proxySelector:
        return l10n.nodeSelection;
      case HomeWidgetId.inbound:
        return l10n.inbound;
      case HomeWidgetId.subscription:
        return l10n.subscription;
      case HomeWidgetId.nodes:
        return l10n.homeWidgetNodes;
    }
  }

  Widget buildWidget(BuildContext context, HomeLayoutPreset preset) {
    switch (this) {
      case HomeWidgetId.upload:
        return const RealtimeSpeed(isUpload: true);
      case HomeWidgetId.download:
        return const RealtimeSpeed(isUpload: false);
      case HomeWidgetId.memory:
        return const MemoryStats();
      case HomeWidgetId.connections:
        return const ConnectionsStats();
      case HomeWidgetId.nodesHelper:
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: preset == HomeLayoutPreset.compact ? 284 : 614,
          ),
          child: const NodesHelper(),
        );
      case HomeWidgetId.route:
        return const _Route();
      case HomeWidgetId.proxySelector:
        return const ProxySelector(home: true);
      case HomeWidgetId.inbound:
        return const _Inbound();
      case HomeWidgetId.subscription:
        return const _Subscription();
      case HomeWidgetId.nodes:
        return const Nodes();
    }
  }
}

class _Inbound extends StatelessWidget {
  const _Inbound();

  @override
  Widget build(BuildContext context) {
    final disableTun = Platform.isWindows && !isRunningAsAdmin && isWinStore;
    return HomeCard(
      title: AppLocalizations.of(context)!.inbound,
      icon: Icons.keyboard_double_arrow_right_rounded,
      child: BlocBuilder<InboundCubit, InboundMode>(
        builder: (ctx, mode) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  ChoiceChip(
                    label: Text(InboundMode.tun.toLocalString(context)),
                    selected: mode == InboundMode.tun,
                    onSelected: disableTun
                        ? null
                        : (value) => context
                              .read<InboundCubit>()
                              .setInboundMode(InboundMode.tun),
                  ),
                  ChoiceChip(
                    label: Text(InboundMode.systemProxy.toLocalString(context)),
                    selected: mode == InboundMode.systemProxy,
                    onSelected: (value) => context
                        .read<InboundCubit>()
                        .setInboundMode(InboundMode.systemProxy),
                  ),
                ],
              ),
              if (disableTun)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    AppLocalizations.of(context)!.tunNeedAdmin,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
