import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/api_client.dart';

/// Whether to use mock data (true) or the real API (false).
/// The backend implements API_CONTRACT.md, so real mode is the default.
const bool useMockData = false;

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

/// Safely extract the nested `user` object from a TokenResponse.
/// TokenResponse = {access_token, token_type, user: UserResponse}.
User? _parseTokenUser(Map<String, dynamic> data) {
  final raw = data['user'];
  if (raw is Map) {
    try {
      return User.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      return null;
    }
  }
  return null;
}

/// Auth state notifier managing login, register, and logout.
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;

  AuthNotifier(this._api) : super(const AuthState()) {
    _tryAutoLogin();
  }

  /// Attempt to restore session from stored JWT via GET /auth/me.
  Future<void> _tryAutoLogin() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _api.getToken();
      if (token != null && useMockData) {
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
      } else if (token != null && token.isNotEmpty) {
        // Contract: GET /auth/me returns the current UserResponse.
        final user = await _api.getCurrentUser();
        state = state.copyWith(user: user, isLoading: false, clearError: true);
      } else {
        state = state.copyWith(isLoading: false, clearUser: true);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false, clearUser: true);
    }
  }

  /// Register a new customer. POST /auth/register → TokenResponse {user}.
  Future<bool> register({
    required String phone,
    required String name,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (useMockData) {
        await Future.delayed(const Duration(milliseconds: 800));
        await _api.saveToken(
            'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}');
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
      await _api.saveToken(data['access_token']?.toString() ?? '');
      var user = _parseTokenUser(data); // nested user per contract
      user ??= await _api.getCurrentUser(); // null-safe fallback
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.friendlyError(e),
      );
      return false;
    }
  }

  /// Login with phone + password. POST /auth/login → TokenResponse {user}.
  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (useMockData) {
        await Future.delayed(const Duration(milliseconds: 800));
        await _api.saveToken(
            'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}');
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
      await _api.saveToken(data['access_token']?.toString() ?? '');
      var user = _parseTokenUser(data);
      user ??= await _api.getCurrentUser();
      state = state.copyWith(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: ApiClient.friendlyError(e),
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
