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

class HomeEditButton extends StatelessWidget {
  const HomeEditButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.edit_rounded),
      onPressed: () {
        final compact = context.read<MyLayout>().isCompact;
        if (compact) {
          Navigator.of(context, rootNavigator: true).push<void>(
            CupertinoPageRoute<void>(
              builder: (context) => const _HomeConfigScaffoldPage(),
            ),
          );
        } else {
          showDialog<void>(
            context: context,
            builder: (context) => const _HomeConfigDialog(),
          );
        }
      },
    );
  }
}

/// Chips + expandable editor (standard vs customizable). Used inside a
/// bounded-height parent ([Column] with [MainAxisSize.max] or [Expanded]).
class _HomeConfigEditorContent extends StatelessWidget {
  const _HomeConfigEditorContent();

  @override
  Widget build(BuildContext context) {
    final _useCustomizable = context.watch<HomePageCubit>().state;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: Text(l10n.homeEditStandardLayout),
                selected: !_useCustomizable,
                onSelected: (selected) {
                  if (!selected) return;
                  context.read<HomePageCubit>().setUseCustomizableHomePage(
                    false,
                  );
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: AppendProIcon(
                  child: Text(l10n.homeEditCustomizableLayout),
                ),
                selected: _useCustomizable,
                onSelected: (selected) {
                  if (!selected) return;
                  context.read<HomePageCubit>().setUseCustomizableHomePage(
                    true,
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!_useCustomizable)
          Expanded(child: const _StandardHomeWidgetSetting()),
        if (_useCustomizable)
          Expanded(
            child: ChangeNotifierProvider(
              create: (context) =>
                  CustomizeHomeWidgetNotifier(context.read<HomeLayoutRepo>()),
              child: const _HomeEditDialog(),
            ),
          ),
      ],
    );
  }
}

class _HomeConfigScaffoldPage extends StatelessWidget {
  const _HomeConfigScaffoldPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.home),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: const _HomeConfigEditorContent(),
        ),
      ),
    );
  }
}

class _HomeConfigDialog extends StatelessWidget {
  const _HomeConfigDialog();

  @override
  Widget build(BuildContext context) {
    final _useCustomizable = context.watch<HomePageCubit>().state;
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      constraints: !_useCustomizable
          ? const BoxConstraints(maxWidth: 520)
          : BoxConstraints(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l10n.home, style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Expanded(child: _HomeConfigEditorContent()),
          ],
        ),
      ),
    );
  }
}
