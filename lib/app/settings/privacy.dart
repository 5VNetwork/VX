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
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vx/common/common.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vx/app/settings/setting.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/logger.dart';
import 'package:vx/utils/upload_log.dart';

const String privacyPolicyUrl = 'https://vx.5vnetwork.com/privacy';
const String termOfServiceUrl = 'https://vx.5vnetwork.com/terms';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _shareLog = false;
  bool _shareCnDirectApps = false;

  @override
  void initState() {
    super.initState();
    final pref = context.read<SharedPreferences>();
    _shareLog = pref.shareLog;
    _shareCnDirectApps = pref.shareCnDirectApps;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? getAdaptiveAppBar(
              context,
              Text(AppLocalizations.of(context)!.privacyPolicy),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.privacyPolicySummary),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
              ),
              onPressed: () {
                launchUrl(Uri.parse(privacyPolicyUrl));
              },
              child: Text(AppLocalizations.of(context)!.privacyPolicy),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.shareDiagnosticLogWithDeveloper,
                ),
                const Spacer(),
                Switch(
                  value: _shareLog,
                  onChanged: isPkg
                      ? null
                      : (value) {
                          setState(() {
                            _shareLog = value;
                          });
                          setShareLog(
                            _shareLog,
                            context.read<SharedPreferences>(),
                            context.read<LogUploadService>(),
                          );
                        },
                ),
              ],
            ),
            const Gap(5),
            Text(
              AppLocalizations.of(
                context,
              )!.diagnosticLogDoesNotContainPersonalData,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (Platform.isAndroid) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(
                        context,
                      )!.shareCnDirectAppsWithDeveloper,
                    ),
                  ),
                  Switch(
                    value: _shareCnDirectApps,
                    onChanged: isPkg
                        ? null
                        : (value) {
                            setState(() {
                              _shareCnDirectApps = value;
                            });
                            context
                                .read<SharedPreferences>()
                                .setShareCnDirectApps(value);
                          },
                  ),
                ],
              ),
              const Gap(5),
              Text(
                AppLocalizations.of(context)!.shareCnDirectAppsDescription,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> setShareLog(
    bool value,
    SharedPreferences pref,
    LogUploadService logUploadService,
  ) async {
    pref.setShareLog(value);
    if (value) {
      await startShareLog();
      logUploadService.start();
    } else {
      await stopShareLog();
      logUploadService.stopPeriodicUpload();
    }
  }
}
