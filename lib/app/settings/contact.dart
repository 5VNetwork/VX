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

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vx/l10n/app_localizations.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:vx/app/settings/setting.dart';
import 'package:vx/main.dart';

const String email = 'contactvproxy@proton.me';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showAppBar
          ? getAdaptiveAppBar(
              context,
              Text(AppLocalizations.of(context)!.contactUs),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.contactUsSummary),
            const SizedBox(height: 10),
            Row(
              children: [
                const Chip(label: Text(email)),
                IconButton(
                  onPressed: () {
                    Pasteboard.writeText(email);
                    rootScaffoldMessengerKey.currentState?.showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.copiedToClipboard,
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                ),
                // IconButton(
                //   onPressed: () {
                //     final Uri emailLaunchUri = Uri(
                //       scheme: 'mailto',
                //       path: email,
                //     );
                //     launchUrl(emailLaunchUri);
                //   },
                //   icon: const Icon(Icons.email_outlined),
                // ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // OutlinedButton.icon(
                //   onPressed: () {
                //     launchUrl(Uri.parse('https://x.com/vproxy5vnetwork'));
                //   },
                //   icon: Image.asset(
                //     MediaQuery.of(context).platformBrightness == Brightness.dark
                //         ? 'assets/icons/x_logo_white.png'
                //         : 'assets/icons/x_logo_black.png',
                //     width: 16,
                //     height: 16,
                //   ),
                //   label: const Text(' X'),
                // ),
                // const SizedBox(width: 10),
                // OutlinedButton.icon(
                //   onPressed: () {
                //     launchUrl(Uri.parse('https://t.me/vproxygroup'));
                //   },
                //   icon: Image.asset(
                //     'assets/icons/telegram_icon.png',
                //     width: 20,
                //     height: 20,
                //   ),
                //   label: Text(AppLocalizations.of(context)!.telegram),
                // ),
                // const SizedBox(width: 10),
                // OutlinedButton.icon(
                //   onPressed: () {
                //     launchUrl(
                //       Uri.parse('https://www.youtube.com/@vproxy5vnetwork'),
                //     );
                //   },
                //   icon: Image.asset(
                //     'assets/icons/youtube.png',
                //     width: 24,
                //     height: 24,
                //   ),
                //   label: const Text('Youtube'),
                // ),
              ],
            ),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context)!.contactUsFreely),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context)!.contactUsProPriority),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context)!.bugAreWelcome),
          ],
        ),
      ),
    );
  }
}
