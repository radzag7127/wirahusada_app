// lib/features/khs/domain/entities/khs.dart

import 'package:equatable/equatable.dart';

/// Merepresentasikan objek KHS secara keseluruhan.
class Khs extends Equatable {
  final int semesterKe;
  final String jenisSemester;
  final String tahunAjaran;
  final List<KhsCourse> mataKuliah;
  final Rekapitulasi rekapitulasi;

  const Khs({
    required this.semesterKe,
    required this.jenisSemester,
    required this.tahunAjaran,
    required this.mataKuliah,
    required this.rekapitulasi,
  });

  @override
  List<Object> get props => [
    semesterKe,
    jenisSemester,
    tahunAjaran,
    mataKuliah,
    rekapitulasi,
  ];
}

/// Merepresentasikan satu mata kuliah dalam KHS.
class KhsCourse extends Equatable {
  final String nilai;
  final String kodeMataKuliah;
  final String namaMataKuliah;
  final int sks;
  final String? kelas;

  const KhsCourse({
    required this.nilai,
    required this.kodeMataKuliah,
    required this.namaMataKuliah,
    required this.sks,
    this.kelas,
  });

  @override
  List<Object?> get props => [
    nilai,
    kodeMataKuliah,
    namaMataKuliah,
    sks,
    kelas,
  ];
}

/// Merepresentasikan rekapitulasi IP dan SKS.
class Rekapitulasi extends Equatable {
  final String ipSemester;
  final String sksSemester;
  final String ipKumulatif;
  final String sksKumulatif;

  const Rekapitulasi({
    required this.ipSemester,
    required this.sksSemester,
    required this.ipKumulatif,
    required this.sksKumulatif,
  });

  @override
  List<Object> get props => [
    ipSemester,
    sksSemester,
    ipKumulatif,
    sksKumulatif,
  ];
}
