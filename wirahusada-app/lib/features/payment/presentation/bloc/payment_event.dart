import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class LoadPaymentHistoryEvent extends PaymentEvent {
  final int page;
  final int limit;
  final String? startDate;
  final String? endDate;
  final String? type;
  final String sortBy;
  final String sortOrder;

  const LoadPaymentHistoryEvent({
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

class LoadPaymentSummaryEvent extends PaymentEvent {
  const LoadPaymentSummaryEvent();
}

class LoadTransactionDetailEvent extends PaymentEvent {
  final String transactionId;

  const LoadTransactionDetailEvent({required this.transactionId});

  @override
  List<Object> get props => [transactionId];
}

class RefreshPaymentDataEvent extends PaymentEvent {
  const RefreshPaymentDataEvent();
}

class ResetPaymentBlocEvent extends PaymentEvent {
  const ResetPaymentBlocEvent();
}

/// RADICAL SOLUTION: Force payment data loading with aggressive refresh
class ForcePaymentRefreshEvent extends PaymentEvent {
  final bool clearCache;
  final bool bypassCurrentState;
  final String debugSource;
  
  const ForcePaymentRefreshEvent({
    this.clearCache = true,
    this.bypassCurrentState = true,
    this.debugSource = 'unknown',
  });
  
  @override
  List<Object> get props => [clearCache, bypassCurrentState, debugSource];
}

/// RADICAL SOLUTION: Pre-emptive payment loading for critical scenarios
class PreemptivePaymentLoadEvent extends PaymentEvent {
  final String userNrm;
  final String loadSource;
  
  const PreemptivePaymentLoadEvent({
    required this.userNrm,
    required this.loadSource,
  });
  
  @override
  List<Object> get props => [userNrm, loadSource];
}
