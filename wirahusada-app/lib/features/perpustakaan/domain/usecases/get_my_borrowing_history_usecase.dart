import 'package:dartz/dartz.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/borrow_request.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/repositories/library_repository.dart';

/// Use case for getting current user's complete borrowing history
/// Returns all borrowing activities including current, returned, and overdue
class GetMyBorrowingHistoryUseCase implements UseCase<List<BorrowRequest>, NoParams> {
  final LibraryRepository repository;

  const GetMyBorrowingHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<BorrowRequest>>> call(NoParams params) async {
    return await repository.getMyBorrowingHistory();
  }
}

/// Parameters for filtering borrowing history
class BorrowingHistoryParams {
  /// Filter by status (dipinjam, dikembalikan, terlambat, etc.)
  final String? status;
  
  /// Filter by date range - from date
  final DateTime? dateFrom;
  
  /// Filter by date range - to date  
  final DateTime? dateTo;
  
  /// Include only returned items
  final bool? returnedOnly;
  
  /// Include only overdue items
  final bool? overdueOnly;
  
  /// Sort by field
  final String? sortBy;
  
  /// Sort order
  final String? sortOrder;
  
  /// Pagination
  final int page;
  final int limit;

  const BorrowingHistoryParams({
    this.status,
    this.dateFrom,
    this.dateTo,
    this.returnedOnly,
    this.overdueOnly,
    this.sortBy,
    this.sortOrder,
    this.page = 1,
    this.limit = 20,
  });

  /// Check if any filters are applied
  bool get hasFilters =>
      status != null ||
      dateFrom != null ||
      dateTo != null ||
      returnedOnly == true ||
      overdueOnly == true;
}

/// Enhanced use case with advanced filtering and pagination
class GetMyBorrowingHistoryWithFilterUseCase 
    implements UseCase<List<BorrowRequest>, BorrowingHistoryParams> {
  final LibraryRepository repository;

  const GetMyBorrowingHistoryWithFilterUseCase(this.repository);

  @override
  Future<Either<Failure, List<BorrowRequest>>> call(BorrowingHistoryParams params) async {
    final result = await repository.getMyBorrowingHistory();
    
    return result.fold(
      (failure) => Left(failure),
      (history) {
        var filteredHistory = history;
        
        // Apply filters
        if (params.hasFilters) {
          filteredHistory = _applyFilters(history, params);
        }
        
        // Apply sorting
        if (params.sortBy != null) {
          filteredHistory = _applySorting(filteredHistory, params);
        }
        
        // Apply pagination
        final paginatedHistory = _applyPagination(filteredHistory, params);
        
        return Right(paginatedHistory);
      },
    );
  }

  List<BorrowRequest> _applyFilters(List<BorrowRequest> history, BorrowingHistoryParams params) {
    return history.where((borrowing) {
      // Filter by status
      if (params.status != null && borrowing.status != params.status) {
        return false;
      }
      
      // Filter by date range
      if (params.dateFrom != null || params.dateTo != null) {
        final borrowDate = DateTime.tryParse(borrowing.tanggalPengambilan);
        if (borrowDate != null) {
          if (params.dateFrom != null && borrowDate.isBefore(params.dateFrom!)) {
            return false;
          }
          if (params.dateTo != null && borrowDate.isAfter(params.dateTo!)) {
            return false;
          }
        }
      }
      
      // Filter returned only
      if (params.returnedOnly == true) {
        return borrowing.status.toLowerCase() == 'dikembalikan';
      }
      
      // Filter overdue only
      if (params.overdueOnly == true) {
        final dueDate = DateTime.tryParse(borrowing.tanggalKembali);
        if (dueDate != null) {
          final now = DateTime.now();
          final isOverdue = now.isAfter(dueDate) && 
                           borrowing.status.toLowerCase() != 'dikembalikan';
          return isOverdue;
        }
        return false;
      }
      
      return true;
    }).toList();
  }

  List<BorrowRequest> _applySorting(List<BorrowRequest> history, BorrowingHistoryParams params) {
    history.sort((a, b) {
      int comparison = 0;
      
      switch (params.sortBy) {
        case 'borrow_date':
          final aDate = DateTime.tryParse(a.tanggalPengambilan);
          final bDate = DateTime.tryParse(b.tanggalPengambilan);
          if (aDate != null && bDate != null) {
            comparison = aDate.compareTo(bDate);
          }
          break;
        case 'due_date':
          final aDate = DateTime.tryParse(a.tanggalKembali);
          final bDate = DateTime.tryParse(b.tanggalKembali);
          if (aDate != null && bDate != null) {
            comparison = aDate.compareTo(bDate);
          }
          break;
        case 'status':
          comparison = a.status.compareTo(b.status);
          break;
        default:
          // Default sort by borrow date descending (newest first)
          final aDate = DateTime.tryParse(a.tanggalPengambilan);
          final bDate = DateTime.tryParse(b.tanggalPengambilan);
          if (aDate != null && bDate != null) {
            comparison = bDate.compareTo(aDate);
          }
          break;
      }
      
      // Reverse if descending order
      if (params.sortOrder == 'desc') {
        comparison = -comparison;
      }
      
      return comparison;
    });
    
    return history;
  }

  List<BorrowRequest> _applyPagination(List<BorrowRequest> history, BorrowingHistoryParams params) {
    final startIndex = (params.page - 1) * params.limit;
    final endIndex = startIndex + params.limit;
    
    if (startIndex >= history.length) {
      return [];
    }
    
    return history.sublist(
      startIndex, 
      endIndex > history.length ? history.length : endIndex
    );
  }
}