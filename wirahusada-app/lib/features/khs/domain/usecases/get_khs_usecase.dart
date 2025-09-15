// lib/features/khs/domain/usecases/get_khs_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/khs.dart';
import '../repositories/khs_repository.dart';

class GetKhsUseCase implements UseCase<Khs, KhsParams> {
  final KhsRepository repository;

  GetKhsUseCase(this.repository);

  @override
  Future<Either<Failure, Khs>> call(KhsParams params) async {
    // PERBAIKAN: Teruskan kedua parameter ke repository
    return await repository.getKhs(params.semesterKe, params.jenisSemester);
  }
}

class KhsParams extends Equatable {
  final int semesterKe;
  // PERBAIKAN: Tambahkan parameter jenisSemester
  final int jenisSemester;

  const KhsParams({required this.semesterKe, required this.jenisSemester});

  @override
  // PERBAIKAN: Tambahkan jenisSemester ke props
  List<Object> get props => [semesterKe, jenisSemester];
}
