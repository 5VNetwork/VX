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

import 'package:uuid/uuid.dart';
import 'package:vx/main.dart';

Future<String> fetchRealmSecret() async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) {
    throw Exception('Not authenticated');
  }

  final response = await supabase
      .from('profiles')
      .select('realm_secret')
      .eq('id', userId)
      .single();

  final secret = response['realm_secret'] as String?;
  if (secret == null || secret.isEmpty) {
    throw Exception('Realm secret not found');
  }
  return secret;
}

Future<String> resetRealmSecret() async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) {
    throw Exception('Not authenticated');
  }

  final newSecret = const Uuid().v4();
  final response = await supabase
      .from('profiles')
      .update({'realm_secret': newSecret})
      .eq('id', userId)
      .select('realm_secret')
      .single();

  return response['realm_secret'] as String;
}
