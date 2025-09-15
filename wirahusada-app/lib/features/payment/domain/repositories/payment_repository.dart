import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/payment.dart';

abstract class PaymentRepository {
  Future<Either<Failure, List<PaymentHistoryItem>>> getPaymentHistory({
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
    String? type,
    String sortBy = 'tanggal',
    String sortOrder = 'desc',
  });

  Future<Either<Failure, PaymentSummary>> getPaymentSummary();

  Future<Either<Failure, TransactionDetail>> getTransactionDetail(
    String transactionId,
  );

  Future<Either<Failure, bool>> refreshPaymentData();
}
