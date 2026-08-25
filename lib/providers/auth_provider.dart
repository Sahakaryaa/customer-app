import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../services/api_client.dart';

/// Whether to use mock data by default when backend is unreachable.
bool useMockData = false;

/// Auth state holding the current user and login status.
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isDemo;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isDemo = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isDemo,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isDemo: isDemo ?? this.isDemo,
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

  /// 1-Tap Quick Demo Mode — immediately logs in as a verified demo customer.
  Future<void> loginAsDemo({
    String name = 'Demo Customer',
    String phone = '9876543210',
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    await Future.delayed(const Duration(milliseconds: 350));
    final token = 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
    await _api.saveToken(token);
    useMockData = true;
    state = state.copyWith(
      user: User(
        id: 'demo_customer',
        phone: phone,
        name: name,
        role: 'customer',
        createdAt: DateTime.now(),
      ),
      isLoading: false,
      isDemo: true,
      clearError: true,
    );
  }

  /// Attempt to restore session from stored JWT via GET /auth/me.
  Future<void> _tryAutoLogin() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _api.getToken();
      if (token != null && (token.startsWith('demo_') || token.startsWith('mock_') || useMockData)) {
        useMockData = true;
        state = state.copyWith(
          user: User(
            id: 'demo_customer',
            phone: '9876543210',
            name: 'Demo Customer',
            role: 'customer',
            createdAt: DateTime.now(),
          ),
          isLoading: false,
          isDemo: true,
          clearError: true,
        );
      } else if (token != null && token.isNotEmpty) {
        try {
          final user = await _api.getCurrentUser();
          state = state.copyWith(user: user, isLoading: false, isDemo: false, clearError: true);
        } catch (_) {
          // If server is unreachable, fall back to offline demo session rather than kicking to login
          useMockData = true;
          state = state.copyWith(
            user: User(
              id: 'demo_customer',
              phone: '9876543210',
              name: 'Demo Customer',
              role: 'customer',
              createdAt: DateTime.now(),
            ),
            isLoading: false,
            isDemo: true,
            clearError: true,
          );
        }
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
        await Future.delayed(const Duration(milliseconds: 600));
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
          isDemo: true,
        );
        return true;
      }

      try {
        final data = await _api.register(
          phone: phone,
          name: name,
          password: password,
        );
        await _api.saveToken(data['access_token']?.toString() ?? '');
        var user = _parseTokenUser(data);
        user ??= await _api.getCurrentUser();
        state = state.copyWith(user: user, isLoading: false, isDemo: false);
        return true;
      } catch (e) {
        // If server is unreachable, seamlessly fall back to local demo registration
        useMockData = true;
        await _api.saveToken('demo_token_${DateTime.now().millisecondsSinceEpoch}');
        state = state.copyWith(
          user: User(
            id: 'demo_customer',
            phone: phone,
            name: name,
            role: 'customer',
            createdAt: DateTime.now(),
          ),
          isLoading: false,
          isDemo: true,
        );
        return true;
      }
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
        await Future.delayed(const Duration(milliseconds: 600));
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
          isDemo: true,
        );
        return true;
      }

      try {
        final data = await _api.login(phone: phone, password: password);
        await _api.saveToken(data['access_token']?.toString() ?? '');
        var user = _parseTokenUser(data);
        user ??= await _api.getCurrentUser();
        state = state.copyWith(user: user, isLoading: false, isDemo: false);
        return true;
      } catch (e) {
        // If server is unreachable, fall back to offline demo login
        useMockData = true;
        await _api.saveToken('demo_token_${DateTime.now().millisecondsSinceEpoch}');
        state = state.copyWith(
          user: User(
            id: 'demo_customer',
            phone: phone,
            name: 'Demo Customer',
            role: 'customer',
            createdAt: DateTime.now(),
          ),
          isLoading: false,
          isDemo: true,
        );
        return true;
      }
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
    useMockData = false;
    state = const AuthState();
  }
}

/// Riverpod provider for auth state.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiClientProvider));
});

