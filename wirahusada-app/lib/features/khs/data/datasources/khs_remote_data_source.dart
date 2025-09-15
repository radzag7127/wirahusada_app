// lib/features/khs/data/datasources/khs_remote_data_source.dart

import '../../../../core/services/api_service.dart';
import '../models/khs_model.dart';

abstract class KhsRemoteDataSource {
  // PERBAIKAN: Update signature method
  Future<KhsModel> getKhs(int semesterKe, int jenisSemester);
}

class KhsRemoteDataSourceImpl implements KhsRemoteDataSource {
  final ApiService apiService;

  KhsRemoteDataSourceImpl({required this.apiService});

  @override
  // PERBAIKAN: Update implementasi method
  Future<KhsModel> getKhs(int semesterKe, int jenisSemester) async {
    // Panggil method getKhs di ApiService yang sudah diperbarui
    return await apiService.getKhs(semesterKe, jenisSemester);
  }
}
