import 'package:flutter/foundation.dart';

import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/core/formatting/money_formatter.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';

const Object _unset = Object();

@immutable
class SubscriptionFormState {
  SubscriptionFormState({
    required this.name,
    required this.currency,
    required this.period,
    required this.startDate,
    this.isEdit = false,
    this.catalogKey,
    this.category,
    this.priceText = '',
    this.customDaysText = '',
    this.isTrial = false,
    this.trialLengthDays = defaultTrialLength,
    this.nextBillingDate,
    List<int> reminderOffsets = const [],
    this.cancelUrl = '',
    this.paymentMethod = '',
    this.notes = '',
    Map<SubscriptionField, String> errors = const {},
    this.isSaving = false,
    this.isLoading = false,
    this.loadError,
  }) : reminderOffsets = List.unmodifiable(
         reminderOffsets.toSet().toList()..sort((a, b) => b.compareTo(a)),
       ),
       errors = Map.unmodifiable(errors);

  static const defaultTrialLength = 7;
  static const trialLengths = [3, 7, 14, 30];

  final bool isEdit;
  final String name;
  final String? catalogKey;
  final String? category;
  final String priceText;
  final String currency;
  final BillingPeriod period;
  final String customDaysText;
  final bool isTrial;
  final int? trialLengthDays;
  final CalendarDate startDate;
  final CalendarDate? nextBillingDate;
  final List<int> reminderOffsets;
  final String cancelUrl;
  final String paymentMethod;
  final String notes;
  final Map<SubscriptionField, String> errors;
  final bool isSaving;
  final bool isLoading;
  final String? loadError;

  Money? get price => parseMoneyInput(priceText, currency);

  int? get customDays => int.tryParse(customDaysText.trim());

  bool get hasValidCustomDays {
    final days = customDays;
    return days != null && days >= 1;
  }

  bool get canSave {
    if (isSaving || isLoading || loadError != null) return false;
    if (name.trim().isEmpty) return false;
    final parsed = price;
    if (parsed == null || !parsed.isPositive) return false;
    if (nextBillingDate == null) return false;
    if (period == BillingPeriod.customDays && !hasValidCustomDays) {
      return false;
    }
    return true;
  }

  bool isDirtyComparedTo(SubscriptionFormState initial) =>
      name != initial.name ||
      catalogKey != initial.catalogKey ||
      category != initial.category ||
      priceText.trim() != initial.priceText.trim() ||
      currency != initial.currency ||
      period != initial.period ||
      customDaysText.trim() != initial.customDaysText.trim() ||
      isTrial != initial.isTrial ||
      (isTrial && trialLengthDays != initial.trialLengthDays) ||
      startDate != initial.startDate ||
      nextBillingDate != initial.nextBillingDate ||
      !listEquals(reminderOffsets, initial.reminderOffsets) ||
      cancelUrl.trim() != initial.cancelUrl.trim() ||
      paymentMethod.trim() != initial.paymentMethod.trim() ||
      notes.trim() != initial.notes.trim();

  SubscriptionFormState copyWith({
    bool? isEdit,
    String? name,
    Object? catalogKey = _unset,
    Object? category = _unset,
    String? priceText,
    String? currency,
    BillingPeriod? period,
    String? customDaysText,
    bool? isTrial,
    Object? trialLengthDays = _unset,
    CalendarDate? startDate,
    Object? nextBillingDate = _unset,
    List<int>? reminderOffsets,
    String? cancelUrl,
    String? paymentMethod,
    String? notes,
    Map<SubscriptionField, String>? errors,
    bool? isSaving,
    bool? isLoading,
    Object? loadError = _unset,
  }) => SubscriptionFormState(
    isEdit: isEdit ?? this.isEdit,
    name: name ?? this.name,
    catalogKey: identical(catalogKey, _unset)
        ? this.catalogKey
        : catalogKey as String?,
    category: identical(category, _unset) ? this.category : category as String?,
    priceText: priceText ?? this.priceText,
    currency: currency ?? this.currency,
    period: period ?? this.period,
    customDaysText: customDaysText ?? this.customDaysText,
    isTrial: isTrial ?? this.isTrial,
    trialLengthDays: identical(trialLengthDays, _unset)
        ? this.trialLengthDays
        : trialLengthDays as int?,
    startDate: startDate ?? this.startDate,
    nextBillingDate: identical(nextBillingDate, _unset)
        ? this.nextBillingDate
        : nextBillingDate as CalendarDate?,
    reminderOffsets: reminderOffsets ?? this.reminderOffsets,
    cancelUrl: cancelUrl ?? this.cancelUrl,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    notes: notes ?? this.notes,
    errors: errors ?? this.errors,
    isSaving: isSaving ?? this.isSaving,
    isLoading: isLoading ?? this.isLoading,
    loadError: identical(loadError, _unset)
        ? this.loadError
        : loadError as String?,
  );

  @override
  bool operator ==(Object other) =>
      other is SubscriptionFormState &&
      other.isEdit == isEdit &&
      other.name == name &&
      other.catalogKey == catalogKey &&
      other.category == category &&
      other.priceText == priceText &&
      other.currency == currency &&
      other.period == period &&
      other.customDaysText == customDaysText &&
      other.isTrial == isTrial &&
      other.trialLengthDays == trialLengthDays &&
      other.startDate == startDate &&
      other.nextBillingDate == nextBillingDate &&
      listEquals(other.reminderOffsets, reminderOffsets) &&
      other.cancelUrl == cancelUrl &&
      other.paymentMethod == paymentMethod &&
      other.notes == notes &&
      mapEquals(other.errors, errors) &&
      other.isSaving == isSaving &&
      other.isLoading == isLoading &&
      other.loadError == loadError;

  @override
  int get hashCode => Object.hashAll([
    isEdit,
    name,
    catalogKey,
    category,
    priceText,
    currency,
    period,
    customDaysText,
    isTrial,
    trialLengthDays,
    startDate,
    nextBillingDate,
    Object.hashAll(reminderOffsets),
    cancelUrl,
    paymentMethod,
    notes,
    Object.hashAllUnordered(
      errors.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    isSaving,
    isLoading,
    loadError,
  ]);

  @override
  String toString() =>
      'SubscriptionFormState($name, $priceText $currency, ${period.name}, '
      'next $nextBillingDate${isTrial ? ', trial' : ''}'
      '${isLoading ? ', loading' : ''}${errors.isEmpty ? '' : ', $errors'})';
}
