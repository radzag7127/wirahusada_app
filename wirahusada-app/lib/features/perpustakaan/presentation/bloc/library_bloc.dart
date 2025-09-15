import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/usecases/get_all_collections_usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/usecases/get_collections_by_category_usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/usecases/search_collections_usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/usecases/get_collection_by_code_usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/usecases/submit_borrow_request_usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_event.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final GetAllCollectionsUseCase getAllCollectionsUseCase;
  final GetCollectionsByCategoryUseCase getCollectionsByCategoryUseCase;
  final SearchCollectionsUseCase searchCollectionsUseCase;
  final GetCollectionByCodeUseCase getCollectionByCodeUseCase;
  final SubmitBorrowRequestUseCase submitBorrowRequestUseCase;

  LibraryBloc({
    required this.getAllCollectionsUseCase,
    required this.getCollectionsByCategoryUseCase,
    required this.searchCollectionsUseCase,
    required this.getCollectionByCodeUseCase,
    required this.submitBorrowRequestUseCase,
  }) : super(const LibraryInitial()) {
    on<LoadAllCollectionsEvent>(_onLoadAllCollections);
    on<LoadCollectionsByCategoryEvent>(_onLoadCollectionsByCategory);
    on<SearchCollectionsEvent>(_onSearchCollections);
    on<LoadCollectionByCodeEvent>(_onLoadCollectionByCode);
    on<FilterCollectionsByTopicEvent>(_onFilterCollectionsByTopic);
    on<SubmitBorrowRequestEvent>(_onSubmitBorrowRequest);
    on<ClearSearchEvent>(_onClearSearch);
    on<ResetLibraryStateEvent>(_onResetLibraryState);
  }

  Future<void> _onLoadAllCollections(
    LoadAllCollectionsEvent event,
    Emitter<LibraryState> emit,
  ) async {
    if (kDebugMode) {
      print('📚 [LibraryBloc] Loading all collections');
    }

    emit(const LibraryLoading());

    final result = await getAllCollectionsUseCase(NoParams());

    result.fold(
      (failure) {
        if (kDebugMode) {
          print('❌ [LibraryBloc] Failed to load collections: ${_mapFailureToMessage(failure)}');
        }
        emit(LibraryError(message: _mapFailureToMessage(failure)));
      },
      (collections) {
        if (kDebugMode) {
          print('✅ [LibraryBloc] Loaded ${collections.length} collections');
        }
        if (collections.isEmpty) {
          emit(const LibraryEmpty(message: 'No collections found'));
        } else {
          emit(LibraryLoaded(collections: collections));
        }
      },
    );
  }

  Future<void> _onLoadCollectionsByCategory(
    LoadCollectionsByCategoryEvent event,
    Emitter<LibraryState> emit,
  ) async {
    if (kDebugMode) {
      print('📚 [LibraryBloc] Loading collections by category: ${event.category}');
    }

    emit(const LibraryLoading());

    final result = await getCollectionsByCategoryUseCase(
      CategoryParams(category: event.category),
    );

    result.fold(
      (failure) {
        if (kDebugMode) {
          print('❌ [LibraryBloc] Failed to load ${event.category} collections: ${_mapFailureToMessage(failure)}');
        }
        emit(LibraryError(message: _mapFailureToMessage(failure)));
      },
      (collections) {
        if (kDebugMode) {
          print('✅ [LibraryBloc] Loaded ${collections.length} ${event.category} collections');
        }
        if (collections.isEmpty) {
          emit(LibraryEmpty(message: 'No ${event.category} collections found'));
        } else {
          emit(LibraryLoaded(
            collections: collections,
            selectedCategory: event.category,
          ));
        }
      },
    );
  }

  Future<void> _onSearchCollections(
    SearchCollectionsEvent event,
    Emitter<LibraryState> emit,
  ) async {
    if (kDebugMode) {
      print('🔍 [LibraryBloc] Searching collections with query: ${event.query}');
    }

    emit(const LibraryLoading());

    final result = await searchCollectionsUseCase(
      SearchParams(query: event.query),
    );

    result.fold(
      (failure) {
        if (kDebugMode) {
          print('❌ [LibraryBloc] Search failed: ${_mapFailureToMessage(failure)}');
        }
        emit(LibraryError(message: _mapFailureToMessage(failure)));
      },
      (collections) {
        if (kDebugMode) {
          print('✅ [LibraryBloc] Found ${collections.length} collections for query: ${event.query}');
        }
        if (collections.isEmpty) {
          emit(LibraryEmpty(message: 'No collections found for "${event.query}"'));
        } else {
          emit(LibraryLoaded(
            collections: collections,
            searchQuery: event.query,
            isSearchActive: true,
          ));
        }
      },
    );
  }

  Future<void> _onLoadCollectionByCode(
    LoadCollectionByCodeEvent event,
    Emitter<LibraryState> emit,
  ) async {
    if (kDebugMode) {
      print('📖 [LibraryBloc] Loading collection by code: ${event.kode}');
    }

    emit(const LibraryLoading());

    final result = await getCollectionByCodeUseCase(
      CollectionCodeParams(kode: event.kode),
    );

    result.fold(
      (failure) {
        if (kDebugMode) {
          print('❌ [LibraryBloc] Failed to load collection: ${_mapFailureToMessage(failure)}');
        }
        emit(LibraryError(message: _mapFailureToMessage(failure)));
      },
      (collection) {
        if (kDebugMode) {
          print('✅ [LibraryBloc] Loaded collection: ${collection.judul}');
        }
        emit(CollectionDetailLoaded(collection: collection));
      },
    );
  }

  Future<void> _onFilterCollectionsByTopic(
    FilterCollectionsByTopicEvent event,
    Emitter<LibraryState> emit,
  ) async {
    if (state is LibraryLoaded) {
      final currentState = state as LibraryLoaded;
      
      if (kDebugMode) {
        print('🏷️ [LibraryBloc] Filtering collections by topic: ${event.topic}');
      }

      // Filter existing collections by topic
      final filteredCollections = currentState.collections
          .where((collection) => collection.topik.toLowerCase().contains(event.topic.toLowerCase()))
          .toList();

      if (filteredCollections.isEmpty) {
        emit(LibraryEmpty(message: 'No collections found for topic "${event.topic}"'));
      } else {
        emit(currentState.copyWith(
          collections: filteredCollections,
          selectedTopic: event.topic,
        ));
      }
    }
  }

  Future<void> _onSubmitBorrowRequest(
    SubmitBorrowRequestEvent event,
    Emitter<LibraryState> emit,
  ) async {
    if (kDebugMode) {
      print('📤 [LibraryBloc] Submitting borrow request for collection: ${event.kode}');
    }

    emit(const BorrowRequestSubmitting());

    final result = await submitBorrowRequestUseCase(
      BorrowRequestParams(
        nrm: event.nrm,
        kode: event.kode,
        tanggalPengambilan: event.tanggalPengambilan,
        tanggalKembali: event.tanggalKembali,
        notes: event.notes,
      ),
    );

    result.fold(
      (failure) {
        if (kDebugMode) {
          print('❌ [LibraryBloc] Borrow request failed: ${_mapFailureToMessage(failure)}');
        }
        emit(LibraryError(message: _mapFailureToMessage(failure)));
      },
      (success) {
        if (kDebugMode) {
          print('✅ [LibraryBloc] Borrow request submitted successfully');
        }
        if (success) {
          emit(const BorrowRequestSuccess(message: 'Borrow request submitted successfully'));
        } else {
          emit(const LibraryError(message: 'Failed to submit borrow request'));
        }
      },
    );
  }

  void _onClearSearch(ClearSearchEvent event, Emitter<LibraryState> emit) {
    if (state is LibraryLoaded) {
      final currentState = state as LibraryLoaded;
      if (kDebugMode) {
        print('🧹 [LibraryBloc] Clearing search and filters');
      }
      emit(currentState.clearFilters());
    }
  }

  void _onResetLibraryState(ResetLibraryStateEvent event, Emitter<LibraryState> emit) {
    if (kDebugMode) {
      print('🔄 [LibraryBloc] Resetting library state');
    }
    emit(const LibraryInitial());
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return (failure as ServerFailure).message;
      case NetworkFailure:
        return (failure as NetworkFailure).message;
      case CacheFailure:
        return (failure as CacheFailure).message;
      case AuthFailure:
        return (failure as AuthFailure).message;
      default:
        return 'Unexpected error occurred';
    }
  }
}