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

import 'package:ads/ad.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_common/common.dart';
import 'package:flutter_common/services/auto_update.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vx/app/home/home.dart';
import 'package:vx/app/outbound/outbounds_bloc.dart';
import 'package:vx/app/settings/ads.dart';
import 'package:vx/app/settings/debug.dart';
import 'package:vx/app/settings/general/general.dart';
import 'package:vx/app/settings/service.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/common/common.dart';
import 'package:vx/data/database_provider.dart';
import 'package:vx/iap/pro.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:vx/app/settings/account.dart';
import 'package:vx/app/settings/advanced/advanced.dart';
import 'package:vx/app/settings/contact.dart';
import 'package:vx/app/settings/open_source_software_notice_screen.dart';
import 'package:vx/app/settings/privacy.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/auth/user.dart';
import 'package:vx/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/backup_service.dart';
import 'package:vx/utils/debug.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/path.dart';
import 'package:vx/utils/xapi_client.dart';
import 'package:vx/widgets/circular_progress_indicator.dart';
import 'package:vx/widgets/pro_icon.dart';
import 'package:vx/widgets/pro_promotion.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:window_manager/window_manager.dart';

final InAppReview inAppReview = InAppReview.instance;

enum SettingItem {
  account(icon: Icon(Icons.person_rounded), pathSegment: 'account'),
  advanced(icon: Icon(Icons.engineering_rounded), pathSegment: 'advanced'),
  general(icon: Icon(Icons.settings), pathSegment: 'general'),
  privacyPolicy(icon: Icon(Icons.info), pathSegment: 'privacy'),
  contactUs(icon: Icon(Icons.email_outlined), pathSegment: 'contactUs'),
  openSourceSoftwareNotice(
    icon: Icon(Icons.code_rounded),
    pathSegment: 'openSourceSoftwareNotice',
  ),
  debugLog(icon: Icon(Icons.bug_report_rounded), pathSegment: 'debugLog'),
  ads(icon: ImageIcon(AssetImage('assets/icons/ad.png')), pathSegment: 'ads');

  final Widget icon;
  final String pathSegment;

  const SettingItem({required this.icon, required this.pathSegment});

  static SettingItem? fromPathSegment(String pathSegment) {
    for (final se in SettingItem.values) {
      if (se.pathSegment == pathSegment) {
        return se;
      }
    }
    return null;
  }

  static SettingItem? fromFullPath(String fullPath) {
    for (final se in SettingItem.values) {
      if (fullPath.startsWith('/setting/${se.pathSegment}')) {
        return se;
      }
    }
    return null;
  }

  Widget getIcon(BuildContext context) {
    switch (this) {
      case SettingItem.account:
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (ctx, state) {
            if (state.proUser) {
              return proIcon;
            } else {
              return icon;
            }
          },
        );
      default:
        return icon;
    }
  }

  Widget title(BuildContext context) {
    switch (this) {
      case SettingItem.account:
        return Text(AppLocalizations.of(context)!.account);
      case SettingItem.advanced:
        return Text(AppLocalizations.of(context)!.advanced);
      case SettingItem.general:
        return Text(AppLocalizations.of(context)!.general);
      case SettingItem.privacyPolicy:
        return Text(AppLocalizations.of(context)!.privacyPolicy);
      case SettingItem.contactUs:
        return Text(AppLocalizations.of(context)!.contactUs);
      case SettingItem.openSourceSoftwareNotice:
        return Text(AppLocalizations.of(context)!.openSourceSoftwareNotice);
      case SettingItem.ads:
        return Text(AppLocalizations.of(context)!.promote);
      case SettingItem.debugLog:
        return Text(AppLocalizations.of(context)!.debugLog);
    }
  }

  Widget? subtitle(BuildContext context) {
    switch (this) {
      case SettingItem.account:
        return null;
      case SettingItem.advanced:
        return Text(AppLocalizations.of(context)!.advancedSettingDesc);
      case SettingItem.general:
        return null;
      case SettingItem.privacyPolicy:
        return null;
      case SettingItem.contactUs:
        return null;
      case SettingItem.openSourceSoftwareNotice:
        return null;
      case SettingItem.ads:
        return null;
      case SettingItem.debugLog:
        return null;
    }
  }
}

const String websiteUrl = 'https://vx.5vnetwork.com';

Future<void> _reset(BuildContext context) async {
  final pref = context.read<SharedPreferences>();
  await pref.clear();
  await _resetDatabaseFromCleanAsset(context);
}

Future<void> _repairDatabaseSchema(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final database = context.read<DatabaseProvider>().database;
  await context.read<XController>().stop();

  try {
    await database.repairSchemaFromCleanDb();
    snack(l10n.repairDbSchemaSuccess);
  } catch (e, stackTrace) {
    logger.e(
      'Failed to repair database schema',
      error: e,
      stackTrace: stackTrace,
    );
    snack(l10n.repairDbSchemaFailed(e.toString()));
  }
}

Future<void> _resetDatabaseFromCleanAsset(BuildContext context) async {
  final pref = context.read<SharedPreferences>();
  final backupService = context.read<BackupSerevice>();

  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.reset),
      content: Text(l10n.resetConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(AppLocalizations.of(context)!.close),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.resetAction),
        ),
      ],
    ),
  );
  if (confirmed != true) {
    return;
  }

  try {
    final blob = await rootBundle.load('assets/clean.db');
    final buffer = blob.buffer;
    final tempDbPath = await tempFilePath();
    await File(
      tempDbPath,
    ).writeAsBytes(buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes));
    pref.setDatabaseInitialized(false);
    await backupService.restoreFromLocalBackup(tempDbPath);

    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.resetCompletedTitle),
          content: Text(l10n.resetCompletedMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(dialogContext)!.close),
            ),
            FilledButton(
              onPressed: () async {
                exitCurrentApp(context.read<XController>());
              },
              child: Text(AppLocalizations.of(dialogContext)!.exit),
            ),
          ],
        ),
      );
    } else {
      snack(l10n.resetCompletedMessage);
    }
  } catch (e, stackTrace) {
    logger.e(
      'Failed to reset database from clean asset',
      error: e,
      stackTrace: stackTrace,
    );
    snack(l10n.resetFailed(e.toString()));
  }
}

class LargeSettingSreen extends StatefulWidget {
  const LargeSettingSreen({super.key, this.settingItem});

  final SettingItem? settingItem;

  @override
  State<LargeSettingSreen> createState() => _LargeSettingSreenState();
}

class _LargeSettingSreenState extends State<LargeSettingSreen> {
  SettingItem? selectedItem;

  @override
  void initState() {
    selectedItem = widget.settingItem;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant LargeSettingSreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settingItem != widget.settingItem) {
      selectedItem = widget.settingItem;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final list = ListView(
      children: SettingItem.values.map<Widget>((se) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: ListTile(
            minTileHeight: 64,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            leading: se.getIcon(context),
            title: se.title(context),
            subtitle: se.subtitle(context),
            // trailing: context.watch<AuthBloc>().state.pro ||
            //         se != SettingItem.advanced
            //     ? const Icon(Icons.keyboard_arrow_right_rounded)
            //     : proIcon,
            selected: selectedItem == se,
            selectedTileColor: Theme.of(context).colorScheme.surfaceContainer,
            onTap: () async {
              setState(() {
                selectedItem = se;
              });
              context.go('/setting/${se.pathSegment}');
            },
          ),
        );
      }).toList()..addAll(_getBottomButtons(context, user)),
    );

    late Widget detail;
    switch (selectedItem) {
      case SettingItem.general:
        // Use a nested Navigator for advanced settings
        detail = Navigator(
          onDidRemovePage: (page) {
            context.go('/setting');
          },
          pages: const [
            MaterialPage(child: GeneralSettingPage(showAppBar: false)),
          ],
        );
      case SettingItem.privacyPolicy:
        detail = const PrivacyPolicyScreen(showAppBar: false);
      case SettingItem.contactUs:
        detail = const ContactScreen(showAppBar: false);
      case SettingItem.openSourceSoftwareNotice:
        detail = const OpenSourceSoftwareNoticeScreen(showAppBar: false);
      case SettingItem.advanced:
        // Use a nested Navigator for advanced settings
        detail = Navigator(
          onDidRemovePage: (page) {
            context.go('/setting');
          },
          pages: const [MaterialPage(child: AdvancedScreen(showAppBar: false))],
        );
      case SettingItem.account:
        detail = const AccountPage(showAppBar: false);
      case SettingItem.ads:
        detail = const PromotionPage(showAppBar: false);
      case SettingItem.debugLog:
        detail = const DebugLogPage(showAppBar: false);
      default:
        detail = const SizedBox.shrink();
    }

    return Material(
      child: Row(
        children: [
          Expanded(child: list),
          const VerticalDivider(),
          Expanded(
            child: KeyedSubtree(key: ValueKey(selectedItem), child: detail),
          ),
        ],
      ),
    );
  }
}

List<Widget> _getBottomButtons(BuildContext context, User? user) {
  return [
    const SizedBox(height: 5),
    if (context.watch<AuthBloc>().state.isActivated)
      const Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(bottom: 10.0, left: 5.0),
          child: ActivatedIcon(),
        ),
      ),
    if ((user == null || (user.lifetimePro == false)) &&
        !context.watch<AuthBloc>().state.isActivated &&
        !applePlatform)
      Padding(
        padding: const EdgeInsets.only(left: 5, right: 5, bottom: 5),
        child: OutlinedButton.icon(
          onPressed: () {
            if (useStripe) {
              launchUrl(getProPaymentLink(user?.email ?? '', user?.id ?? ''));
            } else {
              showProPromotionDialog(context, showTitle: false);
            }
          },
          icon: Icon(
            Icons.stars_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: AutoSizeText(
            AppLocalizations.of(context)!.upgradeToPermanentPro,
            maxLines: 1,
            minFontSize: 12,
          ),
        ),
      ),
    if ((!useStripe && (user == null || (user.lifetimePro == false))) &&
        !applePlatform)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: OutlinedButton.icon(
          onPressed: () {
            if (user == null) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.loginBeforeRestore),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(AppLocalizations.of(context)!.close),
                    ),
                  ],
                ),
              );
            } else {
              context.read<ProPurchases>().restore();
            }
          },
          icon: Icon(
            Icons.history_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          label: AutoSizeText(
            AppLocalizations.of(context)!.restoreIAP,
            maxLines: 1,
            minFontSize: 12,
          ),
        ),
      ),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: OutlinedButton.icon(
        onPressed: () {
          launchUrl(Uri.parse(websiteUrl));
        },
        label: Text(AppLocalizations.of(context)!.website),
        icon: const Icon(Icons.link),
      ),
    ),
    const SizedBox(height: 5),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: OutlinedButton.icon(
        onPressed: () async {
          context.read<SharedPreferences>().setReviewAutoPromptDisabled(true);
          if (await inAppReview.isAvailable()) {
            inAppReview.requestReview();
          } else {
            inAppReview.openStoreListing(
              appStoreId: '6744701950',
              microsoftStoreId: '9PHBCBZ9R1FX',
            );
          }
        },
        label: Text(AppLocalizations.of(context)!.rateApp),
        icon: const Icon(Icons.rate_review_outlined),
      ),
    ),
    const Gap(5),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: OutlinedButton.icon(
        onPressed: () {
          launchUrl(Uri.parse('https://www.youtube.com/@vproxy5vnetwork'));
        },
        label: Text(AppLocalizations.of(context)!.tutorial),
        icon: Image.asset('assets/icons/youtube.png', width: 24, height: 24),
      ),
    ),
    const SizedBox(height: 5),
    if (!applePlatform)
      Padding(
        padding: const EdgeInsets.only(left: 5, right: 5, bottom: 5),
        child: OutlinedButton.icon(
          onPressed: () {
            launchUrl(Uri.parse(adWantedUrl));
          },
          label: Text(AppLocalizations.of(context)!.adWanted),
          icon: Icon(
            Icons.campaign_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: OutlinedButton.icon(
        onPressed: () => _repairDatabaseSchema(context),
        icon: const Icon(Icons.build_circle_outlined),
        label: Text(AppLocalizations.of(context)!.repairDbSchemaAction),
      ),
    ),
    const SizedBox(height: 5),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: OutlinedButton.icon(
        onPressed: () => _reset(context),
        icon: Icon(Icons.restart_alt_rounded),
        label: Text(AppLocalizations.of(context)!.reset),
      ),
    ),
    if (isWinStore)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        child: WindowsServiceButtons(),
      ),
    const Gap(5),
    const Version(),
    const Gap(5),
    if (autoUpdateSupported) const CheckUpdateButton(),
    BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.proUser) {
          return const SizedBox.shrink();
        }
        return const BannerAdWidget();
      },
    ),
    if (!isProduction())
      Column(
        children: [
          const IconButton(
            onPressed: saveLogToApplicationDocumentsDir,
            icon: Icon(Icons.file_copy),
          ),
          IconButton(
            onPressed: () async {
              final dbPath = await getDbPath(context.read<SharedPreferences>());
              clearDatabase(dbPath);
            },
            icon: const Icon(Icons.delete),
          ),
          TextButton(
            onPressed: () async {
              final dstDir = Platform.isAndroid
                  ? ('/storage/emulated/0/Documents/vx')
                  : (await getApplicationDocumentsDirectory()).path;
              if (!Directory(dstDir).existsSync()) {
                Directory(dstDir).createSync(recursive: true);
              }
              final newFile = await File(
                await getDbPath(context.read<SharedPreferences>()),
              ).copy(join(dstDir, "db.sqlite"));
              print('copied, ${newFile.path}');
            },
            child: const Text('Copy Database'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().unsetTestUser();
            },
            child: const Text('Unset'),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().setTestUser();
            },
            child: const Text('Set'),
          ),
          ElevatedButton(
            onPressed: () {
              throw StateError('This is test exception');
            },
            child: const Text('Verify Sentry Setup'),
          ),
          ElevatedButton(
            onPressed: () {
              throw Exception('This is test exception');
            },
            child: const Text('Verify Crashlytics Setup'),
          ),
        ],
      ),
  ];
}

class CompactSettingScreen extends StatelessWidget {
  const CompactSettingScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(AppLocalizations.of(context)!.settings),
              leading: IconButton(
                onPressed: () {
                  context.pop();
                },
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              automaticallyImplyLeading: true,
            )
          : null,
      body: ListView(
        children: SettingItem.values.map<Widget>((se) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: ListTile(
              minTileHeight: 64,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              leading: se.getIcon(context),
              title: se.title(context),
              subtitle: se.subtitle(context),
              trailing: const Icon(Icons.keyboard_arrow_right_rounded),
              onTap: () async {
                final currentPath =
                    GoRouterState.of(context).fullPath ??
                    GoRouter.of(
                      context,
                    ).routeInformationProvider.value.uri.toString();
                final basePath = currentPath.endsWith('/')
                    ? currentPath.substring(0, currentPath.length - 1)
                    : currentPath;
                final newPath = '$basePath/${se.pathSegment}';
                GoRouter.of(context).push(newPath);
              },
            ),
          );
        }).toList()..addAll(_getBottomButtons(context, user)),
      ),
    );
  }
}

class Version extends StatelessWidget {
  const Version({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError) {
          return const SizedBox();
        } else {
          final packageInfo = snapshot.data!;
          int count = 0;
          return Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                return GestureDetector(
                  onLongPress: () {
                    throw Exception('This is test exception');
                  },
                  onTap: () async {
                    setState(() {
                      print('count: $count');
                      count++;
                    });
                    if (count >= 10) {
                      demo = true;
                      App.of(context)?.rebuildAllChildren();
                      if (Platform.isMacOS) {
                        await windowManager.setSize(const Size(1280, 800));
                      }
                      context.read<RealtimeSpeedNotifier>().demo();
                    }
                  },
                  child: Text(
                    'Version: ${packageInfo.version} (${packageInfo.buildNumber})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }
}

AppBar getAdaptiveAppBar(BuildContext context, Widget? title) {
  return AppBar(
    automaticallyImplyLeading: Platform.isMacOS ? false : true,
    title: title,
    actions: [
      if (Platform.isMacOS)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
    ],
  );
}

class CheckUpdateButton extends StatefulWidget {
  const CheckUpdateButton({super.key});

  @override
  State<CheckUpdateButton> createState() => _CheckUpdateButtonState();
}

class _CheckUpdateButtonState extends State<CheckUpdateButton> {
  bool _checkingUpdate = false;

  @override
  Widget build(BuildContext context) {
    final autoUpdateService = context.watch<AutoUpdateService>();
    final isDownloading = autoUpdateService.isDownloading;

    return TextButton(
      onPressed: (_checkingUpdate || isDownloading)
          ? null
          : () async {
              setState(() {
                _checkingUpdate = true;
              });
              try {
                final release = await autoUpdateService.getLatestRelease();
                if (release != null) {
                  setState(() {
                    _checkingUpdate = false;
                  });
                  await autoUpdateService.updateToRelease(release);
                } else {
                  snack(AppLocalizations.of(context)!.noNewVersion);
                }
              } catch (e, stackTrace) {
                logger.e(
                  'Error checking update',
                  error: e,
                  stackTrace: stackTrace,
                );
                snack(e.toString());
              } finally {
                if (mounted) {
                  setState(() {
                    _checkingUpdate = false;
                  });
                }
              }
            },
      child: _checkingUpdate
          ? smallCircularProgressIndicator
          : Text(
              isDownloading
                  ? AppLocalizations.of(
                      context,
                    )!.downloading(autoUpdateService.downloadingVersion ?? '')
                  : AppLocalizations.of(context)!.checkUpdate,
            ),
    );
  }
}
