// FILE BARU: lib/features/transkrip/domain/usecases/propose_deletion_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart';
import 'package:wismon_keuangan/features/transkrip/domain/entities/transkrip.dart';
import 'package:wismon_keuangan/features/transkrip/domain/repositories/transkrip_repository.dart';

// Use case ini bertanggung jawab untuk satu tugas: mengusulkan penghapusan.
class ProposeDeletionUseCase implements UseCase<bool, ProposeDeletionParams> {
  final TranskripRepository repository;
  ProposeDeletionUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(ProposeDeletionParams params) async {
    return await repository.proposeCourseDeletion(params.course);
  }
}

// Parameter yang dibutuhkan oleh use case ini.
class ProposeDeletionParams extends Equatable {
  final Course course;
  const ProposeDeletionParams({required this.course});

  @override
  List<Object> get props => [course];
}
