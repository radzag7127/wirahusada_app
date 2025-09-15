import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/payment.dart';
import '../repositories/payment_repository.dart';

class GetPaymentSummaryUseCase implements UseCase<PaymentSummary, NoParams> {
  final PaymentRepository repository;

  GetPaymentSummaryUseCase(this.repository);

  @override
  Future<Either<Failure, PaymentSummary>> call(NoParams params) async {
    return await repository.getPaymentSummary();
  }
}
