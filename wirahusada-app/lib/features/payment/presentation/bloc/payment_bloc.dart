import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/performance_utils.dart';
import '../../domain/entities/payment.dart';
import '../../domain/usecases/get_payment_history_usecase.dart';
import '../../domain/usecases/get_payment_summary_usecase.dart';
import '../../domain/usecases/get_transaction_detail_usecase.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final GetPaymentHistoryUseCase getPaymentHistoryUseCase;
  final GetPaymentSummaryUseCase getPaymentSummaryUseCase;
  final GetTransactionDetailUseCase getTransactionDetailUseCase;

  PaymentBloc({
    required this.getPaymentHistoryUseCase,
    required this.getPaymentSummaryUseCase,
    required this.getTransactionDetailUseCase,
  }) : super(const PaymentInitial()) {
    on<LoadPaymentHistoryEvent>(_onLoadPaymentHistory);
    on<LoadPaymentSummaryEvent>(_onLoadPaymentSummary);
    on<LoadTransactionDetailEvent>(_onLoadTransactionDetail);
    on<RefreshPaymentDataEvent>(_onRefreshPaymentData);
    on<ResetPaymentBlocEvent>(_onResetPaymentBloc);
    // RADICAL SOLUTION: Add aggressive payment loading events
    on<ForcePaymentRefreshEvent>(_onForcePaymentRefresh);
    on<PreemptivePaymentLoadEvent>(_onPreemptivePaymentLoad);
  }

  Future<void> _onLoadPaymentHistory(
    LoadPaymentHistoryEvent event,
    Emitter<PaymentState> emit,
  ) async {
    // Keep current history for a better refresh experience
    List<PaymentHistoryItem> currentHistory = [];
    if (state is PaymentHistoryLoaded) {
      currentHistory = (state as PaymentHistoryLoaded).historyItems;
    }

    // Show loading indicator only on initial load
    if (event.page == 1) {
      emit(const PaymentLoading());
    }

    try {
      // Execute payment history and summary requests in parallel for better performance
      final parallelResults = await PerformanceUtils.executeParallel<dynamic>(
        futures: {
          'history': () => getPaymentHistoryUseCase(
            PaymentHistoryParams(page: event.page, limit: event.limit),
          ),
          'summary': () => getPaymentSummaryUseCase(NoParams()),
        },
        timeout: const Duration(seconds: 30),
      );

      if (parallelResults['hasErrors']) {
        // Handle case where history succeeds but summary fails
        final historyResult = parallelResults['results']['history'];
        final summaryError = parallelResults['errors']['summary'];

        if (historyResult != null) {
          await historyResult.fold(
            (failure) async =>
                emit(PaymentError(message: _mapFailureToMessage(failure))),
            (newHistoryItems) async => emit(
              PaymentHistoryLoaded(
                historyItems: event.page == 1
                    ? newHistoryItems
                    : (currentHistory + newHistoryItems),
              ),
            ),
          );
        } else {
          emit(
            PaymentError(message: 'Failed to load payment data: $summaryError'),
          );
        }
      } else {
        // Both requests successful
        final historyResult = parallelResults['results']['history'];
        final summaryResult = parallelResults['results']['summary'];

        await historyResult.fold(
          (failure) async =>
              emit(PaymentError(message: _mapFailureToMessage(failure))),
          (newHistoryItems) async {
            await summaryResult.fold(
              (summaryFailure) async => emit(
                PaymentHistoryLoaded(
                  historyItems: event.page == 1
                      ? newHistoryItems
                      : (currentHistory + newHistoryItems),
                ),
              ),
              (summary) async => emit(
                PaymentHistoryLoaded(
                  historyItems: event.page == 1
                      ? newHistoryItems
                      : (currentHistory + newHistoryItems),
                  summary: summary,
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      emit(
        PaymentError(message: 'Failed to load payment data: ${e.toString()}'),
      );
    }
  }

  Future<void> _onLoadPaymentSummary(
    LoadPaymentSummaryEvent event,
    Emitter<PaymentState> emit,
  ) async {
    debugPrint('🔥 RADICAL: LoadPaymentSummary event received');
    emit(const PaymentLoading());

    final result = await getPaymentSummaryUseCase(NoParams());

    result.fold(
      (failure) {
        debugPrint('🔥 RADICAL: LoadPaymentSummary failed: ${_mapFailureToMessage(failure)}');
        emit(PaymentError(message: _mapFailureToMessage(failure)));
      },
      (summary) {
        debugPrint('🔥 RADICAL: LoadPaymentSummary successful');
        emit(PaymentSummaryLoaded(summary: summary));
      },
    );
  }

  Future<void> _onLoadTransactionDetail(
    LoadTransactionDetailEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading());

    final result = await getTransactionDetailUseCase(
      TransactionDetailParams(transactionId: event.transactionId),
    );

    await result.fold(
      (failure) async =>
          emit(PaymentError(message: _mapFailureToMessage(failure))),
      (transactionDetail) async =>
          emit(TransactionDetailLoaded(transactionDetail: transactionDetail)),
    );
  }

  Future<void> _onRefreshPaymentData(
    RefreshPaymentDataEvent event,
    Emitter<PaymentState> emit,
  ) async {
    debugPrint('🔥 RADICAL: RefreshPaymentData event received');
    // Clear cache before refreshing
    await _clearAllPaymentCaches();
    
    // Always emit loading state for consistent behavior
    emit(const PaymentLoading());

    final result = await getPaymentSummaryUseCase(NoParams());

    result.fold(
      (failure) {
        debugPrint('🔥 RADICAL: RefreshPaymentData failed: ${_mapFailureToMessage(failure)}');
        emit(PaymentError(message: _mapFailureToMessage(failure)));
      },
      (summary) {
        debugPrint('🔥 RADICAL: RefreshPaymentData successful');
        emit(PaymentSummaryLoaded(summary: summary));
      },
    );
  }

  Future<void> _onResetPaymentBloc(
    ResetPaymentBlocEvent event,
    Emitter<PaymentState> emit,
  ) async {
    // RADICAL SOLUTION: Clear all cached data aggressively
    await _clearAllPaymentCaches();
    debugPrint('🔥 RADICAL: PaymentBloc reset - all caches cleared');
    emit(const PaymentInitial());
  }

  /// RADICAL SOLUTION: Force payment refresh with aggressive clearing
  Future<void> _onForcePaymentRefresh(
    ForcePaymentRefreshEvent event,
    Emitter<PaymentState> emit,
  ) async {
    debugPrint('🔥 RADICAL: Force payment refresh initiated from ${event.debugSource}');
    
    if (event.clearCache) {
      await _clearAllPaymentCaches();
      debugPrint('🔥 RADICAL: All payment caches cleared before refresh');
    }
    
    // Always emit loading state to ensure UI updates
    emit(const PaymentLoading());
    
    try {
      final result = await getPaymentSummaryUseCase(NoParams());
      
      result.fold(
        (failure) {
          debugPrint('🔥 RADICAL: Force refresh failed: ${_mapFailureToMessage(failure)}');
          emit(PaymentError(message: _mapFailureToMessage(failure)));
        },
        (summary) {
          debugPrint('🔥 RADICAL: Force refresh successful - data loaded');
          emit(PaymentSummaryLoaded(summary: summary));
        },
      );
    } catch (e) {
      debugPrint('🔥 RADICAL: Force refresh exception: $e');
      emit(PaymentError(message: 'Force refresh failed: ${e.toString()}'));
    }
  }

  /// RADICAL SOLUTION: Preemptive payment loading for critical user scenarios
  Future<void> _onPreemptivePaymentLoad(
    PreemptivePaymentLoadEvent event,
    Emitter<PaymentState> emit,
  ) async {
    debugPrint('🔥 RADICAL: Preemptive payment load for user ${event.userNrm} from ${event.loadSource}');
    
    // Clear any existing data for this user
    await _clearUserSpecificPaymentCache(event.userNrm);
    
    // Force loading state
    emit(const PaymentLoading());
    
    try {
      final result = await getPaymentSummaryUseCase(NoParams());
      
      result.fold(
        (failure) {
          debugPrint('🔥 RADICAL: Preemptive load failed: ${_mapFailureToMessage(failure)}');
          emit(PaymentError(message: _mapFailureToMessage(failure)));
        },
        (summary) {
          debugPrint('🔥 RADICAL: Preemptive load successful for user ${event.userNrm}');
          emit(PaymentSummaryLoaded(summary: summary));
        },
      );
    } catch (e) {
      debugPrint('🔥 RADICAL: Preemptive load exception: $e');
      emit(PaymentError(message: 'Preemptive load failed: ${e.toString()}'));
    }
  }

  /// RADICAL SOLUTION: Clear all payment-related caches aggressively
  Future<void> _clearAllPaymentCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all payment-related keys
      final keys = prefs.getKeys().where((key) => 
        key.contains('payment') || 
        key.contains('wismon') ||
        key.contains('dashboard_preferences') ||
        key.contains('user_payment_data')
      ).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
        debugPrint('🔥 RADICAL: Cleared cache key: $key');
      }
      
      debugPrint('🔥 RADICAL: Cleared ${keys.length} payment cache keys');
    } catch (e) {
      debugPrint('🔥 RADICAL: Error clearing payment caches: $e');
    }
  }

  /// RADICAL SOLUTION: Clear user-specific payment cache
  Future<void> _clearUserSpecificPaymentCache(String userNrm) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear user-specific payment keys
      final keys = prefs.getKeys().where((key) => 
        key.contains(userNrm) && (
          key.contains('payment') || 
          key.contains('wismon') ||
          key.contains('dashboard')
        )
      ).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
        debugPrint('🔥 RADICAL: Cleared user cache key: $key');
      }
      
      debugPrint('🔥 RADICAL: Cleared ${keys.length} user-specific payment keys for $userNrm');
    } catch (e) {
      debugPrint('🔥 RADICAL: Error clearing user payment cache: $e');
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return (failure as ServerFailure).message;
      case NetworkFailure:
        return (failure as NetworkFailure).message;
      case CacheFailure:
        return (failure as CacheFailure).message;
      default:
        return 'Unexpected error occurred';
    }
  }
}
