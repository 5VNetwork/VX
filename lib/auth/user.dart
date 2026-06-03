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

import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    this.proExpiredAt,
    required this.pro,
  });
  final String id;
  final String email;
  final DateTime? proExpiredAt;

  final bool pro;

  @override
  List<Object?> get props => [id, email, proExpiredAt, pro];

  bool get isProUser {
    return pro;
  }

  bool get lifetimePro => pro && proExpiredAt == null;
}
