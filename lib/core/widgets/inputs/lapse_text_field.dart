import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lapse/core/motion/motion.dart';
import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';
import 'package:lapse/core/theme/tokens/lapse_typography.dart';

class LapseTextField extends StatefulWidget {
  const LapseTextField({
    this.controller,
    this.label,
    this.hint,
    this.prefixText,
    this.suffixText,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onChanged,
    this.tabular = false,
    this.focusNode,
    this.leading,
    this.trailing,
    this.onSuffixTap,
    this.suffixSemanticLabel,
    this.textStyle,
    super.key,
  });

  final TextEditingController? controller;

  final String? label;
  final String? hint;

  final String? prefixText;

  final String? suffixText;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  final bool tabular;
  final FocusNode? focusNode;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onSuffixTap;
  final String? suffixSemanticLabel;
  final TextStyle? textStyle;

  @override
  State<LapseTextField> createState() => _LapseTextFieldState();
}

class _LapseTextFieldState extends State<LapseTextField> {
  FocusNode? _ownFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownFocusNode ??= FocusNode());

  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(LapseTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownFocusNode)?.removeListener(_onFocus);
      _focusNode.addListener(_onFocus);
    }
  }

  void _onFocus() => setState(() => _focused = _focusNode.hasFocus);

  @override
  void dispose() {
    _focusNode.removeListener(_onFocus);
    _ownFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final hasError = widget.errorText != null;

    final borderColor = hasError
        ? c.urgent.withValues(alpha: 0.5)
        : _focused
        ? c.primary
        : c.inputBorder;

    final inputStyle = (widget.textStyle ?? lapse.text.itemTitle).copyWith(
      fontWeight: widget.textStyle == null ? FontWeight.w500 : null,
      fontFeatures: widget.tabular ? LapseTypography.tabular : null,
    );
    final unitStyle = lapse.text.itemTitle.copyWith(color: c.inkSubtle);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!.toUpperCase(), style: lapse.text.caption),
          const SizedBox(height: Space.sm),
        ],
        AnimatedContainer(
          duration: Motion.pressOpacity,
          constraints: const BoxConstraints(minHeight: Sizes.input),
          padding: EdgeInsets.only(
            left: 14,
            right: widget.trailing == null && widget.onSuffixTap == null
                ? 14
                : Space.xs,
          ),
          decoration: BoxDecoration(
            color: _focused ? c.surface : c.inputFill,
            borderRadius: BorderRadius.circular(Radii.control),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
            boxShadow: _focused && !hasError
                ? [BoxShadow(color: c.primaryTint, spreadRadius: 4)]
                : null,
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 10),
              ],
              if (widget.prefixText != null) ...[
                Text(widget.prefixText!, style: unitStyle),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  textInputAction: widget.textInputAction,
                  onChanged: widget.onChanged,
                  style: inputStyle,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: inputStyle.copyWith(color: c.inkSubtle),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (widget.suffixText != null)
                _Suffix(
                  text: widget.suffixText!,
                  onTap: widget.onSuffixTap,
                  semanticLabel: widget.suffixSemanticLabel,
                ),
              ?widget.trailing,
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 15, color: c.urgentText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: lapse.text.meta.copyWith(color: c.urgentText),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Suffix extends StatelessWidget {
  const _Suffix({required this.text, this.onTap, this.semanticLabel});

  final String text;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final label = Text(
      text,
      style: lapse.text.chip.copyWith(
        color: onTap == null ? lapse.colors.inkSubtle : lapse.colors.primary,
      ),
    );
    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.only(left: 10),
        child: label,
      );
    }
    return Semantics(
      button: true,
      label: semanticLabel ?? text,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        key: const ValueKey('lapse-text-field-suffix'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: Sizes.minTap,
            minHeight: Sizes.minTap,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(widthFactor: 1, child: label),
          ),
        ),
      ),
    );
  }
}
