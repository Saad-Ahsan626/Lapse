import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_controller.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_state.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/currency_picker_sheet.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/billing_cycle_section.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/details_section.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/form_header.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/next_billing_date_section.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/price_section.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/reminders_section.dart';
import 'package:lapse/features/subscriptions/presentation/widgets/form/trial_block.dart';

class AddEditSubscriptionScreen extends ConsumerStatefulWidget {
  const AddEditSubscriptionScreen({required this.args, super.key});

  final SubscriptionFormArgs args;

  @override
  ConsumerState<AddEditSubscriptionScreen> createState() =>
      _AddEditSubscriptionScreenState();
}

class _AddEditSubscriptionScreenState
    extends ConsumerState<AddEditSubscriptionScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _customDays = TextEditingController();
  final TextEditingController _cancelUrl = TextEditingController();
  final TextEditingController _paymentMethod = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _priceFocus = FocusNode();

  bool _seeded = false;
  bool _leaving = false;

  SubscriptionFormArgs get _args => widget.args;

  SubscriptionFormController get _form =>
      ref.read(subscriptionFormProvider(_args).notifier);

  @override
  void initState() {
    super.initState();
    ref.listenManual<SubscriptionFormState>(
      subscriptionFormProvider(_args),
      (_, next) => _seed(next),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _price,
      _customDays,
      _cancelUrl,
      _paymentMethod,
      _notes,
    ]) {
      controller.dispose();
    }
    _nameFocus.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  void _seed(SubscriptionFormState form) {
    if (_seeded || form.isLoading || form.loadError != null) return;
    _seeded = true;
    _name.text = form.name;
    _price.text = form.priceText;
    _customDays.text = form.customDaysText;
    _cancelUrl.text = form.cancelUrl;
    _paymentMethod.text = form.paymentMethod;
    _notes.text = form.notes;
    if (_args.isEdit) return;
    final focusPrice = _args.serviceKey != null || _args.name != null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      (focusPrice ? _priceFocus : _nameFocus).requestFocus();
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final delete = ref.read(deleteSubscriptionProvider);
    final isNew = !_args.isEdit;
    final form = _form;
    try {
      final saved = await form.save();
      if (saved == null || !mounted) return;
      setState(() => _leaving = true);
      navigator.pop();
      if (!isNew) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${saved.name} added'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => unawaited(delete(saved.id)),
            ),
          ),
        );
    } on Object {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save. Try again.')),
      );
    }
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your changes will not be saved.'),
        actions: [
          LapseButton(
            label: 'Keep editing',
            variant: LapseButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          LapseButton(
            label: 'Discard',
            variant: LapseButtonVariant.text,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (discard != true || !mounted) return;
    setState(() => _leaving = true);
    Navigator.of(context).pop();
  }

  Future<void> _pickCurrency(String current) async {
    final code = await showCurrencyPicker(context, current);
    if (code != null && mounted) _form.setCurrency(code);
  }

  void _back() => unawaited(Navigator.of(context).maybePop());

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(subscriptionFormProvider(_args));
    final dirty = ref.read(subscriptionFormProvider(_args).notifier).isDirty;
    final c = context.lapse.colors;
    final title = _args.isEdit ? 'Edit subscription' : 'Add subscription';

    final Widget body;
    if (form.isLoading) {
      body = _statusBody(
        const Center(child: CircularProgressIndicator()),
      );
    } else if (form.loadError != null) {
      body = _statusBody(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  form.loadError!,
                  textAlign: TextAlign.center,
                  style: context.lapse.text.bodyMuted,
                ),
                const SizedBox(height: Space.lg),
                LapseButton(label: 'Go back', onPressed: _back),
              ],
            ),
          ),
        ),
      );
    } else {
      body = _formBody(form);
    }

    return PopScope(
      canPop: !dirty || _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmDiscard());
      },
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: title,
        child: Scaffold(
          backgroundColor: c.background,
          body: SafeArea(bottom: false, child: body),
        ),
      ),
    );
  }

  Widget _statusBody(Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(Space.xs, Space.sm, 0, 0),
        child: IconButton(
          tooltip: 'Back',
          onPressed: _back,
          icon: const Icon(Icons.chevron_left_rounded, size: 30),
        ),
      ),
      Expanded(child: child),
    ],
  );

  Widget _formBody(SubscriptionFormState form) {
    final c = context.lapse.colors;
    final today = ref.watch(todayProvider);
    final notifier = _form;

    return Column(
      children: [
        FormHeader(
          state: form,
          nameController: _name,
          nameFocusNode: _nameFocus,
          onNameChanged: notifier.setName,
          onBack: _back,
        ),
        Expanded(
          child: Stack(
            children: [
              ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(
                  Space.xl,
                  Space.xs,
                  Space.xl,
                  Space.xxxl,
                ),
                children: [
                  TrialBlock(
                    state: form,
                    priceController: _price,
                    onTrialChanged: (on) => notifier.setTrial(on: on),
                    onTrialLengthChanged: notifier.setTrialLength,
                    onPriceChanged: notifier.setPrice,
                  ),
                  const SizedBox(height: Space.xl),
                  if (!form.isTrial) ...[
                    PriceSection(
                      state: form,
                      controller: _price,
                      focusNode: _priceFocus,
                      onChanged: notifier.setPrice,
                      onCurrencyTap: () =>
                          unawaited(_pickCurrency(form.currency)),
                    ),
                    const SizedBox(height: Space.xl),
                  ],
                  BillingCycleSection(
                    state: form,
                    customDaysController: _customDays,
                    onPeriodChanged: notifier.setPeriod,
                    onCustomDaysChanged: notifier.setCustomDays,
                  ),
                  const SizedBox(height: Space.lg),
                  NextBillingDateSection(
                    state: form,
                    today: today,
                    onChanged: notifier.setNextBillingDate,
                  ),
                  const SizedBox(height: Space.xl),
                  RemindersSection(
                    state: form,
                    onToggle: notifier.toggleReminder,
                  ),
                  const SizedBox(height: Space.lg),
                  DetailsSection(
                    state: form,
                    cancelUrlController: _cancelUrl,
                    paymentMethodController: _paymentMethod,
                    notesController: _notes,
                    onCancelUrlChanged: notifier.setCancelUrl,
                    onCategoryChanged: notifier.setCategory,
                    onPaymentMethodChanged: notifier.setPaymentMethod,
                    onNotesChanged: notifier.setNotes,
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          c.background.withValues(alpha: 0),
                          c.background,
                        ],
                      ),
                    ),
                    child: const SizedBox(height: Space.xxl),
                  ),
                ),
              ),
            ],
          ),
        ),
        _saveBar(form),
      ],
    );
  }

  Widget _saveBar(SubscriptionFormState form) {
    final c = context.lapse.colors;
    return ColoredBox(
      color: c.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Space.xl,
            14,
            Space.xl,
            Space.md,
          ),
          child: LapseButton(
            label: 'Save',
            expand: true,
            loading: form.isSaving,
            onPressed: form.canSave ? () => unawaited(_save()) : null,
          ),
        ),
      ),
    );
  }
}
