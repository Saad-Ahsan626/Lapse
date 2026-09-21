import 'package:flutter/material.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/home/presentation/widgets/home_hero_placeholder.dart';

class HomeLoading extends StatelessWidget {
  const HomeLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: Space.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          HomeHeroPlaceholder(),
          SizedBox(height: Space.xxxl),
          SkeletonRow(),
          SizedBox(height: 10),
          SkeletonRow(),
          SizedBox(height: 10),
          SkeletonRow(),
        ],
      ),
    );
  }
}
