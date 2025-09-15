// lib/features/khs/data/models/khs_model.dart

import '../../domain/entities/khs.dart';

/// Model untuk mem-parsing data KHS dari JSON API.
class KhsModel extends Khs {
  const KhsModel({
    required super.semesterKe,
    required super.jenisSemester,
    required super.tahunAjaran,
    required super.mataKuliah,
    required super.rekapitulasi,
  });

  factory KhsModel.fromJson(Map<String, dynamic> json) {
    var list = json['mataKuliah'] as List;
    List<KhsCourse> mataKuliahList = list
        .map((i) => KhsCourseModel.fromJson(i))
        .toList();

    return KhsModel(
      semesterKe: json['semesterKe'] ?? 0,
      jenisSemester: json['jenisSemester'] ?? 'Tidak diketahui',
      tahunAjaran: json['tahunAjaran'] ?? '-',
      mataKuliah: mataKuliahList,
      rekapitulasi: RekapitulasiModel.fromJson(json['rekapitulasi']),
    );
  }
}

/// Model untuk mem-parsing data mata kuliah KHS dari JSON.
class KhsCourseModel extends KhsCourse {
  const KhsCourseModel({
    required super.nilai,
    required super.kodeMataKuliah,
    required super.namaMataKuliah,
    required super.sks,
    super.kelas,
  });

  factory KhsCourseModel.fromJson(Map<String, dynamic> json) {
    return KhsCourseModel(
      nilai: json['nilai'] ?? '-',
      kodeMataKuliah: json['kodeMataKuliah'] ?? '-',
      namaMataKuliah: json['namaMataKuliah'] ?? 'Mata Kuliah Tidak Ditemukan',
      sks: json['sks'] ?? 0,
      kelas: json['kelas'],
    );
  }
}

/// Model untuk mem-parsing data rekapitulasi dari JSON.
class RekapitulasiModel extends Rekapitulasi {
  const RekapitulasiModel({
    required super.ipSemester,
    required super.sksSemester,
    required super.ipKumulatif,
    required super.sksKumulatif,
  });

  factory RekapitulasiModel.fromJson(Map<String, dynamic> json) {
    return RekapitulasiModel(
      ipSemester: json['ipSemester'] ?? '0.00 / 0.00',
      sksSemester: json['sksSemester'] ?? '0 / 0',
      ipKumulatif: json['ipKumulatif'] ?? '0.00 / 0.00',
      sksKumulatif: json['sksKumulatif'] ?? '0 / 0',
    );
  }
}
