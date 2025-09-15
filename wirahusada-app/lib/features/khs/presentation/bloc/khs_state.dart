// lib/features/khs/presentation/bloc/khs_state.dart

part of 'khs_bloc.dart';

abstract class KhsState extends Equatable {
  const KhsState();

  @override
  List<Object?> get props => [];
}

class KhsInitial extends KhsState {}

class KhsLoading extends KhsState {}

class KhsLoaded extends KhsState {
  final Khs khs;

  const KhsLoaded({required this.khs});

  @override
  List<Object?> get props => [khs];
}

class KhsError extends KhsState {
  final String message;

  const KhsError({required this.message});

  @override
  List<Object> get props => [message];
}
