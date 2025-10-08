import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

/// Global service to handle auth-related navigation and state changes
/// This service provides a way to trigger auth events from anywhere in the app
class AuthNavigationService {
  static final AuthNavigationService _instance = AuthNavigationService._internal();

  factory AuthNavigationService() => _instance;

  AuthNavigationService._internal();

  /// Global navigator key for navigation without context
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Circuit breaker: Track logout attempts to prevent infinite loops
  static DateTime? _lastLogoutAttempt;
  static const Duration _logoutCooldown = Duration(seconds: 2);

  /// Trigger logout from anywhere in the app
  static void triggerLogout(BuildContext? context) {
    if (kDebugMode) {
      print('🚨 [AuthNav] triggerLogout called');
      print('🚨 [AuthNav] Context provided: ${context != null}');
      print('🚨 [AuthNav] Context mounted: ${context?.mounted}');
    }

    final authBloc = _findAuthBloc(context);
    if (authBloc != null) {
      if (kDebugMode) {
        print('✅ [AuthNav] AuthBloc found, adding LogoutRequestedEvent');
      }
      authBloc.add(const LogoutRequestedEvent());

      // CRITICAL: Start circuit breaker to ensure navigation happens
      _startNavigationCircuitBreaker();
    } else {
      if (kDebugMode) {
        print('❌ [AuthNav] AuthBloc NOT found, using direct navigation fallback');
      }
      // Fallback: Direct navigation if AuthBloc is not available
      _forceNavigateToLogin();
    }
  }

  /// Circuit breaker: Ensure navigation happens within timeout
  static void _startNavigationCircuitBreaker() {
    if (kDebugMode) {
      print('⏱️ [AuthNav] Starting circuit breaker (2 second timeout)');
    }

    _lastLogoutAttempt = DateTime.now();

    Future.delayed(const Duration(seconds: 2), () {
      if (_lastLogoutAttempt == null) {
        // Navigation already happened, circuit breaker not needed
        if (kDebugMode) {
          print('✅ [AuthNav] Circuit breaker: Navigation already completed');
        }
        return;
      }

      final timeSinceLogout = DateTime.now().difference(_lastLogoutAttempt!);
      if (timeSinceLogout < _logoutCooldown) {
        if (kDebugMode) {
          print('⚠️ [AuthNav] Circuit breaker TRIGGERED: Navigation did not happen within 2 seconds');
          print('🔧 [AuthNav] Forcing direct navigation to login page');
        }
        _forceNavigateToLogin();
      }
    });
  }

  /// Reset circuit breaker when navigation completes successfully
  static void resetCircuitBreaker() {
    if (kDebugMode) {
      print('✅ [AuthNav] Circuit breaker reset - navigation completed');
    }
    _lastLogoutAttempt = null;
  }

  /// Force navigate to login page using navigatorKey
  static void _forceNavigateToLogin() {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      if (kDebugMode) {
        print('🔧 [AuthNav] Force navigating to login page');
      }
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
      resetCircuitBreaker();
    } else {
      if (kDebugMode) {
        print('❌ [AuthNav] CRITICAL: NavigatorState is null! Cannot navigate to login');
      }
    }
  }

  /// Trigger token refresh from anywhere in the app
  static void triggerTokenRefresh(BuildContext? context) {
    if (kDebugMode) {
      print('🔄 [AuthNav] triggerTokenRefresh called');
    }

    final authBloc = _findAuthBloc(context);
    if (authBloc != null) {
      authBloc.add(const TokenRefreshRequestedEvent());
    } else if (kDebugMode) {
      print('⚠️ [AuthNav] AuthBloc not found for token refresh');
    }
  }

  /// Find AuthBloc from context or navigator
  static AuthBloc? _findAuthBloc(BuildContext? context) {
    if (kDebugMode) {
      print('🔍 [AuthNav] Searching for AuthBloc...');
    }

    // Try to get from provided context first
    if (context != null && context.mounted) {
      try {
        final bloc = BlocProvider.of<AuthBloc>(context);
        if (kDebugMode) {
          print('✅ [AuthNav] AuthBloc found in provided context');
        }
        return bloc;
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [AuthNav] Bloc not found in provided context: $e');
        }
      }
    }

    // Try to get from global navigator context
    final navigatorContext = navigatorKey.currentState?.context;
    if (navigatorContext != null && navigatorContext.mounted) {
      try {
        final bloc = BlocProvider.of<AuthBloc>(navigatorContext);
        if (kDebugMode) {
          print('✅ [AuthNav] AuthBloc found in navigator context');
        }
        return bloc;
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ [AuthNav] Bloc not found in navigator context: $e');
        }
      }
    }

    if (kDebugMode) {
      print('❌ [AuthNav] AuthBloc not found anywhere!');
    }
    return null;
  }

  /// Handle token expiration - automatically trigger logout
  static void handleTokenExpiration(BuildContext? context) {
    if (kDebugMode) {
      print('🔒 [AuthNav] handleTokenExpiration called');
    }
    triggerLogout(context);
  }

  /// Navigate to login page (for cases where BlocListener doesn't work)
  static void navigateToLogin() {
    if (kDebugMode) {
      print('🚀 [AuthNav] navigateToLogin called');
    }
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    } else if (kDebugMode) {
      print('❌ [AuthNav] NavigatorState is null');
    }
  }

  /// Navigate to main page (for cases where BlocListener doesn't work)
  static void navigateToMain() {
    if (kDebugMode) {
      print('🚀 [AuthNav] navigateToMain called');
    }
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamedAndRemoveUntil('/main', (route) => false);
    } else if (kDebugMode) {
      print('❌ [AuthNav] NavigatorState is null');
    }
  }

  /// Monitor AuthBloc state changes for debugging
  static StreamSubscription<AuthState>? _stateMonitor;

  static void startMonitoring(AuthBloc authBloc) {
    _stateMonitor?.cancel();
    _stateMonitor = authBloc.stream.listen((state) {
      if (kDebugMode) {
        print('📡 [AuthNav Monitor] AuthBloc state changed to: ${state.runtimeType}');
      }
    });
  }

  static void stopMonitoring() {
    _stateMonitor?.cancel();
    _stateMonitor = null;
  }
}