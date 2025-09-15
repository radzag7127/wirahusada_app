// File: lib/features/krs/domain/entities/krs.dart

import 'package:equatable/equatable.dart';

class Krs extends Equatable {
  final int semesterKe;
  final String jenisSemester;
  final String tahunAjaran;
  final List<KrsCourse> mataKuliah;
  final int totalSks;

  const Krs({
    required this.semesterKe,
    required this.jenisSemester,
    required this.tahunAjaran,
    required this.mataKuliah,
    required this.totalSks,
  });

  @override
  List<Object?> get props => [
    semesterKe,
    jenisSemester,
    tahunAjaran,
    mataKuliah,
    totalSks,
  ];
}

class KrsCourse extends Equatable {
  final String kodeMataKuliah;
  final String namaMataKuliah;
  final int sks;
  final String? kelas;

  const KrsCourse({
    required this.kodeMataKuliah,
    required this.namaMataKuliah,
    required this.sks,
    this.kelas,
  });

  @override
  List<Object?> get props => [kodeMataKuliah, namaMataKuliah, sks, kelas];
}
