// lib/features/transkrip/domain/usecases/get_transkrip_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart';
import 'package:wismon_keuangan/features/transkrip/domain/entities/transkrip.dart';
import 'package:wismon_keuangan/features/transkrip/domain/repositories/transkrip_repository.dart';

class GetTranskripUseCase implements UseCase<Transkrip, NoParams> {
  final TranskripRepository repository;

  GetTranskripUseCase(this.repository);

  // Kode ini sekarang sudah valid karena repository.getTranskrip()
  // tidak lagi memerlukan argumen.
  @override
  Future<Either<Failure, Transkrip>> call(NoParams params) async {
    return await repository.getTranskrip();
  }
}
