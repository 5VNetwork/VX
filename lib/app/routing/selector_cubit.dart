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

import 'package:fixnum/fixnum.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tm/protos/vx/router/router.pb.dart';
import 'package:vx/app/outbound/outbound_repo.dart';
import 'package:vx/app/routing/repo.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/main.dart';
import 'package:vx/utils/logger.dart';

/// The list of selectors shown on the routing page.
class SelectorsCubit extends Cubit<List<SelectorConfig>> {
  SelectorsCubit({
    required SelectorRepo selectorRepo,
    required XController xController,
  }) : _selectorRepo = selectorRepo,
       _xController = xController,
       super(const []) {
    _sub = _selectorRepo.getSelectorsStream().listen((selectors) {
      if (!isClosed) emit(selectors);
    });
  }

  final SelectorRepo _selectorRepo;
  final XController _xController;
  late final StreamSubscription<List<SelectorConfig>> _sub;

  /// Returns false without adding anything if [name] is already taken.
  Future<bool> add(String name) async {
    if (state.any((e) => e.tag == name)) return false;
    final config = SelectorConfig(
      tag: name,
      filter: SelectorConfig_Filter(all: true),
    );
    try {
      await _selectorRepo.addSelector(config);
      if (!isClosed && !state.any((e) => e.tag == name)) {
        emit([...state, config]);
      }
      await _xController.selectorSelectStrategyOrLandhandlerChange(config);
    } catch (e) {
      logger.e('Error adding selector', error: e);
      snack(e.toString());
    }
    return true;
  }

  Future<void> remove(String tag) async {
    try {
      await _selectorRepo.removeSelector(tag);
      if (!isClosed) emit(state.where((e) => e.tag != tag).toList());
      await _xController.selectorRemove(tag);
    } catch (e) {
      logger.e('Error removing selector', error: e);
      snack(e.toString());
    }
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}

/// Owns the editable state of a single selector.
///
/// Every change is persisted first, then emitted and pushed to the running
/// core, in the order it was made. Most fields are stored as one config blob,
/// so writes must not overlap: a slower, older write would otherwise overwrite
/// a newer one.
class SelectorCubit extends Cubit<SelectorConfig> {
  SelectorCubit({
    required SelectorConfig initial,
    required SelectorRepo selectorRepo,
    required OutboundRepo outboundRepo,
    required XController xController,
  }) : _selectorRepo = selectorRepo,
       _outboundRepo = outboundRepo,
       _xController = xController,
       super(initial) {
    _sub = _selectorRepo.watchSelector(initial.tag).listen(_onRepoChanged);
    _removeDeletedHandlers();
  }

  final SelectorRepo _selectorRepo;
  final OutboundRepo _outboundRepo;
  final XController _xController;
  late final StreamSubscription<SelectorConfig?> _sub;

  Future<void> _writes = Future.value();
  int _pendingWrites = 0;

  String get tag => state.tag;

  void _onRepoChanged(SelectorConfig? config) {
    // Emissions triggered by earlier queued writes can arrive out of order;
    // the last write triggers another emission once everything has landed.
    if (config == null || _pendingWrites > 0 || isClosed) return;
    emit(config);
  }

  Future<void> setAllNodes(bool all) =>
      _update((c) => c.filter.all = all, apply: _applyFilter);

  Future<void> setStrategy(SelectorConfig_SelectingStrategy strategy) =>
      _update((c) => c.strategy = strategy, apply: _applyStrategy);

  Future<void> setBalanceStrategy(SelectorConfig_BalanceStrategy strategy) =>
      _update((c) => c.balanceStrategy = strategy, apply: _applyBalance);

  Future<void> setLandHandlers(List<Int64> handlerIds) => _update(
    (c) => c.landHandlers
      ..clear()
      ..addAll(handlerIds),
    apply: _applyStrategy,
  );

  /// Replaces the whole config, e.g. after editing the test parameters.
  Future<void> replace(SelectorConfig config) => _update(
    (c) => c
      ..clear()
      ..mergeFromMessage(config),
    apply: _applyStrategy,
  );

  Future<void> setPrefix(String prefix, bool selected) =>
      _toggle((c) => c.filter.prefixes, prefix, selected);

  Future<void> setSubString(String subString, bool selected) =>
      _toggle((c) => c.filter.subStrings, subString, selected);

  Future<void> setCountryCode(String countryCode, bool selected) =>
      _toggle((c) => c.filter.countryCodes, countryCode, selected);

  Future<void> setHandlerSelected(int handlerId, bool selected) => _toggle(
    (c) => c.filter.handlerIds,
    Int64(handlerId),
    selected,
    persist: (_) => selected
        ? _selectorRepo.addHandlerToSelector(tag, handlerId)
        : _selectorRepo.removeHandlerFromSelector(tag, handlerId),
  );

  Future<void> setGroupSelected(String groupName, bool selected) => _toggle(
    (c) => c.filter.groupTags,
    groupName,
    selected,
    persist: (_) => selected
        ? _selectorRepo.addHandlerGroupToSelector(tag, groupName)
        : _selectorRepo.removeHandlerGroupFromSelector(tag, groupName),
  );

  Future<void> setSubscriptionSelected(int subId, bool selected) => _toggle(
    (c) => c.filter.subIds,
    Int64(subId),
    selected,
    persist: (_) => selected
        ? _selectorRepo.addSubscriptionToSelector(tag, subId)
        : _selectorRepo.removeSubscriptionFromSelector(tag, subId),
  );

  /// Drops filter entries that point at handlers which no longer exist.
  Future<void> _removeDeletedHandlers() async {
    for (final id in List.of(state.filter.handlerIds)) {
      final handler = await _outboundRepo.getHandlerById(id.toInt());
      if (isClosed) return;
      if (handler == null) {
        await _toggle(
          (c) => c.filter.handlerIds,
          id,
          false,
          persist: (_) =>
              _selectorRepo.removeHandlerFromSelector(tag, id.toInt()),
          applyToCore: false,
        );
      }
    }
  }

  Future<void> _toggle<T>(
    List<T> Function(SelectorConfig c) list,
    T value,
    bool selected, {
    Future<void> Function(SelectorConfig config)? persist,
    bool applyToCore = true,
  }) => _update(
    (c) {
      final values = list(c);
      if (values.contains(value) == selected) return;
      selected ? values.add(value) : values.remove(value);
    },
    persist: persist,
    apply: applyToCore ? _applyFilter : null,
  );

  /// Queues [change]. When its turn comes, it is applied to a copy of the
  /// then-current state, persisted, and only then emitted and applied to the
  /// core. A failed save leaves the state untouched.
  Future<void> _update(
    void Function(SelectorConfig draft) change, {
    Future<void> Function(SelectorConfig config)? persist,
    required Future<void> Function(SelectorConfig config)? apply,
  }) {
    _pendingWrites++;
    return _writes = _writes
        .then((_) async {
          if (isClosed) return;
          final next = state.deepCopy();
          change(next);
          if (next == state) return;

          try {
            await (persist ?? _selectorRepo.updateSelector)(next);
          } catch (e) {
            logger.e('Error saving selector $tag', error: e);
            snack(e.toString());
            return;
          }
          if (!isClosed) emit(next);

          try {
            await apply?.call(next);
          } catch (e) {
            logger.e('Error applying selector $tag', error: e);
            snack(e.toString());
          }
        })
        .whenComplete(() => _pendingWrites--);
  }

  Future<void> _applyFilter(SelectorConfig c) =>
      _xController.selectorFilterChange(c);

  Future<void> _applyStrategy(SelectorConfig c) =>
      _xController.selectorSelectStrategyOrLandhandlerChange(c);

  Future<void> _applyBalance(SelectorConfig c) =>
      _xController.selectorBalancingStrategyChange(c.tag, c.balanceStrategy);

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
