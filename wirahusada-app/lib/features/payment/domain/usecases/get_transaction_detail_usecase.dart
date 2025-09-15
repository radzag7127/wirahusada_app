import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class GetTransactionDetailUseCase
    implements UseCase<TransactionDetail, TransactionDetailParams> {
  final PaymentRepository repository;

  GetTransactionDetailUseCase(this.repository);

  @override
  Future<Either<Failure, TransactionDetail>> call(
    TransactionDetailParams params,
  ) async {
    return await repository.getTransactionDetail(params.transactionId);
  }
}

class TransactionDetailParams extends Equatable {
  final String transactionId;

  const TransactionDetailParams({required this.transactionId});

  @override
  List<Object> get props => [transactionId];
}
