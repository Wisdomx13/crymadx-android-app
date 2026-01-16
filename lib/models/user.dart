/// User model
class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? avatar;
  final String? country;
  final String? language;
  final String? currency;
  final int kycLevel; // 0, 1, 2, 3
  final UserStatus status;
  final bool twoFactorEnabled;
  final bool emailVerified;
  final bool phoneVerified;
  final String referralCode;
  final String? referredBy;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.avatar,
    this.country,
    this.language,
    this.currency,
    this.kycLevel = 0,
    this.status = UserStatus.active,
    this.twoFactorEnabled = false,
    this.emailVerified = false,
    this.phoneVerified = false,
    required this.referralCode,
    this.referredBy,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'],
      country: json['country'],
      language: json['language'],
      currency: json['currency'],
      kycLevel: json['kycLevel'] ?? 0,
      status: UserStatus.fromString(json['status']),
      twoFactorEnabled: json['twoFactorEnabled'] ?? false,
      emailVerified: json['emailVerified'] ?? false,
      phoneVerified: json['phoneVerified'] ?? false,
      referralCode: json['referralCode'] ?? '',
      referredBy: json['referredBy'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'avatar': avatar,
      'country': country,
      'language': language,
      'currency': currency,
      'kycLevel': kycLevel,
      'status': status.value,
      'twoFactorEnabled': twoFactorEnabled,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? avatar,
    String? country,
    String? language,
    String? currency,
    int? kycLevel,
    UserStatus? status,
    bool? twoFactorEnabled,
    bool? emailVerified,
    bool? phoneVerified,
    String? referralCode,
    String? referredBy,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      country: country ?? this.country,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      kycLevel: kycLevel ?? this.kycLevel,
      status: status ?? this.status,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Empty user for initialization
  static User get empty => User(
        id: '',
        email: '',
        name: '',
        referralCode: '',
        createdAt: DateTime.now(),
      );

  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;
}

/// User status enum
enum UserStatus {
  active('active'),
  inactive('inactive'),
  suspended('suspended');

  final String value;
  const UserStatus(this.value);

  static UserStatus fromString(String? value) {
    switch (value) {
      case 'inactive':
        return UserStatus.inactive;
      case 'suspended':
        return UserStatus.suspended;
      default:
        return UserStatus.active;
    }
  }
}

/// Profile update request
class UpdateProfileRequest {
  final String? name;
  final String? phone;
  final String? country;
  final String? language;
  final String? currency;

  UpdateProfileRequest({
    this.name,
    this.phone,
    this.country,
    this.language,
    this.currency,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (country != null) 'country': country,
      if (language != null) 'language': language,
      if (currency != null) 'currency': currency,
    };
  }
}
