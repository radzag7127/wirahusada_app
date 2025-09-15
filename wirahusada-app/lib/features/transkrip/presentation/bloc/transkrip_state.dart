// lib/features/transkrip/presentation/bloc/transkrip_state.dart
import 'package:equatable/equatable.dart';
import 'package:wismon_keuangan/features/transkrip/domain/entities/transkrip.dart';

abstract class TranskripState extends Equatable {
  const TranskripState();

  @override
  List<Object> get props => [];
}

class TranskripInitial extends TranskripState {}

class TranskripLoading extends TranskripState {}

class TranskripLoaded extends TranskripState {
  final Transkrip transkrip;

  const TranskripLoaded({required this.transkrip});

  @override
  List<Object> get props => [transkrip];
}

class TranskripError extends TranskripState {
  final String message;

  const TranskripError({required this.message});

  @override
  List<Object> get props => [message];
}

// --- STATE BARU: Untuk memberikan feedback ke UI ---
class TranskripUpdateSuccess extends TranskripState {
  const TranskripUpdateSuccess();
}

class TranskripUpdateError extends TranskripState {
  final String message;
  const TranskripUpdateError({required this.message});
  @override
  List<Object> get props => [message];
}
