import 'package:barruu/features/workspace/data/sources/user_identity_service.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Local user identity state (replaces Firebase Auth).
class LocalAuthState {
  final String userId;
  final String? displayName;
  final bool isLoading;
  final String? error;

  const LocalAuthState({
    required this.userId,
    this.displayName,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => userId.isNotEmpty;

  LocalAuthState copyWith({
    String? userId,
    String? displayName,
    bool? isLoading,
    String? error,
  }) {
    return LocalAuthState(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for local auth state.
final authStateProvider = StateNotifierProvider<LocalAuthNotifier, LocalAuthState>(
  (ref) => LocalAuthNotifier(ref.read(userIdentityServiceProvider)),
);

/// Notifier that manages local auth state.
class LocalAuthNotifier extends StateNotifier<LocalAuthState> {
  final UserIdentityService _identityService;

  LocalAuthNotifier(this._identityService) : super(const LocalAuthState(userId: '')) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true);
    final userId = await _identityService.getUserId();
    final name = await _identityService.getUserName();
    if (mounted) {
      state = LocalAuthState(
        userId: userId,
        displayName: name,
        isLoading: false,
      );
    }
  }

  /// Sets the user name and returns success.
  Future<bool> setUserName(String name) async {
    final success = await _identityService.setUserName(name);
    if (success && mounted) {
      state = state.copyWith(displayName: name);
    }
    return success;
  }

  /// Always succeeds — no cloud auth needed.
  Future<bool> login(String _, String __) async {
    await _load();
    if (mounted) {
      state = state.copyWith(userId: state.userId.isNotEmpty ? state.userId : await _identityService.getUserId());
    }
    return true;
  }

  Future<bool> register(
    String email,
    String password,
    String name, {
    String? username,
    String? accountType,
    String? profession,
    List<String>? interests,
  }) async {
    await _identityService.setUserName(name);
    await _load();
    return true;
  }

  Future<void> logout() async {
    state = const LocalAuthState(userId: '');
  }

  Future<void> deleteAccount() async {
    state = const LocalAuthState(userId: '');
  }

  Future<void> refresh() => _load();
}