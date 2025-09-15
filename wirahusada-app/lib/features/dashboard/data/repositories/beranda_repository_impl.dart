import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/entities/beranda.dart';
import '../../domain/repositories/beranda_repository.dart';
import '../models/beranda_model.dart';

class BerandaRepositoryImpl implements BerandaRepository {
  final ApiService apiService;

  BerandaRepositoryImpl({required this.apiService});

  @override
  Future<Either<Failure, BerandaData>> getBerandaData() async {
    try {
      final response = await apiService.get('/api/beranda');

      if (response['success'] == true && response['data'] != null) {
        final berandaModel = BerandaModel.fromJson(response['data']);
        return Right(berandaModel);
      } else {
        return Left(
          ServerFailure(response['message'] ?? 'Failed to fetch beranda data'),
        );
      }
    } catch (e) {
      return Left(ServerFailure('Network error: ${e.toString()}'));
    }
  }
}
