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


class AddPopUpRoute<T> extends PopupRoute<T> {
  AddPopUpRoute({super.settings, required this.child}) : super();
  final Widget child;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 200);

  @override
  Color get barrierColor => Colors.black.withAlpha(0x50);

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null; //TODO

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return child;
  }
}

class AddPopUpPage extends Page {
  const AddPopUpPage({super.key, required this.child});
  final Widget child;
  @override
  Route createRoute(BuildContext context) {
    return AddPopUpRoute(child: child, settings: this);
  }
}
