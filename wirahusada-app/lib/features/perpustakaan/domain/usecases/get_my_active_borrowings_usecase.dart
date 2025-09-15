import 'package:dartz/dartz.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/borrow_request.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/repositories/library_repository.dart';

/// Use case for getting current user's active borrowings
/// Returns all currently borrowed books that haven't been returned
class GetMyActiveBorrowingsUseCase implements UseCase<List<BorrowRequest>, NoParams> {
  final LibraryRepository repository;

  const GetMyActiveBorrowingsUseCase(this.repository);

  @override
  Future<Either<Failure, List<BorrowRequest>>> call(NoParams params) async {
    return await repository.getMyActiveBorrowings();
  }
}

/// Parameters for getting active borrowings with additional options
class ActiveBorrowingsParams {
  /// Include overdue items only
  final bool overdueOnly;
  
  /// Sort by field (due_date, borrow_date, title)
  final String? sortBy;
  
  /// Sort order (asc/desc)
  final String? sortOrder;

  const ActiveBorrowingsParams({
    this.overdueOnly = false,
    this.sortBy,
    this.sortOrder,
  });
}

/// Enhanced use case with filtering options
class GetMyActiveBorrowingsWithFilterUseCase 
    implements UseCase<List<BorrowRequest>, ActiveBorrowingsParams> {
  final LibraryRepository repository;

  const GetMyActiveBorrowingsWithFilterUseCase(this.repository);

  @override
  Future<Either<Failure, List<BorrowRequest>>> call(ActiveBorrowingsParams params) async {
    final result = await repository.getMyActiveBorrowings();
    
    return result.fold(
      (failure) => Left(failure),
      (borrowings) {
        var filteredBorrowings = borrowings;
        
        // Filter overdue only if requested
        if (params.overdueOnly) {
          final now = DateTime.now();
          filteredBorrowings = borrowings.where((borrowing) {
            final dueDate = DateTime.tryParse(borrowing.tanggalKembali);
            return dueDate != null && now.isAfter(dueDate);
          }).toList();
        }
        
        // Apply sorting
        if (params.sortBy != null) {
          filteredBorrowings.sort((a, b) {
            int comparison = 0;
            
            switch (params.sortBy) {
              case 'due_date':
                final aDate = DateTime.tryParse(a.tanggalKembali);
                final bDate = DateTime.tryParse(b.tanggalKembali);
                if (aDate != null && bDate != null) {
                  comparison = aDate.compareTo(bDate);
                }
                break;
              case 'borrow_date':
                final aDate = DateTime.tryParse(a.tanggalPengambilan);
                final bDate = DateTime.tryParse(b.tanggalPengambilan);
                if (aDate != null && bDate != null) {
                  comparison = aDate.compareTo(bDate);
                }
                break;
              case 'title':
                // Would need collection title from joined data
                break;
              default:
                break;
            }
            
            // Reverse if descending order
            if (params.sortOrder == 'desc') {
              comparison = -comparison;
            }
            
            return comparison;
          });
        }
        
        return Right(filteredBorrowings);
      },
    );
  }
}