import 'package:flutter/foundation.dart';
import 'package:wismon_keuangan/core/services/api_service.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/utils/web_type_utils.dart';
import 'package:wismon_keuangan/features/perpustakaan/data/models/collection_model.dart';
import 'package:wismon_keuangan/features/perpustakaan/data/models/borrow_request_model.dart';
import 'package:wismon_keuangan/features/perpustakaan/data/datasources/library_remote_data_source.dart';

/// Concrete implementation of LibraryRemoteDataSource
class LibraryRemoteDataSourceImpl implements LibraryRemoteDataSource {
  final ApiService apiService;

  const LibraryRemoteDataSourceImpl({required this.apiService});

  @override
  Future<List<CollectionModel>> getAllCollections() async {
    try {
      if (kDebugMode) {
        print('🔍 [LibraryDataSource] Fetching all collections from /api/perpustakaan/koleksi');
      }

      final data = await apiService.get('/api/perpustakaan/koleksi');

      if (kDebugMode) {
        WebTypeUtils.debugLogType('LibraryDataSource getAllCollections', data);
        print('📋 [LibraryDataSource] Raw data type: ${data.runtimeType}');
        print('📋 [LibraryDataSource] Raw data is List: ${data is List}');
        print('📋 [LibraryDataSource] Raw data is Map: ${data is Map}');
      }

      // Use web-safe array extraction
      final arrayData = WebTypeUtils.extractArrayData(data);

      if (kDebugMode) {
        print('📋 [LibraryDataSource] Extracted array data length: ${arrayData.length}');
        if (arrayData.isNotEmpty) {
          print('📋 [LibraryDataSource] First item type: ${arrayData[0].runtimeType}');
          print('📋 [LibraryDataSource] First item is List: ${arrayData[0] is List}');
          print('📋 [LibraryDataSource] First item is Map: ${arrayData[0] is Map}');
        }
      }

      if (arrayData.isNotEmpty) {
        // Validate the array contains valid collection data
        if (!WebTypeUtils.isValidCollectionArray(data)) {
          if (kDebugMode) {
            print('⚠️ [LibraryDataSource] Invalid collection array detected, parsing carefully');
          }
        }

        final collections = <CollectionModel>[];
        for (int i = 0; i < arrayData.length; i++) {
          try {
            final item = arrayData[i];
            
            // Additional type checking before casting
            if (item is! Map) {
              if (kDebugMode) {
                print('⚠️ [LibraryDataSource] Item at index $i is not a Map, skipping. Type: ${item.runtimeType}');
                print('📋 [LibraryDataSource] Item content: $item');
              }
              continue;
            }
            
            final safeJson = WebTypeUtils.safeMapCast(item);

            // Validate individual collection data before parsing
            if (WebTypeUtils.isValidCollectionData(safeJson)) {
              final collection = CollectionModel.fromJson(safeJson);
              collections.add(collection);
            } else {
              if (kDebugMode) {
                print('⚠️ [LibraryDataSource] Skipping invalid collection at index $i');
                print('📋 [LibraryDataSource] Available keys: ${safeJson.keys.toList()}');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ [LibraryDataSource] Failed to parse collection at index $i: $e');
              print('📋 [LibraryDataSource] Raw item: ${arrayData[i]}');
            }
            // Continue with other items instead of failing completely
            continue;
          }
        }

        if (kDebugMode) {
          print('✅ [LibraryDataSource] Successfully parsed ${collections.length} collections from ${arrayData.length} items');
        }
        return collections;
      }

      // Check for error response
      final mapData = WebTypeUtils.safeMapCast(data);
      if (mapData.containsKey('success') && mapData['success'] != true) {
        final errorMessage = mapData['message'] ?? 'Failed to fetch collections';
        if (kDebugMode) {
          print('❌ [LibraryDataSource] Server error: $errorMessage');
        }
        throw ServerFailure(errorMessage);
      }

      if (kDebugMode) {
        print('⚠️ [LibraryDataSource] Empty response data - returning empty list');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ [LibraryDataSource] Exception in getAllCollections: $e');
        print('❌ [LibraryDataSource] Exception type: ${e.runtimeType}');
      }
      if (e is ServerFailure) rethrow;
      if (e.toString().contains('network')) {
        throw NetworkFailure('Network error: ${e.toString()}');
      }
      throw ServerFailure('Failed to fetch collections: ${e.toString()}');
    }
  }

  @override
  Future<List<CollectionModel>> getCollectionsByCategory(String category) async {
    try {
      if (kDebugMode) {
        print('🔍 [LibraryDataSource] Fetching collections for category: $category');
      }

      final data = await apiService.get('/api/perpustakaan/koleksi/kategori/$category');

      if (kDebugMode) {
        WebTypeUtils.debugLogType('LibraryDataSource getCollectionsByCategory', data);
        print('📋 [LibraryDataSource] Raw data type: ${data.runtimeType}');
        print('📋 [LibraryDataSource] Raw data is List: ${data is List}');
        print('📋 [LibraryDataSource] Raw data is Map: ${data is Map}');
      }

      // Use web-safe array extraction
      final arrayData = WebTypeUtils.extractArrayData(data);

      if (kDebugMode) {
        print('📋 [LibraryDataSource] Extracted array data length: ${arrayData.length}');
        if (arrayData.isNotEmpty) {
          print('📋 [LibraryDataSource] First item type: ${arrayData[0].runtimeType}');
          print('📋 [LibraryDataSource] First item is List: ${arrayData[0] is List}');
          print('📋 [LibraryDataSource] First item is Map: ${arrayData[0] is Map}');
        }
      }

      if (arrayData.isNotEmpty) {
        // Validate the array contains valid collection data
        if (!WebTypeUtils.isValidCollectionArray(data)) {
          if (kDebugMode) {
            print('⚠️ [LibraryDataSource] Invalid collection array detected for category $category, parsing carefully');
          }
        }

        final collections = <CollectionModel>[];
        for (int i = 0; i < arrayData.length; i++) {
          try {
            final item = arrayData[i];
            
            // Additional type checking before casting
            if (item is! Map) {
              if (kDebugMode) {
                print('⚠️ [LibraryDataSource] Item at index $i is not a Map, skipping. Type: ${item.runtimeType}');
                print('📋 [LibraryDataSource] Item content: $item');
              }
              continue;
            }
            
            final safeJson = WebTypeUtils.safeMapCast(item);

            // Validate individual collection data before parsing
            if (WebTypeUtils.isValidCollectionData(safeJson)) {
              final collection = CollectionModel.fromJson(safeJson);
              collections.add(collection);
            } else {
              if (kDebugMode) {
                print('⚠️ [LibraryDataSource] Skipping invalid collection at index $i for category $category');
                print('📋 [LibraryDataSource] Available keys: ${safeJson.keys.toList()}');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ [LibraryDataSource] Failed to parse collection at index $i for category $category: $e');
              print('📋 [LibraryDataSource] Raw item: ${arrayData[i]}');
            }
            // Continue with other items instead of failing completely
            continue;
          }
        }

        if (kDebugMode) {
          print('✅ [LibraryDataSource] Successfully parsed ${collections.length} collections from ${arrayData.length} items for category $category');
        }
        return collections;
      }

      // Check for error response
      final mapData = WebTypeUtils.safeMapCast(data);
      if (mapData.containsKey('success') && mapData['success'] != true) {
        final errorMessage = mapData['message'] ?? 'Failed to fetch collections by category';
        if (kDebugMode) {
          print('❌ [LibraryDataSource] Server error for category $category: $errorMessage');
        }
        throw ServerFailure(errorMessage);
      }

      if (kDebugMode) {
        print('⚠️ [LibraryDataSource] Empty response data for category $category - returning empty list');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ [LibraryDataSource] Exception in getCollectionsByCategory($category): $e');
        print('❌ [LibraryDataSource] Exception type: ${e.runtimeType}');
      }
      if (e is ServerFailure) rethrow;
      if (e.toString().contains('network')) {
        throw NetworkFailure('Network error: ${e.toString()}');
      }
      throw ServerFailure('Failed to fetch collections by category: ${e.toString()}');
    }
  }

  @override
  Future<List<CollectionModel>> searchCollections(String query) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final data = await apiService.get('/api/library/search?q=$encodedQuery');

      if (kDebugMode) {
        WebTypeUtils.debugLogType('LibraryDataSource searchCollections', data);
      }

      // First check for error response patterns
      final mapData = WebTypeUtils.safeMapCast(data);

      // Pattern 1: Explicit error response {success: false, message: "..."}
      if (mapData.containsKey('success') && mapData['success'] == false) {
        final errorMessage = mapData['message'] ?? 'Search failed';
        if (kDebugMode) {
          print('❌ [LibraryDataSource] Search error for query "$query": $errorMessage');
        }
        throw ServerFailure(errorMessage);
      }

      // Pattern 2: Generic error response {message: "..."}
      if (mapData.containsKey('message') && mapData.containsKey('error')) {
        final errorMessage = mapData['message'] ?? 'Failed to search collections';
        if (kDebugMode) {
          print('❌ [LibraryDataSource] Search error message for query "$query": $errorMessage');
        }
        throw ServerFailure(errorMessage);
      }

      // Use web-safe array extraction for successful responses
      final arrayData = WebTypeUtils.extractArrayData(data);

      if (arrayData.isNotEmpty) {
        final collections = <CollectionModel>[];
        for (int i = 0; i < arrayData.length; i++) {
          try {
            final safeJson = WebTypeUtils.safeMapCast(arrayData[i]);

            // Validate each collection has required fields before parsing
            if (safeJson.containsKey('kode') &&
                safeJson.containsKey('kategori') &&
                safeJson.containsKey('topik') &&
                safeJson.containsKey('judul') &&
                safeJson.containsKey('penulis')) {

              final collection = CollectionModel.fromJson(safeJson);
              collections.add(collection);
            } else {
              if (kDebugMode) {
                print('⚠️ [LibraryDataSource] Skipping invalid collection at index $i: missing required fields');
                print('📋 [LibraryDataSource] Available keys: ${safeJson.keys.toList()}');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('❌ [LibraryDataSource] Failed to parse collection at index $i: $e');
              print('📋 [LibraryDataSource] Raw item: ${arrayData[i]}');
            }
            // Continue with other items instead of failing completely
            continue;
          }
        }

        if (kDebugMode) {
          print('✅ [LibraryDataSource] Successfully parsed ${collections.length} collections from ${arrayData.length} items');
        }
        return collections;
      }

      // Check for valid empty response patterns
      if (mapData.containsKey('success') && mapData['success'] == true) {
        if (kDebugMode) {
          print('ℹ️ [LibraryDataSource] Empty search results for query "$query"');
        }
        return [];
      }

      if (kDebugMode) {
        print('⚠️ [LibraryDataSource] Unexpected response format for search query "$query"');
        print('📋 [LibraryDataSource] Response data: $data');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ [LibraryDataSource] Exception in searchCollections("$query"): $e');
      }
      if (e is ServerFailure) rethrow;
      if (e.toString().contains('network')) {
        throw NetworkFailure('Network error: ${e.toString()}');
      }
      throw ServerFailure('Failed to search collections: ${e.toString()}');
    }
  }

  @override
  Future<CollectionModel> getCollectionByCode(String code) async {
    try {
      final data = await apiService.get('/api/perpustakaan/koleksi/$code');

      if (kDebugMode) {
        WebTypeUtils.debugLogType('LibraryDataSource getCollectionByCode', data);
      }

      // First check for error response patterns
      final mapData = WebTypeUtils.safeMapCast(data);

      // Pattern 1: Explicit error response {success: false, message: "..."}
      if (mapData.containsKey('success') && mapData['success'] == false) {
        final errorMessage = mapData['message'] ?? 'Collection not found';
        if (kDebugMode) {
          print('❌ [LibraryDataSource] Server error for code $code: $errorMessage');
        }
        throw ServerFailure(errorMessage);
      }

      // Pattern 2: Generic error response {message: "..."}
      if (mapData.containsKey('message') && !mapData.containsKey('kode')) {
        final errorMessage = mapData['message'] ?? 'Failed to fetch collection';
        if (kDebugMode) {
          print('❌ [LibraryDataSource] Error message for code $code: $errorMessage');
        }
        throw ServerFailure(errorMessage);
      }

      // Use web-safe object extraction for successful responses
      final objectData = WebTypeUtils.extractObjectData(data);

      // Validate we have valid collection data before attempting to parse
      if (objectData.isNotEmpty &&
          objectData.containsKey('kode') &&
          objectData['kode'] != null &&
          objectData['kode'].toString().isNotEmpty) {

        // Additional validation for required fields
        if (!objectData.containsKey('kategori') ||
            !objectData.containsKey('topik') ||
            !objectData.containsKey('judul') ||
            !objectData.containsKey('penulis')) {
          if (kDebugMode) {
            print('⚠️ [LibraryDataSource] Incomplete collection data for code $code, missing required fields');
          }
          throw ServerFailure('Incomplete collection data received');
        }

        try {
          return CollectionModel.fromJson(objectData);
        } catch (e) {
          if (kDebugMode) {
            print('❌ [LibraryDataSource] Failed to parse collection JSON for code $code: $e');
            print('📋 [LibraryDataSource] Raw data: $objectData');
          }
          throw ServerFailure('Failed to parse collection data: ${e.toString()}');
        }
      }

      if (kDebugMode) {
        print('❌ [LibraryDataSource] No valid collection data found for code $code');
        print('📋 [LibraryDataSource] Response data: $data');
      }
      throw ServerFailure('Collection with code $code not found');
    } catch (e) {
      if (kDebugMode) {
        print('❌ [LibraryDataSource] Exception in getCollectionByCode($code): $e');
      }
      if (e is ServerFailure) rethrow;
      if (e.toString().contains('network')) {
        throw NetworkFailure('Network error: ${e.toString()}');
      }
      throw ServerFailure('Failed to fetch collection: ${e.toString()}');
    }
  }

  @override
  Future<List<CollectionModel>> getCollectionsByTopic(String topic) async {
    try {
      final data = await apiService.get('/api/koleksi/topic/$topic');

      // Use web-safe array extraction
      final arrayData = WebTypeUtils.extractArrayData(data);

      if (arrayData.isNotEmpty) {
        final collections = arrayData.map((json) {
          final safeJson = WebTypeUtils.safeMapCast(json);
          return CollectionModel.fromJson(safeJson);
        }).toList();
        return collections;
      }

      // Check for error response
      final mapData = WebTypeUtils.safeMapCast(data);
      if (mapData.containsKey('success') && mapData['success'] != true) {
        throw ServerFailure(mapData['message'] ?? 'Failed to fetch collections by topic');
      }

      return [];
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure('Failed to fetch collections by topic: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> getAllTopics() async {
    try {
      final data = await apiService.get('/api/koleksi/topics');

      // Use web-safe array extraction
      final arrayData = WebTypeUtils.extractArrayData(data);

      if (arrayData.isNotEmpty) {
        return arrayData.cast<String>();
      }

      // Check for error response
      final mapData = WebTypeUtils.safeMapCast(data);
      if (mapData.containsKey('success') && mapData['success'] != true) {
        throw ServerFailure(mapData['message'] ?? 'Failed to fetch topics');
      }

      return [];
    } catch (e) {
      if (e is ServerFailure) rethrow;
      throw ServerFailure('Failed to fetch topics: ${e.toString()}');
    }
  }

  @override
  Future<bool> submitBorrowRequest(BorrowRequestModel borrowRequest) async {
    try {
      final requestData = {
        'nrm_mahasiswa': borrowRequest.nrm,
        'kode_koleksi': borrowRequest.kode,
        'notes': borrowRequest.catatan,
      };
      
      final data = await apiService.post('/api/perpustakaan/aktivitas', requestData);
      
      if (data['success'] == true) {
        return true;
      } else {
        // Handle specific error cases from enhanced backend
        final message = data['message'] ?? 'Failed to submit borrow request';
        if (message.contains('BORROWING_LIMIT_EXCEEDED') || 
            message.contains('COLLECTION_NOT_AVAILABLE') ||
            message.contains('STUDENT_NOT_FOUND')) {
          throw BorrowRequestFailure(message);
        }
        throw BorrowRequestFailure(message);
      }
    } catch (e) {
      if (e is BorrowRequestFailure) rethrow;
      if (e.toString().contains('network')) {
        throw NetworkFailure('Network error: ${e.toString()}');
      }
      throw BorrowRequestFailure('Failed to submit borrow request: ${e.toString()}');
    }
  }

  @override
  Future<List<BorrowRequestModel>> getBorrowRequestsByNrm(String nrm) async {
    try {
      final data = await apiService.get('/api/library/activities/student/$nrm/history');

      // Use web-safe array extraction
      final arrayData = WebTypeUtils.extractArrayData(data);

      if (arrayData.isNotEmpty) {
        final requests = arrayData.map((json) {
          final safeJson = WebTypeUtils.safeMapCast(json);
          return BorrowRequestModel.fromJson(safeJson);
        }).toList();
        return requests;
      }

      // Check for error response
      final mapData = WebTypeUtils.safeMapCast(data);
      if (mapData.containsKey('success') && mapData['success'] != true) {
        throw ServerFailure(mapData['message'] ?? 'Failed to fetch borrow requests');
      }

      return [];
    } catch (e) {
      if (e is ServerFailure) rethrow;
      if (e.toString().contains('network')) {
        throw NetworkFailure('Network error: ${e.toString()}');
      }
      throw ServerFailure('Failed to fetch borrow requests: ${e.toString()}');
    }
  }

  @override
  Future<BorrowRequestModel> getBorrowRequestById(String requestId) async {
    try {
      final data = await apiService.get('/api/library/activities/$requestId');

      // Use web-safe object extraction
      final objectData = WebTypeUtils.extractObjectData(data);

      if (objectData.isNotEmpty) {
        return BorrowRequestModel.fromJson(objectData);
      }

      // Check for error response
      final mapData = WebTypeUtils.safeMapCast(data);
      final message = mapData['message'] ?? 'Failed to fetch borrow request';

      if (message.contains('not found')) {
        throw ServerFailure('Borrow request with ID $requestId not found');
      }

      throw ServerFailure(message);
    } catch (e) {
      if (e is ServerFailure) rethrow;
      if (e.toString().contains('network')) {
        throw NetworkFailure('Network error: ${e.toString()}');
      }
      throw ServerFailure('Failed to fetch borrow request: ${e.toString()}');
    }
  }

  /// Get user's active borrowings
  Future<List<BorrowRequestModel>> getMyActiveBorrowings() async {
    try {
      final data = await apiService.get('/api/library/my-borrowings/active');

      // Use web-safe array extraction
      final arrayData = WebTypeUtils.extractArrayData(data);

      if (arrayData.isNotEmpty) {
        final activities = arrayData.map((json) {
          final safeJson = WebTypeUtils.safeMapCast(json);
          return BorrowRequestModel.fromJson(safeJson);
        }).toList();
        return activities;
      }

      // Check for error response
      final mapData = WebTypeUtils.safeMapCast(data);
      if (mapData.containsKey('success') && mapData['success'] != true) {
        throw ServerFailure(mapData['message'] ?? 'Failed to fetch active borrowings');
      }

      return [];
    } catch (e) {
      if (e is ServerFailure) rethrow;
      if (e.toString().contains('network')) {
        throw NetworkFailure('Network error: ${e.toString()}');
      }
      throw ServerFailure('Failed to fetch active borrowings: ${e.toString()}');
    }
  }

  /// Get user's borrowing history
  Future<List<BorrowRequestModel>> getMyBorrowingHistory() async {
    try {
      final data = await apiService.get('/api/library/my-borrowings');

      // Use web-safe array extraction
      final arrayData = WebTypeUtils.extractArrayData(data);

      if (arrayData.isNotEmpty) {
        final history = arrayData.map((json) {
          final safeJson = WebTypeUtils.safeMapCast(json);
          return BorrowRequestModel.fromJson(safeJson);
        }).toList();
        return history;
      }

      // Check for error response
      final mapData = WebTypeUtils.safeMapCast(data);
      if (mapData.containsKey('success') && mapData['success'] != true) {
        throw ServerFailure(mapData['message'] ?? 'Failed to fetch borrowing history');
      }

      return [];
    } catch (e) {
      if (e is ServerFailure) rethrow;
      if (e.toString().contains('network')) {
        throw NetworkFailure('Network error: ${e.toString()}');
      }
      throw ServerFailure('Failed to fetch borrowing history: ${e.toString()}');
    }
  }

  /// Get user's borrowing limits
  Future<Map<String, dynamic>> getMyBorrowingLimits() async {
    try {
      final data = await apiService.get('/api/library/my-limits');

      // Use web-safe object extraction
      final objectData = WebTypeUtils.extractObjectData(data);

      if (objectData.isNotEmpty) {
        return objectData;
      }

      // Check for error response
      final mapData = WebTypeUtils.safeMapCast(data);
      if (mapData.containsKey('success') && mapData['success'] != true) {
        throw ServerFailure(mapData['message'] ?? 'Failed to fetch borrowing limits');
      }

      return {};
    } catch (e) {
      if (e is ServerFailure) rethrow;
      if (e.toString().contains('network')) {
        throw NetworkFailure('Network error: ${e.toString()}');
      }
      throw ServerFailure('Failed to fetch borrowing limits: ${e.toString()}');
    }
  }

  /// Return a borrowed book
  Future<bool> returnBook(String activityId, {String? notes}) async {
    try {
      final requestData = <String, dynamic>{};
      if (notes != null) requestData['notes'] = notes;
      
      final data = await apiService.patch('/api/library/activities/$activityId/return', requestData);
      
      if (data['success'] == true) {
        return true;
      } else {
        throw ServerFailure(data['message'] ?? 'Failed to return book');
      }
    } catch (e) {
      if (e is ServerFailure) rethrow;
      if (e.toString().contains('network')) {
        throw NetworkFailure('Network error: ${e.toString()}');
      }
      throw ServerFailure('Failed to return book: ${e.toString()}');
    }
  }

  /// Renew a borrowing
  Future<bool> renewBorrowing(String activityId) async {
    try {
      final data = await apiService.patch('/api/library/activities/$activityId/renew', {});
      
      if (data['success'] == true) {
        return true;
      } else {
        final message = data['message'] ?? 'Failed to renew borrowing';
        if (message.contains('MAX_RENEWALS_EXCEEDED') || 
            message.contains('BOOK_RESERVED') ||
            message.contains('CANNOT_RENEW')) {
          throw BorrowRequestFailure(message);
        }
        throw ServerFailure(message);
      }
    } catch (e) {
      if (e is BorrowRequestFailure || e is ServerFailure) rethrow;
      if (e.toString().contains('network')) {
        throw NetworkFailure('Network error: ${e.toString()}');
      }
      throw ServerFailure('Failed to renew borrowing: ${e.toString()}');
    }
  }

  /// Get popular collections
  Future<List<CollectionModel>> getPopularCollections({int limit = 10}) async {
    try {
      final data = await apiService.get('/api/library/collections/popular?limit=$limit');

      // Use web-safe array extraction
      final arrayData = WebTypeUtils.extractArrayData(data);

      if (arrayData.isNotEmpty) {
        final collections = arrayData.map((json) {
          final safeJson = WebTypeUtils.safeMapCast(json);
          return CollectionModel.fromJson(safeJson);
        }).toList();
        return collections;
      }

      // Check for error response
      final mapData = WebTypeUtils.safeMapCast(data);
      if (mapData.containsKey('success') && mapData['success'] != true) {
        throw ServerFailure(mapData['message'] ?? 'Failed to fetch popular collections');
      }

      return [];
    } catch (e) {
      if (e is ServerFailure) rethrow;
      if (e.toString().contains('network')) {
        throw NetworkFailure('Network error: ${e.toString()}');
      }
      throw ServerFailure('Failed to fetch popular collections: ${e.toString()}');
    }
  }

  /// Get recent collections
  Future<List<CollectionModel>> getRecentCollections({int limit = 10}) async {
    try {
      final data = await apiService.get('/api/library/collections/recent?limit=$limit');

      // Use web-safe array extraction
      final arrayData = WebTypeUtils.extractArrayData(data);

      if (arrayData.isNotEmpty) {
        final collections = arrayData.map((json) {
          final safeJson = WebTypeUtils.safeMapCast(json);
          return CollectionModel.fromJson(safeJson);
        }).toList();
        return collections;
      }

      // Check for error response
      final mapData = WebTypeUtils.safeMapCast(data);
      if (mapData.containsKey('success') && mapData['success'] != true) {
        throw ServerFailure(mapData['message'] ?? 'Failed to fetch recent collections');
      }

      return [];
    } catch (e) {
      if (e is ServerFailure) rethrow;
      if (e.toString().contains('network')) {
        throw NetworkFailure('Network error: ${e.toString()}');
      }
      throw ServerFailure('Failed to fetch recent collections: ${e.toString()}');
    }
  }

  /// Check collection availability
  Future<Map<String, dynamic>> checkCollectionAvailability(String collectionId) async {
    try {
      final data = await apiService.get('/api/library/collections/$collectionId/availability');

      // Use web-safe object extraction
      final objectData = WebTypeUtils.extractObjectData(data);

      if (objectData.isNotEmpty) {
        return objectData;
      }

      // Check for error response
      final mapData = WebTypeUtils.safeMapCast(data);
      if (mapData.containsKey('success') && mapData['success'] != true) {
        throw ServerFailure(mapData['message'] ?? 'Failed to check availability');
      }

      return {};
    } catch (e) {
      if (e is ServerFailure) rethrow;
      if (e.toString().contains('network')) {
        throw NetworkFailure('Network error: ${e.toString()}');
      }
      throw ServerFailure('Failed to check availability: ${e.toString()}');
    }
  }

  /// Advanced search with filters
  Future<List<CollectionModel>> searchCollectionsAdvanced({
    required String query,
    String? category,
    String? author,
    int? year,
    bool? availableOnly,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'q': query,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (category != null) queryParams['category'] = category;
      if (author != null) queryParams['author'] = author;
      if (year != null) queryParams['year'] = year.toString();
      if (availableOnly != null) queryParams['available'] = availableOnly.toString();

      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      final data = await apiService.get('/api/library/search?$queryString');

      // Use web-safe array extraction
      final arrayData = WebTypeUtils.extractArrayData(data);

      if (arrayData.isNotEmpty) {
        final collections = arrayData.map((json) {
          final safeJson = WebTypeUtils.safeMapCast(json);
          return CollectionModel.fromJson(safeJson);
        }).toList();
        return collections;
      }

      // Check for error response
      final mapData = WebTypeUtils.safeMapCast(data);
      if (mapData.containsKey('success') && mapData['success'] != true) {
        throw ServerFailure(mapData['message'] ?? 'Failed to search collections');
      }

      return [];
    } catch (e) {
      if (e is ServerFailure) rethrow;
      if (e.toString().contains('network')) {
        throw NetworkFailure('Network error: ${e.toString()}');
      }
      throw ServerFailure('Failed to search collections: ${e.toString()}');
    }
  }
}