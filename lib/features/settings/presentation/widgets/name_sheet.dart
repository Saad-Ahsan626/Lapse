import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

Future<String?> showNameSheet(BuildContext context, String? current) =>
    showLapseSheet<String>(
      context: context,
      title: 'Your name',
      builder: (_) => NameSheet(initial: current),
    );

class NameSheet extends StatefulWidget {
  const NameSheet({this.initial, super.key});

  final String? initial;

  static const maxLength = 30;
  static const note = 'Used in the Home greeting. Leave it empty for none.';

  @override
  State<NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<NameSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close(String value) => Navigator.of(context).pop(value.trim());

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        Space.screen,
        0,
        Space.screen,
        Space.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Your name',
            child: LapseTextField(
              controller: _controller,
              hint: 'Your name',
              textInputAction: TextInputAction.done,
              inputFormatters: [
                LengthLimitingTextInputFormatter(NameSheet.maxLength),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
          Text(NameSheet.note, style: lapse.text.meta),
          const SizedBox(height: Space.xl),
          Row(
            children: [
              Expanded(
                child: LapseButton(
                  label: 'Clear',
                  variant: LapseButtonVariant.secondary,
                  expand: true,
                  onPressed: () => _close(''),
                ),
              ),
              const SizedBox(width: Space.md),
              Expanded(
                child: LapseButton(
                  label: 'Save',
                  expand: true,
                  onPressed: () => _close(_controller.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
