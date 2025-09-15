import 'package:equatable/equatable.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/collection.dart';

abstract class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class LibraryInitial extends LibraryState {
  const LibraryInitial();
}

/// Loading state
class LibraryLoading extends LibraryState {
  const LibraryLoading();
}

/// State when collections are loaded successfully
class LibraryLoaded extends LibraryState {
  final List<Collection> collections;
  final String? selectedCategory;
  final String? selectedTopic;
  final String? searchQuery;
  final bool isSearchActive;

  const LibraryLoaded({
    required this.collections,
    this.selectedCategory,
    this.selectedTopic,
    this.searchQuery,
    this.isSearchActive = false,
  });

  /// Create a copy with updated values
  LibraryLoaded copyWith({
    List<Collection>? collections,
    String? selectedCategory,
    String? selectedTopic,
    String? searchQuery,
    bool? isSearchActive,
  }) {
    return LibraryLoaded(
      collections: collections ?? this.collections,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedTopic: selectedTopic ?? this.selectedTopic,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearchActive: isSearchActive ?? this.isSearchActive,
    );
  }

  /// Clear search and filters
  LibraryLoaded clearFilters() {
    return LibraryLoaded(
      collections: collections,
      selectedCategory: null,
      selectedTopic: null,
      searchQuery: null,
      isSearchActive: false,
    );
  }

  @override
  List<Object?> get props => [
        collections,
        selectedCategory,
        selectedTopic,
        searchQuery,
        isSearchActive,
      ];
}

/// State when a single collection is loaded (for detail view)
class CollectionDetailLoaded extends LibraryState {
  final Collection collection;

  const CollectionDetailLoaded({required this.collection});

  @override
  List<Object> get props => [collection];
}

/// State when borrow request is being submitted
class BorrowRequestSubmitting extends LibraryState {
  const BorrowRequestSubmitting();
}

/// State when borrow request is submitted successfully
class BorrowRequestSuccess extends LibraryState {
  final String message;

  const BorrowRequestSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

/// Error state
class LibraryError extends LibraryState {
  final String message;

  const LibraryError({required this.message});

  @override
  List<Object> get props => [message];
}

/// Empty state when no collections found
class LibraryEmpty extends LibraryState {
  final String message;

  const LibraryEmpty({required this.message});

  @override
  List<Object> get props => [message];
}