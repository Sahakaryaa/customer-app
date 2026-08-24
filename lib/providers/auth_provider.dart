import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/api_client.dart';

/// Whether to use mock data (true) or real API (false).
/// Set to false once the backend is deployed.
const bool useMockData = true;

/// Auth state holding the current user and login status.
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Auth state notifier managing login, register, and logout.
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;

  AuthNotifier(this._api) : super(const AuthState()) {
    _tryAutoLogin();
  }

  /// Attempt to restore session from stored JWT.
  Future<void> _tryAutoLogin() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _api.getToken();
      if (token != null && useMockData) {
        // In mock mode, create a demo user if token exists
        state = state.copyWith(
          user: User(
            id: 'demo_customer',
            phone: '9876543210',
            name: 'Demo User',
            role: 'customer',
            createdAt: DateTime.now(),
          ),
          isLoading: false,
          clearError: true,
        );
      } else if (token != null) {
        final user = await _api.getCurrentUser();
        state = state.copyWith(user: user, isLoading: false, clearError: true);
      } else {
        state = state.copyWith(isLoading: false, clearUser: true);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, clearUser: true);
    }
  }

  /// Register a new customer.
  Future<bool> register({
    required String phone,
    required String name,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (useMockData) {
        // Simulate registration
        await Future.delayed(const Duration(milliseconds: 800));
        await _api.saveToken('mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}');
        state = state.copyWith(
          user: User(
            id: 'demo_customer',
            phone: phone,
            name: name,
            role: 'customer',
            createdAt: DateTime.now(),
          ),
          isLoading: false,
        );
        return true;
      }

      final data = await _api.register(
        phone: phone,
        name: name,
        password: password,
      );
      await _api.saveToken(data['access_token'] as String);
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed. Please try again.',
      );
      return false;
    }
  }

  /// Login with phone and password (OTP mock: any 6-digit code works).
  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (useMockData) {
        // Simulate login
        await Future.delayed(const Duration(milliseconds: 800));
        await _api.saveToken('mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}');
        state = state.copyWith(
          user: User(
            id: 'demo_customer',
            phone: phone,
            name: 'Demo User',
            role: 'customer',
            createdAt: DateTime.now(),
          ),
          isLoading: false,
        );
        return true;
      }

      final data = await _api.login(phone: phone, password: password);
      await _api.saveToken(data['access_token'] as String);
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed. Check your credentials.',
      );
      return false;
    }
  }

  /// Logout and clear session.
  Future<void> logout() async {
    await _api.clearToken();
    state = const AuthState();
  }
}

/// Riverpod provider for auth state.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiClientProvider));
});
