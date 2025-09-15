import 'package:dartz/dartz.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/collection.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/borrow_request.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/borrowing_limits.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/collection_availability.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/search_filter.dart';

/// Abstract repository interface for library operations
/// Defines the contract that data layer implementations must follow
abstract class LibraryRepository {
  /// Get all collections from the library
  Future<Either<Failure, List<Collection>>> getAllCollections();

  /// Get collections by category (buku, jurnal, skripsi)
  Future<Either<Failure, List<Collection>>> getCollectionsByCategory(
    String category,
  );

  /// Search collections by query string
  Future<Either<Failure, List<Collection>>> searchCollections(
    String query,
  );

  /// Get collection details by code
  Future<Either<Failure, Collection>> getCollectionByCode(
    String kode,
  );

  /// Get collections filtered by topic
  Future<Either<Failure, List<Collection>>> getCollectionsByTopic(
    String topic,
  );

  /// Get all unique topics from collections
  Future<Either<Failure, List<String>>> getAllTopics();

  /// Submit a borrow request for a collection
  Future<Either<Failure, bool>> submitBorrowRequest(
    BorrowRequest borrowRequest,
  );

  /// Get borrow requests for a specific student
  Future<Either<Failure, List<BorrowRequest>>> getBorrowRequestsByNrm(
    String nrm,
  );

  /// Get borrow request by ID
  Future<Either<Failure, BorrowRequest>> getBorrowRequestById(
    String requestId,
  );

  // === Enhanced Repository Methods ===

  /// Get user's active borrowings
  Future<Either<Failure, List<BorrowRequest>>> getMyActiveBorrowings();

  /// Get user's complete borrowing history
  Future<Either<Failure, List<BorrowRequest>>> getMyBorrowingHistory();

  /// Get user's borrowing limits and restrictions
  Future<Either<Failure, BorrowingLimits>> getMyBorrowingLimits();

  /// Return a borrowed book
  Future<Either<Failure, bool>> returnBook(
    String activityId, {
    String? notes,
  });

  /// Renew a borrowing
  Future<Either<Failure, bool>> renewBorrowing(String activityId);

  /// Get popular collections
  Future<Either<Failure, List<Collection>>> getPopularCollections({
    int limit = 10,
  });

  /// Get recently added collections
  Future<Either<Failure, List<Collection>>> getRecentCollections({
    int limit = 10,
  });

  /// Check collection availability
  Future<Either<Failure, CollectionAvailability>> checkCollectionAvailability(
    String collectionId,
  );

  /// Advanced search with filters
  Future<Either<Failure, List<Collection>>> searchCollectionsAdvanced(
    SearchFilter filter,
  );

  /// Get collections with pagination and filters
  Future<Either<Failure, List<Collection>>> getCollectionsWithFilters(
    SearchFilter filter,
  );
}