import 'package:equatable/equatable.dart';
import '../../domain/entities/beranda.dart';

abstract class BerandaState extends Equatable {
  const BerandaState();

  @override
  List<Object?> get props => [];
}

class BerandaInitial extends BerandaState {
  const BerandaInitial();
}

class BerandaLoading extends BerandaState {
  const BerandaLoading();
}

class BerandaLoaded extends BerandaState {
  final BerandaData data;

  const BerandaLoaded({required this.data});

  @override
  List<Object> get props => [data];
}

class BerandaError extends BerandaState {
  final String message;

  const BerandaError({required this.message});

  @override
  List<Object> get props => [message];
}
