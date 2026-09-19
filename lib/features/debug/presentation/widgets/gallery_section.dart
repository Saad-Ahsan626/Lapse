import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

class GallerySection extends StatelessWidget {
  const GallerySection({
    required this.title,
    required this.child,
    this.note,
    super.key,
  });

  final String title;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.xxxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          if (note != null) Text(note!, style: context.lapse.text.meta),
          const SizedBox(height: Space.lg),
          child,
        ],
      ),
    );
  }
}
