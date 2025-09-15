import 'package:dartz/dartz.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/borrowing_limits.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/repositories/library_repository.dart';

/// Use case for getting current user's borrowing limits and restrictions
/// Returns comprehensive information about borrowing capacity and limitations
class GetMyBorrowingLimitsUseCase implements UseCase<BorrowingLimits, NoParams> {
  final LibraryRepository repository;

  const GetMyBorrowingLimitsUseCase(this.repository);

  @override
  Future<Either<Failure, BorrowingLimits>> call(NoParams params) async {
    return await repository.getMyBorrowingLimits();
  }
}

/// Use case for checking if user can borrow a specific number of books
class CanBorrowBooksUseCase implements UseCase<bool, CanBorrowParams> {
  final LibraryRepository repository;

  const CanBorrowBooksUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(CanBorrowParams params) async {
    final result = await repository.getMyBorrowingLimits();
    
    return result.fold(
      (failure) => Left(failure),
      (limits) {
        final canBorrowCount = limits.remainingBooks >= params.requestedCount;
        final hasNoRestrictions = limits.canBorrow && !limits.hasRestrictions;
        
        return Right(canBorrowCount && hasNoRestrictions);
      },
    );
  }
}

/// Parameters for checking borrowing capacity
class CanBorrowParams {
  /// Number of books requested to borrow
  final int requestedCount;
  
  /// Check specific restrictions
  final bool checkOverdue;
  final bool checkFines;
  final bool checkSuspension;

  const CanBorrowParams({
    required this.requestedCount,
    this.checkOverdue = true,
    this.checkFines = true,
    this.checkSuspension = true,
  });
}

/// Use case for getting detailed borrowing status
class GetBorrowingStatusUseCase implements UseCase<BorrowingStatus, NoParams> {
  final LibraryRepository repository;

  const GetBorrowingStatusUseCase(this.repository);

  @override
  Future<Either<Failure, BorrowingStatus>> call(NoParams params) async {
    final result = await repository.getMyBorrowingLimits();
    
    return result.fold(
      (failure) => Left(failure),
      (limits) {
        final status = BorrowingStatus.fromLimits(limits);
        return Right(status);
      },
    );
  }
}

/// Comprehensive borrowing status information
class BorrowingStatus {
  final BorrowingLimits limits;
  final BorrowingStatusLevel statusLevel;
  final String statusMessage;
  final List<String> recommendations;
  final bool needsAction;

  const BorrowingStatus({
    required this.limits,
    required this.statusLevel,
    required this.statusMessage,
    required this.recommendations,
    required this.needsAction,
  });

  factory BorrowingStatus.fromLimits(BorrowingLimits limits) {
    BorrowingStatusLevel level;
    String message;
    List<String> recommendations = [];
    bool needsAction = false;

    if (!limits.canBorrow) {
      level = BorrowingStatusLevel.blocked;
      message = 'Borrowing is currently blocked';
      needsAction = true;
      
      if (limits.hasOverdueBooks) {
        recommendations.add('Return ${limits.overdueCount} overdue book(s)');
      }
      
      if (limits.isAtLimit) {
        recommendations.add('Return some books to borrow more');
      }
      
      recommendations.addAll(limits.restrictions);
    } else if (limits.hasOverdueBooks) {
      level = BorrowingStatusLevel.warning;
      message = 'You have ${limits.overdueCount} overdue book(s)';
      needsAction = true;
      recommendations.add('Return overdue books to avoid fines');
    } else if (limits.remainingBooks <= 1) {
      level = BorrowingStatusLevel.caution;
      message = 'You can borrow ${limits.remainingBooks} more book(s)';
      recommendations.add('Consider returning books before borrowing more');
    } else {
      level = BorrowingStatusLevel.good;
      message = 'You can borrow ${limits.remainingBooks} more book(s)';
    }

    return BorrowingStatus(
      limits: limits,
      statusLevel: level,
      statusMessage: message,
      recommendations: recommendations,
      needsAction: needsAction,
    );
  }

  /// Check if user is in good standing
  bool get isGoodStanding => statusLevel == BorrowingStatusLevel.good;

  /// Check if immediate action is required
  bool get requiresImmediateAction => 
      statusLevel == BorrowingStatusLevel.blocked;

  /// Get priority level for UI display
  int get priorityLevel => statusLevel.index;
}

enum BorrowingStatusLevel {
  good,      // No issues, can borrow freely
  caution,   // Close to limits but okay
  warning,   // Has issues but can still borrow
  blocked,   // Cannot borrow due to restrictions
}

extension BorrowingStatusLevelExtension on BorrowingStatusLevel {
  String get displayName {
    switch (this) {
      case BorrowingStatusLevel.good:
        return 'Good Standing';
      case BorrowingStatusLevel.caution:
        return 'Approaching Limit';
      case BorrowingStatusLevel.warning:
        return 'Warning';
      case BorrowingStatusLevel.blocked:
        return 'Blocked';
    }
  }

  String get colorCode {
    switch (this) {
      case BorrowingStatusLevel.good:
        return '#4CAF50'; // Green
      case BorrowingStatusLevel.caution:
        return '#FF9800'; // Orange
      case BorrowingStatusLevel.warning:
        return '#F44336'; // Red
      case BorrowingStatusLevel.blocked:
        return '#9E9E9E'; // Grey
    }
  }
}