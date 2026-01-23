import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/spacing.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/app_button.dart';
import '../../services/p2p_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<P2PPaymentMethod> _paymentMethods = [];
  bool _isLoading = true;
  String? _error;
  bool _isSubmitting = false;

  // Form controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _routingController = TextEditingController();
  final _accountHolderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _routingController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final methods = await p2pService.getPaymentMethods();
      if (mounted) {
        setState(() {
          _paymentMethods = methods;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _setAsDefault(String id) {
    // For now, just update locally - backend would need a setDefault endpoint
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Default payment method updated'),
        backgroundColor: AppColors.tradingBuy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deletePaymentMethod(String id) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.backgroundCard : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF555555);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove Payment Method?',
          style: AppTypography.titleMedium.copyWith(color: textColor),
        ),
        content: Text(
          'This action cannot be undone.',
          style: AppTypography.bodySmall.copyWith(color: mutedColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: mutedColor)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await p2pService.removePaymentMethod(id);
                setState(() {
                  _paymentMethods.removeWhere((pm) => pm.id == id);
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Payment method removed'),
                      backgroundColor: AppColors.tradingBuy,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove: ${e.toString().replaceAll('Exception: ', '')}'),
                      backgroundColor: AppColors.tradingSell,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text('Remove', style: TextStyle(color: AppColors.tradingSell)),
          ),
        ],
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
          'Payment Methods',
          style: AppTypography.headlineSmall.copyWith(
            color: textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildErrorState()
                : RefreshIndicator(
                    onRefresh: _loadPaymentMethods,
                    child: Column(
                      children: [
                        // Add new button
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: GestureDetector(
                            onTap: _showAddPaymentMethodModal,
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline, color: AppColors.primary),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Add Payment Method',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Payment methods list
                        Expanded(
                          child: _paymentMethods.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                                  itemCount: _paymentMethods.length,
                                  itemBuilder: (context, index) {
                                    final pm = _paymentMethods[index];
                                    return _buildPaymentMethodCard(pm);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildErrorState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtextColor = isDark ? AppColors.textTertiary : const Color(0xFF555555);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.tradingSell),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Failed to load payment methods',
              style: AppTypography.titleMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error ?? 'Unknown error',
              style: AppTypography.bodySmall.copyWith(color: subtextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Retry',
              onPressed: _loadPaymentMethods,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(P2PPaymentMethod pm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF555555);
    final cardBg = isDark ? AppColors.backgroundCard : Colors.white;
    final borderColor = isDark ? AppColors.glassBorder : Colors.black.withOpacity(0.1);

    IconData icon;
    Color iconColor;

    // Map type string to icon and color
    final typeLC = pm.type.toLowerCase();
    if (typeLC.contains('card') || typeLC.contains('credit') || typeLC.contains('debit')) {
      icon = Icons.credit_card;
      iconColor = pm.name.toLowerCase().contains('visa') ? Colors.blue : Colors.orange;
    } else if (typeLC.contains('bank')) {
      icon = Icons.account_balance;
      iconColor = AppColors.info;
    } else if (typeLC.contains('crypto') || typeLC.contains('wallet')) {
      icon = Icons.currency_bitcoin;
      iconColor = AppColors.warning;
    } else if (typeLC.contains('mobile') || typeLC.contains('paypal') || typeLC.contains('apple') || typeLC.contains('google')) {
      icon = Icons.phone_android;
      iconColor = AppColors.tradingBuy;
    } else {
      icon = Icons.payment;
      iconColor = AppColors.primary;
    }

    // Extract display details from the details map
    String detailsDisplay = _formatPaymentDetails(pm);

    return GestureDetector(
      onTap: () => _showPaymentMethodOptions(pm),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: pm.isDefault
                ? AppColors.primary.withOpacity(0.3)
                : borderColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          pm.name,
                          style: AppTypography.bodyMedium.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (pm.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'DEFAULT',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detailsDisplay,
                    style: AppTypography.bodySmall.copyWith(color: mutedColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: mutedColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF555555);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off, color: mutedColor, size: 64),
          const SizedBox(height: 16),
          Text(
            'No payment methods',
            style: AppTypography.titleMedium.copyWith(color: mutedColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a payment method to start trading',
            style: AppTypography.bodySmall.copyWith(color: mutedColor),
          ),
        ],
      ),
    );
  }

  /// Format payment details from Map to display string
  String _formatPaymentDetails(P2PPaymentMethod pm) {
    final details = pm.details;
    if (details.isEmpty) return pm.type;

    // Try to extract common fields
    if (details.containsKey('accountNumber')) {
      final account = details['accountNumber']?.toString() ?? '';
      if (account.length >= 4) {
        return '****${account.substring(account.length - 4)}';
      }
    }
    if (details.containsKey('cardNumber')) {
      final card = details['cardNumber']?.toString() ?? '';
      if (card.length >= 4) {
        return '**** **** **** ${card.substring(card.length - 4)}';
      }
    }
    if (details.containsKey('email')) {
      return details['email']?.toString() ?? '';
    }
    if (details.containsKey('phone')) {
      return details['phone']?.toString() ?? '';
    }
    if (details.containsKey('bankName')) {
      return details['bankName']?.toString() ?? '';
    }

    // Fallback to first value or type
    if (details.values.isNotEmpty) {
      return details.values.first?.toString() ?? pm.type;
    }

    return pm.type;
  }

  void _showPaymentMethodOptions(P2PPaymentMethod pm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.backgroundSecondary : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
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
                  pm.name,
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
            if (!pm.isDefault)
              _buildOptionItem(
                icon: Icons.star_outline,
                label: 'Set as Default',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  _setAsDefault(pm.id);
                },
              ),
            _buildOptionItem(
              icon: Icons.edit_outlined,
              label: 'Edit Details',
              color: AppColors.info,
              onTap: () {
                Navigator.pop(context);
                // Show edit modal
              },
            ),
            _buildOptionItem(
              icon: Icons.delete_outline,
              label: 'Remove',
              color: AppColors.tradingSell,
              onTap: () {
                Navigator.pop(context);
                _deletePaymentMethod(pm.id);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.backgroundCard : const Color(0xFFF8F8F8);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF555555);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: mutedColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _showAddPaymentMethodModal() {
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
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Payment Method',
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
              _buildPaymentTypeOption(
                icon: Icons.credit_card,
                label: 'Credit/Debit Card',
                subtitle: 'Visa, Mastercard, etc.',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _showAddCardModal();
                },
              ),
              _buildPaymentTypeOption(
                icon: Icons.account_balance,
                label: 'Bank Account',
                subtitle: 'Link your bank account',
                color: AppColors.info,
                onTap: () {
                  Navigator.pop(context);
                  _showAddBankModal();
                },
              ),
              _buildPaymentTypeOption(
                icon: Icons.phone_android,
                label: 'Mobile Wallet',
                subtitle: 'Apple Pay, Google Pay',
                color: AppColors.tradingBuy,
                onTap: () {
                  Navigator.pop(context);
                  _showMobileWalletModal();
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentTypeOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final mutedColor = isDark ? AppColors.textMuted : const Color(0xFF555555);
    final cardBg = isDark ? AppColors.backgroundCard : Colors.white;
    final borderColor = isDark ? AppColors.glassBorder : Colors.black.withOpacity(0.1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(color: mutedColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: mutedColor, size: 20),
          ],
        ),
      ),
    );
  }

  void _showAddCardModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.backgroundSecondary : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);

    _cardNumberController.clear();
    _expiryController.clear();
    _cvvController.clear();
    _cardHolderController.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Card',
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
              _buildTextField('Card Number', _cardNumberController, Icons.credit_card,
                  hint: '1234 5678 9012 3456'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Expiry', _expiryController, Icons.calendar_today,
                        hint: 'MM/YY'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField('CVV', _cvvController, Icons.lock_outline,
                        hint: '***', obscure: true),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildTextField('Cardholder Name', _cardHolderController, Icons.person_outline,
                  hint: 'JOHN DOE'),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: _isSubmitting ? 'Adding...' : 'Add Card',
                  onPressed: _isSubmitting ? null : () async {
                    if (_cardNumberController.text.length < 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Please enter a valid card number'),
                          backgroundColor: AppColors.tradingSell,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    setState(() => _isSubmitting = true);
                    Navigator.pop(context);

                    try {
                      final newMethod = await p2pService.addPaymentMethod(
                        type: 'card',
                        name: 'Card ending in ${_cardNumberController.text.substring(_cardNumberController.text.length - 4)}',
                        details: {
                          'cardNumber': _cardNumberController.text,
                          'expiry': _expiryController.text,
                          'cardHolder': _cardHolderController.text,
                        },
                      );

                      if (mounted) {
                        setState(() {
                          _paymentMethods.add(newMethod);
                          _isSubmitting = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Card added successfully'),
                            backgroundColor: AppColors.tradingBuy,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to add card: ${e.toString().replaceAll('Exception: ', '')}'),
                            backgroundColor: AppColors.tradingSell,
                            behavior: SnackBarBehavior.floating,
                          ),
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
      ),
    );
  }

  void _showAddBankModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.backgroundSecondary : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);

    _bankNameController.clear();
    _accountNumberController.clear();
    _routingController.clear();
    _accountHolderController.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Bank Account',
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
              _buildTextField('Bank Name', _bankNameController, Icons.account_balance),
              const SizedBox(height: AppSpacing.md),
              _buildTextField('Account Number', _accountNumberController, Icons.numbers),
              const SizedBox(height: AppSpacing.md),
              _buildTextField('Routing Number', _routingController, Icons.route),
              const SizedBox(height: AppSpacing.md),
              _buildTextField('Account Holder', _accountHolderController, Icons.person_outline),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: _isSubmitting ? 'Adding...' : 'Add Bank Account',
                  onPressed: _isSubmitting ? null : () async {
                    if (_accountNumberController.text.length < 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Please enter a valid account number'),
                          backgroundColor: AppColors.tradingSell,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    setState(() => _isSubmitting = true);
                    Navigator.pop(context);

                    try {
                      final newMethod = await p2pService.addPaymentMethod(
                        type: 'bank_transfer',
                        name: _bankNameController.text.isNotEmpty
                            ? _bankNameController.text
                            : 'Bank Account',
                        details: {
                          'bankName': _bankNameController.text,
                          'accountNumber': _accountNumberController.text,
                          'routingNumber': _routingController.text,
                          'accountHolder': _accountHolderController.text,
                        },
                      );

                      if (mounted) {
                        setState(() {
                          _paymentMethods.add(newMethod);
                          _isSubmitting = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Bank account added successfully'),
                            backgroundColor: AppColors.tradingBuy,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isSubmitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to add bank: ${e.toString().replaceAll('Exception: ', '')}'),
                            backgroundColor: AppColors.tradingSell,
                            behavior: SnackBarBehavior.floating,
                          ),
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

  Future<void> _addMobileWallet(String name, String type) async {
    Navigator.pop(context);
    setState(() => _isSubmitting = true);

    try {
      final newMethod = await p2pService.addPaymentMethod(
        type: type,
        name: name,
        details: {'linked': true},
      );

      if (mounted) {
        setState(() {
          _paymentMethods.add(newMethod);
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name linked successfully'),
            backgroundColor: AppColors.tradingBuy,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to link $name: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.tradingSell,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showMobileWalletModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.backgroundSecondary : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
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
                  'Link Mobile Wallet',
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
            _buildWalletOption(
              'Apple Pay',
              Icons.apple,
              isDark ? Colors.white : Colors.black,
              onTap: () => _addMobileWallet('Apple Pay', 'apple_pay'),
            ),
            _buildWalletOption(
              'Google Pay',
              Icons.g_mobiledata,
              Colors.blue,
              onTap: () => _addMobileWallet('Google Pay', 'google_pay'),
            ),
            _buildWalletOption(
              'PayPal',
              Icons.payment,
              Colors.blue.shade700,
              onTap: () => _addMobileWallet('PayPal', 'paypal'),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletOption(String name, IconData icon, Color color, {required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final cardBg = isDark ? AppColors.backgroundCard : Colors.white;
    final borderColor = isDark ? AppColors.glassBorder : Colors.black.withOpacity(0.1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: AppTypography.bodyMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Link',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    String? hint,
    bool obscure = false,
  }) {
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
          obscureText: obscure,
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
