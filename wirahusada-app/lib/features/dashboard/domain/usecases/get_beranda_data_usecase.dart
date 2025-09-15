import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/beranda.dart';
import '../repositories/beranda_repository.dart';

class GetBerandaDataUseCase implements UseCase<BerandaData, NoParams> {
  final BerandaRepository repository;

  GetBerandaDataUseCase(this.repository);

  @override
  Future<Either<Failure, BerandaData>> call(NoParams params) async {
    return await repository.getBerandaData();
  }
}
