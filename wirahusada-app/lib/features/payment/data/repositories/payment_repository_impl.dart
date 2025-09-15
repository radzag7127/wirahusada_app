import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/entities/payment.dart';
import '../../domain/repositories/payment_repository.dart';
// import '../models/payment_model.dart'; // Unused import

class PaymentRepositoryImpl implements PaymentRepository {
  final ApiService apiService;

  PaymentRepositoryImpl({required this.apiService});

  @override
  Future<Either<Failure, List<PaymentHistoryItem>>> getPaymentHistory({
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
    String? type,
    String sortBy = 'tanggal',
    String sortOrder = 'desc',
  }) async {
    try {
      final historyModels = await apiService.getPaymentHistory(
        page: page,
        limit: limit,
        startDate: startDate,
        endDate: endDate,
        type: type,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );

      // Convert models to entities
      final List<PaymentHistoryItem> entities = historyModels
          .map((model) => model as PaymentHistoryItem)
          .toList();
      return Right(entities);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, PaymentSummary>> getPaymentSummary() async {
    try {
      if (kDebugMode) {
        print('💳 [PaymentRepository] Requesting payment summary...');
      }
      
      final summaryModel = await apiService.getPaymentSummary();
      
      if (kDebugMode) {
        print('✅ [PaymentRepository] Payment summary received successfully');
        print('📊 [PaymentRepository] Summary breakdown keys: ${summaryModel.breakdown.keys.toList()}');
        // Note: The model might not have a totalAmount field, so we'll skip this
      }
      
      return Right(summaryModel);
    } catch (e) {
      if (kDebugMode) {
        print('❌ [PaymentRepository] Error getting payment summary: $e');
        print('_STACK_TRACE_: ${StackTrace.current}');
      }
      
      // Check if it's a token-related error
      final errorMessage = e.toString();
      if (errorMessage.contains('Sesi telah berakhir') || 
          errorMessage.contains('token') ||
          errorMessage.contains('auth') ||
          errorMessage.contains('401')) {
        if (kDebugMode) {
          print('🔒 [PaymentRepository] Token-related error detected');
        }
        return Left(ServerFailure('Sesi telah berakhir, silakan login kembali'));
      }
      
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, TransactionDetail>> getTransactionDetail(
    String transactionId,
  ) async {
    try {
      final detailModel = await apiService.getTransactionDetail(transactionId);
      return Right(detailModel);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  @override
  Future<Either<Failure, bool>> refreshPaymentData() async {
    try {
      final refreshed = await apiService.refreshPaymentData();
      return Right(refreshed);
    } catch (e) {
      return Left(ServerFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
