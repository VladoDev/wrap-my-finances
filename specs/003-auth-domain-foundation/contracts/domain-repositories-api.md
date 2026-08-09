# Contract: `expenses`/`categories` Domain API

`004` (and any feature after it) implements against these interfaces and entities without
modifying them structurally — only adding a `data/` implementation and `presentation/` layer.

## `ExpenseRepository`

```dart
abstract class ExpenseRepository {
  Future<Result<Expense>> create(Expense expense);
  Future<Result<void>> delete(String expenseId);
  Stream<List<Expense>> watchByMonth(String monthKey);
}
```

## `CategoryRepository`

```dart
abstract class CategoryRepository {
  Future<Result<List<Category>>> getActive();
  Stream<List<Category>> watchActive();
  Future<Result<void>> incrementUsage(String categoryId);
}
```

## Entities

```dart
class Money {
  const Money({required this.minorUnits, required this.currencyCode});
  final int minorUnits;
  final String currencyCode;
}

class Expense {
  const Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.createdAt,
    this.note,
  });
  final String id;
  final Money amount;
  final String categoryId;
  final DateTime date;
  final DateTime createdAt;
  final String? note;
}

class Category {
  Category({
    required this.id,
    required this.color,
    required this.iconName,
    required this.isDefault,
    required this.sortOrder,
    required this.isActive,
    required this.usageCount,
    this.nameKey,
    this.name,
    this.lastUsedAt,
  }) : assert(
         (nameKey != null) != (name != null),
         'exactly one of nameKey/name must be non-null',
       );
  final String id;
  final String? nameKey;
  final String? name;
  final String color;
  final String iconName;
  final bool isDefault;
  final int sortOrder;
  final bool isActive;
  final int usageCount;
  final DateTime? lastUsedAt;
}
```

## Stability notes for consumers

- Every method returns `Result<T>` (success/failure) or a `Stream`, never throws — consistent with
  `docs/ARCHITECTURE.md`'s "no exception crosses a layer boundary" rule.
- `Category`'s constructor enforces the `nameKey`/`name` invariant client-side; the Security Rules
  in this same feature enforce it server-side. Neither depends on the other — a client bug can't
  bypass server validation, and server rejection is what actually protects the data.
- These signatures are the *initial* contract (spec Assumptions). `004` may find it needs to widen
  a method (e.g. pagination on `watchByMonth`) — that's an additive change to this contract, not a
  violation of it, as long as existing callers keep working.
