// lib/features/krs/data/datasources/krs_remote_data_source.dart

import '../../../../core/services/api_service.dart';
import '../models/krs_model.dart';

abstract class KrsRemoteDataSource {
  // PERBAIKAN: Update signature method
  Future<KrsModel> getKrs(int semesterKe, int jenisSemester);
}

class KrsRemoteDataSourceImpl implements KrsRemoteDataSource {
  final ApiService apiService;

  KrsRemoteDataSourceImpl({required this.apiService});

  @override
  // PERBAIKAN: Update implementasi method
  Future<KrsModel> getKrs(int semesterKe, int jenisSemester) async {
    // Panggil method getKrs di ApiService yang sudah diperbarui
    return await apiService.getKrs(semesterKe, jenisSemester);
  }
}
