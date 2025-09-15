import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class LoginRequestedEvent extends AuthEvent {
  final String namamNim;
  final String nrm;

  const LoginRequestedEvent({required this.namamNim, required this.nrm});

  @override
  List<Object> get props => [namamNim, nrm];
}

class LogoutRequestedEvent extends AuthEvent {
  const LogoutRequestedEvent();
}

class TokenRefreshRequestedEvent extends AuthEvent {
  const TokenRefreshRequestedEvent();
}
