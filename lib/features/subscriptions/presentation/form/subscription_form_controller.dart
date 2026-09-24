import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/errors/validation_exception.dart';
import 'package:lapse/core/formatting/money_formatter.dart';
import 'package:lapse/core/providers/clock_providers.dart';
import 'package:lapse/features/catalog/domain/entities/catalog_service.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:lapse/features/settings/presentation/providers/settings_providers.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_state.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_service_providers.dart';

final NotifierProviderFamily<
  SubscriptionFormController,
  SubscriptionFormState,
  SubscriptionFormArgs
>
subscriptionFormProvider = NotifierProvider.autoDispose
    .family<
      SubscriptionFormController,
      SubscriptionFormState,
      SubscriptionFormArgs
    >(SubscriptionFormController.new);

class SubscriptionFormController extends Notifier<SubscriptionFormState> {
  SubscriptionFormController(this.args);

  static const notFoundMessage = 'This subscription no longer exists';
  static const loadFailedMessage = 'Could not load this subscription';

  final SubscriptionFormArgs args;

  late SubscriptionFormState _initial;
  Subscription? _existing;
  CalendarDate? _manualNextDate;
  bool _userPickedDate = false;

  SubscriptionFormState get initial => _initial;

  bool get isDirty => !state.isLoading && state.isDirtyComparedTo(_initial);

  CalendarDate get _today => ref.read(todayProvider);

  CalendarDate get _trialStart =>
      state.isEdit && (_existing?.isTrial ?? false) ? state.startDate : _today;

  @override
  SubscriptionFormState build() {
    _existing = null;
    _manualNextDate = null;
    _userPickedDate = false;

    final settings = ref.read(settingsProvider);
    final base = SubscriptionFormState(
      isEdit: args.isEdit,
      name: args.name?.trim() ?? '',
      currency: settings.defaultCurrency,
      period: BillingPeriod.monthly,
      startDate: _today,
      reminderOffsets: settings.defaultReminderOffsets,
    );

    final id = args.id;
    if (id != null) {
      _initial = base.copyWith(isLoading: true);
      unawaited(_loadExisting(id));
      return _initial;
    }

    final key = args.serviceKey;
    if (key != null) {
      final service = ref.read(catalogServiceByKeyProvider(key));
      if (service == null) {
        _initial = base.copyWith(isLoading: true);
        unawaited(_loadService(key, base));
        return _initial;
      }
      return _initial = _withSuggestedDate(_applyService(base, service));
    }

    final template = _recentCustomNamed(args.name);
    if (template != null) {
      return _initial = _withSuggestedDate(_applyTemplate(base, template));
    }

    return _initial = _withSuggestedDate(base);
  }

  void setName(String value) =>
      _update(state.copyWith(name: value), clear: SubscriptionField.name);

  void setPrice(String value) =>
      _update(state.copyWith(priceText: value), clear: SubscriptionField.price);

  void setCurrency(String code) =>
      _update(state.copyWith(currency: code), clear: SubscriptionField.price);

  void setPeriod(BillingPeriod period) {
    if (period == state.period) return;
    _update(
      _maybeSuggest(state.copyWith(period: period)),
      clear: SubscriptionField.customDays,
    );
  }

  void setCustomDays(String value) => _update(
    _maybeSuggest(state.copyWith(customDaysText: value)),
    clear: SubscriptionField.customDays,
  );

  void setTrial({required bool on}) {
    if (on == state.isTrial) return;
    final today = _today;
    final start = state.isEdit ? state.startDate : today;
    if (on) {
      final length =
          state.trialLengthDays ?? SubscriptionFormState.defaultTrialLength;
      _update(
        state.copyWith(
          isTrial: true,
          startDate: start,
          trialLengthDays: length,
          nextBillingDate: _trialStart.addDays(length),
        ),
        clear: SubscriptionField.nextBillingDate,
      );
      return;
    }
    final off = state.copyWith(isTrial: false, startDate: start);
    _update(
      off.copyWith(nextBillingDate: _manualNextDate ?? _suggestedDate(off)),
      clear: SubscriptionField.nextBillingDate,
    );
  }

  void setTrialLength(int? days) {
    if (days == null) {
      _update(state.copyWith(trialLengthDays: null));
      return;
    }
    _update(
      state.copyWith(
        trialLengthDays: days,
        nextBillingDate: _trialStart.addDays(days),
      ),
      clear: SubscriptionField.nextBillingDate,
    );
  }

  void setNextBillingDate(CalendarDate date) {
    if (state.isTrial) {
      final length = _trialStart.daysUntil(date);
      _update(
        state.copyWith(
          nextBillingDate: date,
          trialLengthDays: SubscriptionFormState.trialLengths.contains(length)
              ? length
              : null,
        ),
        clear: SubscriptionField.nextBillingDate,
      );
      return;
    }
    _manualNextDate = date;
    _userPickedDate = true;
    _update(
      state.copyWith(nextBillingDate: date),
      clear: SubscriptionField.nextBillingDate,
    );
  }

  void toggleReminder(int offset) {
    final offsets = state.reminderOffsets.toSet();
    if (!offsets.remove(offset)) offsets.add(offset);
    _update(
      state.copyWith(reminderOffsets: offsets.toList()),
      clear: SubscriptionField.reminderOffsets,
    );
  }

  void setCategory(String? category) =>
      _update(state.copyWith(category: category));

  void setCancelUrl(String value) => _update(
    state.copyWith(cancelUrl: value),
    clear: SubscriptionField.cancelUrl,
  );

  void setPaymentMethod(String value) => _update(
    state.copyWith(paymentMethod: value),
    clear: SubscriptionField.paymentMethod,
  );

  void setNotes(String value) => _update(state.copyWith(notes: value));

  Future<Subscription?> save() async {
    if (!state.canSave) return null;
    final draft = _draft();
    final saveSubscription = ref.read(saveSubscriptionProvider);
    state = state.copyWith(isSaving: true, errors: const {});
    try {
      final saved = await saveSubscription(draft);
      if (ref.mounted) {
        _initial = state.copyWith(isSaving: false);
        state = _initial;
      }
      return saved;
    } on ValidationException<SubscriptionField> catch (e) {
      if (ref.mounted) {
        state = state.copyWith(isSaving: false, errors: e.errors);
      }
      return null;
    } on Object {
      if (ref.mounted) state = state.copyWith(isSaving: false);
      rethrow;
    }
  }

  Future<void> _loadExisting(String id) async {
    Subscription? existing;
    String? error;
    try {
      existing = await ref.read(subscriptionRepositoryProvider).getById(id);
      if (existing == null) error = notFoundMessage;
    } on Object {
      error = loadFailedMessage;
    }
    if (!ref.mounted) return;
    if (existing == null) {
      _initial = state.copyWith(isLoading: false, loadError: error);
      state = _initial;
      return;
    }
    _existing = existing;
    _manualNextDate = existing.nextBillingDate;
    _userPickedDate = true;
    final length = existing.startDate.daysUntil(existing.nextBillingDate);
    _initial = SubscriptionFormState(
      isEdit: true,
      name: existing.name,
      catalogKey: existing.catalogKey,
      category: existing.category,
      priceText: moneyInputText(existing.price),
      currency: existing.price.currency,
      period: existing.period,
      customDaysText: existing.customDays?.toString() ?? '',
      isTrial: existing.isTrial,
      trialLengthDays: !existing.isTrial
          ? SubscriptionFormState.defaultTrialLength
          : SubscriptionFormState.trialLengths.contains(length)
          ? length
          : null,
      startDate: existing.startDate,
      nextBillingDate: existing.nextBillingDate,
      reminderOffsets: existing.reminderOffsets,
      cancelUrl: existing.cancelUrl ?? '',
      paymentMethod: existing.paymentMethod ?? '',
      notes: existing.notes ?? '',
    );
    state = _initial;
  }

  Future<void> _loadService(String key, SubscriptionFormState base) async {
    CatalogService? service;
    try {
      final services = await ref.read(catalogProvider.future);
      for (final candidate in services) {
        if (candidate.key == key) {
          service = candidate;
          break;
        }
      }
    } on Object {
      service = null;
    }
    if (!ref.mounted) return;
    _initial = _withSuggestedDate(
      service == null ? base : _applyService(base, service),
    );
    state = _initial;
  }

  SubscriptionFormState _applyService(
    SubscriptionFormState base,
    CatalogService service,
  ) => base.copyWith(
    name: service.name,
    catalogKey: service.key,
    category: service.category,
    period: service.defaultPeriod,
    cancelUrl: service.cancelUrl ?? '',
  );

  Subscription? _recentCustomNamed(String? name) {
    final wanted = name?.trim().toLowerCase();
    if (wanted == null || wanted.isEmpty) return null;
    final matches =
        (ref.read(subscriptionsProvider).value ?? const <Subscription>[])
            .where(
              (s) => s.catalogKey == null && s.name.toLowerCase() == wanted,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return matches.isEmpty ? null : matches.first;
  }

  SubscriptionFormState _applyTemplate(
    SubscriptionFormState base,
    Subscription template,
  ) => base.copyWith(
    name: template.name,
    category: template.category,
    period: template.period,
    customDaysText: template.customDays?.toString() ?? '',
    priceText: moneyInputText(template.price),
    currency: template.price.currency,
  );

  CalendarDate? _suggestedDate(SubscriptionFormState form) {
    if (form.period == BillingPeriod.customDays && !form.hasValidCustomDays) {
      return null;
    }
    return ref
        .read(billingEngineProvider)
        .nextDate(
          form.startDate,
          form.period,
          anchorDay: form.startDate.day,
          customDays: form.customDays,
        );
  }

  SubscriptionFormState _withSuggestedDate(SubscriptionFormState form) =>
      form.copyWith(nextBillingDate: _suggestedDate(form));

  SubscriptionFormState _maybeSuggest(SubscriptionFormState form) {
    if (form.isEdit || form.isTrial || _userPickedDate) return form;
    final suggested = _suggestedDate(form);
    return suggested == null ? form : form.copyWith(nextBillingDate: suggested);
  }

  void _update(SubscriptionFormState next, {SubscriptionField? clear}) {
    state = clear != null && next.errors.containsKey(clear)
        ? next.copyWith(errors: {...next.errors}..remove(clear))
        : next;
  }

  Subscription _draft() {
    final form = state;
    final price = form.price!;
    final next = form.nextBillingDate!;
    final now = ref.read(clockProvider)().toUtc();
    final customDays = form.period == BillingPeriod.customDays
        ? form.customDays
        : null;
    final existing = _existing;
    if (existing != null) {
      return existing.copyWith(
        name: form.name,
        catalogKey: form.catalogKey,
        category: form.category,
        price: price,
        period: form.period,
        customDays: customDays,
        nextBillingDate: next,
        isTrial: form.isTrial,
        reminderOffsets: form.reminderOffsets,
        cancelUrl: form.cancelUrl,
        paymentMethod: form.paymentMethod,
        notes: form.notes,
        updatedAt: now,
      );
    }
    return Subscription(
      id: args.id ?? Subscription.unsavedId,
      name: form.name,
      catalogKey: form.catalogKey,
      category: form.category,
      price: price,
      period: form.period,
      customDays: customDays,
      anchorDay: next.day,
      startDate: form.startDate,
      nextBillingDate: next,
      isTrial: form.isTrial,
      reminderOffsets: form.reminderOffsets,
      cancelUrl: form.cancelUrl,
      paymentMethod: form.paymentMethod,
      notes: form.notes,
      createdAt: now,
      updatedAt: now,
    );
  }
}
