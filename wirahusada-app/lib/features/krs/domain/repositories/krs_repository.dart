// lib/features/krs/domain/repositories/krs_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/krs.dart';

abstract class KrsRepository {
  // PERBAIKAN: Update signature method
  Future<Either<Failure, Krs>> getKrs(int semesterKe, int jenisSemester);
}
