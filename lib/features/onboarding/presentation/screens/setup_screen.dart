import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lapse/app/router/routes.dart';
import 'package:lapse/core/domain/currency_for_country.dart';
import 'package:lapse/core/providers/storage_providers.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/onboarding/presentation/providers/onboarding_controller.dart';
import 'package:lapse/features/onboarding/presentation/widgets/reminder_time_field.dart';
import 'package:lapse/features/onboarding/presentation/widgets/setup_progress_bar.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/currency_list.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  static const title = 'Set your defaults';
  static const subtitle = 'You can change both of these later in Settings.';
  static const timeCaption =
      'Reminders arrive at this time on the days you pick per subscription.';
  static const visibleRows = 5;

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = '';
  bool _saving = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(onboardingControllerProvider.notifier).saveDefaults();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    unawaited(context.push<void>(Routes.permission));
  }

  double _listHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final row = math.max(
      CurrencyList.rowExtent,
      Space.sm * 2 + scaler.scale(35),
    );
    const rows = SetupScreen.visibleRows;
    final natural = row * rows + rows - 1;
    final cap = math.max(
      CurrencyList.rowExtent * rows + rows - 1,
      MediaQuery.sizeOf(context).height * 0.5,
    );
    return math.min(natural, cap);
  }

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final draft = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final pinned = currencyForCountry(ref.watch(deviceCountryProvider));

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Space.screen,
                  Space.md,
                  Space.screen,
                  Space.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SetupProgressBar(),
                    const SizedBox(height: Space.xxl),
                    Semantics(
                      header: true,
                      child: Text(
                        SetupScreen.title,
                        style: lapse.text.title.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: Space.xs),
                    Text(SetupScreen.subtitle, style: lapse.text.bodyMuted),
                    const SizedBox(height: Space.xxl),
                    const _SectionLabel('CURRENCY'),
                    const SizedBox(height: Space.sm),
                    Semantics(
                      label: 'Search currencies',
                      child: LapseTextField(
                        controller: _search,
                        hint: 'Search currency',
                        textInputAction: TextInputAction.search,
                        leading: ExcludeSemantics(
                          child: Icon(
                            Icons.search_rounded,
                            size: 22,
                            color: c.inkSubtle,
                          ),
                        ),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                    const SizedBox(height: Space.md),
                    LapseCard(
                      padding: EdgeInsets.zero,
                      child: SizedBox(
                        height: _listHeight(context),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CurrencyList(
                                selected: draft.currency,
                                pinned: pinned,
                                query: _query,
                                horizontalInset: Space.lg,
                                onSelected: controller.setCurrency,
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: Space.xl,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        c.surface.withValues(alpha: 0),
                                        c.surface,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: Space.xxl),
                    const _SectionLabel('DEFAULT REMINDER TIME'),
                    const SizedBox(height: Space.sm),
                    LapseCard(
                      padding: const EdgeInsets.all(Space.lg),
                      child: Column(
                        children: [
                          ReminderTimeField(
                            minutes: draft.minutes,
                            onChanged: controller.setMinutes,
                          ),
                          const SizedBox(height: Space.md),
                          Text(
                            SetupScreen.timeCaption,
                            textAlign: TextAlign.center,
                            style: lapse.text.bodyMuted.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Space.screen,
                Space.sm,
                Space.screen,
                Space.lg,
              ),
              child: LapseButton(
                label: 'Continue',
                expand: true,
                loading: _saving,
                onPressed: () => unawaited(_continue()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: context.lapse.text.caption),
  );
}
