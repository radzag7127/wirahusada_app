import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class GetPaymentHistoryUseCase
    implements UseCase<List<PaymentHistoryItem>, PaymentHistoryParams> {
  final PaymentRepository repository;

  GetPaymentHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<PaymentHistoryItem>>> call(
    PaymentHistoryParams params,
  ) async {
    return await repository.getPaymentHistory(
      page: params.page,
      limit: params.limit,
      startDate: params.startDate,
      endDate: params.endDate,
      type: params.type,
      sortBy: params.sortBy,
      sortOrder: params.sortOrder,
    );
  }
}

class PaymentHistoryParams extends Equatable {
  final int page;
  final int limit;
  final String? startDate;
  final String? endDate;
  final String? type;
  final String sortBy;
  final String sortOrder;

  const PaymentHistoryParams({
    this.page = 1,
    this.limit = 20,
    this.startDate,
    this.endDate,
    this.type,
    this.sortBy = 'tanggal',
    this.sortOrder = 'desc',
  });

  @override
  List<Object?> get props => [
    page,
    limit,
    startDate,
    endDate,
    type,
    sortBy,
    sortOrder,
  ];
}
