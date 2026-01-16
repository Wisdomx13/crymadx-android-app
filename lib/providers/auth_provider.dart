import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

/// Authentication state provider - Connected to real CrymadX backend
class AuthProvider extends ChangeNotifier {
  User _user = User.empty;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  bool _requires2FA = false;
  String? _pending2FAUserId;
  String? _pendingVerificationEmail;

  User get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  bool get requires2FA => _requires2FA;
  String? get pending2FAUserId => _pending2FAUserId;
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  /// Initialize auth state - check if user is already logged in
  Future<void> init() async {
    try {
      _isAuthenticated = await authService.isAuthenticated();
      if (_isAuthenticated) {
        // Try to fetch user profile
        try {
          _user = await userService.getProfile();
        } catch (e) {
          // Token might be invalid, reset auth state
          _isAuthenticated = false;
          await authService.logout();
        }
      }
    } catch (e) {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  /// Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    _requires2FA = false;
    _pending2FAUserId = null;
    notifyListeners();

    try {
      final result = await authService.login(
        email: email,
        password: password,
      );

      if (result.requires2FA) {
        // 2FA is required, store userId for completion
        _requires2FA = true;
        _pending2FAUserId = result.userId;
        _isLoading = false;
        notifyListeners();
        return false; // Return false to indicate 2FA step needed
      }

      if (result.isSuccess) {
        // Login successful
        if (result.user != null) {
          _user = result.user!;
        } else {
          // Fetch user profile if not included in response
          _user = await userService.getProfile();
        }
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Complete 2FA login
  Future<bool> complete2FA(String code) async {
    if (_pending2FAUserId == null) {
      _error = 'No pending 2FA session';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await authService.complete2FA(
        userId: _pending2FAUserId!,
        code: code,
      );

      if (result.isSuccess) {
        if (result.user != null) {
          _user = result.user!;
        } else {
          _user = await userService.getProfile();
        }
        _isAuthenticated = true;
        _requires2FA = false;
        _pending2FAUserId = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message ?? '2FA verification failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    String? referralCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await authService.register(
        email: email,
        password: password,
        fullName: fullName,
        referralCode: referralCode,
      );

      if (result.requiresVerification) {
        // Email verification required
        _pendingVerificationEmail = result.email;
        _isLoading = false;
        notifyListeners();
        return true; // Return true to proceed to verification screen
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify email with code
  Future<bool> verifyEmail(String code) async {
    if (_pendingVerificationEmail == null) {
      _error = 'No pending email verification';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await authService.verifyEmail(
        email: _pendingVerificationEmail!,
        code: code,
      );

      if (result.isSuccess) {
        if (result.user != null) {
          _user = result.user!;
        } else {
          _user = await userService.getProfile();
        }
        _isAuthenticated = true;
        _pendingVerificationEmail = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.message ?? 'Email verification failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Resend verification email
  Future<bool> resendVerification() async {
    if (_pendingVerificationEmail == null) {
      _error = 'No pending email verification';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await authService.resendVerification(_pendingVerificationEmail!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Forgot password
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await authService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Reset password
  Future<bool> resetPassword({
    required String token,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await authService.resetPassword(token: token, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await authService.logout();
    } catch (e) {
      // Ignore logout errors
    }
    _user = User.empty;
    _isAuthenticated = false;
    _requires2FA = false;
    _pending2FAUserId = null;
    _pendingVerificationEmail = null;
    _error = null;
    notifyListeners();
  }

  /// Update user data
  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }

  /// Refresh user profile from backend
  Future<void> refreshProfile() async {
    if (!_isAuthenticated) return;

    try {
      _user = await userService.getProfile();
      notifyListeners();
    } catch (e) {
      // Silently fail
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Cancel 2FA flow
  void cancel2FA() {
    _requires2FA = false;
    _pending2FAUserId = null;
    _error = null;
    notifyListeners();
  }

  /// Cancel email verification flow
  void cancelVerification() {
    _pendingVerificationEmail = null;
    _error = null;
    notifyListeners();
  }
}
