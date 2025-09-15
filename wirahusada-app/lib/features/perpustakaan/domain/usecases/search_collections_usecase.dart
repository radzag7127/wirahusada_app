import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/collection.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/repositories/library_repository.dart';

/// Use case for searching collections by query
class SearchCollectionsUseCase implements UseCase<List<Collection>, SearchParams> {
  final LibraryRepository repository;

  SearchCollectionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Collection>>> call(SearchParams params) async {
    return await repository.searchCollections(params.query);
  }
}

/// Parameters for collection search
class SearchParams extends Equatable {
  final String query;

  const SearchParams({required this.query});

  @override
  List<Object> get props => [query];
}