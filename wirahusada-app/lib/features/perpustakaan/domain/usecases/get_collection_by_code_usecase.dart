import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/collection.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/repositories/library_repository.dart';

/// Use case for fetching a specific collection by its code
class GetCollectionByCodeUseCase implements UseCase<Collection, CollectionCodeParams> {
  final LibraryRepository repository;

  GetCollectionByCodeUseCase(this.repository);

  @override
  Future<Either<Failure, Collection>> call(CollectionCodeParams params) async {
    return await repository.getCollectionByCode(params.kode);
  }
}

/// Parameters for fetching collection by code
class CollectionCodeParams extends Equatable {
  final String kode;

  const CollectionCodeParams({required this.kode});

  @override
  List<Object> get props => [kode];
}