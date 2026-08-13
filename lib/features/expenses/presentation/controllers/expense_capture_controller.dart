import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wrap_my_finances/core/di/providers.dart';
import 'package:wrap_my_finances/core/errors/failure.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/expense.dart';
import 'package:wrap_my_finances/features/expenses/domain/entities/money.dart';
import 'package:wrap_my_finances/features/expenses/domain/usecases/log_expense.dart';
import 'package:wrap_my_finances/features/expenses/presentation/controllers/amount_input_state.dart';
import 'package:wrap_my_finances/features/expenses/presentation/current_currency_code_provider.dart';

/// The capture screen's two steps.
enum CaptureStep {
  /// Typing the amount.
  amount,

  /// Choosing a category.
  category,
}

/// Screen state: which step is active, the amount typed so far, whether a
/// submission is in flight, and the last local-write failure (if any, per
/// FR-012).
@immutable
class ExpenseCaptureState {
  const ExpenseCaptureState._({
    required this.step,
    required this.amount,
    required this.isSubmitting,
    required this.lastError,
  });

  /// The empty starting state for [locale].
  factory ExpenseCaptureState.initial(String locale) => ExpenseCaptureState._(
    step: CaptureStep.amount,
    amount: AmountInputState(locale: locale),
    isSubmitting: false,
    lastError: null,
  );

  /// Which step is active.
  final CaptureStep step;

  /// The amount typed so far.
  final AmountInputState amount;

  /// `true` only for the brief window between tapping a category and the
  /// local write resolving — prevents a double-submit from a fast
  /// double-tap, never gates a spinner.
  final bool isSubmitting;

  /// Non-null only after a local-write failure (FR-012); cleared on the
  /// next attempt.
  final Failure? lastError;

  /// Returns a copy with [step]/[amount]/[isSubmitting] replaced if given,
  /// and [lastError] replaced with [lastError] verbatim (including `null`,
  /// to explicitly clear it) whenever [clearError] is `true`.
  ExpenseCaptureState copyWith({
    CaptureStep? step,
    AmountInputState? amount,
    bool? isSubmitting,
    Failure? lastError,
    bool clearError = false,
  }) {
    return ExpenseCaptureState._(
      step: step ?? this.step,
      amount: amount ?? this.amount,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastError: clearError ? lastError : (lastError ?? this.lastError),
    );
  }
}

/// Orchestrates the capture screen: keypad input, the amount→category step
/// transition, and submission via [LogExpense]. Category data itself is not
/// held here — the category picker watches `activeCategoriesProvider`
/// directly, since it's a live Firestore stream Riverpod already models
/// well as its own provider.
class ExpenseCaptureController extends StateNotifier<ExpenseCaptureState> {
  /// Creates the controller for [locale], using [_logExpense] to persist.
  /// [_currencyCodeOf] is a live getter, not a snapshot — read fresh on
  /// every [submit], so a currency preference change (US8) takes effect
  /// immediately without needing this controller to be rebuilt.
  ExpenseCaptureController({
    required LogExpense logExpense,
    required String locale,
    required String Function() currencyCodeOf,
  })
    // The public param name stays `logExpense` for call-site clarity; only
    // the field itself is private.
    // ignore: prefer_initializing_formals
    : _logExpense = logExpense,
       // Same reasoning as _logExpense above.
       // ignore: prefer_initializing_formals
       _currencyCodeOf = currencyCodeOf,
       super(ExpenseCaptureState.initial(locale));

  final LogExpense _logExpense;
  final String Function() _currencyCodeOf;

  /// Appends [digit] to the amount.
  void appendDigit(String digit) {
    state = state.copyWith(amount: state.amount.appendDigit(digit));
  }

  /// Presses the decimal separator key.
  void appendDecimalSeparator() {
    state = state.copyWith(amount: state.amount.appendDecimalSeparator());
  }

  /// Removes the last keystroke.
  void backspace() {
    state = state.copyWith(amount: state.amount.backspace());
  }

  /// Advances to the category step. A no-op while the amount is invalid
  /// (FR-010) — the "Next" button is disabled in that state anyway, but the
  /// controller enforces it too, defensively.
  void advanceToCategory() {
    if (!state.amount.isValid) return;
    state = state.copyWith(step: CaptureStep.category);
  }

  /// Logs the expense against [categoryId]. On success, resets to the
  /// initial state (FR-004). On failure, preserves the typed amount and
  /// exposes the error (FR-012) — never clears it on its own.
  Future<void> submit(String categoryId) async {
    if (state.isSubmitting) return;
    state = state.copyWith(isSubmitting: true, clearError: true);

    final now = DateTime.now();
    final draft = Expense(
      id: '',
      amount: Money(
        minorUnits: state.amount.minorUnits,
        currencyCode: _currencyCodeOf(),
      ),
      categoryId: categoryId,
      date: now,
      createdAt: now,
    );

    final result = await _logExpense.call(draft);
    result.when(
      success: (_) {
        state = ExpenseCaptureState.initial(state.amount.locale);
      },
      failed: (failure) {
        state = state.copyWith(isSubmitting: false, lastError: failure);
      },
    );
  }
}

/// Riverpod provider for [ExpenseCaptureController].
final expenseCaptureControllerProvider =
    StateNotifierProvider<ExpenseCaptureController, ExpenseCaptureState>((
      ref,
    ) {
      return ExpenseCaptureController(
        logExpense: ref.watch(logExpenseProvider),
        locale: ref.watch(deviceLanguageCodeProvider),
        currencyCodeOf: () => ref.read(currentCurrencyCodeProvider),
      );
    });
