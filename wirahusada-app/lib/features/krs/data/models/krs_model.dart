// File: lib/features/krs/data/models/krs_model.dart

import '../../domain/entities/krs.dart';

// Model untuk merepresentasikan data mentah dari JSON API
class KrsModel extends Krs {
  const KrsModel({
    required super.semesterKe,
    required super.jenisSemester,
    required super.tahunAjaran,
    required super.mataKuliah,
    required super.totalSks,
  });

  factory KrsModel.fromJson(Map<String, dynamic> json) {
    var list = json['mataKuliah'] as List;
    List<KrsCourse> mataKuliahList = list
        .map((i) => KrsCourseModel.fromJson(i))
        .toList();

    return KrsModel(
      semesterKe: json['semesterKe'] ?? 0,
      jenisSemester: json['jenisSemester'] ?? 'Tidak diketahui',
      tahunAjaran: json['tahunAjaran'] ?? '-',
      mataKuliah: mataKuliahList,
      totalSks: json['totalSks'] ?? 0,
    );
  }
}

class KrsCourseModel extends KrsCourse {
  const KrsCourseModel({
    required super.kodeMataKuliah,
    required super.namaMataKuliah,
    required super.sks,
    super.kelas,
  });

  factory KrsCourseModel.fromJson(Map<String, dynamic> json) {
    return KrsCourseModel(
      kodeMataKuliah: json['kodeMataKuliah'] ?? '-',
      namaMataKuliah: json['namaMataKuliah'] ?? 'Mata Kuliah Tidak Ditemukan',
      sks: json['sks'] ?? 0,
      kelas: json['kelas'],
    );
  }
}
