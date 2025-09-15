import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/dashboard_preferences_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiService apiService;

  AuthRepositoryImpl({required this.apiService});

  @override
  Future<Either<Failure, User>> login(String namamNim, String nrm) async {
    try {
      final userModel = await apiService.login(namamNim, nrm);
      return Right(userModel);
    } catch (e) {
      return Left(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await apiService.clearAuthToken();
      // Also clear dashboard preferences on logout to prevent data leakage
      await DashboardPreferencesService().clearPreferences();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final userModel = await apiService.getProfile();
      return Right(userModel);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, String?>> getToken() async {
    try {
      final token = await apiService.getAuthToken();
      return Right(token);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearToken() async {
    try {
      await apiService.clearAuthToken();
      // Also clear dashboard preferences when clearing tokens
      await DashboardPreferencesService().clearPreferences();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> refreshToken() async {
    try {
      final success = await apiService.refreshToken();
      return Right(success);
    } catch (e) {
      return Left(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
