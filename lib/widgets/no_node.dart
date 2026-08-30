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
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gap/gap.dart';
import 'package:vx/app/settings/contact.dart';
import 'package:vx/l10n/app_localizations.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppLocalizations.of(context)!.sourceCodeAvailable,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        const Gap(10),
        Wrap(
          spacing: 10,
          runSpacing: 5,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                launchUrl(Uri.parse('https://github.com/5vnetwork/vx'));
              },
              icon: SvgPicture.asset(
                Theme.of(context).brightness == Brightness.dark
                    ? 'assets/icons/github-mark-white.svg'
                    : 'assets/icons/github-mark.svg',
                width: 18,
                height: 18,
              ),
              label: Text(AppLocalizations.of(context)!.vxSourceCode),
            ),
            OutlinedButton.icon(
              onPressed: () {
                launchUrl(Uri.parse('https://github.com/5vnetwork/vx-core'));
              },
              icon: SvgPicture.asset(
                Theme.of(context).brightness == Brightness.dark
                    ? 'assets/icons/github-mark-white.svg'
                    : 'assets/icons/github-mark.svg',
                width: 18,
                height: 18,
              ),
              label: Text(AppLocalizations.of(context)!.vxCoreSourceCode),
            ),
          ],
        ),
        const Gap(10),
        Text(
          AppLocalizations.of(context)!.howToUseVX,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        const Gap(10),
        OutlinedButton.icon(
          onPressed: () {
            launchUrl(Uri.parse('https://www.youtube.com/@vproxy5vnetwork'));
          },
          icon: Image.asset('assets/icons/youtube.png', width: 24, height: 24),
          label: const Text('VX代理客户端'),
        ),
        const Gap(10),
        Text(
          AppLocalizations.of(context)!.contactUsFreely,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        ),
        const Gap(10),
        Wrap(
          spacing: 10,
          runSpacing: 5,
          children: [
            OutlinedButton.icon(
              label: Text(AppLocalizations.of(context)!.email),
              onPressed: () {
                final Uri emailLaunchUri = Uri(scheme: 'mailto', path: email);
                launchUrl(emailLaunchUri);
              },
              icon: const Icon(Icons.email_outlined),
            ),
          ],
        ),
      ],
    );
  }
}
