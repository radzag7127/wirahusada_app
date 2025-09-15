import 'package:dartz/dartz.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/collection.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/borrow_request.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/borrowing_limits.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/collection_availability.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/search_filter.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/repositories/library_repository.dart';
import 'package:wismon_keuangan/features/perpustakaan/data/datasources/library_remote_data_source.dart';
import 'package:wismon_keuangan/features/perpustakaan/data/datasources/library_remote_data_source_impl.dart';
import 'package:wismon_keuangan/features/perpustakaan/data/models/borrow_request_model.dart';

/// Concrete implementation of LibraryRepository
/// Handles data operations and error handling for library features
class LibraryRepositoryImpl implements LibraryRepository {
  final LibraryRemoteDataSource remoteDataSource;
  
  // Cast to implementation to access enhanced methods
  LibraryRemoteDataSourceImpl get _enhancedDataSource => 
      remoteDataSource as LibraryRemoteDataSourceImpl;

  const LibraryRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<Collection>>> getAllCollections() async {
    try {
      final collectionModels = await remoteDataSource.getAllCollections();
      final collections = collectionModels
          .map((model) => model.toEntity())
          .toList();
      return Right(collections);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on NetworkFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch collections: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Collection>>> getCollectionsByCategory(
    String category,
  ) async {
    try {
      final collectionModels = await remoteDataSource.getCollectionsByCategory(category);
      final collections = collectionModels
          .map((model) => model.toEntity())
          .toList();
      return Right(collections);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on NetworkFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch $category collections: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Collection>>> searchCollections(
    String query,
  ) async {
    try {
      final collectionModels = await remoteDataSource.searchCollections(query);
      final collections = collectionModels
          .map((model) => model.toEntity())
          .toList();
      return Right(collections);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on NetworkFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Failed to search collections: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Collection>> getCollectionByCode(String kode) async {
    try {
      final collectionModel = await remoteDataSource.getCollectionByCode(kode);
      return Right(collectionModel.toEntity());
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on NetworkFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch collection: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Collection>>> getCollectionsByTopic(
    String topic,
  ) async {
    try {
      final collectionModels = await remoteDataSource.getCollectionsByTopic(topic);
      final collections = collectionModels
          .map((model) => model.toEntity())
          .toList();
      return Right(collections);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on NetworkFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch collections by topic: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getAllTopics() async {
    try {
      final topics = await remoteDataSource.getAllTopics();
      return Right(topics);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on NetworkFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch topics: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> submitBorrowRequest(
    BorrowRequest borrowRequest,
  ) async {
    try {
      final borrowRequestModel = BorrowRequestModel.fromEntity(borrowRequest);
      final success = await remoteDataSource.submitBorrowRequest(borrowRequestModel);
      return Right(success);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on NetworkFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Failed to submit borrow request: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BorrowRequest>>> getBorrowRequestsByNrm(
    String nrm,
  ) async {
    try {
      final borrowRequestModels = await remoteDataSource.getBorrowRequestsByNrm(nrm);
      final borrowRequests = borrowRequestModels
          .map((model) => model.toEntity())
          .toList();
      return Right(borrowRequests);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on NetworkFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch borrow requests: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BorrowRequest>> getBorrowRequestById(
    String requestId,
  ) async {
    try {
      final borrowRequestModel = await remoteDataSource.getBorrowRequestById(requestId);
      return Right(borrowRequestModel.toEntity());
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on NetworkFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch borrow request: ${e.toString()}'));
    }
  }

  // === Enhanced Repository Methods Implementation ===

  @override
  Future<Either<Failure, List<BorrowRequest>>> getMyActiveBorrowings() async {
    try {
      final borrowRequestModels = await _enhancedDataSource.getMyActiveBorrowings();
      final borrowRequests = borrowRequestModels
          .map((model) => model.toEntity())
          .toList();
      return Right(borrowRequests);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on NetworkFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch active borrowings: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<BorrowRequest>>> getMyBorrowingHistory() async {
    try {
      final borrowRequestModels = await _enhancedDataSource.getMyBorrowingHistory();
      final borrowRequests = borrowRequestModels
          .map((model) => model.toEntity())
          .toList();
      return Right(borrowRequests);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on NetworkFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch borrowing history: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, BorrowingLimits>> getMyBorrowingLimits() async {
    try {
      final limitsData = await _enhancedDataSource.getMyBorrowingLimits();
      
      final limits = BorrowingLimits(
        maxBooks: limitsData['max_books'] ?? 5,
        maxDurationDays: limitsData['max_duration_days'] ?? 7,
        maxRenewals: limitsData['max_renewals'] ?? 2,
        currentBorrows: limitsData['current_borrows'] ?? 0,
        overdueCount: limitsData['overdue_count'] ?? 0,
        canBorrow: limitsData['can_borrow'] ?? true,
        restrictions: List<String>.from(limitsData['restrictions'] ?? []),
      );
      
      return Right(limits);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on NetworkFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch borrowing limits: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> returnBook(String activityId, {String? notes}) async {
    try {
      final success = await _enhancedDataSource.returnBook(activityId, notes: notes);
      return Right(success);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on NetworkFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Failed to return book: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> renewBorrowing(String activityId) async {
    try {
      final success = await _enhancedDataSource.renewBorrowing(activityId);
      return Right(success);
    } on BorrowRequestFailure catch (failure) {
      return Left(failure);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on NetworkFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Failed to renew borrowing: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Collection>>> getPopularCollections({int limit = 10}) async {
    try {
      final collectionModels = await _enhancedDataSource.getPopularCollections(limit: limit);
      final collections = collectionModels
          .map((model) => model.toEntity())
          .toList();
      return Right(collections);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on NetworkFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch popular collections: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Collection>>> getRecentCollections({int limit = 10}) async {
    try {
      final collectionModels = await _enhancedDataSource.getRecentCollections(limit: limit);
      final collections = collectionModels
          .map((model) => model.toEntity())
          .toList();
      return Right(collections);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on NetworkFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch recent collections: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CollectionAvailability>> checkCollectionAvailability(String collectionId) async {
    try {
      final availabilityData = await _enhancedDataSource.checkCollectionAvailability(collectionId);
      
      final availability = CollectionAvailability(
        available: availabilityData['available'] ?? false,
        availableCopies: availabilityData['availableCopies'] ?? 0,
        totalCopies: availabilityData['totalCopies'] ?? 0,
        borrowedCopies: availabilityData['borrowedCopies'] ?? 0,
        reservedCopies: availabilityData['reservedCopies'] ?? 0,
      );
      
      return Right(availability);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on NetworkFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Failed to check availability: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Collection>>> searchCollectionsAdvanced(SearchFilter filter) async {
    try {
      final collectionModels = await _enhancedDataSource.searchCollectionsAdvanced(
        query: filter.query ?? '',
        category: filter.category,
        author: filter.author,
        year: filter.year,
        availableOnly: filter.availableOnly,
        page: filter.page,
        limit: filter.limit,
      );
      
      final collections = collectionModels
          .map((model) => model.toEntity())
          .toList();
      return Right(collections);
    } on ServerFailure catch (failure) {
      return Left(failure);
    } on NetworkFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return Left(ServerFailure('Failed to search collections: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Collection>>> getCollectionsWithFilters(SearchFilter filter) async {
    try {
      // Use advanced search for filtered requests
      if (filter.hasFilters) {
        return searchCollectionsAdvanced(filter);
      }
      
      // Use regular getAllCollections for simple requests
      return getAllCollections();
    } catch (e) {
      return Left(ServerFailure('Failed to get collections with filters: ${e.toString()}'));
    }
  }
}