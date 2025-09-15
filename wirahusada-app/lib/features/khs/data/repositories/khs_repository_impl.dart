// lib/features/khs/data/repositories/khs_repository_impl.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/khs.dart';
import '../../domain/repositories/khs_repository.dart';
import '../datasources/khs_remote_data_source.dart';

class KhsRepositoryImpl implements KhsRepository {
  final KhsRemoteDataSource remoteDataSource;

  KhsRepositoryImpl({required this.remoteDataSource});

  @override
  // PERBAIKAN: Update implementasi method
  Future<Either<Failure, Khs>> getKhs(int semesterKe, int jenisSemester) async {
    try {
      final khsModel = await remoteDataSource.getKhs(semesterKe, jenisSemester);
      return Right(khsModel);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
