import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/debug/presentation/widgets/gallery_section.dart';

class InputsSection extends StatefulWidget {
  const InputsSection({super.key});

  @override
  State<InputsSection> createState() => _InputsSectionState();
}

class _InputsSectionState extends State<InputsSection> {
  bool _trial = true;

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Inputs',
      child: Column(
        children: [
          const LapseTextField(
            label: 'Price',
            prefixText: 'Rs',
            suffixText: 'PKR',
            hint: '649',
            tabular: true,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: Space.md),
          LapseTextField(
            hint: 'Price',
            prefixText: 'Rs',
            errorText: 'Enter a price',
            tabular: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: Space.md),
          LapseSwitchRow(
            label: 'Free trial',
            leading: const TrialBadge(),
            activeColor: context.lapse.colors.trial,
            value: _trial,
            onChanged: (v) => setState(() => _trial = v),
          ),
        ],
      ),
    );
  }
}
