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

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User, decodeJwt;
import 'package:vx/auth/user.dart';
import 'package:flutter_common/auth/auth_provider.dart';
import 'package:flutter_common/util/jwt.dart';
import 'package:vx/utils/logger.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepo, bool isActivated)
    : super(
        AuthState(
          user: _authRepo.currentSession != null
              ? _toUser(_authRepo.currentSession!)
              : null,
          isActivated: isActivated,
        ),
      ) {
    on<_AuthUserChanged>(_onUserChanged);
    on<AuthActivatedEvent>(_onActivated);
    _userSubscription = _authRepo.sessionStreams.listen((session) {
      logger.d("authStateChange, current user: ${session?.user}");
      add(_AuthUserChanged(session != null ? _toUser(session) : null));
    });
  }

  void setTestUser() {
    emit(
      const AuthState(
        user: User(
          id: 'test',
          email: 'test@test.com',
          pro: true,
          level: UserLevel.max,
        ),
        isActivated: false,
      ),
    );
  }

  void unsetTestUser() {
    emit(const AuthState(isActivated: false));
  }

  final AuthProvider _authRepo;
  late final StreamSubscription<Session?> _userSubscription;
  late String deviceToken;

  void _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) {
    emit(AuthState(user: event.user, isActivated: state.isActivated));
  }

  void _onActivated(AuthActivatedEvent event, Emitter<AuthState> emit) {
    emit(AuthState(user: state.user, isActivated: true));
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    return super.close();
  }

  // retrive user profile from supabase
  static User _toUser(Session session) {
    final user = session.user;

    // Decode the access token to get custom claims
    final claims = decodeJwt(session.accessToken);
    logger.d('JWT claims: $claims');

    // Extract the 'pro' claim from JWT
    final isPro = claims['pro'] as bool? ?? false;
    final proExpiredAt = claims['pro_expired_at'] as int?;
    if (claims['level'] == '' || claims['level'] == null) {
      claims['level'] = 'free';
    }
    return User(
      id: user.id,
      email: user.email!,
      pro: isPro,
      proExpiredAt: proExpiredAt != null
          ? DateTime.fromMillisecondsSinceEpoch(proExpiredAt * 1000)
          : null,
      level: UserLevel.values.byName(claims['level']),
    );
  }
}

abstract class AuthEvent {
  const AuthEvent();
}

class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);

  final User? user;
}

class AuthActivatedEvent extends AuthEvent {
  const AuthActivatedEvent();
}

class AuthState extends Equatable {
  const AuthState({this.user, required this.isActivated});

  final User? user;
  final bool isActivated;

  bool get isAuthenticated => user != null;

  /// whether unlock pro features
  bool get proUser {
    if (isActivated) {
      return true;
    }
    return user?.isProUser ?? false;
  }

  @override
  List<Object?> get props => [user, isActivated];
}
