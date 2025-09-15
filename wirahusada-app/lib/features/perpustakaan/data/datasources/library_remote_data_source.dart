import 'package:wismon_keuangan/features/perpustakaan/data/models/collection_model.dart';
import 'package:wismon_keuangan/features/perpustakaan/data/models/borrow_request_model.dart';

/// Abstract interface for library remote data source
abstract class LibraryRemoteDataSource {
  /// Fetch all collections from remote API
  Future<List<CollectionModel>> getAllCollections();

  /// Fetch collections by category from remote API
  Future<List<CollectionModel>> getCollectionsByCategory(String category);

  /// Search collections by query from remote API
  Future<List<CollectionModel>> searchCollections(String query);

  /// Fetch collection by code from remote API
  Future<CollectionModel> getCollectionByCode(String kode);

  /// Fetch collections by topic from remote API
  Future<List<CollectionModel>> getCollectionsByTopic(String topic);

  /// Fetch all unique topics from remote API
  Future<List<String>> getAllTopics();

  /// Submit borrow request to remote API
  Future<bool> submitBorrowRequest(BorrowRequestModel borrowRequest);

  /// Fetch borrow requests by student NRM from remote API
  Future<List<BorrowRequestModel>> getBorrowRequestsByNrm(String nrm);

  /// Fetch borrow request by ID from remote API
  Future<BorrowRequestModel> getBorrowRequestById(String requestId);
}