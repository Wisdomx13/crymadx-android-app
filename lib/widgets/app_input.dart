import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// AppInput - Custom text field matching CrymadX design
class AppInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? placeholder; // Alias for hint
  final String? errorText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Widget? suffix;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final TextStyle? style;
  final bool showPasswordToggle;
  final String? initialValue;

  /// Get effective hint text
  String? get effectiveHint => hint ?? placeholder;

  const AppInput({
    super.key,
    this.label,
    this.hint,
    this.placeholder,
    this.errorText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.onSuffixTap,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.style,
    this.showPasswordToggle = false,
    this.initialValue,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late bool _obscureText;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _toggleObscure() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: AppTypography.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: hasError
                  ? AppColors.error
                  : _isFocused
                      ? AppColors.primary
                      : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Input Field
        Container(
          decoration: BoxDecoration(
            color: widget.enabled
                ? AppColors.backgroundInput
                : AppColors.backgroundContainer,
            borderRadius: BorderRadius.circular(AppRadius.input),
            border: Border.all(
              color: hasError
                  ? AppColors.error
                  : _isFocused
                      ? AppColors.primary
                      : AppColors.glassBorder,
              width: _isFocused || hasError ? 1.5 : 1,
            ),
          ),
          child: TextFormField(
            controller: widget.controller,
            initialValue: widget.controller == null ? widget.initialValue : null,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: _obscureText,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            textAlign: widget.textAlign,
            style: widget.style ??
                TextStyle(
                  fontSize: AppTypography.fontSizeMd,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
            decoration: InputDecoration(
              hintText: widget.effectiveHint,
              hintStyle: TextStyle(
                fontSize: AppTypography.fontSizeMd,
                color: AppColors.textMuted,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused
                          ? AppColors.primary
                          : AppColors.textMuted,
                      size: 20,
                    )
                  : null,
              suffixIcon: _buildSuffixIcon(),
              counterText: '',
            ),
          ),
        ),

        // Error Text
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.errorText!,
            style: TextStyle(
              fontSize: AppTypography.fontSizeXs,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.showPasswordToggle && widget.obscureText) {
      return IconButton(
        onPressed: _toggleObscure,
        icon: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textMuted,
          size: 20,
        ),
      );
    }

    if (widget.suffix != null) {
      return widget.suffix;
    }

    if (widget.suffixIcon != null) {
      return IconButton(
        onPressed: widget.onSuffixTap,
        icon: Icon(
          widget.suffixIcon,
          color: AppColors.textMuted,
          size: 20,
        ),
      );
    }

    return null;
  }
}

/// Search input variant
class AppSearchInput extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const AppSearchInput({
    super.key,
    this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AppInput(
      controller: controller,
      hint: hint,
      prefixIcon: Icons.search,
      suffixIcon: Icons.close,
      onSuffixTap: () {
        controller?.clear();
        onClear?.call();
      },
      onChanged: onChanged,
    );
  }
}

/// Amount input with currency
class AppAmountInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? currency;
  final String? symbol; // Alias for currency
  final String? label;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onMaxTap;
  final VoidCallback? onMaxPressed; // Alias for onMaxTap

  /// Get effective currency text
  String get effectiveCurrency => currency ?? symbol ?? 'USD';

  /// Get effective max tap callback
  VoidCallback? get effectiveOnMaxTap => onMaxTap ?? onMaxPressed;

  const AppAmountInput({
    super.key,
    this.controller,
    this.currency,
    this.symbol,
    this.label,
    this.hint = '0.00',
    this.errorText,
    this.onChanged,
    this.onMaxTap,
    this.onMaxPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppInput(
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.right,
      style: TextStyle(
        fontSize: AppTypography.fontSizeXxl,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      suffix: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (effectiveOnMaxTap != null)
            TextButton(
              onPressed: effectiveOnMaxTap,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                minimumSize: Size.zero,
              ),
              child: Text(
                'MAX',
                style: TextStyle(
                  fontSize: AppTypography.fontSizeXs,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          Text(
            effectiveCurrency,
            style: TextStyle(
              fontSize: AppTypography.fontSizeMd,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
        ],
      ),
      onChanged: onChanged,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
    );
  }
}
