import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/app_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/currency_provider.dart';
import '../../providers/theme_provider.dart';

// Language options
class Language {
  final String code;
  final String name;
  final String flag;

  const Language({required this.code, required this.name, required this.flag});
}

const languages = [
  Language(code: 'en', name: 'English', flag: '🇺🇸'),
  Language(code: 'es', name: 'Español', flag: '🇪🇸'),
  Language(code: 'fr', name: 'Français', flag: '🇫🇷'),
  Language(code: 'de', name: 'Deutsch', flag: '🇩🇪'),
  Language(code: 'it', name: 'Italiano', flag: '🇮🇹'),
  Language(code: 'pt', name: 'Português', flag: '🇧🇷'),
  Language(code: 'ru', name: 'Русский', flag: '🇷🇺'),
  Language(code: 'zh', name: '中文', flag: '🇨🇳'),
  Language(code: 'ja', name: '日本語', flag: '🇯🇵'),
  Language(code: 'ko', name: '한국어', flag: '🇰🇷'),
  Language(code: 'ar', name: 'العربية', flag: '🇸🇦'),
  Language(code: 'hi', name: 'हिन्दी', flag: '🇮🇳'),
];

// FAQ data
class FAQ {
  final String question;
  final String answer;

  const FAQ({required this.question, required this.answer});
}

class FAQSection {
  final String category;
  final List<FAQ> questions;

  const FAQSection({required this.category, required this.questions});
}

const helpFaqs = [
  FAQSection(
    category: 'Getting Started',
    questions: [
      FAQ(
        question: 'How do I create an account?',
        answer: 'Download the CrymadX app, tap "Sign Up", enter your email and create a password. Verify your email to complete registration.',
      ),
      FAQ(
        question: 'How do I verify my identity (KYC)?',
        answer: 'Go to Profile > KYC Verification. Upload a valid ID document and take a selfie. Verification usually takes 1-2 business days.',
      ),
      FAQ(
        question: 'Is CrymadX safe to use?',
        answer: 'Yes! We use bank-grade encryption, 2FA authentication, and cold storage for 95% of assets. We are fully licensed and regulated.',
      ),
    ],
  ),
  FAQSection(
    category: 'Trading',
    questions: [
      FAQ(
        question: 'How do I buy cryptocurrency?',
        answer: 'Go to Markets, select your desired crypto, tap "Buy", enter the amount, choose payment method, and confirm your purchase.',
      ),
      FAQ(
        question: 'What are the trading fees?',
        answer: 'Spot trading fees are 0.1% for makers and 0.1% for takers. VIP levels get reduced fees up to 0.02%.',
      ),
      FAQ(
        question: 'How do I read the charts?',
        answer: 'Green candles show price increase, red show decrease. Use timeframes (1m to 1W) to analyze different periods.',
      ),
    ],
  ),
  FAQSection(
    category: 'Deposits & Withdrawals',
    questions: [
      FAQ(
        question: 'How do I deposit funds?',
        answer: 'Go to Wallet > Deposit, select your crypto, copy the wallet address or scan QR code, and send from your external wallet.',
      ),
      FAQ(
        question: 'How long do withdrawals take?',
        answer: 'Crypto withdrawals are processed within 30 minutes. Bank withdrawals take 1-3 business days.',
      ),
      FAQ(
        question: 'What are the withdrawal limits?',
        answer: 'Basic users: \$2,000/day. Verified users: \$100,000/day. VIP users: Unlimited.',
      ),
    ],
  ),
  FAQSection(
    category: 'Security',
    questions: [
      FAQ(
        question: 'How do I enable 2FA?',
        answer: 'Go to Profile > Security > Two-Factor Authentication. Scan the QR code with Google Authenticator or Authy.',
      ),
      FAQ(
        question: 'What if I forget my password?',
        answer: 'Tap "Forgot Password" on login screen. Enter your email and follow the reset instructions sent to you.',
      ),
      FAQ(
        question: 'How do I secure my account?',
        answer: 'Enable 2FA, use a strong unique password, never share your credentials, and enable withdrawal whitelist.',
      ),
    ],
  ),
];

const termsContent = '''
TERMS AND CONDITIONS

Last Updated: December 2024

1. ACCEPTANCE OF TERMS
By accessing and using the CrymadX platform, you agree to be bound by these Terms and Conditions. If you do not agree, please do not use our services.

2. ELIGIBILITY
You must be at least 18 years old and legally able to enter into contracts. Users from restricted jurisdictions are prohibited from using our services.

3. ACCOUNT REGISTRATION
- You must provide accurate and complete information
- You are responsible for maintaining account security
- One account per person is permitted
- Account sharing is prohibited

4. TRADING SERVICES
- All trades are final and cannot be reversed
- We do not provide investment advice
- Past performance does not guarantee future results
- Trading involves significant risk of loss

5. FEES AND PAYMENTS
- Trading fees are displayed before each transaction
- Deposit and withdrawal fees may apply
- All fees are subject to change with notice

6. PROHIBITED ACTIVITIES
- Market manipulation
- Money laundering
- Fraudulent activities
- Unauthorized access attempts

7. INTELLECTUAL PROPERTY
All content, trademarks, and technology are owned by CrymadX and protected by international copyright laws.

8. LIMITATION OF LIABILITY
CrymadX is not liable for trading losses, technical issues, or third-party service failures beyond our reasonable control.

9. DISPUTE RESOLUTION
Any disputes shall be resolved through binding arbitration in accordance with applicable laws.

10. MODIFICATIONS
We reserve the right to modify these terms at any time. Continued use constitutes acceptance of modified terms.

For questions, contact: legal@crymadx.com
''';

const privacyContent = '''
PRIVACY POLICY

Last Updated: December 2024

1. INFORMATION WE COLLECT

Personal Information:
- Name, email, phone number
- Date of birth, nationality
- Government ID for KYC verification
- Residential address

Financial Information:
- Bank account details
- Transaction history
- Wallet addresses

Technical Information:
- IP address and device information
- Browser type and settings
- Usage patterns and preferences

2. HOW WE USE YOUR INFORMATION

- Account creation and management
- Identity verification (KYC/AML)
- Transaction processing
- Customer support
- Security and fraud prevention
- Legal compliance
- Service improvement

3. DATA SHARING

We may share data with:
- Payment processors
- KYC verification providers
- Legal authorities when required
- Service providers under strict agreements

We NEVER sell your personal data to third parties.

4. DATA SECURITY

- 256-bit AES encryption
- Two-factor authentication
- Regular security audits
- Cold storage for crypto assets
- SOC 2 Type II compliance

5. DATA RETENTION

We retain your data for:
- Active accounts: Duration of account
- Closed accounts: 5 years (legal requirement)
- Transaction records: 7 years

6. YOUR RIGHTS

You have the right to:
- Access your personal data
- Request data correction
- Request data deletion
- Data portability
- Withdraw consent

7. COOKIES

We use cookies for:
- Authentication
- Preferences
- Analytics
- Security

8. CHILDREN'S PRIVACY

Our services are not intended for users under 18.

9. INTERNATIONAL TRANSFERS

Your data may be processed in different countries with adequate protection measures.

10. CONTACT US

Privacy Officer: privacy@crymadx.com
''';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Language _selectedLanguage = languages[0];
  String? _expandedFaq;

  // Controllers for edit profile
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  void _showLanguageModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.backgroundSecondary : AppColors.lightBackgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _LanguageModal(
        selectedLanguage: _selectedLanguage,
        onSelect: (lang) {
          setState(() => _selectedLanguage = lang);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showThemeModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.backgroundSecondary : AppColors.lightBackgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _ThemeModal(),
    );
  }

  void _showCurrencyModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.backgroundSecondary : AppColors.lightBackgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _CurrencyModal(
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showHelpModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.backgroundSecondary : AppColors.lightBackgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _HelpModal(
          scrollController: scrollController,
          expandedFaq: _expandedFaq,
          onFaqTap: (key) {
            setState(() {
              _expandedFaq = _expandedFaq == key ? null : key;
            });
          },
        ),
      ),
    );
  }

  void _showTermsModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.backgroundSecondary : AppColors.lightBackgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _LegalModal(
          title: 'Terms & Conditions',
          content: termsContent,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showPrivacyModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.backgroundSecondary : AppColors.lightBackgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _LegalModal(
          title: 'Privacy Policy',
          content: privacyContent,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _showAvatarModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.backgroundSecondary : AppColors.lightBackgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _AvatarModal(),
    );
  }

  void _showEditProfileModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileProvider = context.read<ProfileProvider>();
    _nameController.text = profileProvider.profile.name;
    _emailController.text = profileProvider.profile.email;
    _phoneController.text = profileProvider.profile.phone;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.backgroundSecondary : AppColors.lightBackgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _EditProfileModal(
          nameController: _nameController,
          emailController: _emailController,
          phoneController: _phoneController,
          onAvatarTap: () {
            Navigator.pop(context);
            Future.delayed(const Duration(milliseconds: 300), _showAvatarModal);
          },
        ),
      ),
    );
  }

  void _show2FAModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.backgroundSecondary : AppColors.lightBackgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _TwoFAModal(
          scrollController: scrollController,
          verificationController: _verificationCodeController,
        ),
      ),
    );
  }

  void _handleMenuPress(String label) {
    switch (label) {
      case 'Security':
        _show2FAModal();
        break;
      case 'KYC Verification':
        context.push('/kyc');
        break;
      case 'Payment Methods':
        context.push('/payment-methods');
        break;
      case 'Notifications':
        context.push('/notifications');
        break;
      case 'Transaction History':
        context.push('/transactions');
        break;
      case 'Rewards':
        context.push('/rewards');
        break;
      case 'Referral Program':
        context.push('/referral');
        break;
      case 'Support Tickets':
        context.push('/tickets');
        break;
      case 'Language':
        _showLanguageModal();
        break;
      case 'Currency':
        _showCurrencyModal();
        break;
      case 'Help Center':
        _showHelpModal();
        break;
      case 'Terms & Conditions':
        _showTermsModal();
        break;
      case 'Privacy Policy':
        _showPrivacyModal();
        break;
    }
  }

  void _handleLogout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF000000), fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to logout?', style: TextStyle(color: isDark ? Colors.grey : const Color(0xFF555555))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.grey[500] : const Color(0xFF555555))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
              context.go('/login');
            },
            child: Text('Logout', style: TextStyle(color: AppColors.tradingSell)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final profile = profileProvider.profile;
    final selectedAvatar = profileProvider.selectedAvatar;
    final screenWidth = MediaQuery.of(context).size.width;
    final contentWidth = screenWidth > 500 ? 460.0 : screenWidth;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : AppColors.lightBackgroundPrimary;
    final borderColor = isDark ? const Color(0xFF151515) : const Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Container(
            width: contentWidth,
            margin: screenWidth > 500
                ? const EdgeInsets.symmetric(horizontal: 12)
                : EdgeInsets.zero,
            decoration: screenWidth > 500
                ? BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: borderColor, width: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  )
                : BoxDecoration(color: bgColor),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(screenWidth > 500 ? 16 : 0),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _HeaderButton(
                            icon: Icons.arrow_back,
                            onTap: () => context.pop(),
                            isDark: isDark,
                          ),
                          Text(
                            'Profile',
                            style: AppTypography.headlineMedium.copyWith(
                              color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          _HeaderButton(
                            icon: Icons.edit,
                            onTap: _showEditProfileModal,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

              // Profile Card
              GlassCard(
                variant: GlassVariant.prominent,
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar
                        GestureDetector(
                          onTap: _showAvatarModal,
                          child: Stack(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      selectedAvatar.color,
                                      selectedAvatar.color.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    selectedAvatar.emoji,
                                    style: const TextStyle(fontSize: 36),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? AppColors.backgroundPrimary : AppColors.lightBackgroundPrimary,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.name,
                                style: AppTypography.titleLarge.copyWith(
                                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                profile.email,
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: AppColors.tradingBuy,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Email Verified',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.tradingBuy,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Stats Row
                    Container(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(value: 'Level 1', label: 'VIP Status'),
                          Container(
                            width: 1,
                            height: 32,
                            color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
                          ),
                          _StatItem(value: '\$2,000', label: 'Daily Limit'),
                          Container(
                            width: 1,
                            height: 32,
                            color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder,
                          ),
                          _StatItem(value: '12', label: 'Referrals'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // KYC Alert
              GestureDetector(
                onTap: () => context.push('/kyc'),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.statusWarningBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.statusWarning.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.statusWarning.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.warning_amber_outlined,
                          color: AppColors.statusWarning,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete KYC Verification',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.statusWarning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Unlock higher withdrawal limits',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Account Section
              _MenuSection(
                title: 'Account',
                items: [
                  _MenuItem(
                    icon: Icons.shield_outlined,
                    label: 'Security',
                    badge: profileProvider.twoFactorEnabled ? '2FA Enabled' : 'Enable 2FA',
                    badgeType: profileProvider.twoFactorEnabled ? 'success' : 'warning',
                    onTap: () => _handleMenuPress('Security'),
                  ),
                  _MenuItem(
                    icon: Icons.badge_outlined,
                    label: 'KYC Verification',
                    badge: 'Pending',
                    badgeType: 'warning',
                    onTap: () => _handleMenuPress('KYC Verification'),
                  ),
                  _MenuItem(
                    icon: Icons.credit_card_outlined,
                    label: 'Payment Methods',
                    onTap: () => _handleMenuPress('Payment Methods'),
                  ),
                  _MenuItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Transaction History',
                    onTap: () => _handleMenuPress('Transaction History'),
                  ),
                  _MenuItem(
                    icon: Icons.emoji_events_outlined,
                    label: 'Rewards',
                    badge: 'New',
                    onTap: () => _handleMenuPress('Rewards'),
                  ),
                  _MenuItem(
                    icon: Icons.people_outline,
                    label: 'Referral Program',
                    badge: 'Earn \$20',
                    onTap: () => _handleMenuPress('Referral Program'),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Preferences Section
              _MenuSection(
                title: 'Preferences',
                items: [
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () => _handleMenuPress('Notifications'),
                  ),
                  _MenuItem(
                    icon: Icons.language_outlined,
                    label: 'Language',
                    value: _selectedLanguage.name,
                    onTap: () => _handleMenuPress('Language'),
                  ),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) => _MenuItem(
                      icon: themeProvider.isDarkMode
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      label: 'Theme',
                      value: themeProvider.themeName,
                      onTap: () => _showThemeModal(context),
                    ),
                  ),
                  _MenuItem(
                    icon: Icons.attach_money,
                    label: 'Currency',
                    value: currencyProvider.currency.code,
                    onTap: () => _handleMenuPress('Currency'),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Support Section
              _MenuSection(
                title: 'Support',
                items: [
                  _MenuItem(
                    icon: Icons.help_outline,
                    label: 'Help Center',
                    onTap: () => _handleMenuPress('Help Center'),
                  ),
                  _MenuItem(
                    icon: Icons.chat_bubble_outline,
                    label: 'Support Tickets',
                    onTap: () => _handleMenuPress('Support Tickets'),
                  ),
                  _MenuItem(
                    icon: Icons.description_outlined,
                    label: 'Terms & Conditions',
                    onTap: () => _handleMenuPress('Terms & Conditions'),
                  ),
                  _MenuItem(
                    icon: Icons.lock_outline,
                    label: 'Privacy Policy',
                    onTap: () => _handleMenuPress('Privacy Policy'),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Logout Button
              GestureDetector(
                onTap: _handleLogout,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.tradingSellBg,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: AppColors.tradingSell.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.logout,
                        color: AppColors.tradingSell,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Log Out',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.tradingSell,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Version
              Center(
                child: Text(
                  'CrymadX v1.0.0',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Header Button Widget
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _HeaderButton({required this.icon, required this.onTap, this.isDark = true});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundCard : AppColors.lightBackgroundCard,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder),
        ),
        child: Icon(icon, color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary, size: 22),
      ),
    );
  }
}

// Stat Item Widget
class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
          ),
        ),
      ],
    );
  }
}

// Menu Section Widget
class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        GlassCard(
          variant: GlassVariant.elevated,
          padding: EdgeInsets.zero,
          child: Column(children: items),
        ),
      ],
    );
  }
}

// Menu Item Widget
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String? badge;
  final String? badgeType;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.value,
    this.badge,
    this.badgeType,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color badgeColor;
    Color badgeBgColor;

    switch (badgeType) {
      case 'success':
        badgeColor = AppColors.tradingBuy;
        badgeBgColor = AppColors.tradingBuyBg;
        break;
      case 'warning':
        badgeColor = AppColors.statusWarning;
        badgeBgColor = AppColors.statusWarningBg;
        break;
      default:
        badgeColor = AppColors.primary;
        badgeBgColor = AppColors.primary.withOpacity(0.15);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  badge!,
                  style: AppTypography.labelSmall.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            if (value != null) ...[
              Text(
                value!,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Icon(
              Icons.chevron_right,
              color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// Language Modal
class _LanguageModal extends StatelessWidget {
  final Language selectedLanguage;
  final Function(Language) onSelect;

  const _LanguageModal({
    required this.selectedLanguage,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Language',
                style: AppTypography.titleLarge.copyWith(
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final lang = languages[index];
              final isSelected = lang.code == selectedLanguage.code;
              return GestureDetector(
                onTap: () => onSelect(lang),
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 2,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.15) : null,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Text(lang.flag, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          lang.name,
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: AppColors.tradingBuy, size: 22),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Theme Modal
class _ThemeModal extends StatelessWidget {
  const _ThemeModal();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Theme',
                style: AppTypography.titleLarge.copyWith(
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.close,
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
        _ThemeOption(
          icon: Icons.light_mode_rounded,
          label: 'Light',
          description: 'Clean and bright interface',
          isSelected: themeProvider.isLightMode,
          onTap: () {
            themeProvider.setThemeMode(AppThemeMode.light);
            Navigator.pop(context);
          },
        ),
        _ThemeOption(
          icon: Icons.dark_mode_rounded,
          label: 'Dark',
          description: 'Easy on the eyes',
          isSelected: themeProvider.isDarkMode,
          onTap: () {
            themeProvider.setThemeMode(AppThemeMode.dark);
            Navigator.pop(context);
          },
        ),
        _ThemeOption(
          icon: Icons.settings_suggest_rounded,
          label: 'System',
          description: 'Follow device settings',
          isSelected: themeProvider.isSystemMode,
          onTap: () {
            themeProvider.setThemeMode(AppThemeMode.system);
            Navigator.pop(context);
          },
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 4,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : (isDark ? AppColors.backgroundCard : AppColors.lightBackgroundCard),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.glassBorder : AppColors.lightGlassBorder),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.backgroundElevated
                        : AppColors.lightBackgroundInput),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppColors.tradingBuy, size: 22),
          ],
        ),
      ),
    );
  }
}

// Currency Modal
class _CurrencyModal extends StatelessWidget {
  final ScrollController scrollController;

  const _CurrencyModal({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyProvider = context.watch<CurrencyProvider>();
    final currencies = CurrencyProvider.supportedCurrencies;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Currency',
                style: AppTypography.titleLarge.copyWith(
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            itemCount: currencies.length,
            itemBuilder: (context, index) {
              final currency = currencies[index];
              final isSelected = currency.code == currencyProvider.currency.code;
              return GestureDetector(
                onTap: () {
                  currencyProvider.setCurrency(currency.code);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 2,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.15) : null,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            currency.symbol,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currency.code,
                              style: AppTypography.bodyMedium.copyWith(
                                color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              currency.name,
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: AppColors.tradingBuy, size: 22),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Help Modal
class _HelpModal extends StatefulWidget {
  final ScrollController scrollController;
  final String? expandedFaq;
  final Function(String) onFaqTap;

  const _HelpModal({
    required this.scrollController,
    required this.expandedFaq,
    required this.onFaqTap,
  });

  @override
  State<_HelpModal> createState() => _HelpModalState();
}

class _HelpModalState extends State<_HelpModal> {
  String? _expandedFaq;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Help Center',
                style: AppTypography.titleLarge.copyWith(
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: helpFaqs.length,
            itemBuilder: (context, sectionIndex) {
              final section = helpFaqs[sectionIndex];
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      section.category,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...section.questions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final faq = entry.value;
                      final key = '${section.category}-$index';
                      final isExpanded = _expandedFaq == key;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _expandedFaq = isExpanded ? null : key;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.backgroundCard : AppColors.lightBackgroundCard,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: isDark ? null : Border.all(color: AppColors.lightGlassBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      faq.question,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
                                    size: 18,
                                  ),
                                ],
                              ),
                              if (isExpanded) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  faq.answer,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Legal Modal (Terms & Privacy)
class _LegalModal extends StatelessWidget {
  final String title;
  final String content;
  final ScrollController scrollController;

  const _LegalModal({
    required this.title,
    required this.content,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.titleLarge.copyWith(
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              content,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                height: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Avatar Modal
class _AvatarModal extends StatelessWidget {
  const _AvatarModal();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileProvider = context.watch<ProfileProvider>();
    final avatars = ProfileProvider.avatars;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose Avatar',
                style: AppTypography.titleLarge.copyWith(
                  color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
              ),
            ],
          ),
        ),
        Text(
          'Select a character to represent you',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.textTertiary : AppColors.lightTextTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.md,
            children: avatars.map((avatar) {
              final isSelected = profileProvider.selectedAvatar.id == avatar.id;
              return GestureDetector(
                onTap: () {
                  profileProvider.setAvatarId(avatar.id);
                  Navigator.pop(context);
                },
                child: Container(
                  width: 80,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.15) : null,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  avatar.color,
                                  avatar.color.withOpacity(0.7),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                avatar.emoji,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: AppColors.tradingBuy,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        avatar.name,
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// Edit Profile Modal
class _EditProfileModal extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final VoidCallback onAvatarTap;

  const _EditProfileModal({
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileProvider = context.watch<ProfileProvider>();
    final selectedAvatar = profileProvider.selectedAvatar;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Profile',
                  style: AppTypography.titleLarge.copyWith(
                    color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary),
                ),
              ],
            ),
          ),
          // Avatar
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        selectedAvatar.color,
                        selectedAvatar.color.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      selectedAvatar.emoji,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.backgroundSecondary : AppColors.lightBackgroundSecondary,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap to change avatar',
            style: AppTypography.labelSmall.copyWith(
              color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // Form fields
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FormField(label: 'Full Name', controller: nameController),
                const SizedBox(height: AppSpacing.lg),
                _FormField(
                  label: 'Email Address',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.lg),
                _FormField(
                  label: 'Phone Number',
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Save Changes',
                    onPressed: () {
                      profileProvider.updateProfile(
                        name: nameController.text,
                        email: emailController.text,
                        phone: phoneController.text,
                      );
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _FormField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: AppTypography.bodyMedium.copyWith(
            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? AppColors.backgroundCard : AppColors.lightBackgroundCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: isDark ? AppColors.glassBorder : AppColors.lightGlassBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ],
    );
  }
}

// 2FA Modal
class _TwoFAModal extends StatefulWidget {
  final ScrollController scrollController;
  final TextEditingController verificationController;

  const _TwoFAModal({
    required this.scrollController,
    required this.verificationController,
  });

  @override
  State<_TwoFAModal> createState() => _TwoFAModalState();
}

class _TwoFAModalState extends State<_TwoFAModal> {
  int _step = 1;
  final String _secretKey = 'CRYMADX2FA7K3XM5';

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                profileProvider.twoFactorEnabled
                    ? 'Two-Factor Authentication'
                    : 'Enable 2FA',
                style: AppTypography.titleLarge.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, color: textColor),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: profileProvider.twoFactorEnabled
                ? _buildEnabledView(context, profileProvider)
                : _step == 1
                    ? _buildStep1(context)
                    : _step == 2
                        ? _buildStep2(context, profileProvider)
                        : _buildStep3(context),
          ),
        ),
      ],
    );
  }

  Widget _buildEnabledView(BuildContext context, ProfileProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark ? AppColors.textTertiary : const Color(0xFF555555);
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.tradingBuyBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.verified_user,
            color: AppColors.tradingBuy,
            size: 48,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '2FA is Active',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.tradingBuy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your account is protected with Google Authenticator',
          style: AppTypography.bodySmall.copyWith(
            color: subtextColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Disable 2FA',
            variant: ButtonVariant.sell,
            onPressed: () {
              provider.disable2FA();
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStep1(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? AppColors.textTertiary : const Color(0xFF555555);
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.security,
            color: AppColors.primary,
            size: 48,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Secure Your Account',
          style: AppTypography.titleLarge.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Two-factor authentication adds an extra layer of security to your account',
          style: AppTypography.bodySmall.copyWith(
            color: subtextColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildStepItem(context, '1', 'Download Google Authenticator'),
        const SizedBox(height: AppSpacing.md),
        _buildStepItem(context, '2', 'Scan the QR code'),
        const SizedBox(height: AppSpacing.md),
        _buildStepItem(context, '3', 'Enter the 6-digit code'),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Continue',
            onPressed: () => setState(() => _step = 2),
          ),
        ),
      ],
    );
  }

  Widget _buildStepItem(BuildContext context, String number, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final cardBg = isDark ? AppColors.backgroundCard : const Color(0xFFF5F5F5);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: isDark ? null : Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(BuildContext context, ProfileProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? AppColors.textTertiary : const Color(0xFF555555);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF777777);
    final cardBg = isDark ? AppColors.backgroundCard : const Color(0xFFF5F5F5);
    final borderColor = isDark ? AppColors.glassBorder : Colors.black.withOpacity(0.1);
    return Column(
      children: [
        Text(
          'Scan QR Code',
          style: AppTypography.titleMedium.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Open Google Authenticator and scan this code',
          style: AppTypography.bodySmall.copyWith(
            color: subtextColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        // Mock QR Code
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: isDark ? null : Border.all(color: Colors.black.withOpacity(0.1)),
          ),
          child: Container(
            width: 160,
            height: 160,
            color: Colors.white,
            child: CustomPaint(painter: _QRCodePainter()),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Or enter this key manually:',
          style: AppTypography.bodySmall.copyWith(
            color: subtextColor,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _secretKey,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _secretKey));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Secret key copied!')),
                  );
                },
                child: Icon(Icons.copy, color: AppColors.primary, size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Enter 6-digit code from authenticator:',
          style: AppTypography.bodySmall.copyWith(
            color: subtextColor,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: widget.verificationController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '000000',
            hintStyle: AppTypography.headlineMedium.copyWith(
              color: mutedColor,
              letterSpacing: 8,
            ),
            filled: true,
            fillColor: cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Verify & Enable',
            onPressed: widget.verificationController.text.length == 6
                ? () {
                    provider.enable2FA();
                    setState(() => _step = 3);
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStep3(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark ? AppColors.textTertiary : const Color(0xFF555555);
    return Column(
      children: [
        const SizedBox(height: AppSpacing.lg),
        Icon(
          Icons.check_circle,
          color: AppColors.tradingBuy,
          size: 80,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          '2FA Enabled!',
          style: AppTypography.titleLarge.copyWith(
            color: AppColors.tradingBuy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your account is now protected with two-factor authentication',
          style: AppTypography.bodySmall.copyWith(
            color: subtextColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: AppButton(
            label: 'Done',
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }
}

// Simple QR Code Painter
class _QRCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final cellSize = size.width / 20;

    // Draw finder patterns (top-left, top-right, bottom-left)
    _drawFinderPattern(canvas, paint, 0, 0, cellSize);
    _drawFinderPattern(canvas, paint, size.width - 7 * cellSize, 0, cellSize);
    _drawFinderPattern(canvas, paint, 0, size.height - 7 * cellSize, cellSize);

    // Draw some random data pattern
    final random = [
      [8, 0], [10, 0], [12, 0],
      [8, 2], [11, 2],
      [8, 8], [10, 8], [12, 8],
      [8, 10], [11, 10],
      [8, 12], [10, 12], [12, 12],
      [14, 8], [16, 8], [18, 8],
      [15, 10], [17, 10],
      [8, 14], [10, 15], [12, 16],
      [8, 17], [10, 18],
      [14, 14], [16, 15], [18, 16],
      [15, 17], [17, 18],
    ];

    for (final pos in random) {
      canvas.drawRect(
        Rect.fromLTWH(pos[0] * cellSize, pos[1] * cellSize, cellSize, cellSize),
        paint,
      );
    }
  }

  void _drawFinderPattern(Canvas canvas, Paint paint, double x, double y, double cellSize) {
    // Outer square
    canvas.drawRect(Rect.fromLTWH(x, y, 7 * cellSize, 7 * cellSize), paint);
    // White inner
    canvas.drawRect(
      Rect.fromLTWH(x + cellSize, y + cellSize, 5 * cellSize, 5 * cellSize),
      Paint()..color = Colors.white,
    );
    // Black center
    canvas.drawRect(
      Rect.fromLTWH(x + 2 * cellSize, y + 2 * cellSize, 3 * cellSize, 3 * cellSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
