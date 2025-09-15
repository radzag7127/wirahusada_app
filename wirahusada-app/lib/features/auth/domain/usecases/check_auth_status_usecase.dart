import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class CheckAuthStatusUseCase implements UseCase<User?, NoParams> {
  final AuthRepository repository;

  CheckAuthStatusUseCase(this.repository);

  @override
  Future<Either<Failure, User?>> call(NoParams params) async {
    final tokenResult = await repository.getToken();

    return tokenResult.fold((failure) => Left(failure), (token) async {
      if (token == null) {
        return const Right(null);
      }

      final userResult = await repository.getCurrentUser();
      return userResult.fold((failure) => Left(failure), (user) => Right(user));
    });
  }
}
