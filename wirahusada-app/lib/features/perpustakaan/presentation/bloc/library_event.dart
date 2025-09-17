import 'package:equatable/equatable.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all collections
class LoadAllCollectionsEvent extends LibraryEvent {
  const LoadAllCollectionsEvent();
}

/// Event to load collections by category
class LoadCollectionsByCategoryEvent extends LibraryEvent {
  final String category;

  const LoadCollectionsByCategoryEvent(String s, {required this.category});

  @override
  List<Object> get props => [category];
}

/// Event to search collections by query
class SearchCollectionsEvent extends LibraryEvent {
  final String query;

  const SearchCollectionsEvent({required this.query});

  @override
  List<Object> get props => [query];
}

/// Event to load a specific collection by code
class LoadCollectionByCodeEvent extends LibraryEvent {
  final String kode;

  const LoadCollectionByCodeEvent({required this.kode});

  @override
  List<Object> get props => [kode];
}

/// Event to filter collections by topic
class FilterCollectionsByTopicEvent extends LibraryEvent {
  final String topic;

  const FilterCollectionsByTopicEvent({required this.topic});

  @override
  List<Object> get props => [topic];
}

/// Event to submit a borrow request
class SubmitBorrowRequestEvent extends LibraryEvent {
  final String nrm;
  final String kode;
  final String tanggalPengambilan;
  final String tanggalKembali;
  final String? notes;

  const SubmitBorrowRequestEvent({
    required this.nrm,
    required this.kode,
    required this.tanggalPengambilan,
    required this.tanggalKembali,
    this.notes,
  });

  @override
  List<Object?> get props => [nrm, kode, tanggalPengambilan, tanggalKembali, notes];
}

/// Event to clear search results
class ClearSearchEvent extends LibraryEvent {
  const ClearSearchEvent();
}

/// Event to reset library state
class ResetLibraryStateEvent extends LibraryEvent {
  const ResetLibraryStateEvent();
}