import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';

/// A premium glassmorphism text input field
class GlassInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final bool obscureText;
  final bool showPasswordToggle;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextInputAction? textInputAction;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;

  const GlassInput({
    super.key,
    this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.obscureText = false,
    this.showPasswordToggle = false,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.onChanged,
    this.onTap,
    this.textInputAction,
    this.onEditingComplete,
    this.onSubmitted,
  });

  @override
  State<GlassInput> createState() => _GlassInputState();
}

class _GlassInputState extends State<GlassInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _obscurePassword = widget.obscureText;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    // Colors based on state
    final borderColor = hasError
        ? AppColors.error
        : _isFocused
            ? (isDark ? AppColors.primary.withOpacity(0.6) : AppColors.primary)
            : (isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!);

    final backgroundColor = isDark
        ? (_isFocused
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
              ))
        : LinearGradient(
            colors: [Colors.white, Colors.white.withOpacity(0.95)],
          );

    final textColor = isDark ? Colors.white : Colors.black;
    final hintColor = isDark ? Colors.grey[600] : Colors.grey[500];
    final iconColor = _isFocused
        ? AppColors.primary
        : (isDark ? Colors.grey[500] : Colors.grey[600]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Input container
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: isDark
                ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: _isFocused ? 1.5 : 1.0,
                ),
                boxShadow: _isFocused && isDark
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.15),
                          blurRadius: 12,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  // Top reflection line
                  if (isDark)
                    Positioned(
                      top: 0,
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(_isFocused ? 0.12 : 0.06),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Text field
                  Row(
                    children: [
                      // Prefix icon
                      if (widget.prefixIcon != null) ...[
                        const SizedBox(width: 14),
                        Icon(
                          widget.prefixIcon,
                          size: 20,
                          color: iconColor,
                        ),
                      ],

                      // Input
                      Expanded(
                        child: TextField(
                          controller: widget.controller,
                          focusNode: _focusNode,
                          obscureText: widget.showPasswordToggle
                              ? _obscurePassword
                              : widget.obscureText,
                          keyboardType: widget.keyboardType,
                          inputFormatters: widget.inputFormatters,
                          maxLines: widget.obscureText ? 1 : widget.maxLines,
                          maxLength: widget.maxLength,
                          enabled: widget.enabled,
                          autofocus: widget.autofocus,
                          onChanged: widget.onChanged,
                          onTap: widget.onTap,
                          textInputAction: widget.textInputAction,
                          onEditingComplete: widget.onEditingComplete,
                          onSubmitted: widget.onSubmitted,
                          cursorColor: AppColors.primary,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.hint,
                            hintStyle: TextStyle(
                              color: hintColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: widget.prefixIcon != null ? 12 : 16,
                              vertical: 14,
                            ),
                            counterText: '',
                          ),
                        ),
                      ),

                      // Password toggle
                      if (widget.showPasswordToggle) ...[
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: iconColor,
                            ),
                          ),
                        ),
                      ] else if (widget.suffix != null) ...[
                        Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: widget.suffix!,
                        ),
                      ] else ...[
                        const SizedBox(width: 14),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Error text
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: 14,
                color: AppColors.error,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A glass-styled search input
class GlassSearchInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool autofocus;

  const GlassSearchInput({
    super.key,
    this.controller,
    this.hint = 'Search...',
    this.onChanged,
    this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: isDark
            ? ImageFilter.blur(sigmaX: 8, sigmaY: 8)
            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.06),
                      Colors.white.withOpacity(0.03),
                    ],
                  )
                : null,
            color: isDark ? null : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(
                Icons.search,
                size: 20,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: autofocus,
                  onChanged: onChanged,
                  cursorColor: AppColors.primary,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[600] : Colors.grey[500],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
              if (controller?.text.isNotEmpty == true && onClear != null) ...[
                GestureDetector(
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
