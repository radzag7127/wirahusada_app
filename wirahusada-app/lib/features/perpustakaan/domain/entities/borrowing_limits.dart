import 'package:equatable/equatable.dart';

/// Domain entity representing borrowing limits and restrictions for a student
class BorrowingLimits extends Equatable {
  /// Maximum number of books allowed to borrow
  final int maxBooks;
  
  /// Maximum borrowing duration in days
  final int maxDurationDays;
  
  /// Maximum number of renewals allowed
  final int maxRenewals;
  
  /// Current number of borrowed books
  final int currentBorrows;
  
  /// Number of overdue books
  final int overdueCount;
  
  /// Whether the student can borrow more books
  final bool canBorrow;
  
  /// List of restrictions preventing borrowing
  final List<String> restrictions;

  const BorrowingLimits({
    required this.maxBooks,
    required this.maxDurationDays,
    required this.maxRenewals,
    required this.currentBorrows,
    required this.overdueCount,
    required this.canBorrow,
    required this.restrictions,
  });

  /// Check if the student has reached the borrowing limit
  bool get isAtLimit => currentBorrows >= maxBooks;

  /// Check if the student has any overdue books
  bool get hasOverdueBooks => overdueCount > 0;

  /// Check if the student has any restrictions
  bool get hasRestrictions => restrictions.isNotEmpty;

  /// Get remaining books that can be borrowed
  int get remainingBooks => maxBooks - currentBorrows;

  /// Get the primary restriction message
  String? get primaryRestriction => restrictions.isNotEmpty ? restrictions.first : null;

  @override
  List<Object> get props => [
        maxBooks,
        maxDurationDays,
        maxRenewals,
        currentBorrows,
        overdueCount,
        canBorrow,
        restrictions,
      ];

  @override
  String toString() => 'BorrowingLimits('
      'maxBooks: $maxBooks, '
      'currentBorrows: $currentBorrows, '
      'canBorrow: $canBorrow, '
      'restrictions: ${restrictions.length}'
      ')';
}