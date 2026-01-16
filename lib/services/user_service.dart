import 'dart:io';
import 'package:dio/dio.dart';
import 'api_service.dart';
import '../config/api_config.dart';
import '../models/user.dart';

/// KYC Document model
class KYCDocument {
  final String id;
  final String type; // id_front, id_back, selfie, proof_of_address
  final String status; // pending, approved, rejected
  final String? rejectionReason;
  final DateTime uploadedAt;

  KYCDocument({
    required this.id,
    required this.type,
    required this.status,
    this.rejectionReason,
    required this.uploadedAt,
  });

  factory KYCDocument.fromJson(Map<String, dynamic> json) {
    return KYCDocument(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      status: json['status'] ?? 'pending',
      rejectionReason: json['rejectionReason'] ?? json['rejection_reason'],
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'])
          : json['uploaded_at'] != null
              ? DateTime.parse(json['uploaded_at'])
              : DateTime.now(),
    );
  }
}

/// KYC Status model - matches backend response
class KYCStatus {
  final String level; // none, basic, advanced
  final String status; // not_started, pending, approved, rejected
  final List<KYCDocument> documents;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final Map<String, dynamic>? limits;

  KYCStatus({
    required this.level,
    required this.status,
    required this.documents,
    this.submittedAt,
    this.approvedAt,
    this.rejectionReason,
    this.limits,
  });

  factory KYCStatus.fromJson(Map<String, dynamic> json) {
    return KYCStatus(
      level: json['level'] ?? json['kycLevel'] ?? 'none',
      status: json['status'] ?? json['verificationStatus'] ?? 'not_started',
      documents: (json['documents'] as List? ?? [])
          .map((d) => KYCDocument.fromJson(d))
          .toList(),
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'])
          : null,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
          : null,
      rejectionReason: json['rejectionReason'],
      limits: json['limits'],
    );
  }

  bool get isVerified => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
}

/// Referral model
class Referral {
  final String id;
  final String email;
  final String status; // registered, verified, traded
  final double earnings;
  final DateTime joinedAt;

  Referral({
    required this.id,
    required this.email,
    required this.status,
    required this.earnings,
    required this.joinedAt,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'] ?? json['userId'] ?? '',
      email: json['email'] ?? '',
      status: json['status'] ?? 'registered',
      earnings: (json['earnings'] ?? json['commission'] ?? 0).toDouble(),
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }
}

/// Referral Stats model - matches backend /api/referral/stats response
class ReferralStats {
  final String referralCode;
  final String referralLink;
  final int totalReferrals;
  final int activeReferrals;
  final double totalEarnings;
  final double pendingEarnings;
  final double commissionRate;
  final List<Referral> referrals;

  ReferralStats({
    required this.referralCode,
    required this.referralLink,
    required this.totalReferrals,
    required this.activeReferrals,
    required this.totalEarnings,
    required this.pendingEarnings,
    this.commissionRate = 0.10,
    required this.referrals,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      referralCode: json['referralCode'] ?? json['code'] ?? '',
      referralLink: json['referralLink'] ?? json['link'] ?? '',
      totalReferrals: json['totalReferrals'] ?? json['totalCount'] ?? 0,
      activeReferrals: json['activeReferrals'] ?? json['activeCount'] ?? 0,
      totalEarnings: (json['totalEarnings'] ?? json['totalCommission'] ?? 0).toDouble(),
      pendingEarnings: (json['pendingEarnings'] ?? json['pendingCommission'] ?? 0).toDouble(),
      commissionRate: (json['commissionRate'] ?? 0.10).toDouble(),
      referrals: (json['referrals'] as List? ?? [])
          .map((r) => Referral.fromJson(r))
          .toList(),
    );
  }
}

/// Reward Task model
class RewardTask {
  final String id;
  final String title;
  final String description;
  final int points;
  final bool completed;
  final String? category;

  RewardTask({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    required this.completed,
    this.category,
  });

  factory RewardTask.fromJson(Map<String, dynamic> json) {
    return RewardTask(
      id: json['id'] ?? json['taskId'] ?? '',
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      points: json['points'] ?? json['reward'] ?? 0,
      completed: json['completed'] ?? json['isCompleted'] ?? false,
      category: json['category'],
    );
  }
}

/// Reward Tier model
class RewardTier {
  final String id;
  final String name;
  final int requiredPoints;
  final double tradingFeeDiscount;
  final double referralBonus;
  final List<String> benefits;

  RewardTier({
    required this.id,
    required this.name,
    required this.requiredPoints,
    required this.tradingFeeDiscount,
    required this.referralBonus,
    required this.benefits,
  });

  factory RewardTier.fromJson(Map<String, dynamic> json) {
    return RewardTier(
      id: json['id'] ?? json['tierId'] ?? '',
      name: json['name'] ?? json['tierName'] ?? '',
      requiredPoints: json['requiredPoints'] ?? json['minPoints'] ?? 0,
      tradingFeeDiscount: (json['tradingFeeDiscount'] ?? json['feeDiscount'] ?? 0).toDouble(),
      referralBonus: (json['referralBonus'] ?? 0).toDouble(),
      benefits: List<String>.from(json['benefits'] ?? json['perks'] ?? []),
    );
  }
}

/// Rewards Summary model - matches backend /api/rewards/summary
class RewardsSummary {
  final int totalPoints;
  final int availablePoints;
  final String currentTier;
  final String nextTier;
  final int pointsToNextTier;
  final List<RewardTask> tasks;
  final List<RewardTier> tiers;

  RewardsSummary({
    required this.totalPoints,
    required this.availablePoints,
    required this.currentTier,
    required this.nextTier,
    required this.pointsToNextTier,
    required this.tasks,
    required this.tiers,
  });

  factory RewardsSummary.fromJson(Map<String, dynamic> json) {
    return RewardsSummary(
      totalPoints: json['totalPoints'] ?? json['points'] ?? 0,
      availablePoints: json['availablePoints'] ?? json['balance'] ?? 0,
      currentTier: json['currentTier'] ?? json['tier'] ?? 'Bronze',
      nextTier: json['nextTier'] ?? '',
      pointsToNextTier: json['pointsToNextTier'] ?? json['remaining'] ?? 0,
      tasks: (json['tasks'] as List? ?? [])
          .map((t) => RewardTask.fromJson(t))
          .toList(),
      tiers: (json['tiers'] as List? ?? [])
          .map((t) => RewardTier.fromJson(t))
          .toList(),
    );
  }
}

/// Support Ticket model
class SupportTicket {
  final String id;
  final String subject;
  final String category;
  final String status; // open, in_progress, resolved, closed
  final String priority; // low, medium, high
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<TicketMessage> messages;

  SupportTicket({
    required this.id,
    required this.subject,
    required this.category,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.updatedAt,
    required this.messages,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] ?? json['ticketId'] ?? '',
      subject: json['subject'] ?? json['title'] ?? '',
      category: json['category'] ?? json['type'] ?? '',
      status: json['status'] ?? 'open',
      priority: json['priority'] ?? 'medium',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      messages: (json['messages'] as List? ?? [])
          .map((m) => TicketMessage.fromJson(m))
          .toList(),
    );
  }
}

/// Ticket Message model
class TicketMessage {
  final String id;
  final String content;
  final String sender; // user, support
  final DateTime createdAt;
  final List<String>? attachments;

  TicketMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.createdAt,
    this.attachments,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] ?? json['messageId'] ?? '',
      content: json['content'] ?? json['message'] ?? json['body'] ?? '',
      sender: json['sender'] ?? json['from'] ?? 'user',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
    );
  }
}

/// Login History entry model
class LoginHistory {
  final String id;
  final String ipAddress;
  final String device;
  final String location;
  final DateTime timestamp;
  final bool successful;

  LoginHistory({
    required this.id,
    required this.ipAddress,
    required this.device,
    required this.location,
    required this.timestamp,
    required this.successful,
  });

  factory LoginHistory.fromJson(Map<String, dynamic> json) {
    return LoginHistory(
      id: json['id'] ?? '',
      ipAddress: json['ipAddress'] ?? json['ip'] ?? '',
      device: json['device'] ?? json['userAgent'] ?? '',
      location: json['location'] ?? json['country'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      successful: json['successful'] ?? json['success'] ?? true,
    );
  }
}

/// User Service - Handles all user-related API calls
class UserService {
  final ApiService _api = api;

  // ============================================
  // PROFILE METHODS
  // ============================================

  /// Get current user profile
  Future<User> getProfile() async {
    final response = await _api.get(ApiConfig.userProfile);

    // Handle both direct user object and wrapped response
    final userData = response['user'] ?? response;
    return User.fromJson(userData);
  }

  /// Update user profile
  Future<User> updateProfile({
    String? fullName,
    String? phone,
    String? country,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['fullName'] = fullName;
    if (phone != null) data['phone'] = phone;
    if (country != null) data['country'] = country;

    final response = await _api.put(ApiConfig.userProfile, data: data);
    final userData = response['user'] ?? response;
    return User.fromJson(userData);
  }

  /// Upload profile avatar
  Future<String> uploadAvatar(File file) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(file.path),
    });
    final response = await _api.uploadMultipart(
      '${ApiConfig.userProfile}/avatar',
      formData: formData,
    );
    return response['avatarUrl'] ?? response['url'] ?? '';
  }

  // ============================================
  // SECURITY METHODS
  // ============================================

  /// Get login history
  Future<List<LoginHistory>> getLoginHistory() async {
    final response = await _api.get(ApiConfig.userLoginHistory);
    final List<dynamic> data = response['history'] ?? response['logins'] ?? [];
    return data.map((json) => LoginHistory.fromJson(json)).toList();
  }

  /// Set/update anti-phishing code
  Future<String> setAntiPhishingCode(String code) async {
    final response = await _api.post(
      ApiConfig.userAntiPhishing,
      data: {'code': code},
    );
    return response['message'] ?? 'Anti-phishing code updated';
  }

  /// Get anti-phishing code status
  Future<Map<String, dynamic>> getAntiPhishingStatus() async {
    final response = await _api.get(ApiConfig.userAntiPhishing);
    return {
      'enabled': response['enabled'] ?? false,
      'code': response['code'],
    };
  }

  // ============================================
  // KYC METHODS
  // ============================================

  /// Get KYC status
  Future<KYCStatus> getKYCStatus() async {
    final response = await _api.get(ApiConfig.kycStatus);
    return KYCStatus.fromJson(response);
  }

  /// Submit KYC documents
  Future<Map<String, dynamic>> submitKYC({
    required String fullName,
    required String dateOfBirth,
    required String nationality,
    required String idType,
    required String idNumber,
    required File idFront,
    required File idBack,
    required File selfie,
    File? proofOfAddress,
  }) async {
    final formData = FormData.fromMap({
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'nationality': nationality,
      'idType': idType,
      'idNumber': idNumber,
      'idFront': await MultipartFile.fromFile(idFront.path),
      'idBack': await MultipartFile.fromFile(idBack.path),
      'selfie': await MultipartFile.fromFile(selfie.path),
      if (proofOfAddress != null)
        'proofOfAddress': await MultipartFile.fromFile(proofOfAddress.path),
    });

    final response = await _api.uploadMultipart(
      ApiConfig.kycSubmit,
      formData: formData,
    );

    return {
      'status': response['status'] ?? 'pending',
      'message': response['message'] ?? 'KYC submitted successfully',
    };
  }

  /// Retry KYC after rejection
  Future<Map<String, dynamic>> retryKYC({
    required String idType,
    required String idNumber,
    File? idFront,
    File? idBack,
    File? selfie,
    File? proofOfAddress,
  }) async {
    final Map<String, dynamic> formMap = {
      'idType': idType,
      'idNumber': idNumber,
    };

    if (idFront != null) {
      formMap['idFront'] = await MultipartFile.fromFile(idFront.path);
    }
    if (idBack != null) {
      formMap['idBack'] = await MultipartFile.fromFile(idBack.path);
    }
    if (selfie != null) {
      formMap['selfie'] = await MultipartFile.fromFile(selfie.path);
    }
    if (proofOfAddress != null) {
      formMap['proofOfAddress'] = await MultipartFile.fromFile(proofOfAddress.path);
    }

    final formData = FormData.fromMap(formMap);
    final response = await _api.uploadMultipart(
      ApiConfig.kycRetry,
      formData: formData,
    );

    return {
      'status': response['status'] ?? 'pending',
      'message': response['message'] ?? 'KYC retry submitted',
    };
  }

  // ============================================
  // REFERRAL METHODS
  // ============================================

  /// Get referral stats
  Future<ReferralStats> getReferralStats() async {
    final response = await _api.get(ApiConfig.referralStats);
    return ReferralStats.fromJson(response);
  }

  /// Get referral code
  Future<String> getReferralCode() async {
    final response = await _api.get(ApiConfig.referralCode);
    return response['code'] ?? response['referralCode'] ?? '';
  }

  /// Apply referral code
  Future<String> applyReferralCode(String code) async {
    final response = await _api.post(
      ApiConfig.referralApply,
      data: {'code': code},
    );
    return response['message'] ?? 'Referral code applied';
  }

  // ============================================
  // REWARDS METHODS
  // ============================================

  /// Get rewards summary
  Future<RewardsSummary> getRewardsSummary() async {
    final response = await _api.get(ApiConfig.rewardsSummary);
    return RewardsSummary.fromJson(response);
  }

  /// Get available tasks
  Future<List<RewardTask>> getRewardTasks() async {
    final response = await _api.get(ApiConfig.rewardsTasks);
    final List<dynamic> data = response['tasks'] ?? response;
    return data.map((json) => RewardTask.fromJson(json)).toList();
  }

  /// Get reward tiers
  Future<List<RewardTier>> getRewardTiers() async {
    final response = await _api.get(ApiConfig.rewardsTiers);
    final List<dynamic> data = response['tiers'] ?? response;
    return data.map((json) => RewardTier.fromJson(json)).toList();
  }

  /// Get rewards history
  Future<List<Map<String, dynamic>>> getRewardsHistory({int page = 1, int limit = 20}) async {
    final response = await _api.get(
      ApiConfig.rewardsHistory,
      queryParameters: {'page': page, 'limit': limit},
    );
    final List<dynamic> data = response['history'] ?? response['items'] ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  // ============================================
  // SUPPORT TICKET METHODS
  // ============================================

  /// Get all support tickets
  Future<List<SupportTicket>> getTickets({String? status, int page = 1, int limit = 20}) async {
    final response = await _api.get(
      ApiConfig.supportTickets,
      queryParameters: {
        if (status != null) 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    final List<dynamic> data = response['tickets'] ?? response['items'] ?? [];
    return data.map((json) => SupportTicket.fromJson(json)).toList();
  }

  /// Get single ticket by ID
  Future<SupportTicket> getTicket(String ticketId) async {
    final response = await _api.get('${ApiConfig.supportTickets}/$ticketId');
    final ticketData = response['ticket'] ?? response;
    return SupportTicket.fromJson(ticketData);
  }

  /// Create new support ticket
  Future<SupportTicket> createTicket({
    required String subject,
    required String category,
    required String message,
    String priority = 'medium',
  }) async {
    final response = await _api.post(
      ApiConfig.supportTickets,
      data: {
        'subject': subject,
        'category': category,
        'message': message,
        'priority': priority,
      },
    );
    final ticketData = response['ticket'] ?? response;
    return SupportTicket.fromJson(ticketData);
  }

  /// Reply to a ticket
  Future<TicketMessage> replyToTicket(String ticketId, String message) async {
    final response = await _api.post(
      '${ApiConfig.supportTickets}/$ticketId/reply',
      data: {'message': message},
    );
    final messageData = response['message'] ?? response;
    return TicketMessage.fromJson(messageData);
  }

  /// Close a ticket
  Future<void> closeTicket(String ticketId) async {
    await _api.post('${ApiConfig.supportTickets}/$ticketId/close');
  }
}

/// Update Profile Request model
class UpdateProfileRequest {
  final String? fullName;
  final String? phone;
  final String? country;

  UpdateProfileRequest({
    this.fullName,
    this.phone,
    this.country,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (fullName != null) map['fullName'] = fullName;
    if (phone != null) map['phone'] = phone;
    if (country != null) map['country'] = country;
    return map;
  }
}

/// Global user service instance
final userService = UserService();
