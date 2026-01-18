import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import 'api_service.dart';

/// Authentication Service - Handles all auth-related API calls
class AuthService {
  final ApiService _api = api;

  /// Login with email and password
  /// Returns AuthResult on success, handles 2FA requirement
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.post(
      ApiConfig.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    // Check if 2FA is required
    if (response['requires2FA'] == true) {
      return AuthResult(
        requires2FA: true,
        userId: response['userId'],
        message: response['message'],
      );
    }

    // Normal login success - extract tokens
    final tokens = response['tokens'];
    final userData = response['user'];

    if (tokens != null) {
      await _api.saveTokens(
        accessToken: tokens['accessToken'],
        refreshToken: tokens['refreshToken'],
      );
      if (userData != null && userData['id'] != null) {
        await _api.saveUserId(userData['id']);
      }
    }

    return AuthResult(
      accessToken: tokens?['accessToken'] ?? '',
      refreshToken: tokens?['refreshToken'] ?? '',
      user: userData != null ? User.fromJson(userData) : null,
      message: response['message'],
    );
  }

  /// Complete 2FA login
  Future<AuthResult> complete2FA({
    required String userId,
    required String code,
  }) async {
    final response = await _api.post(
      ApiConfig.complete2FA,
      data: {
        'userId': userId,
        'code': code,
      },
    );

    final tokens = response['tokens'];
    final userData = response['user'];

    if (tokens != null) {
      await _api.saveTokens(
        accessToken: tokens['accessToken'],
        refreshToken: tokens['refreshToken'],
      );
      if (userData != null && userData['id'] != null) {
        await _api.saveUserId(userData['id']);
      }
    }

    return AuthResult(
      accessToken: tokens?['accessToken'] ?? '',
      refreshToken: tokens?['refreshToken'] ?? '',
      user: userData != null ? User.fromJson(userData) : null,
      message: response['message'],
    );
  }

  /// Register new user
  Future<RegisterResult> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String? referralCode,
  }) async {
    final response = await _api.post(
      ApiConfig.register,
      data: {
        'email': email,
        'password': password,
        'confirm_password': password,
        'full_name': fullName,
        'phone': phone ?? '',
        'terms_accepted': true,
        if (referralCode != null && referralCode.isNotEmpty)
          'referral_code': referralCode,
      },
    );

    return RegisterResult(
      message: response['message'] ?? 'Registration successful',
      requiresVerification: response['requiresVerification'] ?? true,
      email: response['user']?['email'] ?? email,
    );
  }

  /// Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google Sign-In cancelled');
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      // Send token to backend for verification
      final response = await _api.post(
        ApiConfig.googleAuth,
        data: {
          'idToken': googleAuth.idToken,
          'accessToken': googleAuth.accessToken,
        },
      );

      // Handle 2FA if required
      if (response['requires2FA'] == true) {
        return AuthResult(
          requires2FA: true,
          userId: response['userId'],
          message: response['message'],
        );
      }

      // Extract tokens and user data
      final tokens = response['tokens'];
      final userData = response['user'];

      if (tokens != null) {
        await _api.saveTokens(
          accessToken: tokens['accessToken'],
          refreshToken: tokens['refreshToken'],
        );
        if (userData != null && userData['id'] != null) {
          await _api.saveUserId(userData['id']);
        }
      }

      return AuthResult(
        accessToken: tokens?['accessToken'] ?? '',
        refreshToken: tokens?['refreshToken'] ?? '',
        user: userData != null ? User.fromJson(userData) : null,
        message: response['message'],
      );
    } catch (e) {
      // Sign out from Google on error
      await _googleSignIn.signOut();
      rethrow;
    }
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }

  /// Verify email with code
  Future<AuthResult> verifyEmail({
    required String email,
    required String code,
  }) async {
    final response = await _api.post(
      ApiConfig.verifyEmail,
      data: {
        'email': email,
        'code': code,
      },
    );

    final tokens = response['tokens'];
    final userData = response['user'];

    if (tokens != null) {
      await _api.saveTokens(
        accessToken: tokens['accessToken'],
        refreshToken: tokens['refreshToken'],
      );
      if (userData != null && userData['id'] != null) {
        await _api.saveUserId(userData['id']);
      }
    }

    return AuthResult(
      accessToken: tokens?['accessToken'] ?? '',
      refreshToken: tokens?['refreshToken'] ?? '',
      user: userData != null ? User.fromJson(userData) : null,
      message: response['message'],
    );
  }

  /// Resend verification email
  Future<String> resendVerification(String email) async {
    final response = await _api.post(
      ApiConfig.resendVerification,
      data: {'email': email},
    );
    return response['message'] ?? 'Verification code sent';
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _api.post(ApiConfig.logout);
    } finally {
      await _api.clearTokens();
    }
  }

  /// Forgot password - request reset email
  Future<String> forgotPassword(String email) async {
    final response = await _api.post(
      ApiConfig.forgotPassword,
      data: {'email': email},
    );
    return response['message'] ?? 'If an account exists, a reset email has been sent';
  }

  /// Reset password with token
  Future<String> resetPassword({
    required String token,
    required String password,
  }) async {
    final response = await _api.post(
      ApiConfig.resetPassword,
      data: {
        'token': token,
        'password': password,
      },
    );
    return response['message'] ?? 'Password reset successful';
  }

  /// Setup 2FA - get QR code and secret
  Future<TwoFactorSetup> setup2FA() async {
    final response = await _api.post(ApiConfig.twoFASetup);
    return TwoFactorSetup(
      qrCodeUrl: response['qrCodeUrl'] ?? '',
      secret: response['secret'] ?? '',
      backupCodes: List<String>.from(response['backupCodes'] ?? []),
    );
  }

  /// Enable 2FA with verification code
  Future<bool> enable2FA(String code) async {
    final response = await _api.post(
      ApiConfig.twoFAEnable,
      data: {'code': code},
    );
    return response['enabled'] == true;
  }

  /// Verify 2FA code
  Future<bool> verify2FA(String code) async {
    final response = await _api.post(
      ApiConfig.twoFAVerify,
      data: {'code': code},
    );
    return response['valid'] == true || response['message'] != null;
  }

  /// Disable 2FA
  Future<bool> disable2FA(String code) async {
    final response = await _api.post(
      ApiConfig.twoFADisable,
      data: {'code': code},
    );
    return response['disabled'] == true;
  }

  /// Get backup codes for 2FA
  Future<List<String>> getBackupCodes() async {
    final response = await _api.post(ApiConfig.twoFABackupCodes);
    return List<String>.from(response['backupCodes'] ?? []);
  }

  /// Check authentication status
  Future<bool> isAuthenticated() => _api.isAuthenticated();

  /// Get current access token
  Future<String?> getAccessToken() => _api.getAccessToken();
}

/// Auth result model - returned after successful login
class AuthResult {
  final String? accessToken;
  final String? refreshToken;
  final User? user;
  final bool requires2FA;
  final String? userId;
  final String? message;

  AuthResult({
    this.accessToken,
    this.refreshToken,
    this.user,
    this.requires2FA = false,
    this.userId,
    this.message,
  });

  bool get isSuccess => accessToken != null && accessToken!.isNotEmpty;
}

/// Register result model
class RegisterResult {
  final String message;
  final bool requiresVerification;
  final String email;

  RegisterResult({
    required this.message,
    required this.requiresVerification,
    required this.email,
  });
}

/// 2FA setup data
class TwoFactorSetup {
  final String qrCodeUrl;
  final String secret;
  final List<String> backupCodes;

  TwoFactorSetup({
    required this.qrCodeUrl,
    required this.secret,
    required this.backupCodes,
  });
}

/// Global auth service instance
final authService = AuthService();
