import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/repositories/expense_repository.dart';
import 'package:wrap_my_finances/features/expenses/presentation/day_group.dart';

/// The undo window's default duration — 5 seconds, taken directly from
/// `docs/UI_UX_SPEC.md` §4 (see
/// `specs/005-expense-history-undo/research.md`).
const Duration defaultUndoWindow = Duration(seconds: 5);

/// The history screen's state: the visible (already pending-deletion
/// filtered) day groups, and which expense ids are currently mid-undo-window.
@immutable
class ExpenseHistoryState {
  /// Creates a state with [dayGroups] already filtered by [pendingDeletionIds].
  const ExpenseHistoryState({
    required this.dayGroups,
    required this.pendingDeletionIds,
  });

  /// Empty starting state, before the first stream event arrives.
  static const initial = ExpenseHistoryState(
    dayGroups: [],
    pendingDeletionIds: {},
  );

  /// Day-grouped, subtotaled expenses — already excludes anything in
  /// [pendingDeletionIds], per FR-006 ("deja de contar... desde el
  /// instante del borrado").
  final List<DayGroup> dayGroups;

  /// Expense ids swiped away but not yet written to Firestore.
  final Set<String> pendingDeletionIds;
}

/// Orchestrates the history screen: subscribes to
/// [ExpenseRepository.watchAll], and layers the "instant local filter,
/// single write at expiry" undo mechanism on top — see
/// `specs/005-expense-history-undo/research.md`. Category resolution is
/// not this controller's concern; the page joins [ExpenseHistoryState] with
/// `activeCategoriesProvider` separately.
class ExpenseHistoryController extends StateNotifier<ExpenseHistoryState> {
  /// Creates the controller over [_expenseRepository]. [undoWindow] is
  /// injectable so tests don't need to wait 5 real seconds.
  ExpenseHistoryController({
    required ExpenseRepository expenseRepository,
    this.undoWindow = defaultUndoWindow,
    AppLifecycleListener Function({required VoidCallback onPause})?
    lifecycleListenerFactory,
  })
    // The public param name stays `expenseRepository` for call-site clarity;
    // only the field itself is private.
    // ignore: prefer_initializing_formals
    : _expenseRepository = expenseRepository,
       super(ExpenseHistoryState.initial) {
    _subscription = _expenseRepository.watchAll().listen(_onExpenses);
    _lifecycleListener =
        (lifecycleListenerFactory ??
        ({required onPause}) => AppLifecycleListener(onPause: onPause))(
          onPause: _confirmAllPendingDeletions,
        );
  }

  final ExpenseRepository _expenseRepository;

  /// How long a deletion stays undoable before it's written to Firestore.
  final Duration undoWindow;

  late final StreamSubscription<List<Expense>> _subscription;
  late final AppLifecycleListener _lifecycleListener;
  final Map<String, Timer> _timers = {};
  List<Expense> _rawExpenses = const [];

  void _onExpenses(List<Expense> expenses) {
    _rawExpenses = expenses;
    _applyPendingIds(state.pendingDeletionIds);
  }

  void _applyPendingIds(Set<String> ids) {
    final visible = _rawExpenses
        .where((expense) => !ids.contains(expense.id))
        .toList();
    state = ExpenseHistoryState(
      dayGroups: groupByDay(visible),
      pendingDeletionIds: ids,
    );
  }

  /// Swipe-to-delete: excludes [expenseId] from [ExpenseHistoryState
  /// .dayGroups] immediately (FR-006). No Firestore write happens here —
  /// only when [undoWindow] elapses without [undoDelete].
  void requestDelete(String expenseId) {
    _applyPendingIds({...state.pendingDeletionIds, expenseId});
    _timers[expenseId] = Timer(
      undoWindow,
      () => _confirmDelete(expenseId),
    );
  }

  /// Cancels [expenseId]'s pending deletion. It reappears in its original
  /// position, since it was never actually removed from [_rawExpenses] —
  /// zero Firestore writes occur for an undone deletion.
  void undoDelete(String expenseId) {
    _timers.remove(expenseId)?.cancel();
    _applyPendingIds({...state.pendingDeletionIds}..remove(expenseId));
  }

  void _confirmDelete(String expenseId) {
    _timers.remove(expenseId);
    // Fire-and-forget: nothing is still waiting on this write's completion
    // by this point — the entry already left the view at swipe time.
    unawaited(_expenseRepository.delete(expenseId));
    _applyPendingIds({...state.pendingDeletionIds}..remove(expenseId));
  }

  /// Backgrounding the app confirms every still-pending deletion
  /// immediately — a `Timer` doesn't reliably keep counting wall-clock
  /// time once the process is suspended, so this is the actual signal that
  /// "the undo window closed while the app wasn't in the foreground"
  /// (spec.md Edge Cases), not just a Timer racing against suspension.
  void _confirmAllPendingDeletions() {
    for (final expenseId in state.pendingDeletionIds.toList()) {
      _timers.remove(expenseId)?.cancel();
      unawaited(_expenseRepository.delete(expenseId));
    }
    _applyPendingIds(const {});
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    _lifecycleListener.dispose();
    for (final timer in _timers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}

/// Riverpod provider for [ExpenseHistoryController].
final expenseHistoryControllerProvider =
    StateNotifierProvider<ExpenseHistoryController, ExpenseHistoryState>((
      ref,
    ) {
      // StateNotifierProvider calls the notifier's own dispose() when this
      // provider is disposed — no separate ref.onDispose needed.
      return ExpenseHistoryController(
        expenseRepository: ref.watch(expenseRepositoryProvider),
      );
    });
