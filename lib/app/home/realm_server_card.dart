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

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class RealmServerStatusNotifier extends ChangeNotifier {
  RealmServerStatusNotifier({
    required XController controller,
    required SharedPreferences prefs,
  }) : _controller = controller,
       _prefs = prefs {
    _statusSub = _controller.statusStream().listen((event) {
      if (event == XStatus.connected) {
        _startIfEnabled();
      } else if (event == XStatus.disconnected) {
        _stop();
        _status = null;
        notifyListeners();
      }
    });
    if (_controller.status == XStatus.connected) {
      _startIfEnabled();
    }
  }

  final XController _controller;
  final SharedPreferences _prefs;
  StreamSubscription<XStatus>? _statusSub;
  StreamSubscription<RealmServerStatus>? _stream;

  /// null = not yet received; use this to distinguish "loading" from "inactive"
  RealmServerStatus? _status;
  RealmServerStatus? get status => _status;

  bool get realmEnabled => _prefs.getBool('realmServerEnabled') ?? false;

  void _startIfEnabled() {
    if (!realmEnabled) return;
    _stream?.cancel();
    _controller
        .realmStatusStream(5)
        .then((stream) {
          logger.d("started realm server status stream");
          _stream = stream.listen(
            (msg) {
              logger.d("received realm server status: $msg");
              _status = msg;
              notifyListeners();
            },
            onError: (e) {
              logger.e(
                "failed to listen to realm server status stream",
                error: e,
              );
            },
            onDone: () {
              logger.d("stopped realm server status stream");
            },
            cancelOnError: false,
          );
        })
        .catchError((e) {
          logger.e("failed to start realm server status stream", error: e);
        });
  }

  void _stop() {
    _stream?.cancel();
    _stream = null;
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _stop();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Card widget
// ---------------------------------------------------------------------------

class _RealmServerCard extends StatelessWidget {
  const _RealmServerCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notifier = context.watch<RealmServerStatusNotifier>();

    // Don't render the card at all when realm server is disabled.
    if (!notifier.realmEnabled) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HomeCard(
        title: l10n.realmServer,
        icon: Icons.hub_rounded,
        child: _buildBody(context, notifier.status),
      ),
    );
  }

  Widget _buildBody(BuildContext context, RealmServerStatus? status) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (status == null) {
      return const SizedBox(
        height: 40,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final active = status.active;
    final addresses = status.publicAddresses;
    final peers = status.peers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status badge row
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? Colors.green : colorScheme.outlineVariant,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              active ? l10n.realmRegistered : l10n.realmRegistering,
              style: textTheme.bodySmall?.copyWith(
                color: active ? Colors.green : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (active) ...[
              Icon(
                Icons.people_outline,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.realmPeersCount(peers),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        if (active && addresses.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...addresses.map(
            (addr) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Icon(
                    Icons.lan_outlined,
                    size: 12,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      addr,
                      style: textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ] else if (active && addresses.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            l10n.discoveringPublicAddresses,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}
