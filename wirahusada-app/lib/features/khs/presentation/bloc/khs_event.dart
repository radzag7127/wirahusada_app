// lib/features/khs/presentation/bloc/khs_event.dart

part of 'khs_bloc.dart';

abstract class KhsEvent extends Equatable {
  const KhsEvent();

  @override
  List<Object> get props => [];
}

class FetchKhsData extends KhsEvent {
  final int semesterKe;
  // PERBAIKAN: Tambahkan parameter jenisSemester
  final int jenisSemester;

  const FetchKhsData({required this.semesterKe, required this.jenisSemester});

  @override
  // PERBAIKAN: Tambahkan jenisSemester ke props
  List<Object> get props => [semesterKe, jenisSemester];
}
