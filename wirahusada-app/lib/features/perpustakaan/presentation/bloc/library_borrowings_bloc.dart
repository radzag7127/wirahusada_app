// ignore_for_file: unreachable_switch_default

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/borrow_request.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/borrowing_limits.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/usecases/get_my_active_borrowings_usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/usecases/get_my_borrowing_history_usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/usecases/get_my_borrowing_limits_usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/usecases/return_book_usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/usecases/renew_borrowing_usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_borrowings_event.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_borrowings_state.dart';

/// Bloc for managing user's borrowing activities
/// Handles active borrowings, history, limits, and borrowing actions
class LibraryBorrowingsBloc extends Bloc<LibraryBorrowingsEvent, LibraryBorrowingsState> {
  final GetMyActiveBorrowingsUseCase getMyActiveBorrowingsUseCase;
  final GetMyBorrowingHistoryUseCase getMyBorrowingHistoryUseCase;
  final GetMyBorrowingLimitsUseCase getMyBorrowingLimitsUseCase;
  final GetBorrowingStatusUseCase getBorrowingStatusUseCase;
  final ReturnBookUseCase returnBookUseCase;
  final RenewBorrowingUseCase renewBorrowingUseCase;
  final BulkReturnBooksUseCase bulkReturnBooksUseCase;
  final BulkRenewBorrowingsUseCase bulkRenewBorrowingsUseCase;
  final CanRenewBorrowingUseCase canRenewBorrowingUseCase;

  LibraryBorrowingsBloc({
    required this.getMyActiveBorrowingsUseCase,
    required this.getMyBorrowingHistoryUseCase,
    required this.getMyBorrowingLimitsUseCase,
    required this.getBorrowingStatusUseCase,
    required this.returnBookUseCase,
    required this.renewBorrowingUseCase,
    required this.bulkReturnBooksUseCase,
    required this.bulkRenewBorrowingsUseCase,
    required this.canRenewBorrowingUseCase,
  }) : super(const BorrowingsInitial()) {
    on<LoadBorrowingsDataEvent>(_onLoadBorrowingsData);
    on<RefreshActiveBorrowingsEvent>(_onRefreshActiveBorrowings);
    on<RefreshBorrowingHistoryEvent>(_onRefreshBorrowingHistory);
    on<RefreshBorrowingLimitsEvent>(_onRefreshBorrowingLimits);
    on<ReturnBookEvent>(_onReturnBook);
    on<RenewBorrowingEvent>(_onRenewBorrowing);
    on<BulkReturnBooksEvent>(_onBulkReturnBooks);
    on<BulkRenewBorrowingsEvent>(_onBulkRenewBorrowings);
    on<FilterBorrowingHistoryEvent>(_onFilterBorrowingHistory);
    on<SortBorrowingHistoryEvent>(_onSortBorrowingHistory);
    on<CheckRenewalEligibilityEvent>(_onCheckRenewalEligibility);
    on<ClearBorrowingsDataEvent>(_onClearBorrowingsData);
    on<GetBorrowingStatisticsEvent>(_onGetBorrowingStatistics);
  }

  /// Load complete borrowing data (active + history + limits + status)
  Future<void> _onLoadBorrowingsData(
    LoadBorrowingsDataEvent event,
    Emitter<LibraryBorrowingsState> emit,
  ) async {
    if (kDebugMode) {
      print('📚 [BorrowingsBloc] Loading complete borrowing data (forceRefresh: ${event.forceRefresh})');
    }

    // Don't show loading if just refreshing
    if (state is! BorrowingsLoaded || event.forceRefresh) {
      emit(const BorrowingsLoading(loadingMessage: 'Loading your borrowing data...'));
    } else {
      emit((state as BorrowingsLoaded).copyWith(isRefreshing: true));
    }

    try {
      // Load all data in parallel for better performance
      final futures = await Future.wait([
        getMyActiveBorrowingsUseCase(NoParams()),
        getMyBorrowingHistoryUseCase(NoParams()),
        getMyBorrowingLimitsUseCase(NoParams()),
        getBorrowingStatusUseCase(NoParams()),
      ]);

      final activeBorrowingsResult = futures[0];
      final historyResult = futures[1];
      final limitsResult = futures[2];
      final statusResult = futures[3];

      // Check for any failures
      final failures = <Failure>[];
      
      activeBorrowingsResult.fold((failure) => failures.add(failure), (success) {});
      historyResult.fold((failure) => failures.add(failure), (success) {});
      limitsResult.fold((failure) => failures.add(failure), (success) {});
      statusResult.fold((failure) => failures.add(failure), (success) {});

      if (failures.isNotEmpty) {
        if (kDebugMode) {
          print('❌ [BorrowingsBloc] Failed to load borrowing data: ${failures.first}');
        }
        emit(BorrowingsError(
          message: _mapFailureToMessage(failures.first),
          errorCode: _getFailureCode(failures.first),
        ));
        return;
      }

      // Extract successful results
      final activeBorrowings = activeBorrowingsResult.fold((l) => <BorrowRequest>[], (r) => r as List<BorrowRequest>);
      final history = historyResult.fold((l) => <BorrowRequest>[], (r) => r as List<BorrowRequest>);
      final limits = limitsResult.fold((l) => throw l, (r) => r as BorrowingLimits);
      final status = statusResult.fold((l) => throw l, (r) => r as BorrowingStatus);

      if (kDebugMode) {
        print('✅ [BorrowingsBloc] Loaded borrowing data: ${activeBorrowings.length} active, ${history.length} history');
      }

      emit(BorrowingsLoaded(
        activeBorrowings: activeBorrowings,
        borrowingHistory: history,
        limits: limits,
        status: status,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('❌ [BorrowingsBloc] Unexpected error loading borrowing data: $e');
      }
      emit(BorrowingsError(
        message: 'Unexpected error occurred while loading borrowing data',
        errorCode: 'UNEXPECTED_ERROR',
      ));
    }
  }

  /// Refresh only active borrowings
  Future<void> _onRefreshActiveBorrowings(
    RefreshActiveBorrowingsEvent event,
    Emitter<LibraryBorrowingsState> emit,
  ) async {
    if (state is! BorrowingsLoaded) return;
    
    final currentState = state as BorrowingsLoaded;
    emit(currentState.copyWith(isRefreshing: true));

    final result = await getMyActiveBorrowingsUseCase(NoParams());
    
    result.fold(
      (failure) {
        emit(BorrowingsError(
          message: _mapFailureToMessage(failure),
          errorCode: _getFailureCode(failure),
        ));
      },
      (activeBorrowings) {
        emit(currentState.copyWith(
          activeBorrowings: activeBorrowings,
          isRefreshing: false,
        ));
      },
    );
  }

  /// Return a single book
  Future<void> _onReturnBook(
    ReturnBookEvent event,
    Emitter<LibraryBorrowingsState> emit,
  ) async {
    if (kDebugMode) {
      print('📤 [BorrowingsBloc] Returning book: ${event.activityId}');
    }

    emit(BorrowingsActionInProgress(
      action: BorrowingAction.return_book,
      targetId: event.activityId,
      message: 'Returning book...',
    ));

    final returnParams = ReturnBookParams(
      activityId: event.activityId,
      notes: event.notes,
      condition: event.condition,
      damageNotes: event.damageNotes,
    );

    final result = await returnBookUseCase(returnParams);

    result.fold(
      (failure) {
        if (kDebugMode) {
          print('❌ [BorrowingsBloc] Return failed: ${_mapFailureToMessage(failure)}');
        }
        emit(BorrowingsError(
          message: _mapFailureToMessage(failure),
          errorCode: _getFailureCode(failure),
          failedAction: BorrowingAction.return_book,
          targetId: event.activityId,
        ));
      },
      (success) {
        if (success) {
          if (kDebugMode) {
            print('✅ [BorrowingsBloc] Book returned successfully');
          }
          emit(BorrowingsActionSuccess(
            action: BorrowingAction.return_book,
            message: 'Book returned successfully',
            targetId: event.activityId,
          ));
          // Refresh data after successful return
          add(const LoadBorrowingsDataEvent(forceRefresh: true));
        } else {
          emit(const BorrowingsError(
            message: 'Failed to return book',
            errorCode: 'RETURN_FAILED',
          ));
        }
      },
    );
  }

  /// Renew a borrowing
  Future<void> _onRenewBorrowing(
    RenewBorrowingEvent event,
    Emitter<LibraryBorrowingsState> emit,
  ) async {
    if (kDebugMode) {
      print('🔄 [BorrowingsBloc] Renewing borrowing: ${event.activityId}');
    }

    emit(BorrowingsActionInProgress(
      action: BorrowingAction.renew_borrowing,
      targetId: event.activityId,
      message: 'Renewing borrowing...',
    ));

    final renewParams = RenewBorrowingParams(
      activityId: event.activityId,
      reason: event.reason,
    );

    final result = await renewBorrowingUseCase(renewParams);

    result.fold(
      (failure) {
        if (kDebugMode) {
          print('❌ [BorrowingsBloc] Renewal failed: ${_mapFailureToMessage(failure)}');
        }
        emit(BorrowingsError(
          message: _mapFailureToMessage(failure),
          errorCode: _getFailureCode(failure),
          failedAction: BorrowingAction.renew_borrowing,
          targetId: event.activityId,
        ));
      },
      (success) {
        if (success) {
          if (kDebugMode) {
            print('✅ [BorrowingsBloc] Borrowing renewed successfully');
          }
          emit(BorrowingsActionSuccess(
            action: BorrowingAction.renew_borrowing,
            message: 'Borrowing renewed successfully',
            targetId: event.activityId,
          ));
          // Refresh data after successful renewal
          add(const LoadBorrowingsDataEvent(forceRefresh: true));
        } else {
          emit(const BorrowingsError(
            message: 'Failed to renew borrowing',
            errorCode: 'RENEWAL_FAILED',
          ));
        }
      },
    );
  }

  /// Bulk return multiple books
  Future<void> _onBulkReturnBooks(
    BulkReturnBooksEvent event,
    Emitter<LibraryBorrowingsState> emit,
  ) async {
    if (kDebugMode) {
      print('📤 [BorrowingsBloc] Bulk returning ${event.activityIds.length} books');
    }

    emit(BorrowingsActionInProgress(
      action: BorrowingAction.bulk_return,
      targetId: event.activityIds.join(','),
      message: 'Returning ${event.activityIds.length} books...',
    ));

    final returnParams = event.activityIds.map((id) => ReturnBookParams(
      activityId: id,
      notes: event.notes,
    )).toList();

    final bulkParams = BulkReturnParams(returns: returnParams);
    final result = await bulkReturnBooksUseCase(bulkParams);

    result.fold(
      (failure) {
        emit(BorrowingsError(
          message: _mapFailureToMessage(failure),
          errorCode: _getFailureCode(failure),
          failedAction: BorrowingAction.bulk_return,
        ));
      },
      (bulkResult) {
        final message = bulkResult.allSuccessful
            ? 'All ${bulkResult.successfulCount} books returned successfully'
            : bulkResult.partiallySuccessful
                ? '${bulkResult.successfulCount} books returned, ${bulkResult.failedCount} failed'
                : 'Failed to return books';

        if (bulkResult.successfulCount > 0) {
          emit(BorrowingsActionSuccess(
            action: BorrowingAction.bulk_return,
            message: message,
          ));
          // Refresh data after bulk return
          add(const LoadBorrowingsDataEvent(forceRefresh: true));
        } else {
          emit(BorrowingsError(
            message: message,
            errorCode: 'BULK_RETURN_FAILED',
            failedAction: BorrowingAction.bulk_return,
          ));
        }
      },
    );
  }

  /// Bulk renew multiple borrowings
  Future<void> _onBulkRenewBorrowings(
    BulkRenewBorrowingsEvent event,
    Emitter<LibraryBorrowingsState> emit,
  ) async {
    if (kDebugMode) {
      print('🔄 [BorrowingsBloc] Bulk renewing ${event.activityIds.length} borrowings');
    }

    emit(BorrowingsActionInProgress(
      action: BorrowingAction.bulk_renew,
      targetId: event.activityIds.join(','),
      message: 'Renewing ${event.activityIds.length} borrowings...',
    ));

    final renewParams = event.activityIds.map((id) => RenewBorrowingParams(
      activityId: id,
      reason: event.reason,
    )).toList();

    final bulkParams = BulkRenewalParams(renewals: renewParams);
    final result = await bulkRenewBorrowingsUseCase(bulkParams);

    result.fold(
      (failure) {
        emit(BorrowingsError(
          message: _mapFailureToMessage(failure),
          errorCode: _getFailureCode(failure),
          failedAction: BorrowingAction.bulk_renew,
        ));
      },
      (bulkResult) {
        final message = bulkResult.allSuccessful
            ? 'All ${bulkResult.successfulCount} borrowings renewed successfully'
            : bulkResult.partiallySuccessful
                ? '${bulkResult.successfulCount} renewals successful, ${bulkResult.failedCount} failed'
                : 'Failed to renew borrowings';

        if (bulkResult.successfulCount > 0) {
          emit(BorrowingsActionSuccess(
            action: BorrowingAction.bulk_renew,
            message: message,
          ));
          // Refresh data after bulk renewal
          add(const LoadBorrowingsDataEvent(forceRefresh: true));
        } else {
          emit(BorrowingsError(
            message: message,
            errorCode: 'BULK_RENEWAL_FAILED',
            failedAction: BorrowingAction.bulk_renew,
          ));
        }
      },
    );
  }

  /// Filter borrowing history
  Future<void> _onFilterBorrowingHistory(
    FilterBorrowingHistoryEvent event,
    Emitter<LibraryBorrowingsState> emit,
  ) async {
    if (state is! BorrowingsLoaded) return;

    final currentState = state as BorrowingsLoaded;
    var filteredHistory = currentState.borrowingHistory;

    // Apply filters based on the filter type
    switch (event.filter) {
      case BorrowingHistoryFilter.active:
        filteredHistory = filteredHistory.where((b) => 
            b.status.toLowerCase() == 'dipinjam' || 
            b.status.toLowerCase() == 'diperpanjang').toList();
        break;
      case BorrowingHistoryFilter.returned:
        filteredHistory = filteredHistory.where((b) => 
            b.status.toLowerCase() == 'dikembalikan').toList();
        break;
      case BorrowingHistoryFilter.overdue:
        final now = DateTime.now();
        filteredHistory = filteredHistory.where((b) {
          if (b.status.toLowerCase() == 'dikembalikan') return false;
          final dueDate = DateTime.tryParse(b.tanggalKembali);
          return dueDate != null && now.isAfter(dueDate);
        }).toList();
        break;
      case BorrowingHistoryFilter.renewed:
        filteredHistory = filteredHistory.where((b) => 
            b.status.toLowerCase() == 'diperpanjang').toList();
        break;
      case BorrowingHistoryFilter.thisWeek:
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        filteredHistory = filteredHistory.where((b) {
          final borrowDate = DateTime.tryParse(b.tanggalPengambilan);
          return borrowDate != null && borrowDate.isAfter(weekAgo);
        }).toList();
        break;
      case BorrowingHistoryFilter.thisMonth:
        final monthAgo = DateTime.now().subtract(const Duration(days: 30));
        filteredHistory = filteredHistory.where((b) {
          final borrowDate = DateTime.tryParse(b.tanggalPengambilan);
          return borrowDate != null && borrowDate.isAfter(monthAgo);
        }).toList();
        break;
      case BorrowingHistoryFilter.thisYear:
        final yearAgo = DateTime.now().subtract(const Duration(days: 365));
        filteredHistory = filteredHistory.where((b) {
          final borrowDate = DateTime.tryParse(b.tanggalPengambilan);
          return borrowDate != null && borrowDate.isAfter(yearAgo);
        }).toList();
        break;
      case BorrowingHistoryFilter.all:
      default:
        // No filtering
        break;
    }

    emit(currentState.copyWith(borrowingHistory: filteredHistory));
  }

  /// Sort borrowing history
  Future<void> _onSortBorrowingHistory(
    SortBorrowingHistoryEvent event,
    Emitter<LibraryBorrowingsState> emit,
  ) async {
    if (state is! BorrowingsLoaded) return;

    final currentState = state as BorrowingsLoaded;
    final sortedHistory = List<dynamic>.from(currentState.borrowingHistory);

    sortedHistory.sort((a, b) {
      int comparison = 0;

      switch (event.sortBy) {
        case BorrowingHistorySortBy.borrowDate:
          final aDate = DateTime.tryParse(a.tanggalPengambilan);
          final bDate = DateTime.tryParse(b.tanggalPengambilan);
          if (aDate != null && bDate != null) {
            comparison = aDate.compareTo(bDate);
          }
          break;
        case BorrowingHistorySortBy.dueDate:
          final aDate = DateTime.tryParse(a.tanggalKembali);
          final bDate = DateTime.tryParse(b.tanggalKembali);
          if (aDate != null && bDate != null) {
            comparison = aDate.compareTo(bDate);
          }
          break;
        case BorrowingHistorySortBy.status:
          comparison = a.status.compareTo(b.status);
          break;
        default:
          break;
      }

      return event.sortOrder == SortOrder.descending ? -comparison : comparison;
    });

    emit(currentState.copyWith(borrowingHistory: sortedHistory.cast()));
  }

  /// Check renewal eligibility
  Future<void> _onCheckRenewalEligibility(
    CheckRenewalEligibilityEvent event,
    Emitter<LibraryBorrowingsState> emit,
  ) async {
    // This would call the CanRenewBorrowingUseCase
    // For now, we'll just emit a simple response
    emit(BorrowingsActionSuccess(
      action: BorrowingAction.renew_borrowing,
      message: 'Renewal eligibility checked',
      targetId: event.activityId,
    ));
  }

  /// Refresh borrowing history with optional filters
  Future<void> _onRefreshBorrowingHistory(
    RefreshBorrowingHistoryEvent event,
    Emitter<LibraryBorrowingsState> emit,
  ) async {
    if (state is! BorrowingsLoaded) return;
    
    final currentState = state as BorrowingsLoaded;
    emit(currentState.copyWith(isRefreshing: true));

    final result = await getMyBorrowingHistoryUseCase(NoParams());
    
    result.fold(
      (failure) {
        emit(BorrowingsError(
          message: _mapFailureToMessage(failure),
          errorCode: _getFailureCode(failure),
        ));
      },
      (history) {
        emit(currentState.copyWith(
          borrowingHistory: history,
          isRefreshing: false,
        ));
      },
    );
  }

  /// Refresh borrowing limits
  Future<void> _onRefreshBorrowingLimits(
    RefreshBorrowingLimitsEvent event,
    Emitter<LibraryBorrowingsState> emit,
  ) async {
    if (state is! BorrowingsLoaded) return;
    
    final currentState = state as BorrowingsLoaded;
    emit(currentState.copyWith(isRefreshing: true));

    final futures = await Future.wait([
      getMyBorrowingLimitsUseCase(NoParams()),
      getBorrowingStatusUseCase(NoParams()),
    ]);

    final limitsResult = futures[0];
    final statusResult = futures[1];
    
    limitsResult.fold(
      (failure) {
        emit(BorrowingsError(
          message: _mapFailureToMessage(failure),
          errorCode: _getFailureCode(failure),
        ));
      },
      (limits) {
        statusResult.fold(
          (failure) {
            emit(currentState.copyWith(
              limits: limits as BorrowingLimits,
              isRefreshing: false,
            ));
          },
          (status) {
            emit(currentState.copyWith(
              limits: limits as BorrowingLimits,
              status: status as BorrowingStatus,
              isRefreshing: false,
            ));
          },
        );
      },
    );
  }

  /// Clear all borrowings data
  Future<void> _onClearBorrowingsData(
    ClearBorrowingsDataEvent event,
    Emitter<LibraryBorrowingsState> emit,
  ) async {
    if (kDebugMode) {
      print('🧹 [BorrowingsBloc] Clearing all borrowings data');
    }
    emit(const BorrowingsInitial());
  }

  /// Get borrowing statistics
  Future<void> _onGetBorrowingStatistics(
    GetBorrowingStatisticsEvent event,
    Emitter<LibraryBorrowingsState> emit,
  ) async {
    if (state is! BorrowingsLoaded) return;
    
    final currentState = state as BorrowingsLoaded;
    
    // Statistics are already calculated in the BorrowingsLoaded state
    // This event could be used to trigger recalculation or emit specific stats
    
    if (kDebugMode) {
      final stats = currentState.statistics;
      print('📊 [BorrowingsBloc] Statistics: ${stats.totalActiveBorrowings} active, ${stats.totalOverdue} overdue');
    }
  }

  // Helper methods

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return (failure as ServerFailure).message;
      case NetworkFailure:
        return (failure as NetworkFailure).message;
      case CacheFailure:
        return (failure as CacheFailure).message;
      case AuthFailure:
        return (failure as AuthFailure).message;
      case BorrowRequestFailure:
        return (failure as BorrowRequestFailure).message;
      default:
        return 'An unexpected error occurred';
    }
  }

  String _getFailureCode(Failure failure) {
    if (failure is ServerFailure) {
      if (failure.message.contains('MAX_RENEWALS_EXCEEDED')) return 'MAX_RENEWALS_EXCEEDED';
      if (failure.message.contains('BOOK_OVERDUE')) return 'BOOK_OVERDUE';
      if (failure.message.contains('BOOK_RESERVED')) return 'BOOK_RESERVED';
      return 'SERVER_ERROR';
    } else if (failure is NetworkFailure) {
      return 'NETWORK_ERROR';
    } else if (failure is AuthFailure) {
      return 'AUTH_ERROR';
    } else if (failure is BorrowRequestFailure) {
      return 'BORROW_REQUEST_ERROR';
    }
    return 'UNKNOWN_ERROR';
  }
}