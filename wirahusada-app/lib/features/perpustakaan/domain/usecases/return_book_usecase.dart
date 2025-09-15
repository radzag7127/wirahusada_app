import 'package:dartz/dartz.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/repositories/library_repository.dart';

/// Use case for returning a borrowed book
/// Handles the return process with optional notes
class ReturnBookUseCase implements UseCase<bool, ReturnBookParams> {
  final LibraryRepository repository;

  const ReturnBookUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(ReturnBookParams params) async {
    return await repository.returnBook(
      params.activityId,
      notes: params.notes,
    );
  }
}

/// Parameters for returning a book
class ReturnBookParams {
  /// ID of the borrowing activity
  final String activityId;
  
  /// Optional return notes
  final String? notes;
  
  /// Condition of the book upon return
  final BookCondition? condition;
  
  /// Any damage notes
  final String? damageNotes;

  const ReturnBookParams({
    required this.activityId,
    this.notes,
    this.condition,
    this.damageNotes,
  });

  /// Get formatted notes including condition and damage info
  String? get formattedNotes {
    final notesParts = <String>[];
    
    if (notes?.isNotEmpty == true) {
      notesParts.add(notes!);
    }
    
    if (condition != null) {
      notesParts.add('Condition: ${condition!.displayName}');
    }
    
    if (damageNotes?.isNotEmpty == true) {
      notesParts.add('Damage: $damageNotes');
    }
    
    return notesParts.isNotEmpty ? notesParts.join('; ') : null;
  }
}

/// Book condition upon return
enum BookCondition {
  excellent,
  good,
  fair,
  poor,
  damaged,
}

extension BookConditionExtension on BookCondition {
  String get displayName {
    switch (this) {
      case BookCondition.excellent:
        return 'Excellent';
      case BookCondition.good:
        return 'Good';
      case BookCondition.fair:
        return 'Fair';
      case BookCondition.poor:
        return 'Poor';
      case BookCondition.damaged:
        return 'Damaged';
    }
  }

  String get description {
    switch (this) {
      case BookCondition.excellent:
        return 'Like new, no visible wear';
      case BookCondition.good:
        return 'Minor wear, all pages intact';
      case BookCondition.fair:
        return 'Moderate wear, readable';
      case BookCondition.poor:
        return 'Heavy wear, some damage';
      case BookCondition.damaged:
        return 'Significant damage, needs repair';
    }
  }

  bool get requiresDamageReport => 
      this == BookCondition.poor || this == BookCondition.damaged;
}

/// Use case for bulk returning multiple books
class BulkReturnBooksUseCase implements UseCase<BulkReturnResult, BulkReturnParams> {
  final ReturnBookUseCase returnBookUseCase;

  const BulkReturnBooksUseCase(this.returnBookUseCase);

  @override
  Future<Either<Failure, BulkReturnResult>> call(BulkReturnParams params) async {
    final results = <String, Either<Failure, bool>>{};
    
    for (final returnParam in params.returns) {
      final result = await returnBookUseCase.call(returnParam);
      results[returnParam.activityId] = result;
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
    
    final bulkResult = BulkReturnResult(
      totalAttempted: params.returns.length,
      successful: successful,
      failed: failed,
    );
    
    return Right(bulkResult);
  }
}

/// Parameters for bulk return operation
class BulkReturnParams {
  final List<ReturnBookParams> returns;

  const BulkReturnParams({required this.returns});
}

/// Result of bulk return operation
class BulkReturnResult {
  final int totalAttempted;
  final List<String> successful;
  final Map<String, Failure> failed;

  const BulkReturnResult({
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
      return 'All $successfulCount book(s) returned successfully';
    } else if (allFailed) {
      return 'Failed to return all $failedCount book(s)';
    } else {
      return '$successfulCount successful, $failedCount failed out of $totalAttempted';
    }
  }
}