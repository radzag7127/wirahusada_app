import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/widgets/optimized_bloc_builder.dart';
import 'core/services/auth_navigation_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/presentation/pages/main_navigation_page.dart';
import 'features/payment/presentation/bloc/payment_bloc.dart';
import 'features/payment/presentation/bloc/payment_event.dart';
import 'features/dashboard/presentation/bloc/beranda_bloc.dart';
import 'core/services/api_service.dart';
import 'core/services/dashboard_preferences_service.dart';

// Cache the text theme to prevent repeated font loading
late final TextTheme _cachedTextTheme;
late final ThemeData _cachedThemeData;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for fast, reliable local storage
  await Hive.initFlutter();
  
  // Open the dashboard preferences box
  await Hive.openBox('dashboard_preferences');

  // Performance optimizations
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Optimize memory usage
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Pre-cache fonts for better performance
  await _initializeTheme();

  await di.init();
  runApp(const MyApp());
}

Future<void> _initializeTheme() async {
  const String fontName = 'Plus Jakarta Sans';

  // Create a custom TextTheme using the local font
  _cachedTextTheme =
      const TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w800,
        ),
        displayMedium: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(fontFamily: fontName, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(fontFamily: fontName, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w400,
        ),
      ).apply(
        bodyColor: const Color(0xFF121212),
        displayColor: const Color(0xFF121212),
      );

  _cachedThemeData = ThemeData(
    primarySwatch: Colors.blue,
    textTheme: _cachedTextTheme,
    fontFamily: fontName, // Set the default font family
    visualDensity: VisualDensity.adaptivePlatformDensity,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF135EA2),
      brightness: Brightness.light,
    ),
    // Optimize app bar theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF121212),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    // Optimize scaffold theme
    scaffoldBackgroundColor: const Color(0xFFFBFBFB),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _memoryCleanupTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preloadCriticalData();
  }

  void _preloadCriticalData() {
    // STARTUP FIX: Remove aggressive preloading to prevent race conditions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use a longer delay to ensure all systems are ready
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          // Only preload critical data that's immediately visible
          // This will be triggered after AuthBloc determines the user is authenticated
          debugPrint('STARTUP FIX: Critical data preload deferred until auth state is resolved');
        } catch (e) {
          // Handle any initialization errors gracefully
          debugPrint('Error preloading critical data: $e');
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _memoryCleanupTimer?.cancel();
    // Clean up API service connections
    ApiService.dispose();
    // Clean up Hive resources
    DashboardPreferencesService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        // Schedule cleanup instead of immediate clearing
        _scheduleMemoryCleanup();
        break;
      case AppLifecycleState.resumed:
        // Cancel cleanup if user returns quickly
        _cancelMemoryCleanup();
        break;
      case AppLifecycleState.detached:
        // App is being terminated, do selective cleanup
        _performSelectiveCleanup();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // No action needed for these states
        break;
    }
  }

  void _scheduleMemoryCleanup() {
    _memoryCleanupTimer?.cancel();
    // Only clean after extended background time (5 minutes)
    _memoryCleanupTimer = Timer(const Duration(minutes: 5), () {
      _performSelectiveCleanup();
    });
  }

  void _cancelMemoryCleanup() {
    _memoryCleanupTimer?.cancel();
  }

  void _performSelectiveCleanup() {
    // Only clear if memory pressure is high
    final imageCache = PaintingBinding.instance.imageCache;
    const int maxCacheSize = 50 * 1024 * 1024; // 50MB threshold

    if (imageCache.currentSizeBytes > maxCacheSize) {
      // Clear live images but keep cached ones for faster reload
      imageCache.clearLiveImages();
      // Only clear cache if still over threshold
      if (imageCache.currentSizeBytes > maxCacheSize) {
        imageCache.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<AuthBloc>()..add(const CheckAuthStatusEvent()),
          lazy: false, // Load immediately for auth - critical for app flow
        ),
        BlocProvider(
          create: (_) => di.sl<PaymentBloc>(),
          lazy: true, // Use lazy loading to defer initialization until actually needed
        ),
        BlocProvider(
          create: (_) => di.sl<BerandaBloc>(),
          lazy: true, // Use lazy loading to defer initialization until actually needed
        ),
      ],
      child: MaterialApp(
        title: 'Wismon Keuangan',
        debugShowCheckedModeBanner: false, // Remove debug banner
        navigatorKey: AuthNavigationService.navigatorKey, // Add global navigator key
        // Performance optimizations
        builder: (context, child) {
          // Prevent text scaling beyond reasonable limits
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
              ),
            ),
            child: child!,
          );
        },

        theme: _cachedThemeData,

        home: const AuthWrapper(),

        // Performance monitoring in debug mode
        showPerformanceOverlay: false, // Set to true only for debugging
        // Optimize route generation
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const LoginPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                transitionDuration: const Duration(milliseconds: 200),
              );
            case '/main':
              return PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const MainNavigationPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                transitionDuration: const Duration(milliseconds: 200),
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}

/// Set user context for Hive dashboard preferences
Future<void> _setUserContextForHive(String userNrm) async {
  try {
    final dashboardService = DashboardPreferencesService();
    await dashboardService.setUserContext(userNrm);
    debugPrint('✅ Set Hive user context: $userNrm');
  } catch (e) {
    debugPrint('❌ Error setting Hive user context: $e');
  }
}

/// Clear user context for Hive dashboard preferences on logout
Future<void> _clearUserContextFromHive() async {
  try {
    final dashboardService = DashboardPreferencesService();
    await dashboardService.clearPreferences();
    debugPrint('✅ Cleared Hive user context');
  } catch (e) {
    debugPrint('❌ Error clearing Hive user context: $e');
  }
}

/// RADICAL SOLUTION: Aggressively reset BLoCs and clear all caches when user logs out
void _resetBlocsOnLogout(BuildContext context) {
  debugPrint('🔥 RADICAL: Starting aggressive logout cleanup');
  
  // Clear Hive user context first
  _clearUserContextFromHive();
  
  try {
    // Use a safer approach to check if providers are available
    final berandaBloc = context.read<BerandaBloc>();
    berandaBloc.updateCurrentUser(null);
    debugPrint('🔥 RADICAL: BerandaBloc user context cleared');
  } catch (e) {
    debugPrint('BerandaBloc not available for logout reset: $e');
  }
  
  try {
    final paymentBloc = context.read<PaymentBloc>();
    paymentBloc.add(const ResetPaymentBlocEvent());
    debugPrint('🔥 RADICAL: PaymentBloc reset event sent');
  } catch (e) {
    debugPrint('PaymentBloc not available for logout reset: $e');
  }
  
  // RADICAL SOLUTION: Aggressively clear SharedPreferences on logout
  _aggressivelyClearUserData();
}

/// STARTUP FIX: More controlled BLoC updates when user logs in
void _updateBlocsOnLogin(BuildContext context, String userNrm) {
  debugPrint('🔥 STARTUP: Starting controlled login update for user: $userNrm');
  
  // STARTUP FIX: Clear user data but less aggressively
  _selectivelyClearUserData();
  
  // Set user context for Hive dashboard preferences
  _setUserContextForHive(userNrm);
  
  try {
    final berandaBloc = context.read<BerandaBloc>();
    berandaBloc.updateCurrentUser(userNrm);
    // STARTUP FIX: Let beranda page handle its own startup sequence
    debugPrint('🔥 STARTUP: BerandaBloc updated with new user');
  } catch (e) {
    debugPrint('BerandaBloc not available for login update: $e');
  }
  
  try {
    final paymentBloc = context.read<PaymentBloc>();
    // STARTUP FIX: Only reset, let beranda page handle loading sequence
    paymentBloc.add(const ResetPaymentBlocEvent());
    debugPrint('🔥 STARTUP: PaymentBloc reset completed');
  } catch (e) {
    debugPrint('PaymentBloc not available for login update: $e');
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        // Listen to all auth state changes for navigation
        return previous.runtimeType != current.runtimeType;
      },
      listener: (context, state) {
        // Handle navigation on auth state changes
        if (state is AuthUnauthenticated || state is AuthError) {
          // Clear any existing routes and navigate to login
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          // Reset BLoCs when user logs out (use safer approach)
          _resetBlocsOnLogout(context);
        } else if (state is AuthAuthenticated) {
          // Navigate to main app
          Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
          // Update BLoCs with new user context (use safer approach)
          _updateBlocsOnLogin(context, state.user.nrm);
        }
      },
      child: OptimizedBlocBuilder<AuthBloc, AuthState>(
        debugName: 'AuthWrapper',
        buildWhen: (previous, current) {
          // Only rebuild when auth state actually changes
          return previous.runtimeType != current.runtimeType;
        },
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return const MainNavigationPage();
          }
          if (state is AuthUnauthenticated || state is AuthError) {
            return const LoginPage();
          }
          return const LoadingScreen();
        },
      ),
    );
  }
}

/// STARTUP FIX: More selective user data clearing
Future<void> _selectivelyClearUserData() async {
  try {
    debugPrint('🔥 STARTUP: Starting selective user data clearing');
    final prefs = await SharedPreferences.getInstance();
    
    // Only clear payment and user-specific keys, keep dashboard preferences
    final keysToRemove = prefs.getKeys().where((key) => 
      key.contains('payment') ||
      key.contains('wismon') ||
      key.contains('user_payment_data') ||
      key.contains('cached_payment') ||
      key.startsWith('user_payment_')
    ).toList();
    
    for (final key in keysToRemove) {
      await prefs.remove(key);
      debugPrint('🔥 STARTUP: Cleared cache key: $key');
    }
    
    // Clear payment-specific cache patterns
    await prefs.remove('last_payment_load_time');
    await prefs.remove('payment_summary_cache');
    
    debugPrint('🔥 STARTUP: Cleared ${keysToRemove.length} cached keys');
  } catch (e) {
    debugPrint('🔥 STARTUP: Error clearing user data: $e');
  }
}

/// RADICAL SOLUTION: Aggressively clear all user-related cached data (keep for existing function calls)
Future<void> _aggressivelyClearUserData() async {
  try {
    debugPrint('🔥 RADICAL: Starting aggressive user data clearing');
    final prefs = await SharedPreferences.getInstance();
    
    // Clear all payment, dashboard, and user-specific keys
    final keysToRemove = prefs.getKeys().where((key) => 
      key.contains('payment') ||
      key.contains('wismon') ||
      key.contains('dashboard_preferences') ||
      key.contains('user_payment_data') ||
      key.contains('beranda_') ||
      key.contains('cached_') ||
      key.startsWith('user_')
    ).toList();
    
    for (final key in keysToRemove) {
      await prefs.remove(key);
      debugPrint('🔥 RADICAL: Cleared cache key: $key');
    }
    
    // Also clear common cache patterns
    await prefs.remove('last_payment_load_time');
    await prefs.remove('payment_summary_cache');
    await prefs.remove('dashboard_customization_cache');
    
    debugPrint('🔥 RADICAL: Cleared ${keysToRemove.length} cached keys');
  } catch (e) {
    debugPrint('🔥 RADICAL: Error clearing user data: $e');
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo with Hero animation
              RepaintBoundary(
                child: Hero(
                  tag: 'app_logo',
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF135EA2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x20135EA2),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App Title
              const Text(
                'Wismon Keuangan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF135EA2),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Student Payment System',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 32),

              // Loading indicator with animation
              RepaintBoundary(
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF135EA2)),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
