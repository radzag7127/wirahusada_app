import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/beranda.dart';

abstract class BerandaRepository {
  Future<Either<Failure, BerandaData>> getBerandaData();
}
