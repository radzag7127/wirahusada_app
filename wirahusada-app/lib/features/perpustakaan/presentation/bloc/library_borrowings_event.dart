import 'package:equatable/equatable.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/usecases/return_book_usecase.dart';

/// Base event for borrowings management
abstract class LibraryBorrowingsEvent extends Equatable {
  const LibraryBorrowingsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load user's borrowing data (active + history + limits)
class LoadBorrowingsDataEvent extends LibraryBorrowingsEvent {
  final bool forceRefresh;
  
  const LoadBorrowingsDataEvent({this.forceRefresh = false});
  
  @override
  List<Object?> get props => [forceRefresh];
}

/// Event to refresh only active borrowings
class RefreshActiveBorrowingsEvent extends LibraryBorrowingsEvent {
  const RefreshActiveBorrowingsEvent();
}

/// Event to refresh borrowing history
class RefreshBorrowingHistoryEvent extends LibraryBorrowingsEvent {
  const RefreshBorrowingHistoryEvent();
}

/// Event to refresh borrowing limits
class RefreshBorrowingLimitsEvent extends LibraryBorrowingsEvent {
  const RefreshBorrowingLimitsEvent();
}

/// Event to return a book
class ReturnBookEvent extends LibraryBorrowingsEvent {
  final String activityId;
  final String? notes;
  final BookCondition? condition;
  final String? damageNotes;
  
  const ReturnBookEvent({
    required this.activityId,
    this.notes,
    this.condition,
    this.damageNotes,
  });
  
  @override
  List<Object?> get props => [activityId, notes, condition, damageNotes];
}

/// Event to renew a borrowing
class RenewBorrowingEvent extends LibraryBorrowingsEvent {
  final String activityId;
  final String? reason;
  
  const RenewBorrowingEvent({
    required this.activityId,
    this.reason,
  });
  
  @override
  List<Object?> get props => [activityId, reason];
}

/// Event to perform bulk return
class BulkReturnBooksEvent extends LibraryBorrowingsEvent {
  final List<String> activityIds;
  final String? notes;
  
  const BulkReturnBooksEvent({
    required this.activityIds,
    this.notes,
  });
  
  @override
  List<Object?> get props => [activityIds, notes];
}

/// Event to perform bulk renewal
class BulkRenewBorrowingsEvent extends LibraryBorrowingsEvent {
  final List<String> activityIds;
  final String? reason;
  
  const BulkRenewBorrowingsEvent({
    required this.activityIds,
    this.reason,
  });
  
  @override
  List<Object?> get props => [activityIds, reason];
}

/// Event to filter borrowing history
class FilterBorrowingHistoryEvent extends LibraryBorrowingsEvent {
  final BorrowingHistoryFilter filter;
  
  const FilterBorrowingHistoryEvent({required this.filter});
  
  @override
  List<Object> get props => [filter];
}

/// Event to sort borrowing history
class SortBorrowingHistoryEvent extends LibraryBorrowingsEvent {
  final BorrowingHistorySortBy sortBy;
  final SortOrder sortOrder;
  
  const SortBorrowingHistoryEvent({
    required this.sortBy,
    required this.sortOrder,
  });
  
  @override
  List<Object> get props => [sortBy, sortOrder];
}

/// Event to clear all borrowing data (logout scenario)
class ClearBorrowingsDataEvent extends LibraryBorrowingsEvent {
  const ClearBorrowingsDataEvent();
}

/// Event to mark notifications as read
class MarkBorrowingNotificationsReadEvent extends LibraryBorrowingsEvent {
  final List<String>? notificationIds;
  
  const MarkBorrowingNotificationsReadEvent({this.notificationIds});
  
  @override
  List<Object?> get props => [notificationIds];
}

/// Event to check renewal eligibility
class CheckRenewalEligibilityEvent extends LibraryBorrowingsEvent {
  final String activityId;
  
  const CheckRenewalEligibilityEvent({required this.activityId});
  
  @override
  List<Object> get props => [activityId];
}

/// Event to calculate fine for overdue books
class CalculateFinesEvent extends LibraryBorrowingsEvent {
  final List<String>? activityIds; // null for all overdue
  
  const CalculateFinesEvent({this.activityIds});
  
  @override
  List<Object?> get props => [activityIds];
}

/// Event to pay fines
class PayFinesEvent extends LibraryBorrowingsEvent {
  final List<String> activityIds;
  final String paymentMethod;
  final double amount;
  
  const PayFinesEvent({
    required this.activityIds,
    required this.paymentMethod,
    required this.amount,
  });
  
  @override
  List<Object> get props => [activityIds, paymentMethod, amount];
}

/// Event to export borrowing history
class ExportBorrowingHistoryEvent extends LibraryBorrowingsEvent {
  final ExportFormat format;
  final DateRange? dateRange;
  
  const ExportBorrowingHistoryEvent({
    required this.format,
    this.dateRange,
  });
  
  @override
  List<Object?> get props => [format, dateRange];
}

/// Event to get borrowing statistics
class GetBorrowingStatisticsEvent extends LibraryBorrowingsEvent {
  final StatisticsPeriod period;
  
  const GetBorrowingStatisticsEvent({this.period = StatisticsPeriod.thisMonth});
  
  @override
  List<Object> get props => [period];
}

// Supporting enums and classes

/// Borrowing history filter options
enum BorrowingHistoryFilter {
  all,
  active,
  returned,
  overdue,
  renewed,
  thisWeek,
  thisMonth,
  thisYear,
}

extension BorrowingHistoryFilterExtension on BorrowingHistoryFilter {
  String get displayName {
    switch (this) {
      case BorrowingHistoryFilter.all:
        return 'All';
      case BorrowingHistoryFilter.active:
        return 'Currently Borrowed';
      case BorrowingHistoryFilter.returned:
        return 'Returned';
      case BorrowingHistoryFilter.overdue:
        return 'Overdue';
      case BorrowingHistoryFilter.renewed:
        return 'Renewed';
      case BorrowingHistoryFilter.thisWeek:
        return 'This Week';
      case BorrowingHistoryFilter.thisMonth:
        return 'This Month';
      case BorrowingHistoryFilter.thisYear:
        return 'This Year';
    }
  }
}

/// Borrowing history sort options
enum BorrowingHistorySortBy {
  borrowDate,
  dueDate,
  returnDate,
  title,
  author,
  status,
}

extension BorrowingHistorySortByExtension on BorrowingHistorySortBy {
  String get displayName {
    switch (this) {
      case BorrowingHistorySortBy.borrowDate:
        return 'Borrow Date';
      case BorrowingHistorySortBy.dueDate:
        return 'Due Date';
      case BorrowingHistorySortBy.returnDate:
        return 'Return Date';
      case BorrowingHistorySortBy.title:
        return 'Title';
      case BorrowingHistorySortBy.author:
        return 'Author';
      case BorrowingHistorySortBy.status:
        return 'Status';
    }
  }
}

/// Sort order
enum SortOrder {
  ascending,
  descending,
}

extension SortOrderExtension on SortOrder {
  String get displayName {
    switch (this) {
      case SortOrder.ascending:
        return 'Ascending';
      case SortOrder.descending:
        return 'Descending';
    }
  }

  String get symbol {
    switch (this) {
      case SortOrder.ascending:
        return '↑';
      case SortOrder.descending:
        return '↓';
    }
  }
}

/// Export format options
enum ExportFormat {
  pdf,
  csv,
  excel,
}

extension ExportFormatExtension on ExportFormat {
  String get displayName {
    switch (this) {
      case ExportFormat.pdf:
        return 'PDF';
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.excel:
        return 'Excel';
    }
  }

  String get fileExtension {
    switch (this) {
      case ExportFormat.pdf:
        return '.pdf';
      case ExportFormat.csv:
        return '.csv';
      case ExportFormat.excel:
        return '.xlsx';
    }
  }
}

/// Date range for filtering
class DateRange extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  
  const DateRange({
    required this.startDate,
    required this.endDate,
  });
  
  /// Check if date range is valid
  bool get isValid => startDate.isBefore(endDate) || startDate.isAtSameMomentAs(endDate);
  
  /// Get duration of the range
  Duration get duration => endDate.difference(startDate);
  
  /// Get human-readable description
  String get description {
    final formatter = DateTime.now().year == startDate.year && 
                     DateTime.now().year == endDate.year
        ? 'MMM d'  // Same year
        : 'MMM d, yyyy'; // Different year
        
    // Note: In a real app, use intl package for proper formatting
    return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
  }
  
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[date.month - 1]} ${date.day}';
  }
  
  @override
  List<Object> get props => [startDate, endDate];
}

/// Statistics period options
enum StatisticsPeriod {
  thisWeek,
  thisMonth,
  thisQuarter,
  thisYear,
  allTime,
}

extension StatisticsPeriodExtension on StatisticsPeriod {
  String get displayName {
    switch (this) {
      case StatisticsPeriod.thisWeek:
        return 'This Week';
      case StatisticsPeriod.thisMonth:
        return 'This Month';
      case StatisticsPeriod.thisQuarter:
        return 'This Quarter';
      case StatisticsPeriod.thisYear:
        return 'This Year';
      case StatisticsPeriod.allTime:
        return 'All Time';
    }
  }

  DateRange get dateRange {
    final now = DateTime.now();
    
    switch (this) {
      case StatisticsPeriod.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        return DateRange(
          startDate: DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
          endDate: now,
        );
      case StatisticsPeriod.thisMonth:
        return DateRange(
          startDate: DateTime(now.year, now.month, 1),
          endDate: now,
        );
      case StatisticsPeriod.thisQuarter:
        final quarterStart = DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
        return DateRange(
          startDate: quarterStart,
          endDate: now,
        );
      case StatisticsPeriod.thisYear:
        return DateRange(
          startDate: DateTime(now.year, 1, 1),
          endDate: now,
        );
      case StatisticsPeriod.allTime:
        return DateRange(
          startDate: DateTime(2000, 1, 1), // Arbitrary start date
          endDate: now,
        );
    }
  }
}