import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';

/// Avatar data
class Avatar {
  final String id;
  final String name;
  final String url;
  final Color color;
  final String emoji;

  const Avatar({
    required this.id,
    required this.name,
    required this.url,
    this.color = const Color(0xFF00E676),
    this.emoji = '👤',
  });
}

/// Profile data model
class Profile {
  final String name;
  final String email;
  final String phone;

  const Profile({
    required this.name,
    required this.email,
    required this.phone,
  });
}

/// Available avatars (Pixel Art Mature Style)
const List<Avatar> _avatarsList = [
  Avatar(id: 'marcus', name: 'Marcus', url: 'https://api.dicebear.com/7.x/pixel-art/svg?seed=Marcus&backgroundColor=0d1117', color: Color(0xFF00E676), emoji: '👨‍💼'),
  Avatar(id: 'david', name: 'David', url: 'https://api.dicebear.com/7.x/pixel-art/svg?seed=David&backgroundColor=0d1117', color: Color(0xFF627EEA), emoji: '👨‍💻'),
  Avatar(id: 'james', name: 'James', url: 'https://api.dicebear.com/7.x/pixel-art/svg?seed=James&backgroundColor=0d1117', color: Color(0xFFF7931A), emoji: '🧑‍💼'),
  Avatar(id: 'michael', name: 'Michael', url: 'https://api.dicebear.com/7.x/pixel-art/svg?seed=Michael&backgroundColor=0d1117', color: Color(0xFF00A896), emoji: '👨‍🔬'),
  Avatar(id: 'sarah', name: 'Sarah', url: 'https://api.dicebear.com/7.x/pixel-art/svg?seed=Sarah&backgroundColor=0d1117', color: Color(0xFFF0B90B), emoji: '👩‍💼'),
  Avatar(id: 'emma', name: 'Emma', url: 'https://api.dicebear.com/7.x/pixel-art/svg?seed=Emma&backgroundColor=0d1117', color: Color(0xFF1E88E5), emoji: '👩‍💻'),
  Avatar(id: 'robert', name: 'Robert', url: 'https://api.dicebear.com/7.x/pixel-art/svg?seed=Robert&backgroundColor=0d1117', color: Color(0xFF00D18C), emoji: '🧔'),
  Avatar(id: 'william', name: 'William', url: 'https://api.dicebear.com/7.x/pixel-art/svg?seed=William&backgroundColor=0d1117', color: Color(0xFFFFD700), emoji: '👴'),
  Avatar(id: 'olivia', name: 'Olivia', url: 'https://api.dicebear.com/7.x/pixel-art/svg?seed=Olivia&backgroundColor=0d1117', color: Color(0xFF8247E5), emoji: '👩‍🎨'),
  Avatar(id: 'alex', name: 'Alex', url: 'https://api.dicebear.com/7.x/pixel-art/svg?seed=Alexander&backgroundColor=0d1117', color: Color(0xFFE6007A), emoji: '🧑‍🎤'),
  Avatar(id: 'sophia', name: 'Sophia', url: 'https://api.dicebear.com/7.x/pixel-art/svg?seed=Sophia&backgroundColor=0d1117', color: Color(0xFFE84142), emoji: '👩‍🔬'),
  Avatar(id: 'daniel', name: 'Daniel', url: 'https://api.dicebear.com/7.x/pixel-art/svg?seed=Daniel&backgroundColor=0d1117', color: Color(0xFF26A17B), emoji: '👨‍🎓'),
];

/// Profile state provider - Connected to CrymadX backend
class ProfileProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  String _name = '';
  String _email = '';
  String _phone = '';
  String _country = '';
  String _avatarId = 'marcus';
  String? _avatarUrl;
  bool _twoFactorEnabled = false;
  String _kycStatus = 'not_started';

  /// Static access to avatars list
  static List<Avatar> get avatars => _avatarsList;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get name => _name;
  String get email => _email;
  String get phone => _phone;
  String get country => _country;
  String get avatarId => _avatarId;
  String? get avatarUrl => _avatarUrl;
  bool get twoFactorEnabled => _twoFactorEnabled;
  String get kycStatus => _kycStatus;

  /// Get current profile data
  Profile get profile => Profile(name: _name, email: _email, phone: _phone);

  Avatar get selectedAvatar =>
      _avatarsList.firstWhere((a) => a.id == _avatarId, orElse: () => _avatarsList.first);

  /// Load profile from backend
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await userService.getProfile();
      loadFromUser(user);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update profile on backend
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
    String? country,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await userService.updateProfile(
        fullName: fullName,
        phone: phone,
        country: country,
      );
      loadFromUser(updatedUser);
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

  /// Upload avatar
  Future<bool> uploadAvatar(File file) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newAvatarUrl = await userService.uploadAvatar(file);
      _avatarUrl = newAvatarUrl;
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

  /// Setup 2FA
  Future<TwoFactorSetup?> setup2FA() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final setup = await authService.setup2FA();
      _isLoading = false;
      notifyListeners();
      return setup;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Enable 2FA
  Future<bool> enable2FA(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await authService.enable2FA(code);
      if (success) {
        _twoFactorEnabled = true;
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Disable 2FA
  Future<bool> disable2FA(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await authService.disable2FA(code);
      if (success) {
        _twoFactorEnabled = false;
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get KYC status
  Future<KYCStatus?> getKYCStatus() async {
    try {
      final status = await userService.getKYCStatus();
      _kycStatus = status.status;
      notifyListeners();
      return status;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return null;
    }
  }

  /// Set avatar (local only)
  void setAvatarId(String id) {
    _avatarId = id;
    notifyListeners();
  }

  /// Load from user
  void loadFromUser(User user) {
    _name = user.name;
    _email = user.email;
    _phone = user.phone ?? '';
    _country = user.country ?? '';
    _avatarId = user.avatar ?? 'marcus';
    _avatarUrl = user.avatarUrl;
    _twoFactorEnabled = user.twoFactorEnabled;
    _kycStatus = user.kycStatus ?? 'not_started';
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset profile (on logout)
  void reset() {
    _name = '';
    _email = '';
    _phone = '';
    _country = '';
    _avatarId = 'marcus';
    _avatarUrl = null;
    _twoFactorEnabled = false;
    _kycStatus = 'not_started';
    _error = null;
    notifyListeners();
  }
}
