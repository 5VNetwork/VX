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
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import "package:flutter/material.dart";
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vx/app/outbound/outbound_repo.dart';
import 'package:vx/app/outbound/subscription.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/qr.dart';
import 'package:vx/app/outbound/add.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vx/app/home/home.dart';
import 'package:vx/app/layout_provider.dart';
import 'package:vx/app/outbound/outbounds_bloc.dart';
import 'package:vx/app/outbound/subscription_bloc.dart';
import 'package:vx/common/common.dart';
import 'package:vx/common/share_link_query_extra.dart';
import 'package:vx/data/database.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/widgets/pro_icon.dart';
import 'package:vx/widgets/pro_promotion.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

const List<int> _subscriptionUpdateIntervals = [
  5,
  10,
  20,
  30,
  60,
  120,
  180,
  240,
  300,
  360,
  420,
  480,
  540,
  600,
  660,
  720,
  780,
  840,
  900,
  960,
  1020,
  1080,
  1140,
  1200,
  1260,
  1320,
  1380,
  1440,
];

String _formatSubscriptionInterval(BuildContext context, int minutes) {
  if (minutes < 60) {
    return AppLocalizations.of(context)!.min(minutes);
  } else if (minutes < 1440) {
    return AppLocalizations.of(context)!.hour(minutes ~/ 60);
  } else {
    return AppLocalizations.of(context)!.hour(24);
  }
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  late Widget _cache;
  final double width = 190;

  late final Widget _updateAllButton;

  @override
  void initState() {
    _updateAllButton = BlocSelector<SubscriptionBloc, SubscriptionState, bool>(
      selector: (state) => state.updatingAll,
      builder: (ctx, updating) {
        return FilledButton.tonalIcon(
          onPressed: updating
              ? null
              : () async {
                  context.read<SubscriptionBloc>().add(
                    UpdateSubscriptionsButtonClickedEvent(),
                  );
                },
          icon: updating
              ? const Padding(
                  padding: EdgeInsets.all(2.0),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.refresh_rounded),
          label: Text(AppLocalizations.of(context)!.update),
        );
      },
    );
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cache = StreamBuilder<List<Subscription>>(
      stream: context.watch<OutboundRepo>().getStreamOfSubs(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const SizedBox();
        }
        final showAd = !ctx.watch<AuthBloc>().state.pro;
        snap.data!.sort((a, b) => a.placeOnTop ? -1 : 1);
        return Material(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 10, top: 8),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: Platform.isAndroid || Platform.isIOS
                        ? 145
                        : 130,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  delegate: SliverChildBuilderDelegate((ctx, index) {
                    // if (index == 0 && showAd) {
                    //   return const _AdCard();
                    // }
                    // if ((index - (showAd ? 1 : 0)) >= snap.data!.length) {
                    //   return null;
                    // }
                    return SubScriptionListTile(
                      group: snap.data![index /* - (showAd ? 1 : 0) */],
                    );
                  }, childCount: snap.data!.length),
                ),
              ),
              if (showAd) const Ads(),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
              // if (showAd)
              //   SliverToBoxAdapter(
              //     child: LayoutBuilder(builder: (ctx, constraints) {
              //       return MyScrollingAdWidget(
              //         width: constraints.maxWidth,
              //         height: constraints.maxHeight,
              //       );
              //     }),
              //   )
            ],
          ),
          // Column(
          //   children: [
          //     ListView(
          //       clipBehavior: Clip.hardEdge,
          //       shrinkWrap: true,
          //       padding: EdgeInsets.only(bottom: showAd ? 0 : 60),
          //       // gridDelegate:
          //       //     SliverGridDelegateWithFixedCrossAxisCount(
          //       //   crossAxisCount: count,
          //       //   childAspectRatio: width / 98,
          //       //   crossAxisSpacing: 10,
          //       //   mainAxisSpacing: 10,
          //       // ),
          //       children: snap.data!.map<Widget>((group) {
          //         return _SubScriptionListTile(group: group, mode: mode);
          //       }).toList(),
          //     ),
          //     if (showAd)
          //       Expanded(child: LayoutBuilder(builder: (ctx, constraints) {
          //         return MyScrollingAdWidget(
          //           width: constraints.maxWidth,
          //           height: constraints.maxHeight,
          //         );
          //       }))
          //   ],
          // ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext ctx) {
    final size = MediaQuery.sizeOf(context);
    final isCompact = size.width <= 600;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(5),
          Row(
            children: [
              _updateAllButton,
              const Gap(10),
              // if (showAd)
              //   MouseRegion(
              //     cursor: SystemMouseCursors.click,
              //     child: GestureDetector(
              //       onTap: () {
              //         launchUrl(Uri.parse(konglongUrl));
              //       },
              //       child: Stack(
              //         children: [
              //           SvgPicture.asset(
              //             'assets/ads/konglong.svg',
              //             width: 100,
              //             height: 30,
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
              const Expanded(child: SizedBox()),
              IconButton(
                tooltip: AppLocalizations.of(context)!.settings,
                onPressed: () => _openUpdateSettings(isCompact),
                icon: const Icon(Icons.settings_rounded),
              ),
              const Gap(8),
              const AddMenuAnchor(colored: true),
            ],
          ),
          Expanded(child: _cache),
        ],
      ),
    );
  }

  Future<void> _openUpdateSettings(bool isCompact) async {
    final pref = context.read<SharedPreferences>();
    final autoUpdate = pref.autoUpdate;
    final savedInterval = pref.updateInterval;
    final selectedIndex = _subscriptionUpdateIntervals.indexOf(savedInterval);
    final normalizedSelectedIndex = selectedIndex >= 0 ? selectedIndex : 7;
    if (isCompact) {
      await Navigator.of(context, rootNavigator: true).push<void>(
        MaterialPageRoute(
          builder: (context) => _SubscriptionUpdateSettingsPage(
            initialAutoUpdate: autoUpdate,
            initialSelectedIndex: normalizedSelectedIndex,
            intervals: _subscriptionUpdateIntervals,
            formatInterval: _formatSubscriptionInterval,
          ),
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _SubscriptionUpdateSettingsDialog(
        initialAutoUpdate: autoUpdate,
        initialSelectedIndex: normalizedSelectedIndex,
        intervals: _subscriptionUpdateIntervals,
        formatInterval: _formatSubscriptionInterval,
      ),
    );
  }
}

class _SubscriptionUpdateSettingsContent extends StatefulWidget {
  const _SubscriptionUpdateSettingsContent({
    required this.initialAutoUpdate,
    required this.initialSelectedIndex,
    required this.intervals,
    required this.formatInterval,
  });

  final bool initialAutoUpdate;
  final int initialSelectedIndex;
  final List<int> intervals;
  final String Function(BuildContext, int) formatInterval;

  @override
  State<_SubscriptionUpdateSettingsContent> createState() =>
      _SubscriptionUpdateSettingsContentState();
}

class _SubscriptionUpdateSettingsContentState
    extends State<_SubscriptionUpdateSettingsContent> {
  late bool _autoUpdate = widget.initialAutoUpdate;
  late int _selectedIndex = widget.initialSelectedIndex;

  void _applyUpdateSettings() {
    context.read<SharedPreferences>().setAutoUpdate(_autoUpdate);
    context.read<XController>().setSubscriptionAutoUpdate(_autoUpdate);
    context.read<AutoSubscriptionUpdater>().reset();
  }

  void _applyInterval() {
    context.read<SharedPreferences>().setUpdateInterval(
      widget.intervals[_selectedIndex],
    );
    context.read<XController>().setSubscriptionInterval(
      widget.intervals[_selectedIndex],
    );
    context.read<AutoSubscriptionUpdater>().onIntervalChange(
      widget.intervals[_selectedIndex],
    );
  }

  @override
  Widget build(BuildContext context) {
    final slider = Slider(
      value: _selectedIndex.toDouble(),
      min: 0,
      max: (widget.intervals.length - 1).toDouble(),
      divisions: widget.intervals.length - 1,
      label: widget.formatInterval(context, widget.intervals[_selectedIndex]),
      onChanged: _autoUpdate
          ? (value) {
              setState(() {
                _selectedIndex = value.round();
              });
              _applyInterval();
            }
          : null,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(AppLocalizations.of(context)!.autoUpdate),
          value: _autoUpdate,
          onChanged: (value) {
            setState(() {
              _autoUpdate = value;
            });
            _applyUpdateSettings();
          },
        ),
        if (_autoUpdate) ...[
          const Gap(8),
          Row(
            children: [
              Text(AppLocalizations.of(context)!.updateInterval),
              const Spacer(),
              Text(
                widget.formatInterval(
                  context,
                  widget.intervals[_selectedIndex],
                ),
              ),
            ],
          ),
          SizedBox(width: 460, child: slider),
        ],
      ],
    );
  }
}

class _SubscriptionUpdateSettingsDialog extends StatefulWidget {
  const _SubscriptionUpdateSettingsDialog({
    required this.initialAutoUpdate,
    required this.initialSelectedIndex,
    required this.intervals,
    required this.formatInterval,
  });

  final bool initialAutoUpdate;
  final int initialSelectedIndex;
  final List<int> intervals;
  final String Function(BuildContext, int) formatInterval;

  @override
  State<_SubscriptionUpdateSettingsDialog> createState() =>
      _SubscriptionUpdateSettingsDialogState();
}

class _SubscriptionUpdateSettingsDialogState
    extends State<_SubscriptionUpdateSettingsDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.settings),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: _SubscriptionUpdateSettingsContent(
          initialAutoUpdate: widget.initialAutoUpdate,
          initialSelectedIndex: widget.initialSelectedIndex,
          intervals: widget.intervals,
          formatInterval: widget.formatInterval,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.close),
        ),
      ],
    );
  }
}

class _SubscriptionUpdateSettingsPage extends StatefulWidget {
  const _SubscriptionUpdateSettingsPage({
    required this.initialAutoUpdate,
    required this.initialSelectedIndex,
    required this.intervals,
    required this.formatInterval,
  });

  final bool initialAutoUpdate;
  final int initialSelectedIndex;
  final List<int> intervals;
  final String Function(BuildContext, int) formatInterval;

  @override
  State<_SubscriptionUpdateSettingsPage> createState() =>
      _SubscriptionUpdateSettingsPageState();
}

class _SubscriptionUpdateSettingsPageState
    extends State<_SubscriptionUpdateSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _SubscriptionUpdateSettingsContent(
          initialAutoUpdate: widget.initialAutoUpdate,
          initialSelectedIndex: widget.initialSelectedIndex,
          intervals: widget.intervals,
          formatInterval: widget.formatInterval,
        ),
      ),
    );
  }
}

class SubScriptionListTile extends StatefulWidget {
  const SubScriptionListTile({super.key, required this.group});
  final Subscription group;
  @override
  State<SubScriptionListTile> createState() => _SubScriptionListTileState();
}

final noExpirationDate = DateTime(9999, 12, 31);

class SubscriptionData {
  final String? totalData;
  final String? usedData;
  final String? remainingData;
  final DateTime? expirationDate;
  final double? usagePercentage;

  SubscriptionData({
    this.totalData,
    this.usedData,
    this.remainingData,
    this.expirationDate,
    this.usagePercentage,
  });

  static SubscriptionData? parse(String description) {
    // Parse format: "STATUS=🚀↑:1.42GB,↓:4.48GB,TOT:200GB💡Expires:2025-12-04"
    // Or Chinese format: "剩余流量: 12.165GB。到期: 2025年11月20日 15时。"
    // Or key-value format: "upload=1234; download=2234; total=1024000; expire=2218532293"
    String? totalData;
    String? usedData;
    String? remainingData;
    DateTime? expirationDate;
    double? usagePercentage;

    try {
      if (description.contains('剩余流量')) {
        // Try Chinese format first: "剩余流量: 12.165GB。到期: 2025年11月20日 15时。"
        final chineseRemainingMatch = RegExp(
          r'剩余流量[：:]\s*(\d+(?:\.\d+)?)\s*(GB|MB|KB|TB)',
          caseSensitive: false,
        ).firstMatch(description);
        if (chineseRemainingMatch != null) {
          remainingData =
              '${chineseRemainingMatch.group(1)}${chineseRemainingMatch.group(2)}';
        }
        // Extract Chinese expiration date: "到期: 2025年11月20日 15时" or "到期: 不过期"
        final chineseExpirationMatch = RegExp(
          r'到期[：:]\s*(?:不过期|(\d{4})年(\d{1,2})月(\d{1,2})日)',
        ).firstMatch(description);
        if (chineseExpirationMatch != null) {
          // Check if it's "不过期" (no expiration) - group 1 will be null
          if (chineseExpirationMatch.group(1) != null) {
            final year = chineseExpirationMatch.group(1);
            final month = chineseExpirationMatch.group(2)!.padLeft(2, '0');
            final day = chineseExpirationMatch.group(3)!.padLeft(2, '0');
            expirationDate = DateTime.tryParse('$year-$month-$day');
          } else {
            expirationDate = noExpirationDate;
          }
          // If group 1 is null, it means "不过期" was matched, so expirationDate stays null
        }
      } else {
        // If Chinese format didn't match, try key-value format: "upload=1234; download=2234; total=1024000; expire=2218532293"
        final keyValueMatch = RegExp(
          r'upload\s*=\s*(\d+)\s*;\s*download\s*=\s*(\d+)\s*;\s*total\s*=\s*(\d+)\s*;\s*expire\s*=\s*(\d+)',
          caseSensitive: false,
        ).firstMatch(description);

        if (keyValueMatch != null) {
          // Parse values (they're in bytes)
          final uploadBytes = int.tryParse(keyValueMatch.group(1) ?? '0') ?? 0;
          final downloadBytes =
              int.tryParse(keyValueMatch.group(2) ?? '0') ?? 0;
          final totalBytes = int.tryParse(keyValueMatch.group(3) ?? '0') ?? 0;
          final expireTimestamp =
              int.tryParse(keyValueMatch.group(4) ?? '0') ?? 0;
          // Convert bytes to human-readable format
          String formatBytes(int bytes) {
            if (bytes >= 1024 * 1024 * 1024 * 1024) {
              return '${(bytes / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(2)}TB';
            } else if (bytes >= 1024 * 1024 * 1024) {
              return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)}GB';
            } else if (bytes >= 1024 * 1024) {
              return '${(bytes / (1024 * 1024)).toStringAsFixed(2)}MB';
            } else if (bytes >= 1024) {
              return '${(bytes / 1024).toStringAsFixed(2)}KB';
            } else {
              return '${bytes}B';
            }
          }

          totalData = formatBytes(totalBytes);
          final usedBytes = uploadBytes + downloadBytes;
          usedData = formatBytes(usedBytes);
          final remainingBytes = totalBytes - usedBytes;
          remainingData = formatBytes(remainingBytes);
          usagePercentage = totalBytes > 0
              ? (usedBytes / totalBytes).clamp(0.0, 1.0)
              : 0.0;

          // Convert Unix timestamp to DateTime
          if (expireTimestamp > 0) {
            expirationDate = DateTime.fromMillisecondsSinceEpoch(
              expireTimestamp * 1000,
              isUtc: true,
            );
          }
        } else {
          // Try standard format
          // Extract total data
          final totMatch = RegExp(
            r'TOT:(\d+(?:\.\d+)?)\s*(GB|MB|KB|TB)',
            caseSensitive: false,
          ).firstMatch(description);
          if (totMatch != null) {
            totalData = '${totMatch.group(1)}${totMatch.group(2)}';
          }

          // Extract upload data
          final uploadMatch = RegExp(
            r'↑:(\d+(?:\.\d+)?)\s*(GB|MB|KB|TB)',
            caseSensitive: false,
          ).firstMatch(description);

          // Extract download data
          final downloadMatch = RegExp(
            r'↓:(\d+(?:\.\d+)?)\s*(GB|MB|KB|TB)',
            caseSensitive: false,
          ).firstMatch(description);

          // Calculate used data
          if (uploadMatch != null && downloadMatch != null) {
            final upload = double.tryParse(uploadMatch.group(1) ?? '0') ?? 0;
            final download =
                double.tryParse(downloadMatch.group(1) ?? '0') ?? 0;
            final total = upload + download;
            usedData = '${total.toStringAsFixed(2)}GB';
          }

          // Calculate remaining data and percentage
          if (totalData != null && usedData != null) {
            final totalValue = double.tryParse(totMatch!.group(1) ?? '0') ?? 0;
            final usedValue =
                double.tryParse(usedData.replaceAll(RegExp(r'[^\d.]'), '')) ??
                0;
            final remaining = totalValue - usedValue;
            remainingData = '${remaining.toStringAsFixed(2)}GB';
            usagePercentage = totalValue > 0
                ? (usedValue / totalValue).clamp(0.0, 1.0)
                : 0.0;
          }

          // Extract expiration date
          final expiresMatch = RegExp(
            r'Expires?:\s*(\d{4}-\d{2}-\d{2})',
          ).firstMatch(description);
          if (expiresMatch != null) {
            expirationDate = DateTime.tryParse(expiresMatch.group(1)!);
          }
        }
      }
    } catch (e) {
      // If parsing fails, return empty data
      logger.e('Failed to parse subscription data: $e');
    }

    return SubscriptionData(
      totalData: totalData,
      usedData: usedData,
      remainingData: remainingData,
      expirationDate: expirationDate,
      usagePercentage: usagePercentage,
    );
  }
}

class _SubScriptionListTileState extends State<SubScriptionListTile> {
  final MenuController _menuController = MenuController();

  void _onTap(BuildContext context, Subscription group) async {
    final outboundBloc = context.read<SubscriptionBloc>();
    final fullScreen = Provider.of<MyLayout>(context, listen: false).isCompact;
    SubscriptionFormData? subscriptiopnFormData;
    if (fullScreen) {
      subscriptiopnFormData = await Navigator.of(context, rootNavigator: true)
          .push<SubscriptionFormData>(
            CupertinoPageRoute(
              builder: (ctx) => EditSubscriptionFullScreen(group: group),
            ),
          );
    } else {
      subscriptiopnFormData = await showDialog<SubscriptionFormData>(
        context: context,
        builder: (ctx) => EditSubscriptionDialog(group: group),
      );
    }
    if (subscriptiopnFormData != null &&
        (subscriptiopnFormData.link != group.link ||
            subscriptiopnFormData.name != group.name ||
            subscriptiopnFormData.shareLinkQueryExtra !=
                group.shareLinkQueryExtra)) {
      outboundBloc.add(
        SubscriptionEditedEvent(
          id: group.id,
          name: subscriptiopnFormData.name != group.name
              ? subscriptiopnFormData.name
              : null,
          link: subscriptiopnFormData.link != group.link
              ? subscriptiopnFormData.link
              : null,
          shareLinkQueryExtra:
              subscriptiopnFormData.shareLinkQueryExtra !=
                  group.shareLinkQueryExtra
              ? subscriptiopnFormData.shareLinkQueryExtra
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsedData = SubscriptionData.parse(widget.group.description);
    final subState = context.read<SubscriptionBloc>().state;
    final hasUpdateError =
        (!subState.updatingSubs.contains(widget.group.id) &&
            !subState.updatingAll) &&
        widget.group.lastSuccessUpdate != widget.group.lastUpdate;
    final colorScheme = Theme.of(context).colorScheme;

    // Check if subscription is expiring soon (within 7 days)
    final isExpiringSoon =
        parsedData?.expirationDate != null &&
        parsedData!.expirationDate!.difference(DateTime.now()).inDays <= 7 &&
        parsedData.expirationDate!.isAfter(DateTime.now());

    // Check if expired
    final isExpired =
        parsedData?.expirationDate != null &&
        parsedData!.expirationDate!.isBefore(DateTime.now());

    final isPro = context.read<AuthBloc>().state.pro;
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          leadingIcon: const Icon(Icons.edit_rounded),
          child: Text(AppLocalizations.of(context)!.edit),
          onPressed: () => _onTap(context, widget.group),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.add_home_rounded),
          trailingIcon: isPro ? null : proIcon,
          child: Text(AppLocalizations.of(context)!.addToHomeScreen),
          onPressed: () {
            if (!isPro) {
              showProPromotionDialog(context);
            }
            context.read<HomeLayoutRepo>().addWidgetIdToHome(
              'SUBSCRIPTION_${widget.group.id}',
            );
          },
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.arrow_upward_rounded),
          child: Text(
            widget.group.placeOnTop
                ? AppLocalizations.of(context)!.stopPlaceOnTop
                : AppLocalizations.of(context)!.placeOnTop,
          ),
          onPressed: () => context.read<OutboundBloc>().add(
            SubscriptionPlaceOnTopEvent(widget.group),
          ),
        ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.share_rounded),
          child: Text(AppLocalizations.of(context)!.share),
          onPressed: () => shareQrCode(context, widget.group.link),
        ),
        const Divider(),
        MenuItemButton(
          leadingIcon: const Icon(Icons.delete_rounded),
          child: Text(AppLocalizations.of(context)!.delete),
          onPressed: () => context.read<OutboundBloc>().add(
            SubscriptionDeleteEvent(widget.group),
          ),
        ),
      ],
      controller: _menuController,
      child: GestureDetector(
        onLongPressStart: (details) {
          if (!desktopPlatforms) {
            _menuController.open();
          }
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onSecondaryTapDown: (TapDownDetails details) {
            _menuController.open(
              position: Offset(
                details.localPosition.dx,
                details.localPosition.dy,
              ),
            );
          },
          onTap: () => _onTap(context, widget.group),
          child: Card(
            elevation: widget.group.placeOnTop ? 2 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: widget.group.placeOnTop
                    ? colorScheme.primary.withOpacity(0.3)
                    : colorScheme.outlineVariant,
                width: widget.group.placeOnTop ? 1.5 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row with name and update button
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.group.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      UpdateSubButton(sub: widget.group),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Show parsed data if available
                  if (parsedData?.expirationDate != null ||
                      parsedData?.remainingData != null) ...[
                    // Data usage section
                    if (parsedData?.remainingData != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.data_usage_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            parsedData!.totalData != null
                                ? '${parsedData.remainingData} / ${parsedData.totalData}'
                                : parsedData.remainingData!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                          ),
                          const Spacer(),
                          if (parsedData.expirationDate != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isExpired
                                      ? Icons.error
                                      : isExpiringSoon
                                      ? Icons.warning_amber_rounded
                                      : Icons.calendar_month,
                                  size: 16,
                                  color: isExpired
                                      ? colorScheme.error
                                      : colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  parsedData.expirationDate == noExpirationDate
                                      ? 'Forever'
                                      : DateFormat(
                                          'yyyy-MM-dd',
                                        ).format(parsedData.expirationDate!),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ]
                  // Show description if no parsed data available
                  else if (widget.group.description.isNotEmpty) ...[
                    AutoSizeText(
                      widget.group.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      minFontSize: 10,
                    ),
                  ],
                  // Push content to bottom
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        hasUpdateError ? Icons.error_outline : Icons.schedule,
                        size: 12,
                        color: hasUpdateError
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          hasUpdateError
                              ? AppLocalizations.of(context)!.failure
                              : '${AppLocalizations.of(context)!.updatedAt} ${DateFormat('MM-dd HH:mm', Localizations.localeOf(context).toString()).format(DateTime.fromMillisecondsSinceEpoch(widget.group.lastSuccessUpdate))}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontSize: 10,
                                color: hasUpdateError
                                    ? colorScheme.error
                                    : colorScheme.onSurfaceVariant.withOpacity(
                                        0.7,
                                      ),
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UpdateSubButton extends StatelessWidget {
  const UpdateSubButton({super.key, required this.sub});
  final Subscription sub;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (ctx, satte) {
        return IconButton(
          onPressed: satte.updatingAll || satte.updatingSubs.contains(sub.id)
              ? null
              : () => context.read<SubscriptionBloc>().add(
                  UpdateSubscriptionEvent(sub),
                ),
          icon: satte.updatingSubs.contains(sub.id)
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        );
      },
    );
  }
}

class SubscriptionFormData {
  SubscriptionFormData({
    this.name = '',
    this.link = '',
    this.shareLinkQueryExtra = '',
  });
  String name;
  String link;
  String shareLinkQueryExtra;
}

class SubscriptionForm extends StatefulWidget {
  const SubscriptionForm({
    super.key,
    required this.data,
    required this.formKey,
  });
  final SubscriptionFormData data;
  final GlobalKey<FormState> formKey;

  @override
  State<SubscriptionForm> createState() => _SubscriptionFormState();
}

class _SubscriptionFormState extends State<SubscriptionForm> {
  final _nameController = TextEditingController();
  final _linkController = TextEditingController();
  final _shareLinkQueryExtraController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    _nameController.text = widget.data.name;
    _linkController.text = widget.data.link;
    _shareLinkQueryExtraController.text = widget.data.shareLinkQueryExtra;
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _nameController.dispose();
    _linkController.dispose();
    _shareLinkQueryExtraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            onChanged: (value) => widget.data.name = value,
            decoration:
                InputDecoration(
                  labelText: AppLocalizations.of(context)!.name,
                ).applyDefaults(
                  const InputDecorationTheme(border: OutlineInputBorder()),
                ),
          ),
          const Gap(10),
          TextFormField(
            controller: _linkController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.subscriptionAddress,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => widget.data.link = value,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context)!.empty;
              }
              // if (!isValidHttpHttpsUrl(value)) {
              //   return AppLocalizations.of(context)!.invalidHttp;
              // }
              widget.data.link = value;
              return null;
            },
            style: const TextStyle(letterSpacing: 0),
          ),
          const Gap(10),
          TextFormField(
            controller: _shareLinkQueryExtraController,
            onChanged: (value) => widget.data.shareLinkQueryExtra = value,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(
                context,
              )!.subscriptionShareLinkQueryExtra,
              hintText: AppLocalizations.of(
                context,
              )!.subscriptionShareLinkQueryExtraHint,
              helperText: AppLocalizations.of(
                context,
              )!.subscriptionShareLinkQueryExtraHelper,
              border: const OutlineInputBorder(),
            ),
            validator: (value) {
              final v = value ?? '';
              if (!isValidShareLinkQueryExtra(v)) {
                return AppLocalizations.of(
                  context,
                )!.subscriptionShareLinkQueryExtraInvalid;
              }
              return null;
            },
            style: const TextStyle(letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}

class EditSubscriptionFullScreen extends StatefulWidget {
  const EditSubscriptionFullScreen({super.key, required this.group});
  final Subscription group;

  @override
  State<EditSubscriptionFullScreen> createState() =>
      _EditSubscriptionFullScreenState();
}

class _EditSubscriptionFullScreenState
    extends State<EditSubscriptionFullScreen> {
  final formKey = GlobalKey<FormState>();
  final _formData = SubscriptionFormData();
  @override
  void initState() {
    // TODO: implement initState
    _formData.name = widget.group.name;
    _formData.link = widget.group.link;
    _formData.shareLinkQueryExtra = widget.group.shareLinkQueryExtra;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.edit),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.pop(_formData);
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: SubscriptionForm(data: _formData, formKey: formKey),
      ),
    );
  }
}

class EditSubscriptionDialog extends StatefulWidget {
  const EditSubscriptionDialog({super.key, required this.group});
  final Subscription group;

  @override
  State<EditSubscriptionDialog> createState() => _EditSubscriptionDialogState();
}

class _EditSubscriptionDialogState extends State<EditSubscriptionDialog> {
  final formKey = GlobalKey<FormState>();
  final _formData = SubscriptionFormData();
  @override
  void initState() {
    // TODO: implement initState
    _formData.name = widget.group.name;
    _formData.link = widget.group.link;
    _formData.shareLinkQueryExtra = widget.group.shareLinkQueryExtra;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.edit),
      scrollable: true,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SubscriptionForm(data: _formData, formKey: formKey),
      ),
      actions: [
        FilledButton.tonal(
          onPressed: () => context.pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              context.pop(_formData);
            }
          },
          child: Text(AppLocalizations.of(context)!.save),
        ),
      ],
    );
  }
}
