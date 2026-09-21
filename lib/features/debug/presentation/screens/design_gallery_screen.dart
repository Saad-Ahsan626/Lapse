import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/features/debug/presentation/widgets/gallery_controls.dart';
import 'package:lapse/features/debug/presentation/widgets/sections/brand_section.dart';
import 'package:lapse/features/debug/presentation/widgets/sections/buttons_section.dart';
import 'package:lapse/features/debug/presentation/widgets/sections/celebration_section.dart';
import 'package:lapse/features/debug/presentation/widgets/sections/chips_section.dart';
import 'package:lapse/features/debug/presentation/widgets/sections/colors_section.dart';
import 'package:lapse/features/debug/presentation/widgets/sections/empty_state_section.dart';
import 'package:lapse/features/debug/presentation/widgets/sections/form_controls_section.dart';
import 'package:lapse/features/debug/presentation/widgets/sections/hero_card_section.dart';
import 'package:lapse/features/debug/presentation/widgets/sections/inputs_section.dart';
import 'package:lapse/features/debug/presentation/widgets/sections/lists_motion_section.dart';
import 'package:lapse/features/debug/presentation/widgets/sections/rings_section.dart';
import 'package:lapse/features/debug/presentation/widgets/sections/spacing_section.dart';
import 'package:lapse/features/debug/presentation/widgets/sections/tiles_section.dart';
import 'package:lapse/features/debug/presentation/widgets/sections/typography_section.dart';

class DesignGalleryScreen extends StatefulWidget {
  const DesignGalleryScreen({super.key});

  @override
  State<DesignGalleryScreen> createState() => _DesignGalleryScreenState();
}

class _DesignGalleryScreenState extends State<DesignGalleryScreen> {
  bool _simulateReduceMotion = false;

  int _replay = 0;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: _simulateReduceMotion),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Design gallery'),
          actions: [
            IconButton(
              tooltip: 'Replay animations',
              onPressed: () => setState(() => _replay++),
              icon: const Icon(Icons.replay_rounded),
            ),
          ],
        ),
        body: ListView(
          key: ValueKey(_replay),
          padding: const EdgeInsets.fromLTRB(
            Space.screen,
            Space.sm,
            Space.screen,
            Space.xxxl,
          ),
          children: [
            GalleryControls(
              reduceMotion: _simulateReduceMotion,
              onReduceMotionChanged: (v) =>
                  setState(() => _simulateReduceMotion = v),
            ),
            const ColorsSection(),
            const TypographySection(),
            const SpacingSection(),
            const ButtonsSection(),
            const ChipsSection(),
            const InputsSection(),
            const FormControlsSection(),
            const RingsSection(),
            const TilesSection(),
            const HeroCardSection(),
            const BrandSection(),
            const EmptyStateSection(),
            const ListsMotionSection(),
            const CelebrationSection(),
          ],
        ),
      ),
    );
  }
}
