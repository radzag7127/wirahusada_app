import 'package:equatable/equatable.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/borrow_request.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/borrowing_limits.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/usecases/get_my_borrowing_limits_usecase.dart';

/// Base state for borrowings management
abstract class LibraryBorrowingsState extends Equatable {
  const LibraryBorrowingsState();

  @override
  List<Object?> get props => [];
}

/// Initial state for borrowings
class BorrowingsInitial extends LibraryBorrowingsState {
  const BorrowingsInitial();
}

/// Loading state for borrowings
class BorrowingsLoading extends LibraryBorrowingsState {
  final String? loadingMessage;
  
  const BorrowingsLoading({this.loadingMessage});
  
  @override
  List<Object?> get props => [loadingMessage];
}

/// State when borrowings data is loaded
class BorrowingsLoaded extends LibraryBorrowingsState {
  final List<BorrowRequest> activeBorrowings;
  final List<BorrowRequest> borrowingHistory;
  final BorrowingLimits limits;
  final BorrowingStatus status;
  final bool isRefreshing;

  const BorrowingsLoaded({
    required this.activeBorrowings,
    required this.borrowingHistory,
    required this.limits,
    required this.status,
    this.isRefreshing = false,
  });

  /// Create a copy with updated values
  BorrowingsLoaded copyWith({
    List<BorrowRequest>? activeBorrowings,
    List<BorrowRequest>? borrowingHistory,
    BorrowingLimits? limits,
    BorrowingStatus? status,
    bool? isRefreshing,
  }) {
    return BorrowingsLoaded(
      activeBorrowings: activeBorrowings ?? this.activeBorrowings,
      borrowingHistory: borrowingHistory ?? this.borrowingHistory,
      limits: limits ?? this.limits,
      status: status ?? this.status,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  /// Get overdue borrowings
  List<BorrowRequest> get overdueBorrowings {
    final now = DateTime.now();
    return activeBorrowings.where((borrowing) {
      final dueDate = DateTime.tryParse(borrowing.tanggalKembali);
      return dueDate != null && now.isAfter(dueDate);
    }).toList();
  }

  /// Get borrowings due soon (within 3 days)
  List<BorrowRequest> get dueSoonBorrowings {
    final now = DateTime.now();
    final threeDaysFromNow = now.add(const Duration(days: 3));
    
    return activeBorrowings.where((borrowing) {
      final dueDate = DateTime.tryParse(borrowing.tanggalKembali);
      return dueDate != null && 
             dueDate.isAfter(now) && 
             dueDate.isBefore(threeDaysFromNow);
    }).toList();
  }

  /// Get borrowing statistics
  BorrowingStatistics get statistics {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    
    final thisMonthBorrowings = borrowingHistory.where((b) {
      final borrowDate = DateTime.tryParse(b.tanggalPengambilan);
      return borrowDate != null && borrowDate.isAfter(thisMonthStart);
    }).length;
    
    return BorrowingStatistics(
      totalActiveBorrowings: activeBorrowings.length,
      totalOverdue: overdueBorrowings.length,
      totalDueSoon: dueSoonBorrowings.length,
      totalBorrowingsThisMonth: thisMonthBorrowings,
      totalLifetimeBorrowings: borrowingHistory.length,
      averageBorrowingDuration: _calculateAverageDuration(),
    );
  }

  double _calculateAverageDuration() {
    final completedBorrowings = borrowingHistory.where((b) => 
        b.status.toLowerCase() == 'dikembalikan').toList();
    
    if (completedBorrowings.isEmpty) return 0.0;
    
    double totalDays = 0;
    int validBorrowings = 0;
    
    for (final borrowing in completedBorrowings) {
      final borrowDate = DateTime.tryParse(borrowing.tanggalPengambilan);
      final returnDate = DateTime.tryParse(borrowing.tanggalKembali);
      
      if (borrowDate != null && returnDate != null) {
        totalDays += returnDate.difference(borrowDate).inDays;
        validBorrowings++;
      }
    }
    
    return validBorrowings > 0 ? totalDays / validBorrowings : 0.0;
  }

  @override
  List<Object?> get props => [
        activeBorrowings,
        borrowingHistory,
        limits,
        status,
        isRefreshing,
      ];
}

/// State when performing an action (return, renew, etc.)
class BorrowingsActionInProgress extends LibraryBorrowingsState {
  final BorrowingAction action;
  final String targetId;
  final String? message;

  const BorrowingsActionInProgress({
    required this.action,
    required this.targetId,
    this.message,
  });

  @override
  List<Object?> get props => [action, targetId, message];
}

/// State when an action completed successfully
class BorrowingsActionSuccess extends LibraryBorrowingsState {
  final BorrowingAction action;
  final String message;
  final String? targetId;

  const BorrowingsActionSuccess({
    required this.action,
    required this.message,
    this.targetId,
  });

  @override
  List<Object?> get props => [action, message, targetId];
}

/// Error state for borrowings
class BorrowingsError extends LibraryBorrowingsState {
  final String message;
  final String? errorCode;
  final BorrowingAction? failedAction;
  final String? targetId;

  const BorrowingsError({
    required this.message,
    this.errorCode,
    this.failedAction,
    this.targetId,
  });

  /// Check if error is recoverable
  bool get isRecoverable => 
      errorCode != 'NETWORK_ERROR' && 
      errorCode != 'AUTH_ERROR';

  /// Get user-friendly error message
  String get userFriendlyMessage {
    switch (errorCode) {
      case 'MAX_RENEWALS_EXCEEDED':
        return 'This book has reached the maximum number of renewals';
      case 'BOOK_OVERDUE':
        return 'Cannot renew overdue books. Please return first';
      case 'BOOK_RESERVED':
        return 'Cannot renew - this book is reserved by another user';
      case 'NETWORK_ERROR':
        return 'Network error. Please check your connection and try again';
      case 'INSUFFICIENT_PRIVILEGES':
        return 'You do not have permission to perform this action';
      default:
        return message;
    }
  }

  @override
  List<Object?> get props => [message, errorCode, failedAction, targetId];
}

/// Borrowing action types
enum BorrowingAction {
  return_book,
  renew_borrowing,
  bulk_return,
  bulk_renew,
  refresh_data,
}

extension BorrowingActionExtension on BorrowingAction {
  String get displayName {
    switch (this) {
      case BorrowingAction.return_book:
        return 'Returning Book';
      case BorrowingAction.renew_borrowing:
        return 'Renewing Borrowing';
      case BorrowingAction.bulk_return:
        return 'Returning Multiple Books';
      case BorrowingAction.bulk_renew:
        return 'Renewing Multiple Borrowings';
      case BorrowingAction.refresh_data:
        return 'Refreshing Data';
    }
  }

  String get successMessage {
    switch (this) {
      case BorrowingAction.return_book:
        return 'Book returned successfully';
      case BorrowingAction.renew_borrowing:
        return 'Borrowing renewed successfully';
      case BorrowingAction.bulk_return:
        return 'Books returned successfully';
      case BorrowingAction.bulk_renew:
        return 'Borrowings renewed successfully';
      case BorrowingAction.refresh_data:
        return 'Data refreshed successfully';
    }
  }
}

/// Borrowing statistics for dashboard
class BorrowingStatistics {
  final int totalActiveBorrowings;
  final int totalOverdue;
  final int totalDueSoon;
  final int totalBorrowingsThisMonth;
  final int totalLifetimeBorrowings;
  final double averageBorrowingDuration;

  const BorrowingStatistics({
    required this.totalActiveBorrowings,
    required this.totalOverdue,
    required this.totalDueSoon,
    required this.totalBorrowingsThisMonth,
    required this.totalLifetimeBorrowings,
    required this.averageBorrowingDuration,
  });

  /// Check if user has urgent items requiring attention
  bool get hasUrgentItems => totalOverdue > 0 || totalDueSoon > 0;

  /// Get the most urgent issue
  String? get urgentIssue {
    if (totalOverdue > 0) {
      return '$totalOverdue overdue book(s) need to be returned';
    } else if (totalDueSoon > 0) {
      return '$totalDueSoon book(s) due within 3 days';
    }
    return null;
  }

  /// Get borrowing activity level
  ActivityLevel get activityLevel {
    if (totalBorrowingsThisMonth >= 10) return ActivityLevel.high;
    if (totalBorrowingsThisMonth >= 5) return ActivityLevel.medium;
    if (totalBorrowingsThisMonth >= 1) return ActivityLevel.low;
    return ActivityLevel.inactive;
  }
}

enum ActivityLevel {
  inactive,
  low,
  medium,
  high,
}

extension ActivityLevelExtension on ActivityLevel {
  String get displayName {
    switch (this) {
      case ActivityLevel.inactive:
        return 'Inactive';
      case ActivityLevel.low:
        return 'Light Reader';
      case ActivityLevel.medium:
        return 'Regular Reader';
      case ActivityLevel.high:
        return 'Active Reader';
    }
  }

  String get description {
    switch (this) {
      case ActivityLevel.inactive:
        return 'No borrowings this month';
      case ActivityLevel.low:
        return '1-4 borrowings this month';
      case ActivityLevel.medium:
        return '5-9 borrowings this month';
      case ActivityLevel.high:
        return '10+ borrowings this month';
    }
  }
}