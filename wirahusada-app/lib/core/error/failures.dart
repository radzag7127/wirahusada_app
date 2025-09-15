import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure();
}

// General failures
class ServerFailure extends Failure {
  final String message;

  const ServerFailure(this.message);

  @override
  List<Object> get props => [message];
}

class CacheFailure extends Failure {
  final String message;

  const CacheFailure(this.message);

  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  final String message;

  const NetworkFailure(this.message);

  @override
  List<Object> get props => [message];
}

class AuthFailure extends Failure {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object> get props => [message];
}

class BorrowRequestFailure extends Failure {
  final String message;

  const BorrowRequestFailure(this.message);

  @override
  List<Object> get props => [message];
}
