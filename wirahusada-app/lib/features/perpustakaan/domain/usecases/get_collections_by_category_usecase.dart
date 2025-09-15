import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/collection.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/repositories/library_repository.dart';

/// Use case for fetching collections by category
class GetCollectionsByCategoryUseCase implements UseCase<List<Collection>, CategoryParams> {
  final LibraryRepository repository;

  GetCollectionsByCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<Collection>>> call(CategoryParams params) async {
    return await repository.getCollectionsByCategory(params.category);
  }
}

/// Parameters for category-based collection fetching
class CategoryParams extends Equatable {
  final String category;

  const CategoryParams({required this.category});

  @override
  List<Object> get props => [category];
}