// File: lib/features/krs/presentation/bloc/krs_state.dart

part of 'krs_bloc.dart';

abstract class KrsState extends Equatable {
  const KrsState();

  @override
  List<Object?> get props => [];
}

class KrsInitial extends KrsState {}

class KrsLoading extends KrsState {}

class KrsLoaded extends KrsState {
  final Krs krs;

  const KrsLoaded({required this.krs});

  @override
  List<Object?> get props => [krs];
}

class KrsError extends KrsState {
  final String message;

  const KrsError({required this.message});

  @override
  List<Object> get props => [message];
}
