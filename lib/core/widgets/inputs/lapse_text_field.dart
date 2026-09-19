import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

    final inputStyle = lapse.text.itemTitle.copyWith(
      fontWeight: FontWeight.w500,
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
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: Sizes.input),
          padding: const EdgeInsets.symmetric(horizontal: 14),
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
              if (widget.suffixText != null) ...[
                const SizedBox(width: 10),
                Text(
                  widget.suffixText!,
                  style: lapse.text.chip.copyWith(color: c.inkSubtle),
                ),
              ],
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
