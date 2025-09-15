import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login(String namamNim, String nrm);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User>> getCurrentUser();
  Future<Either<Failure, String?>> getToken();
  Future<Either<Failure, void>> clearToken();
  Future<Either<Failure, bool>> refreshToken();
}
