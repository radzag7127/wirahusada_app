import 'package:dartz/dartz.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/repositories/library_repository.dart';

/// Use case for renewing a book borrowing
/// Extends the due date if renewal conditions are met
class RenewBorrowingUseCase implements UseCase<bool, RenewBorrowingParams> {
  final LibraryRepository repository;

  const RenewBorrowingUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(RenewBorrowingParams params) async {
    return await repository.renewBorrowing(params.activityId);
  }
}

/// Parameters for renewing a borrowing
class RenewBorrowingParams {
  /// ID of the borrowing activity to renew
  final String activityId;
  
  /// Optional reason for renewal
  final String? reason;
  
  /// Requested extension period in days (if system allows choice)
  final int? extensionDays;

  const RenewBorrowingParams({
    required this.activityId,
    this.reason,
    this.extensionDays,
  });
}

/// Use case for checking if a borrowing can be renewed
class CanRenewBorrowingUseCase implements UseCase<RenewalEligibility, CanRenewParams> {
  final LibraryRepository repository;

  const CanRenewBorrowingUseCase(this.repository);

  @override
  Future<Either<Failure, RenewalEligibility>> call(CanRenewParams params) async {
    // This would ideally call a specific API endpoint to check eligibility
    // For now, we'll simulate the check based on common renewal rules
    
    try {
      // In a real implementation, this would call:
      // return await repository.checkRenewalEligibility(params.activityId);
      
      // Simulate eligibility check
      final eligibility = RenewalEligibility(
        canRenew: true, // Would be determined by backend
        reason: 'Eligible for renewal',
        renewalsUsed: params.currentRenewals ?? 0,
        maxRenewals: 2,
        daysUntilDue: params.daysUntilDue ?? 0,
        hasReservations: false,
        isOverdue: false,
      );
      
      return Right(eligibility);
    } catch (e) {
      return Left(ServerFailure('Failed to check renewal eligibility: ${e.toString()}'));
    }
  }
}

/// Parameters for checking renewal eligibility
class CanRenewParams {
  /// ID of the borrowing activity
  final String activityId;
  
  /// Current number of renewals used (if known)
  final int? currentRenewals;
  
  /// Days until due date (if known)
  final int? daysUntilDue;
  
  /// Whether the item is currently overdue
  final bool? isOverdue;

  const CanRenewParams({
    required this.activityId,
    this.currentRenewals,
    this.daysUntilDue,
    this.isOverdue,
  });
}

/// Renewal eligibility information
class RenewalEligibility {
  /// Whether renewal is allowed
  final bool canRenew;
  
  /// Reason for eligibility or ineligibility
  final String reason;
  
  /// Number of renewals already used
  final int renewalsUsed;
  
  /// Maximum renewals allowed
  final int maxRenewals;
  
  /// Days until due date
  final int daysUntilDue;
  
  /// Whether other users have reserved this item
  final bool hasReservations;
  
  /// Whether the item is currently overdue
  final bool isOverdue;

  const RenewalEligibility({
    required this.canRenew,
    required this.reason,
    required this.renewalsUsed,
    required this.maxRenewals,
    required this.daysUntilDue,
    required this.hasReservations,
    required this.isOverdue,
  });

  /// Get remaining renewals
  int get remainingRenewals => maxRenewals - renewalsUsed;
  
  /// Check if at maximum renewals
  bool get isAtMaxRenewals => renewalsUsed >= maxRenewals;
  
  /// Get renewal status level
  RenewalStatus get status {
    if (!canRenew) return RenewalStatus.blocked;
    if (isOverdue) return RenewalStatus.overdue;
    if (remainingRenewals <= 0) return RenewalStatus.maxReached;
    if (hasReservations) return RenewalStatus.reserved;
    if (daysUntilDue <= 1) return RenewalStatus.urgent;
    return RenewalStatus.eligible;
  }
  
  /// Get user-friendly status message
  String get statusMessage {
    switch (status) {
      case RenewalStatus.eligible:
        return 'Can be renewed ($remainingRenewals renewal(s) remaining)';
      case RenewalStatus.urgent:
        return 'Can be renewed (due in $daysUntilDue day(s))';
      case RenewalStatus.overdue:
        return 'Cannot renew - item is overdue';
      case RenewalStatus.maxReached:
        return 'Cannot renew - maximum renewals reached';
      case RenewalStatus.reserved:
        return 'Cannot renew - reserved by other users';
      case RenewalStatus.blocked:
        return reason;
    }
  }
}

enum RenewalStatus {
  eligible,    // Can be renewed normally
  urgent,      // Can be renewed but due soon
  overdue,     // Cannot renew - overdue
  maxReached,  // Cannot renew - max renewals used
  reserved,    // Cannot renew - reserved by others
  blocked,     // Cannot renew - other restrictions
}

/// Use case for bulk renewing multiple borrowings
class BulkRenewBorrowingsUseCase implements UseCase<BulkRenewalResult, BulkRenewalParams> {
  final RenewBorrowingUseCase renewBorrowingUseCase;

  const BulkRenewBorrowingsUseCase(this.renewBorrowingUseCase);

  @override
  Future<Either<Failure, BulkRenewalResult>> call(BulkRenewalParams params) async {
    final results = <String, Either<Failure, bool>>{};
    
    for (final renewalParam in params.renewals) {
      final result = await renewBorrowingUseCase.call(renewalParam);
      results[renewalParam.activityId] = result;
    }
    
    final successful = <String>[];
    final failed = <String, Failure>{};
    
    results.forEach((activityId, result) {
      result.fold(
        (failure) => failed[activityId] = failure,
        (success) {
          if (success) successful.add(activityId);
        },
      );
    });
    
    final bulkResult = BulkRenewalResult(
      totalAttempted: params.renewals.length,
      successful: successful,
      failed: failed,
    );
    
    return Right(bulkResult);
  }
}

/// Parameters for bulk renewal operation
class BulkRenewalParams {
  final List<RenewBorrowingParams> renewals;

  const BulkRenewalParams({required this.renewals});
}

/// Result of bulk renewal operation
class BulkRenewalResult {
  final int totalAttempted;
  final List<String> successful;
  final Map<String, Failure> failed;

  const BulkRenewalResult({
    required this.totalAttempted,
    required this.successful,
    required this.failed,
  });

  int get successfulCount => successful.length;
  int get failedCount => failed.length;
  bool get allSuccessful => failedCount == 0;
  bool get allFailed => successfulCount == 0;
  bool get partiallySuccessful => successfulCount > 0 && failedCount > 0;

  double get successRate => 
      totalAttempted > 0 ? (successfulCount / totalAttempted) * 100 : 0.0;

  String get summary {
    if (allSuccessful) {
      return 'All $successfulCount borrowing(s) renewed successfully';
    } else if (allFailed) {
      return 'Failed to renew all $failedCount borrowing(s)';
    } else {
      return '$successfulCount renewed, $failedCount failed out of $totalAttempted';
    }
  }
}