// lib/features/transkrip/domain/entities/transkrip.dart
import 'package:equatable/equatable.dart';

class Transkrip extends Equatable {
  final String ipk;
  final int totalSks;
  final List<Course> courses;

  const Transkrip({
    required this.ipk,
    required this.totalSks,
    required this.courses,
  });

  @override
  List<Object?> get props => [ipk, totalSks, courses];
}

class Course extends Equatable {
  final String kodeMataKuliah;
  final String kurikulum;
  final String namamk;
  final int? sks;
  final String? nilai;
  final double? bobotNilai;
  final int semesterKe;
  // --- PERUBAHAN: Menambahkan properti untuk status usulan hapus ---
  final bool usulanHapus;

  const Course({
    required this.kodeMataKuliah,
    required this.kurikulum,
    required this.namamk,
    this.sks,
    this.nilai,
    this.bobotNilai,
    required this.semesterKe,
    // --- PERUBAHAN: Menambahkan properti ke constructor dengan nilai default ---
    this.usulanHapus = false,
  });

  // --- FUNGSI BARU: copyWith untuk memudahkan update state di BLoC ---
  Course copyWith({bool? usulanHapus}) {
    return Course(
      kodeMataKuliah: kodeMataKuliah,
      kurikulum: kurikulum,
      namamk: namamk,
      sks: sks,
      nilai: nilai,
      bobotNilai: bobotNilai,
      semesterKe: semesterKe,
      usulanHapus: usulanHapus ?? this.usulanHapus,
    );
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      kodeMataKuliah: json['kodeMataKuliah'] ?? '-',
      kurikulum: json['kurikulum'] ?? '-',
      namamk: json['namamk'] ?? 'N/A',
      sks: json['sks'],
      nilai: json['nilai'],
      bobotNilai: (json['bobotNilai'] as num?)?.toDouble(),
      semesterKe: json['semesterKe'] ?? 0,
      // --- PERUBAHAN: Membaca 'usulanHapus' dari JSON. Backend mengirim 0 atau 1, jadi kita konversi ke boolean ---
      usulanHapus: (json['usulanHapus'] == 1 || json['usulanHapus'] == true),
    );
  }

  @override
  List<Object?> get props => [
    kodeMataKuliah,
    kurikulum,
    namamk,
    sks,
    nilai,
    bobotNilai,
    semesterKe,
    // --- PERUBAHAN: Menambahkan properti ke props untuk perbandingan objek ---
    usulanHapus,
  ];
}
