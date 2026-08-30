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
import 'dart:developer';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tm/protos/app/api/api.pb.dart';
import 'package:tm/protos/vx/outbound/outbound.pb.dart';
import 'package:tm/protos/vx/proxy/wireguard/config.pb.dart';
import 'package:tm/protos/vx/router/router.pb.dart';
import 'package:tm/protos/vx/transport/headers/wireguard/config.pb.dart';
import 'package:tm/tm.dart';
import 'package:vx/app/control.dart';
import 'package:vx/app/outbound/outbound_page.dart';
import 'package:vx/app/outbound/outbound_repo.dart';
import 'package:vx/app/outbound/subscription.dart';
import 'package:vx/app/routing/routing_page.dart';
import 'package:vx/app/blocs/proxy_selector/proxy_selector_bloc.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/auth/auth_bloc.dart';
import 'package:vx/common/list.dart';
import 'package:vx/pref_helper.dart';
import 'package:vx/utils/logger.dart';
import 'package:flutter_common/util/net.dart';
import 'package:vx/data/database.dart';
import 'package:vx/main.dart';
import 'package:vx/utils/xapi_client.dart';

// TODO: event limiter for verticalDragUpdate
// TODO: Move test logic to statefulWidgets
// TODO: speed test unusable set speed to -1
class OutboundBloc extends Bloc<OutboundEvent, OutboundState> {
  OutboundBloc(
    this._outboundRepo,
    this._xController,
    this._subscriptionUpdater,
    this._authBloc,
    this._pref,
    this._xApiClient,
  ) : super(
        OutboundState(
          sortCol: _pref.sortCol,
          viewMode: _pref.outboundViewMode == 'grid'
              ? OutboundViewMode.grid
              : OutboundViewMode.list,
          smallScreenPreference: _pref.outboundTableSmallScreenPreference,
        ),
      ) {
    on<InitialEvent>(_initial);
    on<SyncEvent>(_sync);
    on<UserIsNotProEvent>(_onUserIsNotPro);
    on<SelectedGroupChangeEvent>(_onSelectedChange);
    on<SelectGroupContainingHandlerEvent>(_onSelectGroupContainingHandler);
    on<OutboundModeSwitchEvent>(_onOutboundModeSwitch);
    on<HandlersDeleteEvent>(_onDelete);
    on<DeleteUnusableEvent>(_onDeleteUnusable);
    on<SortHandlersEvent>(_sort);
    on<SwitchHandlerEvent>(_switchHandler);
    on<ManuualSingleSelectionEvent>(_onManuualSingleSelection);
    on<HandlerEdittedEvent>(_onHandlerEditted);
    on<HandlerUpdatedEvent>(_onHandlerUpdated);
    // on<EnableDisableHandlerEvent>(_onEnableDisableHandler);
    on<AddSelectedHandlersToGroupEvent>(_onAddSelectedHandlersToGroup);
    on<AddHandlerToGroupEvent>(_onAddHandlerToGroup);
    on<AddHandlerEvent>(_onHandlerAdd);
    on<AddHandlersEvent>(_onAddHandlers);
    on<AddGroupEvent>(_onAddGroup);
    on<DeleteGroupEvent>(_onDeleteGroup);
    on<DeleteGroupAndNodesEvent>(_onDeleteGroupAndNodes);
    on<SpeedTestEvent>(_speedTest);
    on<StatusTestEvent>(_statusTest);
    on<SubscriptionDeleteEvent>(_onSubscriptionDelete);
    on<SubscriptionPlaceOnTopEvent>(_onSubscriptionPlaceOnTop);
    on<OutboundHandlerGroupPlaceOnTopEvent>(_onOutboundHandlerGroupPlaceOnTop);
    // on<SubscriptionToggleDisableEvent>(_subscriptionDisableToggle);
    on<PopulateCountryEvent>(_populateCountry);
    on<MultiSelectEvent>(_multiSelect);
    on<MultiSelectVerticalDragUpdateEvent>(
      _multiSelectVerticalDragUpdate,
      transformer: (events, mapper) => events
          .throttleTime(const Duration(milliseconds: 100))
          .asyncExpand(mapper),
      //     transformer: (events, mapper) {
      //   return events.skipWhile((e) {
      //     final nums = (_multiSelectVerticalDragDistance / 50).floor();
      //     if (e.localOffset.dy > _multiSelectVerticalDragStartY + nums * 50) {
      //       return false;
      //     }
      //     print('skip: ${e.localOffset.dy}');
      //     return true;
      //   });
      // }
    );
    on<MultiSelectToggleEvent>(_multiSelectToggle);
    on<MultiSelectSelectAllEvent>(_multiSelectSelectAll);
    // on<MultiSelectVerticalDragStartEvent>(_multiSelectVerticalDragStart);
    on<SubscriptionUpdatedEvent>(_onSubscriptionUpdated);
    _xController.outboundBloc = this;
    _subscriptionUpdater.addListener(() {
      add(SubscriptionUpdatedEvent());
    });
    on<SmallScreenPreferenceEvent>(_onSmallScreenPreference);
    on<ToggleViewModeEvent>(_onToggleViewMode);
    on<HandlersCopyEvent>(_onHandlersCopy);
  }
  final OutboundRepo _outboundRepo;
  final XController _xController;
  final XApiClient _xApiClient;

  final SharedPreferences _pref;
  final AutoSubscriptionUpdater _subscriptionUpdater;
  final AuthBloc _authBloc;

  // late final StreamSubscription subscriptionChangeSub;
  // final _handlerBox = store.box<OutboundHandler>();
  // final _handlerGroupBox = store.box<OHTag>();
  final Set<int> _handlersSpeedTesting = {};
  final Set<int> _handlersUsableTesting = {};

  @override
  Future<void> close() async {
    _xController.outboundBloc = null;
    await super.close();
  }

  void _autoTestHandlersMissingMetrics(List<OutboundHandler> handlers) {
    inspect(handlers);
    if (!_pref.autoTestNodes || handlers.isEmpty) return;
    final needsPing = handlers
        .where((h) => h.ping == 0)
        .toList(growable: false);
    final needsSpeed = handlers
        .where((h) => h.speed == 0)
        .toList(growable: false);
    logger.d(
      'needsPing: ${needsPing.length}, needsSpeed: ${needsSpeed.length}',
    );
    if (needsPing.isNotEmpty) add(StatusTestEvent(handlers: needsPing));
    if (needsSpeed.isNotEmpty) add(SpeedTestEvent(handlers: needsSpeed));
  }

  void _autoTestInsertedHandlers(List<OutboundHandler> handlers) {
    _autoTestHandlersMissingMetrics(handlers);
  }

  @override
  void onTransition(Transition<OutboundEvent, OutboundState> transition) {
    super.onTransition(transition);
  }

  Future<void> _initial(InitialEvent e, Emitter<OutboundState> emit) async {
    final handlers = await _outboundRepo.getHandlers();
    emit(state.copyWith(handlers: _sortHandlers(handlers, state.sortCol)));

    final future = <Future>[];
    future.add(
      emit.forEach(
        _xController.handlerBeingUsedStream(),
        onData: (handlerBeingUsed) {
          // only handlers selected by the default selector will be considered
          if (_pref.proxySelectorMode == ProxySelectorMode.manual) {
            return state;
          }
          if (handlerBeingUsed.selector != '代理') {
            return state;
          }
          if (handlerBeingUsed.tags.length != 1) {
            return state;
          }
          final tag = handlerBeingUsed.tags.first;
          late final int handlerBeingUsedId4;
          if (tag.contains('-')) {
            handlerBeingUsedId4 =
                int.tryParse(tag.split('-').firstOrNull ?? '') ?? 0;
          } else {
            handlerBeingUsedId4 = int.tryParse(tag) ?? 0;
          }
          late final int handlerBeingUsedId6;
          if (tag.contains('-')) {
            handlerBeingUsedId6 =
                int.tryParse(tag.split('-').firstOrNull ?? '') ?? 0;
          } else {
            handlerBeingUsedId6 = int.tryParse(tag) ?? 0;
          }
          List<OutboundHandler> newHandlers = state.handlers;
          if ((handlerBeingUsedId4 != 0 || handlerBeingUsedId6 != 0) &&
              state.sortCol == null) {
            newHandlers = stableMoveToFront(
              state.handlers,
              (h) => h.id == handlerBeingUsedId4 || h.id == handlerBeingUsedId6,
            );
          }
          logger.d(
            'handler being used, ${handlerBeingUsedId4}, ${handlerBeingUsedId6}',
          );
          return state.copyWith(
            handlers: newHandlers,
            using4: handlerBeingUsedId4,
            using6: handlerBeingUsedId6,
          );
        },
      ),
    );
    final subsStream = _outboundRepo.getStreamOfSubs();
    List<MySubscription> mySubs = [];
    future.add(
      subsStream.forEach((subs) async {
        mySubs = subs;
        final groups = await _outboundRepo.getGroups();
        final allGroups = <NodeGroup>[];
        allGroups.addAll(groups);
        allGroups.addAll(subs);
        allGroups.sort((a, b) {
          if (a.placeOnTop == b.placeOnTop) {
            return 0;
          }
          return a.placeOnTop ? -1 : 1;
        });
        final initial = state.selected == null && _pref.nodeGroup != null;
        emit(
          state.copyWith(
            gs: allGroups,
            selected: initial
                ? () => allGroups.firstWhereOrNull(
                    (e) => e.name == _pref.nodeGroup,
                  )
                : null,
          ),
        );
        if (initial) {
          emit(
            state.copyWith(
              handlers: _sortHandlers(await _getHandlers(), state.sortCol),
            ),
          );
        }
      }),
    );
    final groupsStream = _outboundRepo.getStreamOfGroups();
    future.add(
      groupsStream.forEach((groups) async {
        final allGroups = <NodeGroup>[];
        allGroups.addAll(groups);
        allGroups.addAll(mySubs);
        allGroups.sort((a, b) {
          if (a.placeOnTop == b.placeOnTop) {
            return 0;
          }
          return a.placeOnTop ? -1 : 1;
        });
        emit(
          state.copyWith(
            gs: allGroups,
            selected: () {
              if (state.selected is MySubscription) {
                return allGroups.firstWhereOrNull(
                  (e) =>
                      e is MySubscription &&
                      e.id == (state.selected as MySubscription).id,
                );
              } else if (state.selected is OutboundHandlerGroup) {
                return allGroups.firstWhereOrNull(
                  (e) =>
                      e is OutboundHandlerGroup &&
                      e.name == state.selected!.name,
                );
              }
              return null;
            },
          ),
        );
      }),
    );
    await Future.wait(future);
  }

  void _sync(SyncEvent e, Emitter<OutboundState> emit) async {
    logger.d('SyncEvent');
    emit(
      state.copyWith(
        handlers: _sortHandlers(await _getHandlers(), state.sortCol),
      ),
    );
  }

  void _onOutboundModeSwitch(
    OutboundModeSwitchEvent e,
    Emitter<OutboundState> emit,
  ) {
    if (e.mode == ProxySelectorMode.manual) {
      emit(state.copyWith(using4: null, using6: null));
    }
  }

  List<OutboundHandler> _setTestingFields(List<OutboundHandler> handlers) {
    if (_handlersSpeedTesting.isNotEmpty) {
      handlers = handlers.map((h) {
        if (_handlersSpeedTesting.contains(h.id)) {
          return h.copyWith(speedTesting: true);
        }
        return h;
      }).toList();
    }
    if (_handlersUsableTesting.isNotEmpty) {
      handlers = handlers.map((h) {
        if (_handlersUsableTesting.contains(h.id)) {
          return h.copyWith(usableTesting: true);
        }
        return h;
      }).toList();
    }
    return handlers;
  }

  List<OutboundHandler> _sortHandlers(
    List<OutboundHandler> handlers,
    (Col, SortOrder)? colSort,
  ) {
    if (colSort == null) {
      if (state.using4 != 0 &&
          _pref.proxySelectorMode == ProxySelectorMode.auto) {
        handlers = stableMoveToFront(handlers, (h) => h.id == state.using4);
      }
      return handlers;
    }
    final col = colSort.$1;
    final sortOrder = colSort.$2;
    int multiplier = sortOrder;

    switch (col) {
      case Col.speed:
        handlers.sort((a, b) => (a.speed).compareTo(b.speed) * multiplier);
      case Col.ping:
        handlers.sort((a, b) {
          int v1 = a.ping;
          if (v1 <= 0) {
            v1 = 1000000;
          }
          int v2 = b.ping;
          if (v2 <= 0) {
            v2 = 1000000;
          }
          return (v1).compareTo(v2) * multiplier;
        });
      case Col.remark:
        handlers.sort((a, b) => (a.name).compareTo(b.name) * multiplier);
      case Col.usable:
        // handlers.sort((a, b) {
        //   final aOk = a.ok > 0 ? 1 : a.ok;
        //   final bOk = b.ok > 0 ? 1 : b.ok;
        //   return (aOk).compareTo(bOk) * multiplier;
        // });
        insertionSort(
          handlers,
          compare: (a, b) {
            final aOk = a.ok > 0 ? 1 : a.ok;
            final bOk = b.ok > 0 ? 1 : b.ok;
            return (aOk).compareTo(bOk) * multiplier;
          },
        );
      case Col.protocol:
        handlers.sort(
          (a, b) =>
              (a.displayProtocol()).compareTo(b.displayProtocol()) * multiplier,
        );
      case Col.countryIcon:
        handlers.sort(
          (a, b) => (a.countryCode).compareTo(b.countryCode) * multiplier,
        );
      case Col.active:
        insertionSort(
          handlers,
          compare: (a, b) {
            final va = a.selected ? 1 : -1;
            final vb = b.selected ? 1 : -1;
            return va.compareTo(vb) * multiplier;
          },
        );
      default:
    }
    return handlers;
  }

  void _sort(SortHandlersEvent e, Emitter<OutboundState> emit) {
    _pref.setSortCol(e.colSort);
    final handlers = List<OutboundHandler>.from(state.handlers);
    emit(
      state.copyWith(
        handlers: _sortHandlers(handlers, e.colSort),
        sortCol: () => e.colSort,
      ),
    );
  }

  // get currently displayed handlers
  Future<List<OutboundHandler>> _getHandlers() async {
    late List<OutboundHandler> handlers;
    if (state.selected is OutboundHandlerGroup) {
      handlers = await _outboundRepo.getHandlersByGroup(
        (state.selected as OutboundHandlerGroup).name,
      );
    } else if (state.selected is Subscription) {
      handlers = await _outboundRepo.getHandlers(
        subId: (state.selected as Subscription).id,
      );
    } else {
      handlers = await _outboundRepo.getHandlers();
    }

    return _setTestingFields(handlers);
  }

  Future<void> _onSelectedChange(
    SelectedGroupChangeEvent e,
    Emitter<OutboundState> emit,
  ) async {
    emit(state.copyWith(selected: () => e.selected));
    _pref.setNodeGroup(e.selected?.name);
    emit(
      state.copyWith(
        handlers: _sortHandlers(await _getHandlers(), state.sortCol),
      ),
    );
  }

  /// Select the subscription or group the given handler belongs to.
  /// Falls back to [allGroup] if the handler cannot be located in any
  /// known subscription or group.
  Future<void> _onSelectGroupContainingHandler(
    SelectGroupContainingHandlerEvent e,
    Emitter<OutboundState> emit,
  ) async {
    NodeGroup? target;
    final handler = await _outboundRepo.getHandlerById(e.handlerId);
    if (handler != null) {
      if (handler.subId != null) {
        target = state.groups.firstWhereOrNull(
          (g) => g is MySubscription && g.id == handler.subId,
        );
      }
      if (target == null) {
        final groupNames = await _outboundRepo.getGroupNamesForHandler(
          e.handlerId,
        );
        if (groupNames.isNotEmpty) {
          target = state.groups.firstWhereOrNull(
            (g) => g is OutboundHandlerGroup && groupNames.contains(g.name),
          );
        }
      }
    }
    target ??= allGroup;
    await _onSelectedChange(SelectedGroupChangeEvent(target), emit);
  }

  Future<void> _onHandlersCopy(
    HandlersCopyEvent e,
    Emitter<OutboundState> emit,
  ) async {
    final newHandler = (await _outboundRepo.insertHandlersWithGroup([
      e.handler.config,
    ]))[0];
    if (newHandler == null) {
      return;
    }
    if (state.selected == null ||
        state.selected == allGroup ||
        state.selected?.name == defaultGroupName) {
      final handlers = List<OutboundHandler>.from(state.handlers);
      handlers.add(newHandler);
      emit(state.copyWith(handlers: _sortHandlers(handlers, state.sortCol)));
    }
    snack(rootLocalizations()?.handlerCopiedSuccess);
  }

  Future<void> _onDelete(
    HandlersDeleteEvent e,
    Emitter<OutboundState> emit,
  ) async {
    await _outboundRepo.removeHandlersByIds(e.ids);
    emit(
      state.copyWith(
        handlers: _sortHandlers(await _getHandlers(), state.sortCol),
      ),
    );
    await _xController.handlersRemoved(e.ids);
  }

  void _onDeleteUnusable(DeleteUnusableEvent e, Emitter<OutboundState> emit) {
    final newHandlers = <OutboundHandler>[];
    final handlersToDelete = <OutboundHandler>[];
    for (var handler in state.handlers) {
      if (handler.ok == 1) {
        newHandlers.add(handler);
      } else {
        handlersToDelete.add(handler);
      }
    }
    emit(state.copyWith(handlers: newHandlers));
    _outboundRepo.removeHandlersByIds(
      handlersToDelete.map((h) => h.id).toList(),
    );
    _xController.handlersRemoved(handlersToDelete.map((h) => h.id).toList());
  }

  // Future<void> _onEnableDisableHandler(
  //     EnableDisableHandlerEvent e, Emitter<OutboundState> emit) async {
  //   final handlers = List<OutboundHandler>.from(state.handlers);
  //   for (var handler in e.handlers) {
  //     final index = handlers.indexWhere((h) => h.id == handler.id);
  //     if (index >= 0) {
  //       handlers[index] = handlers[index].copyWith(enabled: e.enabled);
  //       emit(state.copyWith(handlers: handlers));
  //     }
  //   }
  //   final Map<int, OutboundHandlersCompanion> map = {};
  //   for (var handler in e.handlers) {
  //     map[handler.id] = OutboundHandlersCompanion(enabled: Value(e.enabled));
  //   }
  //   await _outboundRepo.updateHandlersTx(map);
  //   if (e.enabled) {
  //     _xController.handlerEnabled(e.handlers);
  //   } else {
  //     _xController.handlerDisabled(e.handlers);
  //   }
  // }

  Future<void> _switchHandler(
    SwitchHandlerEvent e,
    Emitter<OutboundState> emit,
  ) async {
    try {
      // final newList = List<OutboundHandler>.from(state.handlers);
      // final index = newList.indexWhere((h) => h.id == e.handler.id);
      // single node mode
      if (_pref.proxySelectorManualMode ==
          ProxySelectorManualNodeSelectionMode.single) {
        // update database
        if (!e.selected) {
          await _outboundRepo.updateHandler(e.handler.id, selected: false);
        } else {
          final currentSelected = await _outboundRepo.getHandlers(
            selected: true,
          );
          final m = {
            e.handler.id: const OutboundHandlersCompanion(
              selected: Value(true),
            ),
          };
          for (var h in currentSelected) {
            m[h.id] = const OutboundHandlersCompanion(selected: Value(false));
          }
          await _outboundRepo.updateHandlersTx(m);
        }

        // final currentlySelected = newList.indexWhere((h) => h.selected);
        // if (currentlySelected >= 0 &&
        //     newList[currentlySelected].id != e.handler.id) {
        //   newList[currentlySelected] = newList[currentlySelected].copyWith(
        //     selected: false,
        //   );
        // }
        // if (index >= 0) {
        //   newList[index] = newList[index].copyWith(selected: e.selected);
        // }
        emit(
          state.copyWith(
            handlers: _sortHandlers(await _getHandlers(), state.sortCol),
          ),
        );
      } else {
        // update database
        await _outboundRepo.updateHandler(e.handler.id, selected: e.selected);
        // multiple node mode
        // if (index >= 0) {
        //   newList[index] = newList[index].copyWith(selected: e.selected);
        // }
        emit(
          state.copyWith(
            handlers: _sortHandlers(await _getHandlers(), state.sortCol),
          ),
        );
      }
      if ((await _outboundRepo.getHandlers(selected: true)).isEmpty) {
        snack(rootLocalizations()?.noSelectedNode);
      }
      // notify core
      await _xController.handlerSelectedChange();
    } catch (e) {
      logger.e('switchHandler error', error: e);
    } finally {
      final c = e.whenPersisted;
      if (c != null && !c.isCompleted) {
        c.complete();
      }
    }
  }

  Future<void> _onUserIsNotPro(
    UserIsNotProEvent e,
    Emitter<OutboundState> emit,
  ) async {
    await _multiSelectToSingle(emit);
  }

  Future<void> _onManuualSingleSelection(
    ManuualSingleSelectionEvent e,
    Emitter<OutboundState> emit,
  ) async {
    await _multiSelectToSingle(emit);
  }

  Future<void> _multiSelectToSingle(Emitter<OutboundState> emit) async {
    final handlers = await _outboundRepo.getHandlers(selected: true);
    if (handlers.length > 1) {
      final m = <int, OutboundHandlersCompanion>{};
      for (var handler in handlers.skip(1)) {
        m[handler.id] = const OutboundHandlersCompanion(selected: Value(false));
      }
      await _outboundRepo.updateHandlersTx(m);
      emit(
        state.copyWith(
          handlers: _sortHandlers(await _getHandlers(), state.sortCol),
        ),
      );
      await _xController.notifyHandlerChange();
      await _xController.selectorBalancingStrategyChange(
        defaultProxySelectorTag,
        SelectorConfig_BalanceStrategy.RANDOM,
      );
    }
  }

  Future<void> _onHandlerEditted(
    HandlerEdittedEvent e,
    Emitter<OutboundState> emit,
  ) async {
    final handlers = List<OutboundHandler>.from(state.handlers);
    final index = handlers.indexWhere((h) => h.id == e.handler.id);
    if (index >= 0) {
      handlers[index] = e.handler;
      emit(state.copyWith(handlers: _sortHandlers(handlers, state.sortCol)));
    }
    await _outboundRepo.replaceHandler(e.handler);
    _xController.handlerUpdated(e.handler);
    await updateCountry([e.handler], emit);
  }

  Future<void> _onHandlerUpdated(
    HandlerUpdatedEvent e,
    Emitter<OutboundState> emit,
  ) async {
    final handler = await _outboundRepo.getHandlerById(e.id);
    final index = state.handlers.indexWhere((h) => h.id == e.id);
    if (index >= 0) {
      if (handler != null) {
        final handlers = List<OutboundHandler>.from(state.handlers);
        handlers[index] = handler;
        emit(state.copyWith(handlers: _sortHandlers(handlers, state.sortCol)));
      }
    }
  }

  Future<void> _onHandlerAdd(
    AddHandlerEvent e,
    Emitter<OutboundState> emit,
  ) async {
    final newHandler = (await _outboundRepo.insertHandlersWithGroup([
      e.handler,
    ]))[0];
    if (newHandler == null) {
      return;
    }
    final handlers = List<OutboundHandler>.from(state.handlers);
    handlers.add(newHandler);
    emit(state.copyWith(handlers: _sortHandlers(handlers, state.sortCol)));
    _xController.handlerAdded();
    _autoTestInsertedHandlers([newHandler]);
    await updateCountry([newHandler], emit);
  }

  Future<void> _onAddHandlers(
    AddHandlersEvent e,
    Emitter<OutboundState> emit,
  ) async {
    final insertedHandlers = <OutboundHandler>[];
    if (e.replaceAll) {
      final existingHandlers = await _outboundRepo.getHandlersByGroup(
        e.groupName,
      );
      final existingByTag = <String, OutboundHandler>{};
      for (final handler in existingHandlers) {
        if (handler.config.hasOutbound() &&
            handler.config.outbound.tag.isNotEmpty) {
          existingByTag[handler.config.outbound.tag] = handler;
        }
      }
      final updatedIds = <int>{};
      for (final config in e.handlers) {
        final existing = existingByTag[config.outbound.tag];
        final nextConfig = OutboundHandlerConfig()
          ..mergeFromMessage(config.outbound);
        if (existing != null && existing.config.hasOutbound()) {
          nextConfig.enableMux = existing.config.outbound.enableMux;
          nextConfig.uot = existing.config.outbound.uot;
          nextConfig.domainStrategy = existing.config.outbound.domainStrategy;
          await _outboundRepo.replaceHandler(
            existing.copyWith(config: HandlerConfig(outbound: nextConfig)),
          );
          updatedIds.add(existing.id);
        } else {
          final inserted = await _outboundRepo.insertHandlersWithGroup([
            HandlerConfig(outbound: nextConfig),
          ], groupName: e.groupName);
          insertedHandlers.addAll(inserted.whereType<OutboundHandler>());
        }
      }
      final toDelete = existingHandlers
          .where((h) => !updatedIds.contains(h.id))
          .map((h) => h.id)
          .toList();
      if (toDelete.isNotEmpty) {
        await _outboundRepo.removeHandlersByIds(toDelete);
      }
    } else {
      final inserted = await _outboundRepo.insertHandlersWithGroup(
        e.handlers,
        groupName: e.groupName,
      );
      insertedHandlers.addAll(inserted.whereType<OutboundHandler>());
    }
    final handlers = await _getHandlers();
    emit(state.copyWith(handlers: _sortHandlers(handlers, state.sortCol)));
    _xController.handlerAdded();
    _autoTestInsertedHandlers(insertedHandlers);
    await updateCountry(
      await _outboundRepo.getHandlers(country: '', ok: 0),
      emit,
    );
  }

  Future<void> _onAddGroup(AddGroupEvent e, Emitter<OutboundState> emit) async {
    await _outboundRepo.addHandlerGroup(e.groupName);
  }

  Future<void> _onDeleteGroup(
    DeleteGroupEvent e,
    Emitter<OutboundState> emit,
  ) async {
    await _outboundRepo.removeHandlerGroup(e.group.name);
    if (e.group.name == state.selected?.name) {
      emit(state.copyWith(selected: () => null));
      _pref.setNodeGroup(null);
    }
  }

  Future<void> _onDeleteGroupAndNodes(
    DeleteGroupAndNodesEvent e,
    Emitter<OutboundState> emit,
  ) async {
    final handlers = await _outboundRepo.getHandlersByGroup(e.group.name);
    final ids = handlers.map((h) => h.id).toList();
    await _outboundRepo.removeHandlerGroup(e.group.name);
    if (e.group.name == state.selected?.name) {
      emit(state.copyWith(selected: () => null));
      _pref.setNodeGroup(null);
    }
    if (ids.isNotEmpty) {
      await _outboundRepo.removeHandlersByIds(ids);
      await _xController.handlersRemoved(ids);
    }
    emit(
      state.copyWith(
        handlers: _sortHandlers(await _getHandlers(), state.sortCol),
      ),
    );
  }

  Future<void> _speedTest(SpeedTestEvent e, Emitter<OutboundState> emit) async {
    final handlersToBeTested = e.handlers ?? state.handlers;
    // if e.handlers is null, a user want to test all handlers in state.handlers
    final testALL = e.handlers == null;
    if (testALL) {
      emit(
        state.copyWith(
          handlers: handlersToBeTested
              .map((h) => h.copyWith(speedTesting: true))
              .toList(),
        ),
      );
    } else {
      final newList = List<OutboundHandler>.from(state.handlers);
      for (var ha in handlersToBeTested) {
        final index = newList.indexWhere((h) => h.id == ha.id);
        if (index >= 0) {
          newList[index] = newList[index].copyWith(speedTesting: true);
        }
      }
      emit(state.copyWith(handlers: newList));
    }

    _handlersSpeedTesting.addAll(handlersToBeTested.map((h) => h.id));

    await _outboundRepo.updateHandlerFields(
      handlersToBeTested.map((h) => h.id).toList(),
      speed: 0,
    );

    final resStream = await _xApiClient.speedTest(
      SpeedTestRequest(
        handlers: handlersToBeTested.map((h) => h.toConfig()).toList(),
        size: _pref.outboundSpeedTestBytes,
      ),
    );

    void onError(e) async {
      logger.e('speedTest error', error: e);
      _handlersSpeedTesting.removeWhere(
        (id) => handlersToBeTested.any((h) => h.id == id),
      );
      emit(
        state.copyWith(
          handlers: _sortHandlers(await _getHandlers(), state.sortCol),
        ),
      );
    }

    await resStream
        .asyncMap((res) async {
          final id = int.parse(res.tag);
          _handlersSpeedTesting.remove(id);
          final handlers = List<OutboundHandler>.from(state.handlers);
          final index = handlers.indexWhere((h) => h.id == id);
          final ok = res.down > 0 ? 1 : -1;
          if (index >= 0) {
            handlers[index] = handlers[index].copyWith(
              speedTesting: false,
              speed: bytesToMbps(res.down.toInt()),
              ping: ok > 0 ? null : 0,
              ok: ok,
            );
          }
          emit(
            state.copyWith(handlers: _sortHandlers(handlers, state.sortCol)),
          );
          await _outboundRepo.updateHandler(
            id,
            ping: ok > 0 ? null : 0,
            speed: bytesToMbps(res.down.toInt()),
            speedTestTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            ok: ok,
          );
          await _xController.updateHandlerSpeed(res.tag, res.down.toInt());
        })
        .forEach((_) {})
        .catchError(onError);
  }

  Future<void> _statusTest(
    StatusTestEvent e,
    Emitter<OutboundState> emit,
  ) async {
    final handlersToBeTested = e.handlers ?? state.handlers;
    final testAll = e.handlers == null;
    if (testAll) {
      emit(
        state.copyWith(
          handlers: handlersToBeTested
              .map((h) => h.copyWith(usableTesting: true))
              .toList(),
        ),
      );
    } else {
      final newList = List<OutboundHandler>.from(state.handlers);
      for (var ha in handlersToBeTested) {
        final index = newList.indexWhere((h) => h.id == ha.id);
        if (index >= 0) {
          newList[index] = newList[index].copyWith(usableTesting: true);
        }
      }
      emit(state.copyWith(handlers: newList));
    }

    _handlersUsableTesting.addAll(handlersToBeTested.map((h) => h.id));

    await _outboundRepo.updateHandlerFields(
      handlersToBeTested.map((h) => h.id).toList(),
      ok: 0,
      ping: 0,
    );

    void onError(dynamic e, OutboundHandler h) {
      _handlersUsableTesting.remove(h.id);
      final handlers = List<OutboundHandler>.from(state.handlers);
      final index = handlers.indexWhere((hh) => hh.id == h.id);
      if (index >= 0) {
        handlers[index] = handlers[index].copyWith(
          usableTesting: false,
          ok: 0,
          ping: 0,
          speed: 0,
        );
        emit(state.copyWith(handlers: _sortHandlers(handlers, state.sortCol)));
      }
      _outboundRepo.updateHandler(h.id, ok: 0, ping: 0, serverIp: '', speed: 0);
      // reportError(e, StackTrace.current);
      logger.e('statusTest error', error: e);
    }

    late PingMode pingMode;
    if (e.pingMode != null) {
      pingMode = e.pingMode!;
    } else {
      pingMode = _pref.pingMode;
    }

    const batchSize = 100;
    for (var i = 0; i < handlersToBeTested.length; i += batchSize) {
      final end = (i + batchSize < handlersToBeTested.length)
          ? i + batchSize
          : handlersToBeTested.length;
      final batch = handlersToBeTested.sublist(i, end);

      late final List<Future> futures;
      if (pingMode == PingMode.Real) {
        futures = batch
            .map(
              (h) => _xApiClient
                  .handlerUsable(HandlerUsableRequest(handler: h.toConfig()))
                  .then((res) async {
                    _handlersUsableTesting.remove(h.id);
                    final handlers = List<OutboundHandler>.from(state.handlers);
                    final index = handlers.indexWhere((hh) => hh.id == h.id);
                    final ok = res.ping > 0;
                    if (index >= 0) {
                      handlers[index] = handlers[index].copyWith(
                        usableTesting: false,
                        ok: ok ? 1 : -1,
                        ping: res.ping,
                        speed: ok ? null : 0,
                      );
                      emit(
                        state.copyWith(
                          handlers: _sortHandlers(handlers, state.sortCol),
                        ),
                      );
                    }
                    await _outboundRepo.updateHandler(
                      h.id,
                      ok: ok ? 1 : -1,
                      ping: res.ping,
                      pingTestTime:
                          DateTime.now().millisecondsSinceEpoch ~/ 1000,
                      speed: ok ? null : 0,
                    );
                  })
                  .catchError((e) {
                    onError(e, h);
                  }),
            )
            .toList();
      } else {
        futures = batch.map((h) async {
          late final OutboundHandlerConfig config;
          if (h.config.hasOutbound()) {
            config = h.config.outbound;
          } else {
            config = h.config.chain.handlers.first;
          }

          String address = config.address;
          int port = config.port;
          if (config.getDisplayProtocol() == "WireGuard") {
            final wireguardConfig = DeviceConfig();
            config.protocol.unpackInto(wireguardConfig);
            address = wireguardConfig.peers.first.endpoint.split(':').first;
            port =
                int.tryParse(
                  wireguardConfig.peers.first.endpoint.split(':').last,
                ) ??
                0;
          } else {
            if (port == 0) {
              port = config.ports.first.from;
            }
          }

          late Future<int> f;
          if (Tm.instance.state == TmStatus.connected) {
            f = _xController.rttTest(address, port);
          } else {
            f = _xApiClient.rtt(RttTestRequest(addr: address, port: port));
          }

          return f
              .then((res) async {
                _handlersUsableTesting.remove(h.id);
                final handlers = List<OutboundHandler>.from(state.handlers);
                final index = handlers.indexWhere((hh) => hh.id == h.id);
                final ok = res > 0;
                if (index >= 0) {
                  handlers[index] = handlers[index].copyWith(
                    usableTesting: false,
                    ok: ok ? 1 : -1,
                    ping: res,
                    speed: ok ? null : 0,
                  );
                  emit(
                    state.copyWith(
                      handlers: _sortHandlers(handlers, state.sortCol),
                    ),
                  );
                }
                await _outboundRepo.updateHandler(
                  h.id,
                  ok: ok ? 1 : -1,
                  ping: res,
                  pingTestTime: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                  speed: ok ? null : 0,
                );
              })
              .catchError((e) {
                onError(e, h);
              });
        }).toList();
      }

      await Future.wait(futures);
    }
  }

  Future<void> _onSubscriptionDelete(
    SubscriptionDeleteEvent e,
    Emitter<OutboundState> emit,
  ) async {
    if (state.selected?.name == e.sub.name) {
      emit(state.copyWith(selected: () => null));
      _pref.setNodeGroup(null);
    }
    try {
      await _outboundRepo.removeSubscription(e.sub.id);
    } catch (e) {
      logger.e('removeSubscription', error: e);
      rethrow;
    }
    _xController.subscriptionUpdated();
    final handlers = _sortHandlers(await _getHandlers(), state.sortCol);
    emit(state.copyWith(handlers: handlers));
  }

  Future<void> _onSubscriptionPlaceOnTop(
    SubscriptionPlaceOnTopEvent e,
    Emitter<OutboundState> emit,
  ) async {
    await _outboundRepo.updateSubscription(
      e.sub.id,
      placeOnTop: !e.sub.placeOnTop,
    );
  }

  Future<void> _onOutboundHandlerGroupPlaceOnTop(
    OutboundHandlerGroupPlaceOnTopEvent e,
    Emitter<OutboundState> emit,
  ) async {
    await _outboundRepo.updateOutboundHandlerGroup(
      e.group.name,
      placeOnTop: !e.group.placeOnTop,
    );
  }

  Future<void> _populateCountry(
    PopulateCountryEvent e,
    Emitter<OutboundState> emit,
  ) async {
    emit(state.copyWith(testingArea: true));
    try {
      await updateCountry(state.handlers, emit);
    } catch (e) {
      logger.e('populateCountry error', error: e);
      // reportError(e, StackTrace.current);
      snack(rootLocalizations()?.failedToUpdateCountry);
    }
    emit(state.copyWith(testingArea: false));
  }

  Future<void> _onSubscriptionUpdated(
    SubscriptionUpdatedEvent e,
    Emitter<OutboundState> emit,
  ) async {
    emit(
      state.copyWith(
        handlers: _sortHandlers(await _getHandlers(), state.sortCol),
      ),
    );
    if (_pref.autoTestNodes) {
      final subHandlers = (await _outboundRepo.getHandlers())
          .where((h) => h.subId != null)
          .toList();
      _autoTestHandlersMissingMetrics(subHandlers);
    }
    await updateCountry(await _outboundRepo.getHandlers(country: ''), emit);
  }

  Future<void> updateCountry(
    List<OutboundHandler> handlers,
    Emitter<OutboundState> emit,
  ) async {
    final handlersToBeTested = handlers;
    final newList = List<OutboundHandler>.from(state.handlers);
    for (var ha in handlersToBeTested) {
      final index = newList.indexWhere((h) => h.id == ha.id);
      if (index >= 0) {
        newList[index] = newList[index].copyWith(usableTesting: true);
      }
    }
    emit(state.copyWith(handlers: newList));

    _handlersUsableTesting.addAll(handlersToBeTested.map((h) => h.id));

    await _outboundRepo.updateHandlerFields(
      handlersToBeTested.map((h) => h.id).toList(),
      ok: 0,
    );

    void onError(dynamic e, OutboundHandler h) {
      _handlersUsableTesting.remove(h.id);
      final handlers = List<OutboundHandler>.from(state.handlers);
      final index = handlers.indexWhere((hh) => hh.id == h.id);
      if (index >= 0) {
        handlers[index] = handlers[index].copyWith(usableTesting: false, ok: 0);
        emit(state.copyWith(handlers: _sortHandlers(handlers, state.sortCol)));
      }
      _outboundRepo.updateHandler(h.id, ok: 0, serverIp: '', country: '');
      // reportError(e, StackTrace.current);
      logger.e('statusTest error', error: e);
    }

    const batchSize = 100;
    for (var i = 0; i < handlersToBeTested.length; i += batchSize) {
      final end = (i + batchSize < handlersToBeTested.length)
          ? i + batchSize
          : handlersToBeTested.length;
      final batch = handlersToBeTested.sublist(i, end);

      late final List<Future> futures;
      futures = batch
          .map(
            (h) => _xApiClient
                .handlerCountryTest(
                  HandlerCountryTestRequest(handler: h.toConfig()),
                )
                .then((res) async {
                  _handlersUsableTesting.remove(h.id);
                  final handlers = List<OutboundHandler>.from(state.handlers);
                  final index = handlers.indexWhere((hh) => hh.id == h.id);
                  if (index >= 0) {
                    handlers[index] = handlers[index].copyWith(
                      usableTesting: false,
                      ok: 1,
                      countryCode: res.country,
                    );
                    emit(
                      state.copyWith(
                        handlers: _sortHandlers(handlers, state.sortCol),
                      ),
                    );
                  }
                  logger.d(
                    'updateHandler: ${h.id}, country: ${res.country}, ip: ${res.ip}',
                  );
                  await _outboundRepo.updateHandler(
                    h.id,
                    ok: 1,
                    country: res.country,
                    serverIp: res.ip,
                  );
                })
                .catchError((e) {
                  onError(e, h);
                }),
          )
          .toList();
      await Future.wait(futures);
    }
  }

  void _multiSelect(MultiSelectEvent e, Emitter<OutboundState> emit) {
    if (e.multiSelect) {
      final handlers = List<OutboundHandler>.from(
        state.handlers.map((h) => h.copyWith(selectInMultipleSelect: false)),
      );
      emit(state.copyWith(handlers: handlers, multiSelect: e.multiSelect));
    } else {
      emit(state.copyWith(multiSelect: e.multiSelect));
    }
  }

  void _multiSelectVerticalDragUpdate(
    MultiSelectVerticalDragUpdateEvent e,
    Emitter<OutboundState> emit,
  ) {
    final handlers = List<OutboundHandler>.from(state.handlers);
    final index = handlers.indexWhere((h) => h.id == e.handler.id);
    if (index >= 0) {
      final num = (e.localOffset.dy / 50).ceil();
      for (int i = 0; i < num; i++) {
        handlers[index + i] = handlers[index + i].copyWith(
          selectInMultipleSelect: true,
        );
      }
      emit(state.copyWith(handlers: handlers));
    }
  }

  void _multiSelectToggle(
    MultiSelectToggleEvent e,
    Emitter<OutboundState> emit,
  ) {
    final handlers = List<OutboundHandler>.from(state.handlers);
    final index = handlers.indexWhere((h) => h.id == e.handler.id);
    if (index >= 0) {
      handlers[index] = handlers[index].copyWith(
        selectInMultipleSelect: !handlers[index].selectedInMultipleSelect,
      );
      emit(state.copyWith(handlers: handlers));
    }
  }

  void _multiSelectSelectAll(
    MultiSelectSelectAllEvent e,
    Emitter<OutboundState> emit,
  ) {
    final handlers = List<OutboundHandler>.from(
      state.handlers.map((h) => h.copyWith(selectInMultipleSelect: e.selected)),
    );
    emit(state.copyWith(handlers: handlers));
  }

  // void _multiSelectVerticalDragStart(
  //     MultiSelectVerticalDragStartEvent e, Emitter<OutboundState> emit) {
  //   _multiSelectVerticalDragStartY = e.localOffset.dy;
  //   _multiSelectVerticalDragDistance = 0;
  // }

  void _onSmallScreenPreference(
    SmallScreenPreferenceEvent e,
    Emitter<OutboundState> emit,
  ) {
    emit(
      state.copyWith(
        smallScreenPreference: state.smallScreenPreference.copyWith(
          showProtocol: e.protocol,
          showUsable: e.usable,
          showPing: e.ping,
          showSpeed: e.speed,
          showActive: e.active,
          showAddress: e.address,
        ),
      ),
    );
    if (e.protocol != null) {
      _pref.setSmScreenShowProtocol(e.protocol!);
    }
    if (e.usable != null) {
      _pref.setSmScreenShowOk(e.usable!);
    }
    if (e.ping != null) {
      _pref.setSmScreenShowLatency(e.ping!);
    }
    if (e.speed != null) {
      _pref.setSmScreenShowSpeed(e.speed!);
    }
    if (e.active != null) {
      _pref.setSmScreenShowActive(e.active!);
    }
    if (e.address != null) {
      _pref.setSmScreenShowAddress(e.address!);
    }
  }

  void _onToggleViewMode(ToggleViewModeEvent e, Emitter<OutboundState> emit) {
    final newMode = state.viewMode == OutboundViewMode.list
        ? OutboundViewMode.grid
        : OutboundViewMode.list;
    emit(state.copyWith(viewMode: newMode));
    _pref.setOutboundViewMode(newMode);
  }

  void _onAddSelectedHandlersToGroup(
    AddSelectedHandlersToGroupEvent e,
    Emitter<OutboundState> emit,
  ) {
    final handlers = state.handlers
        .where((h) => h.selectedInMultipleSelect)
        .toList();
    _outboundRepo.addHandlerToGroup(
      e.groupName,
      handlers.map((h) => h.id).toList(),
    );
  }

  Future<void> _onAddHandlerToGroup(
    AddHandlerToGroupEvent e,
    Emitter<OutboundState> emit,
  ) async {
    await _outboundRepo.addHandlerToGroup(e.groupName, [e.handler.id]);
  }
}

sealed class OutboundEvent extends Equatable {
  const OutboundEvent();

  @override
  List<Object> get props => [];
}

class InitialEvent extends OutboundEvent {}

class SyncEvent extends OutboundEvent {}

class OutboundModeSwitchEvent extends OutboundEvent {
  const OutboundModeSwitchEvent(this.mode);
  final ProxySelectorMode mode;
}

class AddHandlerEvent extends OutboundEvent {
  const AddHandlerEvent(this.handler);
  final HandlerConfig handler;
}

class AddGroupEvent extends OutboundEvent {
  const AddGroupEvent(this.groupName);
  final String groupName;
}

class DeleteGroupEvent extends OutboundEvent {
  const DeleteGroupEvent(this.group);
  final OutboundHandlerGroup group;
}

class DeleteGroupAndNodesEvent extends OutboundEvent {
  const DeleteGroupAndNodesEvent(this.group);
  final OutboundHandlerGroup group;
}

class AddHandlersEvent extends OutboundEvent {
  const AddHandlersEvent(
    this.handlers, {
    this.groupName = defaultGroupName,
    this.replaceAll = false,
  });
  final List<HandlerConfig> handlers;
  final String groupName;
  // if true, existing handlers with same name with be updated and
  // existing handlers that are not in the new handlers list will be deleted.
  final bool replaceAll;
}

class SelectedGroupChangeEvent extends OutboundEvent {
  const SelectedGroupChangeEvent(this.selected);
  final NodeGroup? selected;
}

/// Select the subscription or group that contains [handlerId]. If the handler
/// does not belong to any visible subscription or group, [allGroup] is
/// selected instead.
class SelectGroupContainingHandlerEvent extends OutboundEvent {
  const SelectGroupContainingHandlerEvent(this.handlerId);
  final int handlerId;

  @override
  List<Object> get props => [handlerId];
}

class UserIsNotProEvent extends OutboundEvent {
  const UserIsNotProEvent();
}

class HandlersDeleteEvent extends OutboundEvent {
  const HandlersDeleteEvent(this.ids);
  final List<int> ids;
}

class HandlersCopyEvent extends OutboundEvent {
  const HandlersCopyEvent(this.handler);
  final OutboundHandler handler;
}

class SubscriptionDeleteEvent extends OutboundEvent {
  const SubscriptionDeleteEvent(this.sub);
  final Subscription sub;
}

class SubscriptionPlaceOnTopEvent extends OutboundEvent {
  const SubscriptionPlaceOnTopEvent(this.sub);
  final Subscription sub;
}

class OutboundHandlerGroupPlaceOnTopEvent extends OutboundEvent {
  const OutboundHandlerGroupPlaceOnTopEvent(this.group);
  final OutboundHandlerGroup group;
}

// class SubscriptionToggleDisableEvent extends OutboundEvent {
//   const SubscriptionToggleDisableEvent(this.sub, {this.enabled = false});
//   final Subscription sub;
//   final bool enabled;
// }

class SortHandlersEvent extends OutboundEvent {
  const SortHandlersEvent(this.colSort);
  final (Col, SortOrder)? colSort;
}

class SwitchHandlerEvent extends OutboundEvent {
  SwitchHandlerEvent(this.handler, this.selected, {this.whenPersisted});
  final OutboundHandler handler;
  final bool selected;

  /// If non-null, completed after DB updates in [_switchHandler] finish (success or failure).
  final Completer<void>? whenPersisted;

  @override
  List<Object> get props => [handler, selected];
}

class ManuualSingleSelectionEvent extends OutboundEvent {
  const ManuualSingleSelectionEvent();
}

class SpeedTestEvent extends OutboundEvent {
  const SpeedTestEvent({this.handlers});

  /// if null, test all displayed enabled handlers
  final List<OutboundHandler>? handlers;
}

class StatusTestEvent extends OutboundEvent {
  const StatusTestEvent({this.handlers, this.pingMode});

  /// if null, test all displayed enabled handlers
  final List<OutboundHandler>? handlers;
  final PingMode? pingMode;
}

class PopulateCountryEvent extends OutboundEvent {}

class MultiSelectEvent extends OutboundEvent {
  const MultiSelectEvent(this.multiSelect);
  final bool multiSelect;
}

class MultiSelectVerticalDragStartEvent extends OutboundEvent {
  const MultiSelectVerticalDragStartEvent(this.localOffset);
  final Offset localOffset;
}

class MultiSelectVerticalDragUpdateEvent extends OutboundEvent {
  const MultiSelectVerticalDragUpdateEvent(this.handler, this.localOffset);
  final OutboundHandler handler;
  final Offset localOffset;
}

class MultiSelectToggleEvent extends OutboundEvent {
  const MultiSelectToggleEvent(this.handler);
  final OutboundHandler handler;
}

class DeleteUnusableEvent extends OutboundEvent {}

class HandlerUpdatedEvent extends OutboundEvent {
  const HandlerUpdatedEvent(this.id);
  final int id;
}

class SmallScreenPreferenceEvent extends OutboundEvent {
  const SmallScreenPreferenceEvent({
    this.protocol,
    this.usable,
    this.ping,
    this.speed,
    this.active,
    this.address,
  });
  final bool? protocol;
  final bool? usable;
  final bool? ping;
  final bool? speed;
  final bool? active;
  final bool? address;
}

class ToggleViewModeEvent extends OutboundEvent {
  const ToggleViewModeEvent();
}

class MultiSelectSelectAllEvent extends OutboundEvent {
  const MultiSelectSelectAllEvent(this.selected);
  final bool selected;
}

// two build-in groups
const defaultGroupName = 'default';
const freeGroupName = 'free';

class HandlerEdittedEvent extends OutboundEvent {
  const HandlerEdittedEvent(this.handler);
  final OutboundHandler handler;
}

class AddSelectedHandlersToGroupEvent extends OutboundEvent {
  const AddSelectedHandlersToGroupEvent(this.groupName);
  final String groupName;
}

class AddHandlerToGroupEvent extends OutboundEvent {
  const AddHandlerToGroupEvent(this.handler, this.groupName);
  final OutboundHandler handler;
  final String groupName;
}

// class EnableDisableHandlerEvent extends OutboundEvent {
//   const EnableDisableHandlerEvent(this.handlers, {this.enabled = true});
//   final List<OutboundHandler> handlers;
//   final bool enabled;
// }

class SubscriptionUpdatedEvent extends OutboundEvent {}

abstract class NodeGroup {
  String get name;
  bool get placeOnTop;
}

class AllGroup extends NodeGroup {
  @override
  String get name => 'all';
  @override
  bool get placeOnTop => true;
}

enum OutboundViewMode { list, grid }

class OutboundTableSmallScreenPreference {
  const OutboundTableSmallScreenPreference({
    this.showProtocol = false,
    this.showUsable = true,
    this.showPing = false,
    this.showSpeed = false,
    this.showActive = false,
    this.showAddress = false,
  });

  final bool showProtocol;
  final bool showUsable;
  final bool showPing;
  final bool showSpeed;
  final bool showActive;
  final bool showAddress;

  OutboundTableSmallScreenPreference copyWith({
    bool? showProtocol,
    bool? showUsable,
    bool? showPing,
    bool? showSpeed,
    bool? showActive,
    bool? showAddress,
  }) {
    return OutboundTableSmallScreenPreference(
      showProtocol: showProtocol ?? this.showProtocol,
      showUsable: showUsable ?? this.showUsable,
      showPing: showPing ?? this.showPing,
      showSpeed: showSpeed ?? this.showSpeed,
      showActive: showActive ?? this.showActive,
      showAddress: showAddress ?? this.showAddress,
    );
  }
}

class OutboundState {
  OutboundState({
    // group selector states
    this.selected,
    this.groups = const [],
    // determine cols
    this.multiSelect = false,
    this.smallScreenPreference = const OutboundTableSmallScreenPreference(),
    this.viewMode = OutboundViewMode.list,
    // header states
    this.testingArea = false,
    this.sortCol,
    // table states
    this.using4 = 0,
    // this.using6 = 0,
    this.handlers = const [],
  });

  /// tag of the selected subscription, null if none is selected,
  final NodeGroup? selected;
  final List<NodeGroup> groups;
  // when this list changes, create a new list to trigger blocSelector builder
  final List<OutboundHandler> handlers;
  // the handler used to handle ipv4 in auto single handler mode. Should only
  // populated in auto single handler mode.
  final int using4;
  // the handler used to handle ipv6 in auto single handler mode. Should only
  // populated in auto single handler mode.
  // final int using6;
  final bool testingArea;
  final (Col, SortOrder)? sortCol;
  final bool multiSelect;
  final OutboundTableSmallScreenPreference smallScreenPreference;
  final OutboundViewMode viewMode;

  OutboundState copyWith({
    ValueGetter<NodeGroup?>? selected,
    List<NodeGroup>? gs,
    List<OutboundHandler>? handlers,
    int? using4,
    int? using6,
    bool? testingArea,
    ValueGetter<(Col, SortOrder)?>? sortCol,
    bool? multiSelect,
    OutboundTableSmallScreenPreference? smallScreenPreference,
    OutboundViewMode? viewMode,
  }) {
    return OutboundState(
      selected: selected != null ? selected() : this.selected,
      groups: gs ?? groups,
      handlers: handlers ?? this.handlers,
      using4: using4 ?? this.using4,
      viewMode: viewMode ?? this.viewMode,
      // using6: using6 ?? this.using6,
      testingArea: testingArea ?? this.testingArea,
      sortCol: sortCol != null ? sortCol() : this.sortCol,
      multiSelect: multiSelect ?? this.multiSelect,
      smallScreenPreference:
          smallScreenPreference ?? this.smallScreenPreference,
    );
  }
}
