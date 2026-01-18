import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/app_button.dart';
import '../../services/user_service.dart';
import '../../providers/profile_provider.dart';

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
  bool _isLoading = true;
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

  String _selectedDocType = 'passport';
  final List<String> _docTypes = ['passport', 'driving_license', 'national_id'];
  final List<String> _docTypesDisplay = ['Passport', 'Driver License', 'National ID'];

  // Image files
  File? _frontDocument;
  File? _backDocument;
  File? _selfieImage;
  File? _addressProofDocument;

  final ImagePicker _picker = ImagePicker();
  KYCStatus? _kycStatus;

  @override
  void initState() {
    super.initState();
    _loadKYCStatus();
  }

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

  Future<void> _loadKYCStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await userService.getKYCStatus();
      setState(() {
        _kycStatus = status;
        _kycLevel = _getLevelFromStatus(status);
        _updateStepsFromStatus(status);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading KYC status: $e');
    }
  }

  KYCLevel _getLevelFromStatus(KYCStatus status) {
    switch (status.level) {
      case 0:
        return KYCLevel.none;
      case 1:
        return KYCLevel.basic;
      case 2:
        return KYCLevel.intermediate;
      case 3:
        return KYCLevel.advanced;
      default:
        return KYCLevel.none;
    }
  }

  void _updateStepsFromStatus(KYCStatus status) {
    _personalInfoComplete = status.personalInfoSubmitted;
    _idDocumentComplete = status.documentSubmitted;
    _selfieComplete = status.selfieSubmitted;
    _addressComplete = status.addressProofSubmitted;

    if (!_personalInfoComplete) {
      _currentStep = 0;
    } else if (!_idDocumentComplete) {
      _currentStep = 1;
    } else if (!_selfieComplete) {
      _currentStep = 2;
    } else {
      _currentStep = 3;
    }
  }

  Future<void> _pickImage(ImageSource source, String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
        preferredCameraDevice: type == 'selfie' ? CameraDevice.front : CameraDevice.rear,
      );

      if (image != null) {
        final file = File(image.path);
        // Verify file exists and is readable
        if (!await file.exists()) {
          throw Exception('Image file not found');
        }
        final fileSize = await file.length();
        if (fileSize == 0) {
          throw Exception('Image file is empty');
        }
        if (fileSize > 10 * 1024 * 1024) { // 10MB limit
          throw Exception('Image is too large (max 10MB)');
        }

        setState(() {
          switch (type) {
            case 'front':
              _frontDocument = file;
              break;
            case 'back':
              _backDocument = file;
              break;
            case 'selfie':
              _selfieImage = file;
              break;
            case 'address':
              _addressProofDocument = file;
              break;
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Image captured successfully'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      String errorMessage = 'Error picking image';
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('denied') || errorStr.contains('permission')) {
        errorMessage = 'Permission denied. Please enable camera/gallery access in Settings.';
      } else if (errorStr.contains('camera')) {
        errorMessage = 'Camera not available. Please try using the gallery.';
      } else {
        errorMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _submitPersonalInfo() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _dobController.text.isEmpty ||
        _nationalityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      await userService.submitKYCPersonalInfo(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        dateOfBirth: _dobController.text,
        nationality: _nationalityController.text,
      );

      setState(() {
        _personalInfoComplete = true;
        _currentStep = 1;
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _submitDocuments() async {
    if (_frontDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload the front of your document')),
      );
      return;
    }

    try {
      await userService.submitKYCDocument(
        documentType: _selectedDocType,
        frontImage: _frontDocument!,
        backImage: _backDocument,
      );

      setState(() {
        _idDocumentComplete = true;
        _currentStep = 2;
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _submitSelfie() async {
    if (_selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a selfie')),
      );
      return;
    }

    try {
      await userService.submitKYCSelfie(_selfieImage!);

      setState(() {
        _selfieComplete = true;
        _currentStep = 3;
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _submitAddressProof() async {
    if (_addressProofDocument == null ||
        _addressController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _countryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields and upload a document')),
      );
      return;
    }

    try {
      await userService.submitKYCAddressProof(
        address: _addressController.text,
        city: _cityController.text,
        postalCode: _postalCodeController.text,
        country: _countryController.text,
        document: _addressProofDocument!,
      );

      setState(() {
        _addressComplete = true;
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _submitVerification() async {
    setState(() => _isVerifying = true);

    try {
      await userService.submitKYCForReview();

      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
        _showSuccessDialog();
        // Refresh profile
        context.read<ProfileProvider>().loadProfile();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
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

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => context.pop(),
          ),
          title: Text('KYC Verification', style: TextStyle(color: textColor)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show pending/rejected status if applicable
    if (_kycStatus != null && _kycStatus!.status == 'pending') {
      return _buildPendingScreen(isDark, bgColor, textColor);
    }

    if (_kycStatus != null && _kycStatus!.status == 'rejected') {
      return _buildRejectedScreen(isDark, bgColor, textColor);
    }

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
              _buildLevelCard(),
              const SizedBox(height: AppSpacing.lg),
              _buildBenefitsCard(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Verification Steps',
                style: AppTypography.titleMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildStepCard(
                step: 1,
                title: 'Personal Information',
                subtitle: 'Name, date of birth, nationality',
                icon: Icons.person_outline,
                isComplete: _personalInfoComplete,
                isActive: _currentStep == 0,
                onTap: () => _showPersonalInfoModal(),
              ),
              _buildStepCard(
                step: 2,
                title: 'Identity Document',
                subtitle: 'Passport, ID card, or driver license',
                icon: Icons.badge_outlined,
                isComplete: _idDocumentComplete,
                isActive: _currentStep == 1,
                onTap: _personalInfoComplete ? () => _showDocumentModal() : null,
              ),
              _buildStepCard(
                step: 3,
                title: 'Selfie Verification',
                subtitle: 'Take a selfie holding your ID',
                icon: Icons.camera_alt_outlined,
                isComplete: _selfieComplete,
                isActive: _currentStep == 2,
                onTap: _idDocumentComplete ? () => _showSelfieModal() : null,
              ),
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

  Widget _buildPendingScreen(bool isDark, Color bgColor, Color textColor) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text('KYC Verification', style: TextStyle(color: textColor)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hourglass_empty, color: AppColors.warning, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                'Verification In Progress',
                style: AppTypography.titleLarge.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your documents are being reviewed. This usually takes 1-2 business days.',
                style: AppTypography.bodyMedium.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Refresh Status',
                  onPressed: _loadKYCStatus,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRejectedScreen(bool isDark, Color bgColor, Color textColor) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text('KYC Verification', style: TextStyle(color: textColor)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, color: AppColors.error, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                'Verification Rejected',
                style: AppTypography.titleLarge.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _kycStatus?.rejectionReason ?? 'Your documents could not be verified. Please try again.',
                style: AppTypography.bodyMedium.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Try Again',
                  onPressed: () async {
                    try {
                      await userService.retryKYC();
                      _loadKYCStatus();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  },
                ),
              ),
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
                Text('Verification Level', style: AppTypography.bodySmall.copyWith(color: mutedColor)),
                const SizedBox(height: 4),
                Text(
                  levelText,
                  style: AppTypography.titleLarge.copyWith(color: levelColor, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Withdrawal Limit', style: AppTypography.caption.copyWith(color: mutedColor)),
              const SizedBox(height: 4),
              Text(
                limitText,
                style: AppTypography.titleMedium.copyWith(color: textColor, fontWeight: FontWeight.w600),
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
            style: AppTypography.titleSmall.copyWith(color: textColor, fontWeight: FontWeight.w600),
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
          Text(text, style: AppTypography.bodySmall.copyWith(color: subtextColor)),
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
          color: isActive ? AppColors.primary.withOpacity(0.1) : cardBg,
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
                      color: isLocked ? mutedColor : isActive ? AppColors.primary : mutedColor,
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Optional',
                            style: TextStyle(color: AppColors.info, fontSize: 9, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.caption.copyWith(color: mutedColor)),
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
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Personal Information', style: AppTypography.titleLarge.copyWith(color: textColor, fontWeight: FontWeight.w700)),
                    GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.close, color: textColor)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildTextField('First Name', _firstNameController, Icons.person_outline),
                const SizedBox(height: AppSpacing.md),
                _buildTextField('Last Name', _lastNameController, Icons.person_outline),
                const SizedBox(height: AppSpacing.md),
                _buildTextField('Date of Birth', _dobController, Icons.calendar_today, hint: 'DD/MM/YYYY'),
                const SizedBox(height: AppSpacing.md),
                _buildTextField('Nationality', _nationalityController, Icons.flag_outlined),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: isSubmitting ? 'Submitting...' : 'Continue',
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setModalState(() => isSubmitting = true);
                            await _submitPersonalInfo();
                            setModalState(() => isSubmitting = false);
                          },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
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
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Identity Document', style: AppTypography.titleLarge.copyWith(color: textColor, fontWeight: FontWeight.w700)),
                  GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.close, color: textColor)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Select document type', style: AppTypography.bodySmall.copyWith(color: mutedColor)),
              const SizedBox(height: AppSpacing.md),
              ...List.generate(_docTypes.length, (index) {
                final docType = _docTypes[index];
                final displayName = _docTypesDisplay[index];
                final isSelected = _selectedDocType == docType;
                return GestureDetector(
                  onTap: () => setModalState(() => _selectedDocType = docType),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.1) : cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppColors.primary.withOpacity(0.3) : borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          index == 0 ? Icons.menu_book : index == 1 ? Icons.drive_eta : Icons.credit_card,
                          color: isSelected ? AppColors.primary : mutedColor,
                        ),
                        const SizedBox(width: 14),
                        Text(displayName, style: AppTypography.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        if (isSelected) Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _buildUploadButtonWithImage('Front Side', Icons.credit_card, _frontDocument, () async {
                      await _pickImage(ImageSource.camera, 'front');
                      setModalState(() {});
                    }),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildUploadButtonWithImage('Back Side', Icons.credit_card, _backDocument, () async {
                      await _pickImage(ImageSource.camera, 'back');
                      setModalState(() {});
                    }),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: isSubmitting ? 'Submitting...' : 'Continue',
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          await _submitDocuments();
                          setModalState(() => isSubmitting = false);
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

  Widget _buildUploadButtonWithImage(String label, IconData icon, File? imageFile, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.backgroundCard : const Color(0xFFF8F8F8);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF555555);
    final borderColor = isDark ? AppColors.glassBorder : Colors.black.withOpacity(0.1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: imageFile != null ? AppColors.tradingBuy : borderColor),
        ),
        child: imageFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(imageFile, fit: BoxFit.cover),
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: Center(child: Icon(Icons.check_circle, color: AppColors.tradingBuy, size: 32)),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: mutedColor, size: 32),
                  const SizedBox(height: 8),
                  Text(label, style: AppTypography.bodySmall.copyWith(color: mutedColor)),
                  const SizedBox(height: 4),
                  Text('Tap to capture', style: TextStyle(color: AppColors.primary, fontSize: 11)),
                ],
              ),
      ),
    );
  }

  void _showSelfieModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.backgroundSecondary : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final cardBg = isDark ? AppColors.backgroundCard : const Color(0xFFF8F8F8);
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Selfie Verification', style: AppTypography.titleLarge.copyWith(color: textColor, fontWeight: FontWeight.w700)),
                  GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.close, color: textColor)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                onTap: () async {
                  await _pickImage(ImageSource.camera, 'selfie');
                  setModalState(() {});
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: _selfieImage != null ? AppColors.tradingBuy : AppColors.primary, width: 3),
                  ),
                  child: _selfieImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.file(_selfieImage!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt, color: AppColors.primary, size: 48),
                            const SizedBox(height: 12),
                            Text('Take Selfie', style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tips for a successful verification:', style: AppTypography.bodySmall.copyWith(color: textColor, fontWeight: FontWeight.w600)),
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
                  label: isSubmitting ? 'Submitting...' : (_selfieImage != null ? 'Submit' : 'Take Photo'),
                  icon: Icons.camera_alt,
                  onPressed: isSubmitting
                      ? null
                      : _selfieImage != null
                          ? () async {
                              setModalState(() => isSubmitting = true);
                              await _submitSelfie();
                              setModalState(() => isSubmitting = false);
                            }
                          : () async {
                              await _pickImage(ImageSource.camera, 'selfie');
                              setModalState(() {});
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

  Widget _buildTipRow(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor = isDark ? AppColors.textSecondary : const Color(0xFF333333);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.info, size: 14),
          const SizedBox(width: 8),
          Text(text, style: AppTypography.caption.copyWith(color: subtextColor)),
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
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                    Text('Proof of Address', style: AppTypography.titleLarge.copyWith(color: textColor, fontWeight: FontWeight.w700)),
                    GestureDetector(onTap: () => Navigator.pop(context), child: Icon(Icons.close, color: textColor)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Upload a utility bill or bank statement from the last 3 months', style: AppTypography.bodySmall.copyWith(color: mutedColor)),
                const SizedBox(height: AppSpacing.lg),
                _buildTextField('Address', _addressController, Icons.home_outlined),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(child: _buildTextField('City', _cityController, Icons.location_city)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField('Postal Code', _postalCodeController, Icons.pin)),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _buildTextField('Country', _countryController, Icons.flag_outlined),
                const SizedBox(height: AppSpacing.lg),
                GestureDetector(
                  onTap: () async {
                    await _pickImage(ImageSource.gallery, 'address');
                    setModalState(() {});
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _addressProofDocument != null ? AppColors.tradingBuy : borderColor),
                    ),
                    child: _addressProofDocument != null
                        ? Column(
                            children: [
                              Icon(Icons.check_circle, color: AppColors.tradingBuy, size: 40),
                              const SizedBox(height: 8),
                              Text('Document Uploaded', style: AppTypography.bodyMedium.copyWith(color: AppColors.tradingBuy, fontWeight: FontWeight.w600)),
                            ],
                          )
                        : Column(
                            children: [
                              Icon(Icons.upload_file, color: AppColors.primary, size: 40),
                              const SizedBox(height: 12),
                              Text('Upload Document', style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('PDF, JPG, or PNG (max 10MB)', style: AppTypography.caption.copyWith(color: mutedColor)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: isSubmitting ? 'Submitting...' : 'Submit',
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setModalState(() => isSubmitting = true);
                            await _submitAddressProof();
                            setModalState(() => isSubmitting = false);
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {String? hint}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? AppColors.textSecondary : const Color(0xFF333333);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF777777);
    final cardBg = isDark ? AppColors.backgroundCard : const Color(0xFFF8F8F8);
    final borderColor = isDark ? AppColors.glassBorder : Colors.black.withOpacity(0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.bodySmall.copyWith(color: subtextColor, fontWeight: FontWeight.w600)),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
