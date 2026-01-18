import 'package:flutter_test/flutter_test.dart';
import 'package:crymadx/services/user_service.dart';

void main() {
  group('KYCDocument', () {
    test('fromJson parses document correctly', () {
      final json = {
        'id': 'doc-1',
        'type': 'id_front',
        'status': 'approved',
        'uploadedAt': '2024-01-01T12:00:00Z',
      };

      final doc = KYCDocument.fromJson(json);

      expect(doc.id, 'doc-1');
      expect(doc.type, 'id_front');
      expect(doc.status, 'approved');
      expect(doc.rejectionReason, isNull);
    });

    test('fromJson handles rejection reason', () {
      final json = {
        'id': 'doc-2',
        'type': 'selfie',
        'status': 'rejected',
        'rejectionReason': 'Image is blurry',
        'uploadedAt': '2024-01-01T12:00:00Z',
      };

      final doc = KYCDocument.fromJson(json);

      expect(doc.status, 'rejected');
      expect(doc.rejectionReason, 'Image is blurry');
    });
  });

  group('KYCStatus', () {
    test('fromJson parses status with int level', () {
      final json = {
        'level': 2,
        'status': 'approved',
        'documents': [],
      };

      final status = KYCStatus.fromJson(json);

      expect(status.level, 2);
      expect(status.status, 'approved');
      expect(status.isVerified, true);
    });

    test('fromJson parses status with string level', () {
      final json = {
        'level': 'intermediate',
        'status': 'pending',
        'documents': [],
      };

      final status = KYCStatus.fromJson(json);

      expect(status.level, 2);
      expect(status.status, 'pending');
      expect(status.isPending, true);
    });

    test('fromJson parses level none', () {
      final json = {
        'level': 'none',
        'status': 'not_started',
        'documents': [],
      };

      final status = KYCStatus.fromJson(json);

      expect(status.level, 0);
    });

    test('fromJson parses level basic', () {
      final json = {
        'level': 'basic',
        'status': 'approved',
        'documents': [],
      };

      final status = KYCStatus.fromJson(json);

      expect(status.level, 1);
    });

    test('fromJson parses level advanced', () {
      final json = {
        'level': 'advanced',
        'status': 'approved',
        'documents': [],
      };

      final status = KYCStatus.fromJson(json);

      expect(status.level, 3);
    });

    test('fromJson detects step completion from documents', () {
      final json = {
        'level': 1,
        'status': 'pending',
        'documents': [
          {'id': '1', 'type': 'id_front', 'status': 'pending', 'uploadedAt': '2024-01-01T12:00:00Z'},
          {'id': '2', 'type': 'selfie', 'status': 'pending', 'uploadedAt': '2024-01-01T12:00:00Z'},
        ],
      };

      final status = KYCStatus.fromJson(json);

      expect(status.documentSubmitted, true);
      expect(status.selfieSubmitted, true);
      expect(status.addressProofSubmitted, false);
    });

    test('fromJson handles explicit step flags', () {
      final json = {
        'level': 0,
        'status': 'not_started',
        'documents': [],
        'personalInfoSubmitted': true,
        'documentSubmitted': true,
        'selfieSubmitted': false,
        'addressProofSubmitted': false,
      };

      final status = KYCStatus.fromJson(json);

      expect(status.personalInfoSubmitted, true);
      expect(status.documentSubmitted, true);
      expect(status.selfieSubmitted, false);
    });

    test('isVerified returns true for approved status', () {
      final status = KYCStatus(level: 2, status: 'approved', documents: []);

      expect(status.isVerified, true);
      expect(status.isPending, false);
      expect(status.isRejected, false);
    });

    test('isPending returns true for pending status', () {
      final status = KYCStatus(level: 0, status: 'pending', documents: []);

      expect(status.isPending, true);
      expect(status.isVerified, false);
      expect(status.isRejected, false);
    });

    test('isRejected returns true for rejected status', () {
      final status = KYCStatus(
        level: 0,
        status: 'rejected',
        documents: [],
        rejectionReason: 'Documents unclear',
      );

      expect(status.isRejected, true);
      expect(status.isVerified, false);
      expect(status.rejectionReason, 'Documents unclear');
    });
  });

  group('ReferralStats', () {
    test('fromJson parses referral stats correctly', () {
      final json = {
        'referralCode': 'ABC123',
        'referralLink': 'https://crymadx.io/ref/ABC123',
        'totalReferrals': 10,
        'activeReferrals': 5,
        'totalEarnings': 150.50,
        'pendingEarnings': 25.00,
        'commissionRate': 0.10,
        'referrals': [
          {
            'id': 'ref-1',
            'email': 'user@example.com',
            'status': 'verified',
            'earnings': 50.00,
            'joinedAt': '2024-01-01T12:00:00Z',
          }
        ],
      };

      final stats = ReferralStats.fromJson(json);

      expect(stats.referralCode, 'ABC123');
      expect(stats.totalReferrals, 10);
      expect(stats.activeReferrals, 5);
      expect(stats.totalEarnings, 150.50);
      expect(stats.pendingEarnings, 25.00);
      expect(stats.referrals.length, 1);
      expect(stats.referrals[0].email, 'user@example.com');
    });

    test('fromJson handles alternative field names', () {
      final json = {
        'code': 'XYZ789',
        'link': 'https://crymadx.io/ref/XYZ789',
        'totalCount': 5,
        'activeCount': 3,
        'totalCommission': 100.00,
        'pendingCommission': 10.00,
        'referrals': [],
      };

      final stats = ReferralStats.fromJson(json);

      expect(stats.referralCode, 'XYZ789');
      expect(stats.totalReferrals, 5);
      expect(stats.totalEarnings, 100.00);
    });
  });

  group('RewardsSummary', () {
    test('fromJson parses rewards summary correctly', () {
      final json = {
        'totalPoints': 1500,
        'availablePoints': 1200,
        'currentTier': 'Silver',
        'nextTier': 'Gold',
        'pointsToNextTier': 500,
        'tasks': [
          {'id': 'task-1', 'title': 'Complete KYC', 'description': 'Verify your identity', 'points': 100, 'completed': true}
        ],
        'tiers': [
          {'id': 'tier-1', 'name': 'Bronze', 'requiredPoints': 0, 'tradingFeeDiscount': 0.05, 'referralBonus': 0.0, 'benefits': ['Basic access']}
        ],
      };

      final summary = RewardsSummary.fromJson(json);

      expect(summary.totalPoints, 1500);
      expect(summary.availablePoints, 1200);
      expect(summary.currentTier, 'Silver');
      expect(summary.nextTier, 'Gold');
      expect(summary.pointsToNextTier, 500);
      expect(summary.tasks.length, 1);
      expect(summary.tiers.length, 1);
    });
  });

  group('SupportTicket', () {
    test('fromJson parses ticket correctly', () {
      final json = {
        'id': 'ticket-1',
        'subject': 'Withdrawal issue',
        'category': 'transactions',
        'status': 'in_progress',
        'priority': 'high',
        'createdAt': '2024-01-01T12:00:00Z',
        'messages': [
          {
            'id': 'msg-1',
            'content': 'I have an issue with my withdrawal',
            'sender': 'user',
            'createdAt': '2024-01-01T12:00:00Z',
          }
        ],
      };

      final ticket = SupportTicket.fromJson(json);

      expect(ticket.id, 'ticket-1');
      expect(ticket.subject, 'Withdrawal issue');
      expect(ticket.category, 'transactions');
      expect(ticket.status, 'in_progress');
      expect(ticket.priority, 'high');
      expect(ticket.messages.length, 1);
      expect(ticket.messages[0].content, 'I have an issue with my withdrawal');
    });
  });

  group('LoginHistory', () {
    test('fromJson parses login history correctly', () {
      final json = {
        'id': 'login-1',
        'ipAddress': '192.168.1.1',
        'device': 'Chrome on Windows',
        'location': 'United States',
        'timestamp': '2024-01-01T12:00:00Z',
        'successful': true,
      };

      final history = LoginHistory.fromJson(json);

      expect(history.id, 'login-1');
      expect(history.ipAddress, '192.168.1.1');
      expect(history.device, 'Chrome on Windows');
      expect(history.location, 'United States');
      expect(history.successful, true);
    });

    test('fromJson handles alternative field names', () {
      final json = {
        'id': 'login-2',
        'ip': '10.0.0.1',
        'userAgent': 'Mobile Safari',
        'country': 'Nigeria',
        'createdAt': '2024-01-01T12:00:00Z',
        'success': false,
      };

      final history = LoginHistory.fromJson(json);

      expect(history.ipAddress, '10.0.0.1');
      expect(history.device, 'Mobile Safari');
      expect(history.location, 'Nigeria');
      expect(history.successful, false);
    });
  });

  group('UserService', () {
    test('userService global instance is available', () {
      expect(userService, isNotNull);
      expect(userService, isA<UserService>());
    });
  });
}
