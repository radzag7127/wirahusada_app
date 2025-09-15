// lib/features/krs/domain/usecases/get_krs_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/krs.dart';
import '../repositories/krs_repository.dart';

class GetKrsUseCase implements UseCase<Krs, KrsParams> {
  final KrsRepository repository;

  GetKrsUseCase(this.repository);

  @override
  Future<Either<Failure, Krs>> call(KrsParams params) async {
    // PERBAIKAN: Teruskan kedua parameter ke repository
    return await repository.getKrs(params.semesterKe, params.jenisSemester);
  }
}

class KrsParams extends Equatable {
  final int semesterKe;
  // PERBAIKAN: Tambahkan parameter jenisSemester
  final int jenisSemester;

  const KrsParams({required this.semesterKe, required this.jenisSemester});

  @override
  // PERBAIKAN: Tambahkan jenisSemester ke props
  List<Object> get props => [semesterKe, jenisSemester];
}
