// lib/features/transkrip/presentation/bloc/transkrip_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart';
import 'package:wismon_keuangan/features/transkrip/domain/entities/transkrip.dart';
import 'package:wismon_keuangan/features/transkrip/domain/usecases/get_transkrip_usecase.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_event.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_state.dart';

// --- PERUBAHAN: Import use case baru ---
import 'package:wismon_keuangan/features/transkrip/domain/usecases/propose_deletion_usecase.dart';

class TranskripBloc extends Bloc<TranskripEvent, TranskripState> {
  final GetTranskripUseCase getTranskripUseCase;
  // --- PERUBAHAN: Tambahkan use case baru ---
  final ProposeDeletionUseCase proposeDeletionUseCase;

  TranskripBloc({
    required this.getTranskripUseCase,
    // --- PERUBAHAN: Tambahkan ke constructor ---
    required this.proposeDeletionUseCase,
  }) : super(TranskripInitial()) {
    on<FetchTranskrip>(_onFetchTranskrip);
    // --- PERUBAHAN: Daftarkan event handler baru ---
    on<ProposeDeletionToggled>(_onProposeDeletionToggled);
  }

  Future<void> _onFetchTranskrip(
    FetchTranskrip event,
    Emitter<TranskripState> emit,
  ) async {
    emit(TranskripLoading());
    final result = await getTranskripUseCase(NoParams());
    result.fold(
      (failure) => emit(TranskripError(message: _mapFailureToMessage(failure))),
      (transkrip) => emit(TranskripLoaded(transkrip: transkrip)),
    );
  }

  // --- FUNGSI BARU: Handler untuk event usulan hapus ---
  Future<void> _onProposeDeletionToggled(
    ProposeDeletionToggled event,
    Emitter<TranskripState> emit,
  ) async {
    final currentState = state;
    if (currentState is TranskripLoaded) {
      // Panggil use case
      final result = await proposeDeletionUseCase(
        ProposeDeletionParams(course: event.courseToUpdate),
      );

      result.fold(
        (failure) {
          // Jika gagal, emit error
          emit(TranskripUpdateError(message: _mapFailureToMessage(failure)));
          // Kembalikan ke state semula setelah menampilkan error
          emit(currentState);
        },
        (success) {
          // Jika berhasil, update data secara lokal untuk respons UI yang cepat
          final updatedCourses = currentState.transkrip.courses.map((course) {
            // Cari mata kuliah yang cocok untuk diupdate statusnya
            if (course.kodeMataKuliah == event.courseToUpdate.kodeMataKuliah &&
                course.semesterKe == event.courseToUpdate.semesterKe) {
              return course.copyWith(usulanHapus: !course.usulanHapus);
            }
            return course;
          }).toList();

          final updatedTranskrip = Transkrip(
            ipk: currentState.transkrip.ipk,
            totalSks: currentState.transkrip.totalSks,
            courses: updatedCourses,
          );

          // Emit state sukses untuk feedback (misal: SnackBar) lalu emit state loaded dengan data baru
          emit(const TranskripUpdateSuccess());
          emit(TranskripLoaded(transkrip: updatedTranskrip));
        },
      );
    }
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message;
    } else {
      return 'Terjadi kesalahan yang tidak terduga.';
    }
  }
}
