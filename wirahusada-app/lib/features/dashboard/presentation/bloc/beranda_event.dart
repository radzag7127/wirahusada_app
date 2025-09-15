import 'package:equatable/equatable.dart';

abstract class BerandaEvent extends Equatable {
  const BerandaEvent();

  @override
  List<Object> get props => [];
}

class FetchBerandaDataEvent extends BerandaEvent {
  const FetchBerandaDataEvent();
}

class RefreshBerandaDataEvent extends BerandaEvent {
  const RefreshBerandaDataEvent();
}
