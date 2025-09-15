import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../services/api_service.dart';
import '../services/dashboard_preferences_service.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/check_auth_status_usecase.dart';
import '../../features/auth/domain/usecases/refresh_token_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/payment/data/repositories/payment_repository_impl.dart';
import '../../features/payment/domain/repositories/payment_repository.dart';
import '../../features/payment/domain/usecases/get_payment_history_usecase.dart';
import '../../features/payment/domain/usecases/get_payment_summary_usecase.dart';
import '../../features/payment/domain/usecases/get_transaction_detail_usecase.dart';
import '../../features/payment/presentation/bloc/payment_bloc.dart';

// IMPORT BARU UNTUK FITUR KRS
import '../../features/krs/data/datasources/krs_remote_data_source.dart';
import '../../features/krs/data/repositories/krs_repository_impl.dart';
import '../../features/krs/domain/repositories/krs_repository.dart';
import '../../features/krs/domain/usecases/get_krs_usecase.dart';
import '../../features/krs/presentation/bloc/krs_bloc.dart';

// --- IMPORT BARU UNTUK FITUR KHS ---
import '../../features/khs/data/datasources/khs_remote_data_source.dart';
import '../../features/khs/data/repositories/khs_repository_impl.dart';
import '../../features/khs/domain/repositories/khs_repository.dart';
import '../../features/khs/domain/usecases/get_khs_usecase.dart';
import '../../features/khs/presentation/bloc/khs_bloc.dart';

// --- IMPORT UNTUK FITUR TRANSKRIP ---
import 'package:wismon_keuangan/features/transkrip/data/repositories/transkrip_repository_impl.dart';
import 'package:wismon_keuangan/features/transkrip/domain/repositories/transkrip_repository.dart';
import 'package:wismon_keuangan/features/transkrip/domain/usecases/get_transkrip_usecase.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_bloc.dart';

// --- PERUBAHAN: Import use case baru yang akan kita daftarkan ---
import 'package:wismon_keuangan/features/transkrip/domain/usecases/propose_deletion_usecase.dart';

// --- IMPORT UNTUK FITUR BERANDA ---
import '../../features/dashboard/data/repositories/beranda_repository_impl.dart';
import '../../features/dashboard/domain/repositories/beranda_repository.dart';
import '../../features/dashboard/domain/usecases/get_beranda_data_usecase.dart';
import '../../features/dashboard/presentation/bloc/beranda_bloc.dart';

// --- IMPORT UNTUK FITUR PERPUSTAKAAN ---
import '../../features/perpustakaan/data/datasources/library_remote_data_source.dart';
import '../../features/perpustakaan/data/datasources/library_remote_data_source_impl.dart';
import '../../features/perpustakaan/data/repositories/library_repository_impl.dart';
import '../../features/perpustakaan/domain/repositories/library_repository.dart';
import '../../features/perpustakaan/domain/usecases/get_all_collections_usecase.dart';
import '../../features/perpustakaan/domain/usecases/get_collections_by_category_usecase.dart';
import '../../features/perpustakaan/domain/usecases/search_collections_usecase.dart';
import '../../features/perpustakaan/domain/usecases/get_collection_by_code_usecase.dart';
import '../../features/perpustakaan/domain/usecases/submit_borrow_request_usecase.dart';
import '../../features/perpustakaan/domain/usecases/get_my_active_borrowings_usecase.dart';
import '../../features/perpustakaan/domain/usecases/get_my_borrowing_history_usecase.dart';
import '../../features/perpustakaan/domain/usecases/get_my_borrowing_limits_usecase.dart';
import '../../features/perpustakaan/domain/usecases/return_book_usecase.dart';
import '../../features/perpustakaan/domain/usecases/renew_borrowing_usecase.dart';
// Future features:
// import '../../features/perpustakaan/domain/usecases/get_popular_collections_usecase.dart';
// import '../../features/perpustakaan/domain/usecases/advanced_search_usecase.dart';
import '../../features/perpustakaan/presentation/bloc/library_bloc.dart';
import '../../features/perpustakaan/presentation/bloc/library_borrowings_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton<ApiService>(() => ApiService());
  sl.registerLazySingleton<DashboardPreferencesService>(
    () => DashboardPreferencesService(),
  );
  sl.registerLazySingleton<RouteObserver<PageRoute>>(() => RouteObserver());

  // Auth Feature
  // Data sources & repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(apiService: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));
  sl.registerLazySingleton(() => RefreshTokenUseCase(sl()));

  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      checkAuthStatusUseCase: sl(),
      refreshTokenUseCase: sl(),
    ),
  );

  // Payment Feature
  // Data sources & repositories
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentRepositoryImpl(apiService: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetPaymentHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetPaymentSummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetTransactionDetailUseCase(sl()));

  // Bloc
  sl.registerFactory(
    () => PaymentBloc(
      getPaymentHistoryUseCase: sl(),
      getPaymentSummaryUseCase: sl(),
      getTransactionDetailUseCase: sl(),
    ),
  );

  // =================================================================
  // Transkrip Feature
  // =================================================================
  sl.registerLazySingleton<TranskripRepository>(
    () => TranskripRepositoryImpl(apiService: sl()),
  );

  sl.registerLazySingleton(() => GetTranskripUseCase(sl()));

  // --- PERUBAHAN: Daftarkan use case baru untuk usulan hapus ---
  sl.registerLazySingleton(() => ProposeDeletionUseCase(sl()));

  sl.registerFactory(
    () => TranskripBloc(
      getTranskripUseCase: sl(),
      // --- PERBAIKAN: Sediakan use case yang dibutuhkan oleh BLoC ---
      proposeDeletionUseCase: sl(),
    ),
  );

  // --- BLOK BARU UNTUK FITUR KRS ---
  // Bloc
  sl.registerFactory(() => KrsBloc(getKrsUseCase: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetKrsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<KrsRepository>(
    () => KrsRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<KrsRemoteDataSource>(
    () => KrsRemoteDataSourceImpl(apiService: sl()),
  );

  // --- BLOK BARU UNTUK FITUR KHS ---
  // Data sources
  sl.registerLazySingleton<KhsRemoteDataSource>(
    () => KhsRemoteDataSourceImpl(apiService: sl()),
  );
  // Repository
  sl.registerLazySingleton<KhsRepository>(
    () => KhsRepositoryImpl(remoteDataSource: sl()),
  );
  // Use cases
  sl.registerLazySingleton(() => GetKhsUseCase(sl()));
  // Bloc
  sl.registerFactory(() => KhsBloc(getKhsUseCase: sl()));

  // --- BERANDA FEATURE ---
  // Repository
  sl.registerLazySingleton<BerandaRepository>(
    () => BerandaRepositoryImpl(apiService: sl()),
  );
  // Use cases
  sl.registerLazySingleton(() => GetBerandaDataUseCase(sl()));
  // Bloc
  sl.registerFactory(() => BerandaBloc(getBerandaDataUseCase: sl()));

  // =================================================================
  // PERPUSTAKAAN (Library) FEATURE
  // =================================================================

  // Data sources
  sl.registerLazySingleton<LibraryRemoteDataSource>(
    () => LibraryRemoteDataSourceImpl(apiService: sl()),
  );

  // Repository
  sl.registerLazySingleton<LibraryRepository>(
    () => LibraryRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases for LibraryBloc
  sl.registerLazySingleton(() => GetAllCollectionsUseCase(sl()));
  sl.registerLazySingleton(() => GetCollectionsByCategoryUseCase(sl()));
  sl.registerLazySingleton(() => SearchCollectionsUseCase(sl()));
  sl.registerLazySingleton(() => GetCollectionByCodeUseCase(sl()));
  sl.registerLazySingleton(() => SubmitBorrowRequestUseCase(sl()));

  // Use cases for LibraryBorrowingsBloc
  sl.registerLazySingleton(() => GetMyActiveBorrowingsUseCase(sl()));
  sl.registerLazySingleton(() => GetMyBorrowingHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetMyBorrowingLimitsUseCase(sl()));
  sl.registerLazySingleton(() => GetBorrowingStatusUseCase(sl()));
  sl.registerLazySingleton(() => ReturnBookUseCase(sl()));
  sl.registerLazySingleton(() => RenewBorrowingUseCase(sl()));
  sl.registerLazySingleton(() => BulkReturnBooksUseCase(sl()));
  sl.registerLazySingleton(() => BulkRenewBorrowingsUseCase(sl()));
  sl.registerLazySingleton(() => CanRenewBorrowingUseCase(sl()));

  // Additional use cases (for future features)
  // sl.registerLazySingleton(() => GetPopularCollectionsUseCase(sl()));
  // sl.registerLazySingleton(() => AdvancedSearchUseCase(sl()));

  // Blocs
  sl.registerFactory(
    () => LibraryBloc(
      getAllCollectionsUseCase: sl(),
      getCollectionsByCategoryUseCase: sl(),
      searchCollectionsUseCase: sl(),
      getCollectionByCodeUseCase: sl(),
      submitBorrowRequestUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => LibraryBorrowingsBloc(
      getMyActiveBorrowingsUseCase: sl(),
      getMyBorrowingHistoryUseCase: sl(),
      getMyBorrowingLimitsUseCase: sl(),
      getBorrowingStatusUseCase: sl(),
      returnBookUseCase: sl(),
      renewBorrowingUseCase: sl(),
      bulkReturnBooksUseCase: sl(),
      bulkRenewBorrowingsUseCase: sl(),
      canRenewBorrowingUseCase: sl(),
    ),
  );
}
