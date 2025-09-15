import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';

/// Global service to handle auth-related navigation and state changes
/// This service provides a way to trigger auth events from anywhere in the app
class AuthNavigationService {
  static final AuthNavigationService _instance = AuthNavigationService._internal();
  
  factory AuthNavigationService() => _instance;
  
  AuthNavigationService._internal();

  /// Global navigator key for navigation without context
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Trigger logout from anywhere in the app
  static void triggerLogout(BuildContext? context) {
    final authBloc = _findAuthBloc(context);
    if (authBloc != null) {
      authBloc.add(const LogoutRequestedEvent());
    }
  }

  /// Trigger token refresh from anywhere in the app
  static void triggerTokenRefresh(BuildContext? context) {
    final authBloc = _findAuthBloc(context);
    if (authBloc != null) {
      authBloc.add(const TokenRefreshRequestedEvent());
    }
  }

  /// Find AuthBloc from context or navigator
  static AuthBloc? _findAuthBloc(BuildContext? context) {
    // Try to get from provided context first
    if (context != null && context.mounted) {
      try {
        return BlocProvider.of<AuthBloc>(context);
      } catch (e) {
        // Bloc not found in this context
      }
    }

    // Try to get from global navigator context
    final navigatorContext = navigatorKey.currentState?.context;
    if (navigatorContext != null && navigatorContext.mounted) {
      try {
        return BlocProvider.of<AuthBloc>(navigatorContext);
      } catch (e) {
        // Bloc not found in navigator context
      }
    }

    return null;
  }

  /// Handle token expiration - automatically trigger logout
  static void handleTokenExpiration(BuildContext? context) {
    triggerLogout(context);
  }

  /// Navigate to login page (for cases where BlocListener doesn't work)
  static void navigateToLogin() {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  /// Navigate to main page (for cases where BlocListener doesn't work)
  static void navigateToMain() {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamedAndRemoveUntil('/main', (route) => false);
    }
  }
}