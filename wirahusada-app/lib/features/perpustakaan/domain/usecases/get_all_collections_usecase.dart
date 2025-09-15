import 'package:dartz/dartz.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/collection.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/repositories/library_repository.dart';

/// Use case for fetching all library collections
class GetAllCollectionsUseCase implements UseCase<List<Collection>, NoParams> {
  final LibraryRepository repository;

  GetAllCollectionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Collection>>> call(NoParams params) async {
    return await repository.getAllCollections();
  }
}