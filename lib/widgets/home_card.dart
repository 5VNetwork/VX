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
import 'package:gap/gap.dart';
import 'package:vx/l10n/app_localizations.dart';

class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.title,
    required this.icon,
    this.titleWidget,
    this.button,
    required this.child,
  });
  final String title;
  final Widget? titleWidget;
  final Widget? button;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final labelRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child:
              titleWidget ??
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
        ),
        if (button != null) ...[const SizedBox(width: 8), button!],
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label row with icon (and optional hide menu)
          labelRow,
          const Gap(10),
          // Speed value
          child,
        ],
      ),
    );
  }
}

class _HomeCardTitleMenuAnchor extends StatefulWidget {
  const _HomeCardTitleMenuAnchor({required this.onHide, required this.child});

  final VoidCallback onHide;
  final Widget child;

  @override
  State<_HomeCardTitleMenuAnchor> createState() =>
      _HomeCardTitleMenuAnchorState();
}

class _HomeCardTitleMenuAnchorState extends State<_HomeCardTitleMenuAnchor> {
  final MenuController _menuController = MenuController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MenuAnchor(
      controller: _menuController,
      menuChildren: [
        MenuItemButton(
          onPressed: () {
            widget.onHide();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.visibility_off_outlined, size: 20),
              const SizedBox(width: 12),
              Text(l10n.hide),
            ],
          ),
        ),
      ],
      child: GestureDetector(
        onLongPress: () => _menuController.open(),
        onSecondaryTapDown: (_) => _menuController.open(),
        child: widget.child,
      ),
    );
  }
}
