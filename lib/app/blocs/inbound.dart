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

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vx/app/blocs/proxy_selector/proxy_selector_bloc.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/main.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/logger.dart';

class InboundCubit extends Cubit<InboundMode> {
  InboundCubit(this.pref, this.xController) : super(pref.inboundMode);

  final SharedPreferences pref;
  final XController xController;

  void setInboundMode(InboundMode mode) async {
    emit(mode);
    pref.setInboundMode(mode);
    try {
      await xController.changeInboundMode();
    } catch (e) {
      logger.e('changeInboundMode error', error: e);
      snack(rootLocalizations()?.failedToChangeInboundMode);
    }
  }
}
