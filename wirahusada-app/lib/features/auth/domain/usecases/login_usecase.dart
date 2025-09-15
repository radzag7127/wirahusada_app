import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase implements UseCase<User, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(LoginParams params) async {
    return await repository.login(params.namamNim, params.nrm);
  }
}

class LoginParams extends Equatable {
  final String namamNim;
  final String nrm;

  const LoginParams({required this.namamNim, required this.nrm});

  @override
  List<Object> get props => [namamNim, nrm];
}
