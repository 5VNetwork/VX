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

class _Route extends StatefulWidget {
  const _Route();

  @override
  State<_Route> createState() => _RouteState();
}

class _RouteState extends State<_Route> {
  List<CustomRouteMode> _configs = [];
  StreamSubscription<List<CustomRouteMode>>? _customRouteModesSubscription;

  @override
  void initState() {
    super.initState();
    _customRouteModesSubscription =
        Provider.of<RouteRepo>(
          context,
          listen: false,
        ).getCustomRouteModesStream().listen((value) {
          if (value.isNotEmpty) {
            setState(() {
              _configs = value;
            });
          }
        });
  }

  @override
  void dispose() {
    _customRouteModesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProxySelectorBloc>();
    return HomeCard(
      title: AppLocalizations.of(context)!.mode,
      icon: Icons.alt_route_rounded,
      child: BlocSelector<ProxySelectorBloc, ProxySelectorState, String?>(
        selector: (state) => state.routeMode,
        builder: (context, routeModeIdx) {
          return Wrap(
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: 5,
            runSpacing: 5,
            children: [
              ..._configs.map(
                (e) => ChoiceChip(
                  tooltip: isDefaultRouteMode(e.name, context)
                      ? DefaultRouteMode.values
                            .firstWhereOrNull((defaultMode) {
                              return defaultMode.toLocalString(
                                    AppLocalizations.of(context)!,
                                  ) ==
                                  e.name;
                            })
                            ?.description(context)
                      : null,
                  label: Text(e.name),
                  selected: (routeModeIdx == e.name),
                  onSelected: (value) {
                    if (routeModeIdx == e.name) {
                      return;
                    }
                    bloc.add(RoutingModeSelectionChangeEvent(e));
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
