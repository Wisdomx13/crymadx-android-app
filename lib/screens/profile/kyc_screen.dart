import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/app_button.dart';

// KYC Verification Levels
enum KYCLevel { none, basic, intermediate, advanced }

class KYCScreen extends StatefulWidget {
  const KYCScreen({super.key});

  @override
  State<KYCScreen> createState() => _KYCScreenState();
}

class _KYCScreenState extends State<KYCScreen> {
  int _currentStep = 0;
  KYCLevel _kycLevel = KYCLevel.none;
  bool _isVerifying = false;
  bool _personalInfoComplete = false;
  bool _idDocumentComplete = false;
  bool _selfieComplete = false;
  bool _addressComplete = false;

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();

  String _selectedDocType = 'Passport';
  final List<String> _docTypes = ['Passport', 'Driver License', 'National ID'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _nationalityController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _submitVerification() {
    setState(() => _isVerifying = true);

    // Simulate verification process
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _kycLevel = KYCLevel.intermediate;
        });
        _showSuccessDialog();
      }
    });
  }

  void _showSuccessDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.backgroundCard : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF555555);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.tradingBuyBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: AppColors.tradingBuy, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Verification Submitted!',
              style: AppTypography.titleLarge.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your documents are being reviewed. This usually takes 1-2 business days.',
              style: AppTypography.bodySmall.copyWith(color: mutedColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Done',
                onPressed: () {
                  Navigator.pop(context);
                  context.pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundPrimary : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'KYC Verification',
          style: AppTypography.headlineSmall.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Level Card
              _buildLevelCard(),
              const SizedBox(height: AppSpacing.lg),

              // Benefits Card
              _buildBenefitsCard(),
              const SizedBox(height: AppSpacing.lg),

              // Verification Steps
              Text(
                'Verification Steps',
                style: AppTypography.titleMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Step 1: Personal Information
              _buildStepCard(
                step: 1,
                title: 'Personal Information',
                subtitle: 'Name, date of birth, nationality',
                icon: Icons.person_outline,
                isComplete: _personalInfoComplete,
                isActive: _currentStep == 0,
                onTap: () => _showPersonalInfoModal(),
              ),

              // Step 2: ID Document
              _buildStepCard(
                step: 2,
                title: 'Identity Document',
                subtitle: 'Passport, ID card, or driver license',
                icon: Icons.badge_outlined,
                isComplete: _idDocumentComplete,
                isActive: _currentStep == 1,
                onTap: _personalInfoComplete ? () => _showDocumentModal() : null,
              ),

              // Step 3: Selfie Verification
              _buildStepCard(
                step: 3,
                title: 'Selfie Verification',
                subtitle: 'Take a selfie holding your ID',
                icon: Icons.camera_alt_outlined,
                isComplete: _selfieComplete,
                isActive: _currentStep == 2,
                onTap: _idDocumentComplete ? () => _showSelfieModal() : null,
              ),

              // Step 4: Address Proof (Optional for advanced)
              _buildStepCard(
                step: 4,
                title: 'Proof of Address',
                subtitle: 'Utility bill or bank statement',
                icon: Icons.home_outlined,
                isComplete: _addressComplete,
                isActive: _currentStep == 3,
                isOptional: true,
                onTap: _selfieComplete ? () => _showAddressModal() : null,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              if (_selfieComplete)
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: _isVerifying ? 'Submitting...' : 'Submit Verification',
                    onPressed: _isVerifying ? null : _submitVerification,
                    icon: _isVerifying ? null : Icons.verified_user,
                  ),
                ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF555555);

    Color levelColor;
    String levelText;
    String limitText;
    IconData levelIcon;

    switch (_kycLevel) {
      case KYCLevel.none:
        levelColor = isDark ? AppColors.textMuted : const Color(0xFF777777);
        levelText = 'Unverified';
        limitText = '\$100/day';
        levelIcon = Icons.person_outline;
        break;
      case KYCLevel.basic:
        levelColor = AppColors.warning;
        levelText = 'Basic';
        limitText = '\$2,000/day';
        levelIcon = Icons.verified_outlined;
        break;
      case KYCLevel.intermediate:
        levelColor = AppColors.info;
        levelText = 'Intermediate';
        limitText = '\$50,000/day';
        levelIcon = Icons.verified;
        break;
      case KYCLevel.advanced:
        levelColor = AppColors.tradingBuy;
        levelText = 'Advanced';
        limitText = 'Unlimited';
        levelIcon = Icons.verified_user;
        break;
    }

    return GlassCard(
      variant: GlassVariant.prominent,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: levelColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(levelIcon, color: levelColor, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Verification Level',
                      style: AppTypography.bodySmall.copyWith(
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  levelText,
                  style: AppTypography.titleLarge.copyWith(
                    color: levelColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Withdrawal Limit',
                style: AppTypography.caption.copyWith(color: mutedColor),
              ),
              const SizedBox(height: 4),
              Text(
                limitText,
                style: AppTypography.titleMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification Benefits',
            style: AppTypography.titleSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildBenefitRow(Icons.trending_up, 'Higher withdrawal limits'),
          _buildBenefitRow(Icons.swap_horiz, 'P2P trading access'),
          _buildBenefitRow(Icons.savings, 'Earn higher staking rewards'),
          _buildBenefitRow(Icons.security, 'Enhanced account security'),
          _buildBenefitRow(Icons.support_agent, 'Priority support'),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark ? AppColors.textSecondary : const Color(0xFF333333);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.tradingBuy, size: 18),
          const SizedBox(width: 12),
          Text(
            text,
            style: AppTypography.bodySmall.copyWith(color: subtextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isComplete,
    required bool isActive,
    bool isOptional = false,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF555555);
    final cardBg = isDark ? AppColors.backgroundCard : Colors.white;
    final iconBg = isDark ? AppColors.backgroundPrimary : const Color(0xFFF5F5F5);
    final borderColor = isDark ? AppColors.glassBorder : Colors.black.withOpacity(0.1);

    final isLocked = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.1)
              : cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isComplete
                ? AppColors.tradingBuy.withOpacity(0.3)
                : isActive
                    ? AppColors.primary.withOpacity(0.3)
                    : borderColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isComplete
                    ? AppColors.tradingBuyBg
                    : isActive
                        ? AppColors.primary.withOpacity(0.15)
                        : iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: isComplete
                  ? Icon(Icons.check, color: AppColors.tradingBuy, size: 22)
                  : Icon(
                      icon,
                      color: isLocked
                          ? mutedColor
                          : isActive
                              ? AppColors.primary
                              : mutedColor,
                      size: 22,
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isLocked ? mutedColor : textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isOptional) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Optional',
                            style: TextStyle(
                              color: AppColors.info,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked)
              Icon(Icons.lock_outline, color: mutedColor, size: 18)
            else if (!isComplete)
              Icon(Icons.chevron_right, color: mutedColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _showPersonalInfoModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.backgroundSecondary : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Personal Information',
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
              const SizedBox(height: AppSpacing.lg),
              _buildTextField('First Name', _firstNameController, Icons.person_outline),
              const SizedBox(height: AppSpacing.md),
              _buildTextField('Last Name', _lastNameController, Icons.person_outline),
              const SizedBox(height: AppSpacing.md),
              _buildTextField('Date of Birth', _dobController, Icons.calendar_today,
                  hint: 'DD/MM/YYYY'),
              const SizedBox(height: AppSpacing.md),
              _buildTextField('Nationality', _nationalityController, Icons.flag_outlined),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Continue',
                  onPressed: () {
                    setState(() {
                      _personalInfoComplete = true;
                      _currentStep = 1;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  void _showDocumentModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.backgroundSecondary : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF555555);
    final cardBg = isDark ? AppColors.backgroundCard : Colors.white;
    final borderColor = isDark ? AppColors.glassBorder : Colors.black.withOpacity(0.1);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Identity Document',
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
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Select document type',
                style: AppTypography.bodySmall.copyWith(color: mutedColor),
              ),
              const SizedBox(height: AppSpacing.md),
              ...List.generate(_docTypes.length, (index) {
                final docType = _docTypes[index];
                final isSelected = _selectedDocType == docType;
                return GestureDetector(
                  onTap: () => setModalState(() => _selectedDocType = docType),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.1)
                          : cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.3)
                            : borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          index == 0
                              ? Icons.menu_book
                              : index == 1
                                  ? Icons.drive_eta
                                  : Icons.credit_card,
                          color: isSelected ? AppColors.primary : mutedColor,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          docType,
                          style: AppTypography.bodyMedium.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.lg),
              // Upload buttons
              Row(
                children: [
                  Expanded(
                    child: _buildUploadButton('Front Side', Icons.credit_card),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildUploadButton('Back Side', Icons.credit_card),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Continue',
                  onPressed: () {
                    setState(() {
                      _idDocumentComplete = true;
                      _currentStep = 2;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton(String label, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.backgroundCard : const Color(0xFFF8F8F8);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF555555);
    final borderColor = isDark ? AppColors.glassBorder : Colors.black.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: mutedColor, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: mutedColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to upload',
            style: TextStyle(color: AppColors.primary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showSelfieModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.backgroundSecondary : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final cardBg = isDark ? AppColors.backgroundCard : const Color(0xFFF8F8F8);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selfie Verification',
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
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.primary, width: 3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, color: AppColors.primary, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Take Selfie',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tips for a successful verification:',
                    style: AppTypography.bodySmall.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTipRow('Good lighting on your face'),
                  _buildTipRow('Hold your ID next to your face'),
                  _buildTipRow('Ensure ID text is readable'),
                  _buildTipRow('Remove glasses and hats'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Take Photo',
                icon: Icons.camera_alt,
                onPressed: () {
                  setState(() {
                    _selfieComplete = true;
                    _currentStep = 3;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildTipRow(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark ? AppColors.textSecondary : const Color(0xFF333333);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.info, size: 14),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTypography.caption.copyWith(color: subtextColor),
          ),
        ],
      ),
    );
  }

  void _showAddressModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.backgroundSecondary : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF555555);
    final cardBg = isDark ? AppColors.backgroundCard : const Color(0xFFF8F8F8);
    final borderColor = isDark ? AppColors.glassBorder : Colors.black.withOpacity(0.1);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Proof of Address',
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
              const SizedBox(height: 8),
              Text(
                'Upload a utility bill or bank statement from the last 3 months',
                style: AppTypography.bodySmall.copyWith(color: mutedColor),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField('Address', _addressController, Icons.home_outlined),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('City', _cityController, Icons.location_city),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField('Postal Code', _postalCodeController, Icons.pin),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildTextField('Country', _countryController, Icons.flag_outlined),
              const SizedBox(height: AppSpacing.lg),
              // Upload area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    Icon(Icons.upload_file, color: AppColors.primary, size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'Upload Document',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PDF, JPG, or PNG (max 10MB)',
                      style: AppTypography.caption.copyWith(color: mutedColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Submit',
                  onPressed: () {
                    setState(() {
                      _addressComplete = true;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon,
      {String? hint}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? AppColors.textSecondary : const Color(0xFF333333);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF777777);
    final cardBg = isDark ? AppColors.backgroundCard : const Color(0xFFF8F8F8);
    final borderColor = isDark ? AppColors.glassBorder : Colors.black.withOpacity(0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: subtextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: AppTypography.bodyMedium.copyWith(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: mutedColor),
            prefixIcon: Icon(icon, color: mutedColor, size: 20),
            filled: true,
            fillColor: cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
