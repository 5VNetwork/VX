import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tm/protos/app/grpcservice/grpc.pb.dart';
import 'package:vx/app/blocs/proxy_selector/proxy_selector_bloc.dart';
import 'package:vx/app/outbound/outbound_repo.dart';
import 'package:vx/app/x_controller.dart';
import 'package:vx/l10n/app_localizations.dart';

class SelectorBeingUsedState extends Equatable {
  const SelectorBeingUsedState({
    this.rawTags = const [],
    this.displayNames = const [],
  });

  final List<String> rawTags;
  final List<String> displayNames;

  List<String> get lines =>
      displayNames.length == rawTags.length && displayNames.isNotEmpty
      ? displayNames
      : rawTags;

  @override
  List<Object?> get props => [rawTags, displayNames];
}

class SelectorBeingUsedCubit extends Cubit<SelectorBeingUsedState> {
  SelectorBeingUsedCubit({
    required this.selectorTag,
    required XController xController,
    required OutboundRepo outboundRepo,
    this.clearWhenSelectorEmpty = false,
  }) : _xController = xController,
       _outboundRepo = outboundRepo,
       super(const SelectorBeingUsedState()) {
    _sub = _xController.handlerBeingUsedStream().listen(_onHandlerBeingUsed);
    _statusSub = _xController.statusStream().listen((status) {
      if (status != XStatus.connected) {
        emit(const SelectorBeingUsedState());
      }
    });
  }

  final String selectorTag;
  final bool clearWhenSelectorEmpty;
  final XController _xController;
  final OutboundRepo _outboundRepo;
  StreamSubscription<HandlerBeingUsed>? _sub;
  StreamSubscription<XStatus>? _statusSub;
  int _resolveGen = 0;

  static int _parseHandlerIdFromTag(String tag) {
    if (tag.contains('-')) {
      return int.tryParse(tag.split('-').first) ?? 0;
    }
    return int.tryParse(tag) ?? 0;
  }

  void _onHandlerBeingUsed(HandlerBeingUsed used) {
    final isTarget = used.selector == selectorTag;
    final isClearSignal = clearWhenSelectorEmpty && used.selector.isEmpty;
    if (!isTarget && !isClearSignal) return;
    final tags = List<String>.from(used.tags);
    if (tags.isEmpty) {
      _resolveGen++;
      emit(const SelectorBeingUsedState());
      return;
    }
    emit(SelectorBeingUsedState(rawTags: tags));
    _resolveDisplayNames(tags);
  }

  Future<void> _resolveDisplayNames(List<String> tags) async {
    final gen = ++_resolveGen;
    final names = <String>[];
    for (final tag in tags) {
      final id = _parseHandlerIdFromTag(tag);
      if (id > 0) {
        final h = await _outboundRepo.getHandlerById(id);
        names.add(h?.name ?? tag);
      } else {
        names.add(tag);
      }
    }
    if (isClosed || gen != _resolveGen) return;
    emit(SelectorBeingUsedState(rawTags: tags, displayNames: names));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _statusSub?.cancel();
    return super.close();
  }
}

class SelectorBeingUsedView extends StatelessWidget {
  const SelectorBeingUsedView({super.key});

  void _showDialog(BuildContext context, List<String> lines) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.selectorHandlersInUseTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(e),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectorBeingUsedCubit, SelectorBeingUsedState>(
      builder: (context, state) {
        if (state.rawTags.isEmpty) return const SizedBox.shrink();
        final lines = state.lines;
        final l10n = AppLocalizations.of(context)!;
        final summary = lines.length == 1
            ? lines.first
            : l10n.handlersInUseCount(lines.length);
        return Padding(
          padding: const EdgeInsets.only(top: 1.0),
          child: Tooltip(
            message: lines.join('\n'),
            child: Material(
              color: Theme.of(context).colorScheme.secondaryContainer ,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: () => _showDialog(context, lines),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
