import 'package:flutter/material.dart';

import 'package:lapse/core/theme/lapse_theme.dart';
import 'package:lapse/core/theme/tokens/lapse_spacing.dart';

class LapseRowField extends StatefulWidget {
  const LapseRowField({
    required this.label,
    this.value,
    this.controller,
    this.hint,
    this.onChanged,
    this.onTap,
    this.keyboardType,
    this.textInputAction,
    this.trailing,
    this.maxLines = 1,
    this.errorText,
    super.key,
  });

  final String label;
  final String? value;
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? trailing;
  final int maxLines;
  final String? errorText;

  @override
  State<LapseRowField> createState() => _LapseRowFieldState();
}

class _LapseRowFieldState extends State<LapseRowField> {
  final FocusNode _focusNode = FocusNode();

  bool get _editable => widget.controller != null || widget.onChanged != null;

  bool get _multiline => widget.maxLines > 1;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final labelStyle = lapse.text.body.copyWith(
      fontWeight: FontWeight.w600,
      color: c.inkMuted,
    );
    final valueStyle = lapse.text.body.copyWith(fontWeight: FontWeight.w500);
    final hintStyle = valueStyle.copyWith(color: c.inkSubtle);

    final labelText = Text(
      widget.label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: labelStyle,
    );

    Widget right;
    if (_editable) {
      right = Semantics(
        label: widget.label,
        child: TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          keyboardType:
              widget.keyboardType ??
              (_multiline ? TextInputType.multiline : null),
          textInputAction: widget.textInputAction,
          maxLines: widget.maxLines,
          minLines: _multiline ? 2 : 1,
          textAlign: _multiline ? TextAlign.start : TextAlign.end,
          style: valueStyle,
          decoration: InputDecoration(
            isCollapsed: true,
            contentPadding: _multiline
                ? const EdgeInsets.only(top: 6, bottom: 13)
                : const EdgeInsets.symmetric(vertical: 14),
            border: InputBorder.none,
            hintText: widget.hint,
            hintStyle: hintStyle,
          ),
        ),
      );
    } else {
      final shown = widget.value ?? widget.hint;
      right = Text(
        shown ?? '',
        maxLines: _multiline ? widget.maxLines : 1,
        overflow: TextOverflow.ellipsis,
        textAlign: _multiline ? TextAlign.start : TextAlign.end,
        style: widget.value == null ? hintStyle : valueStyle,
      );
    }

    Widget content;
    if (_multiline) {
      content = Padding(
        padding: EdgeInsets.fromLTRB(14, 13, 14, _editable ? 0 : 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(excluding: _editable, child: labelText),
            if (!_editable) const SizedBox(height: 6),
            right,
          ],
        ),
      );
    } else {
      content = ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Sizes.input),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: _editable ? 0 : 8,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.5,
                  ),
                  child: ExcludeSemantics(
                    excluding: _editable,
                    child: labelText,
                  ),
                ),
                const SizedBox(width: Space.md),
                Expanded(child: right),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 6),
                  IconTheme.merge(
                    data: IconThemeData(color: c.inkSubtle, size: 20),
                    child: widget.trailing!,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (_editable) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: _focusNode.requestFocus,
        child: content,
      );
    } else if (widget.onTap != null) {
      final shown = widget.value ?? widget.hint;
      content = Semantics(
        button: true,
        label: shown == null ? widget.label : '${widget.label}, $shown',
        excludeSemantics: true,
        onTap: widget.onTap,
        child: InkWell(onTap: widget.onTap, child: content),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 15,
                  color: c.urgentText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: lapse.text.meta.copyWith(color: c.urgentText),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
