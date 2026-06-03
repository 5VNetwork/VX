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

part of 'home.dart';

class ProxySelectorHome extends StatelessWidget {
  const ProxySelectorHome({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeCard(
      title: AppLocalizations.of(context)!.selector,
      titleWidget: Row(
        children: [
          Text(
            AppLocalizations.of(context)!.proxy,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          BlocProvider<SelectorBeingUsedCubit>(
            create: (context) => SelectorBeingUsedCubit(
              selectorTag: defaultProxySelectorTag,
              xController: context.read<XController>(),
              outboundRepo: context.read<OutboundRepo>(),
              clearWhenSelectorEmpty: true,
            ),
            child: const SelectorBeingUsedView(),
          ),
        ],
      ),
      icon: Icons.filter_alt_outlined,
      child: const DefaultProxySelector(),
    );
  }
}
