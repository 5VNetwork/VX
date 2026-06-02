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

part of 'vx_config.dart';

String _formatConfigJson(String json) {
  try {
    return const JsonEncoder.withIndent('  ').convert(jsonDecode(json));
  } catch (_) {
    return json;
  }
}

String _editorValueToJsonString(dynamic value) {
  if (value is String) {
    return value;
  }
  return const JsonEncoder.withIndent('  ').convert(value);
}

class _ServerConfigJsonExpansionTile extends StatefulWidget {
  const _ServerConfigJsonExpansionTile();

  @override
  State<_ServerConfigJsonExpansionTile> createState() =>
      _ServerConfigJsonExpansionTileState();
}

class _ServerConfigJsonExpansionTileState
    extends State<_ServerConfigJsonExpansionTile> {
  String? _remoteJson;
  String? _editorJson;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  bool _expanded = false;

  bool get _isDirty =>
      _editorJson != null &&
      _remoteJson != null &&
      _editorJson != _remoteJson;

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final bloc = context.read<VXBloc>();
      final json = await context.read<XApiClient>().serverConfigJson(
        bloc.server,
      );
      if (!mounted) return;
      setState(() {
        _remoteJson = json;
        _editorJson = _formatConfigJson(json);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onExpansionChanged(bool expanded) {
    setState(() => _expanded = expanded);
    if (expanded && _remoteJson == null && !_isLoading && _error == null) {
      _load();
    }
  }

  void _discard() {
    if (_remoteJson == null) return;
    setState(() {
      _editorJson = _formatConfigJson(_remoteJson!);
      _error = null;
    });
  }

  Future<void> _save() async {
    final json = _editorJson;
    if (json == null || json.trim().isEmpty) {
      setState(() => _error = 'JSON is empty');
      return;
    }
    try {
      jsonDecode(json);
    } catch (e) {
      setState(() => _error = e.toString());
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      final bloc = context.read<VXBloc>();
      final l10n = AppLocalizations.of(context)!;
      await context.read<XApiClient>().updateServerConfigJson(
        bloc.server,
        json,
      );
      if (!mounted) return;
      setState(() {
        _remoteJson = json;
        _isSaving = false;
      });
      bloc.add(VXReloadConfigEvent());
      snack(l10n.applySuccess);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isSaving = false;
      });
      snack(
        AppLocalizations.of(context)?.applyFailed ?? 'Failed to apply: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ExpansionTile(
        onExpansionChanged: _onExpansionChanged,
        title: Text(
          l10n.advanced,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          'Edit /usr/local/etc/vx/config.json on the server',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        collapsedBackgroundColor: theme.colorScheme.surfaceContainerLow,
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: theme.colorScheme.outline),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (!_expanded)
            const SizedBox.shrink()
          else if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null && _remoteJson == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const Gap(8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            )
          else if (_editorJson != null) ...[
            SizedBox(
              height: 360,
              child: JsonEditor(
                key: ValueKey(_isDirty ? 'json-editor-dirty' : _remoteJson),
                json: _editorJson!,
                themeColor: theme.colorScheme.primary,
                editors: const [Editors.text, Editors.tree],
                onChanged: (value) {
                  setState(() {
                    _error = null;
                    _editorJson = _editorValueToJsonString(value);
                  });
                },
              ),
            ),
            if (_error != null && _remoteJson != null) ...[
              const Gap(8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const Gap(12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton(
                  onPressed: _isDirty && !_isSaving ? _discard : null,
                  child: Text(l10n.discard),
                ),
                FilledButton(
                  onPressed: _isDirty && !_isSaving ? _save : null,
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.save),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
