// lib/features/khs/presentation/bloc/khs_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/khs.dart';
import '../../domain/usecases/get_khs_usecase.dart';

part 'khs_event.dart';
part 'khs_state.dart';

class KhsBloc extends Bloc<KhsEvent, KhsState> {
  final GetKhsUseCase getKhsUseCase;

  KhsBloc({required this.getKhsUseCase}) : super(KhsInitial()) {
    on<FetchKhsData>(_onFetchKhsData);
  }

  Future<void> _onFetchKhsData(
    FetchKhsData event,
    Emitter<KhsState> emit,
  ) async {
    emit(KhsLoading());
    // PERBAIKAN: Gunakan kedua parameter saat memanggil use case
    final result = await getKhsUseCase(
      KhsParams(
        semesterKe: event.semesterKe,
        jenisSemester: event.jenisSemester,
      ),
    );
    result.fold(
      (failure) => emit(KhsError(message: _mapFailureToMessage(failure))),
      (khs) => emit(KhsLoaded(khs: khs)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return (failure as ServerFailure).message;
      case NetworkFailure:
        return (failure as NetworkFailure).message;
      default:
        return 'Unexpected error occurred';
    }
  }
}
