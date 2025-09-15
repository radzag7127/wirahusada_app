import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_beranda_data_usecase.dart';
import 'beranda_event.dart';
import 'beranda_state.dart';

class BerandaBloc extends Bloc<BerandaEvent, BerandaState> {
  final GetBerandaDataUseCase getBerandaDataUseCase;
  String? _currentUserNrm;

  BerandaBloc({required this.getBerandaDataUseCase})
    : super(const BerandaInitial()) {
    on<FetchBerandaDataEvent>(_onFetchBerandaData);
    on<RefreshBerandaDataEvent>(_onRefreshBerandaData);
  }

  Future<void> _onFetchBerandaData(
    FetchBerandaDataEvent event,
    Emitter<BerandaState> emit,
  ) async {
    emit(const BerandaLoading());

    final result = await getBerandaDataUseCase(NoParams());

    result.fold(
      (failure) => emit(BerandaError(message: _mapFailureToMessage(failure))),
      (berandaData) => emit(BerandaLoaded(data: berandaData)),
    );
  }

  Future<void> _onRefreshBerandaData(
    RefreshBerandaDataEvent event,
    Emitter<BerandaState> emit,
  ) async {
    // Always emit loading state for consistent behavior
    emit(const BerandaLoading());

    final result = await getBerandaDataUseCase(NoParams());

    result.fold(
      (failure) => emit(BerandaError(message: _mapFailureToMessage(failure))),
      (berandaData) => emit(BerandaLoaded(data: berandaData)),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return (failure as ServerFailure).message;
      case NetworkFailure:
        return (failure as NetworkFailure).message;
      case AuthFailure:
        return (failure as AuthFailure).message;
      case CacheFailure:
        return (failure as CacheFailure).message;
      default:
        return 'Terjadi kesalahan yang tidak terduga';
    }
  }

  // Method to update current user context
  void updateCurrentUser(String? nrm) {
    if (_currentUserNrm != nrm) {
      _currentUserNrm = nrm;
      // Reset state to initial when user changes
      add(const RefreshBerandaDataEvent());
    }
  }
}
