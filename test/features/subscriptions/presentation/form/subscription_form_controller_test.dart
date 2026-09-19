import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/core/domain/money.dart';
import 'package:lapse/features/subscriptions/domain/entities/billing_period.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_controller.dart';
import 'package:lapse/features/subscriptions/presentation/providers/subscription_list_providers.dart';

import '../../../../helpers/fake_subscription_repository.dart';
import '../../../../helpers/subscription_fixtures.dart';
import '../form_test_support.dart';

void main() {
  late FakeSubscriptionRepository repository;

  setUp(() => repository = FakeSubscriptionRepository());

  group('initial state', () {
    test(
      'a known custom name copies the latest matching subscription',
      () async {
        repository.seed([
          subscriptionFixture(
            id: 'old',
            name: 'Gym membership',
            priceMinor: 400000,
          ),
          subscriptionFixture(
            id: 'new',
            name: 'Gym membership',
            priceMinor: 450000,
            currency: 'USD',
            period: BillingPeriod.customDays,
            customDays: 45,
          ).copyWith(
            category: 'Health',
            createdAt: DateTime.utc(2026, 9, 10),
          ),
          subscriptionFixture(
            id: 'catalog',
            name: 'Gym membership',
          ).copyWith(catalogKey: 'gym', createdAt: DateTime.utc(2026, 9, 12)),
        ]);
        final container = formContainer(repository)
          ..listen(subscriptionsProvider, (_, _) {});
        await container.read(subscriptionsProvider.future);

        final state = (await openForm(
          container,
          const SubscriptionFormArgs(name: 'gym membership'),
        )).state;

        expect(state.name, 'Gym membership');
        expect(state.priceText, '4500');
        expect(state.currency, 'USD');
        expect(state.period, BillingPeriod.customDays);
        expect(state.customDaysText, '45');
        expect(state.category, 'Health');
        expect(state.catalogKey, isNull);
      },
    );

    test('an unknown custom name starts empty', () async {
      final state = (await openForm(
        formContainer(repository),
        const SubscriptionFormArgs(name: 'Chess club'),
      )).state;

      expect(state.name, 'Chess club');
      expect(state.priceText, isEmpty);
      expect(state.period, BillingPeriod.monthly);
    });

    test('from a catalog service', () async {
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs(serviceKey: 'netflix'),
      );
      final state = form.state;

      expect(state.isLoading, isFalse);
      expect(state.name, 'Netflix');
      expect(state.catalogKey, 'netflix');
      expect(state.category, 'Entertainment');
      expect(state.period, BillingPeriod.monthly);
      expect(state.cancelUrl, 'https://netflix.com/cancelplan');
      expect(state.currency, 'PKR');
      expect(state.reminderOffsets, [7, 1]);
      expect(state.startDate, formToday);
      expect(state.nextBillingDate, CalendarDate(2026, 10, 18));
      expect(state.priceText, isEmpty);
      expect(form.isDirty, isFalse);
    });

    test('uses the service default period for the suggested date', () async {
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs(serviceKey: 'icloud'),
      );
      expect(form.state.period, BillingPeriod.yearly);
      expect(form.state.nextBillingDate, CalendarDate(2027, 9, 18));
    });

    test('unknown service falls back to an empty form', () async {
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs(serviceKey: 'nope'),
      );
      expect(form.state.isLoading, isFalse);
      expect(form.state.name, isEmpty);
      expect(form.state.catalogKey, isNull);
    });

    test('from a custom name', () async {
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs(name: ' Gym '),
      );
      expect(form.state.name, 'Gym');
      expect(form.state.catalogKey, isNull);
      expect(form.state.category, isNull);
      expect(form.state.nextBillingDate, CalendarDate(2026, 10, 18));
    });

    test('plain new form is empty', () async {
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs(),
      );
      expect(form.state.name, isEmpty);
      expect(form.state.isEdit, isFalse);
      expect(form.state.isTrial, isFalse);
      expect(form.state.canSave, isFalse);
    });

    test('edit loads the existing subscription', () async {
      repository.seed([
        subscriptionFixture(
          id: 'sub-9',
          name: 'Spotify',
          period: BillingPeriod.customDays,
          customDays: 45,
          nextBillingDate: CalendarDate(2026, 10, 5),
          reminderOffsets: const [3],
          cancelUrl: 'https://spotify.com/account',
        ),
      ]);
      final container = formContainer(repository);
      const args = SubscriptionFormArgs.edit('sub-9');
      final provider = subscriptionFormProvider(args);
      container.listen(provider, (_, _) {});
      expect(container.read(provider).isLoading, isTrue);

      final form = await openForm(container, args);
      final state = form.state;
      expect(state.isEdit, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.name, 'Spotify');
      expect(state.priceText, '299');
      expect(state.period, BillingPeriod.customDays);
      expect(state.customDaysText, '45');
      expect(state.nextBillingDate, CalendarDate(2026, 10, 5));
      expect(state.startDate, CalendarDate(2026, 9, 1));
      expect(state.reminderOffsets, [3]);
      expect(state.cancelUrl, 'https://spotify.com/account');
      expect(state.canSave, isTrue);
      expect(form.isDirty, isFalse);
    });

    test('edit of a missing subscription reports an error', () async {
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs.edit('ghost'),
      );
      expect(form.state.isLoading, isFalse);
      expect(form.state.loadError, SubscriptionFormController.notFoundMessage);
      expect(form.state.canSave, isFalse);
    });
  });

  group('canSave', () {
    test('needs a name, a positive price and a date', () async {
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs(),
      );
      expect(form.state.canSave, isFalse);
      form.setName('Gym');
      expect(form.state.canSave, isFalse);
      form.setPrice('0');
      expect(form.state.canSave, isFalse);
      form.setPrice('abc');
      expect(form.state.canSave, isFalse);
      form.setPrice('2500');
      expect(form.state.canSave, isTrue);
      form.setName('   ');
      expect(form.state.canSave, isFalse);
    });

    test('custom period needs at least one day', () async {
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs(serviceKey: 'netflix'),
      );
      form
        ..setPrice('649')
        ..setPeriod(BillingPeriod.customDays);
      expect(form.state.canSave, isFalse);
      form.setCustomDays('0');
      expect(form.state.canSave, isFalse);
      form.setCustomDays('10');
      expect(form.state.canSave, isTrue);
    });
  });

  group('trial', () {
    test('on sets the trial end, off restores the suggestion', () async {
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs(serviceKey: 'netflix'),
      );
      form.setTrial(on: true);
      expect(form.state.isTrial, isTrue);
      expect(form.state.trialLengthDays, 7);
      expect(form.state.startDate, formToday);
      expect(form.state.nextBillingDate, CalendarDate(2026, 9, 25));

      form.setTrialLength(30);
      expect(form.state.nextBillingDate, CalendarDate(2026, 10, 18));
      form.setTrialLength(3);
      expect(form.state.nextBillingDate, CalendarDate(2026, 9, 21));

      form.setTrialLength(null);
      expect(form.state.trialLengthDays, isNull);
      expect(form.state.nextBillingDate, CalendarDate(2026, 9, 21));
      form.setNextBillingDate(CalendarDate(2026, 9, 28));
      expect(form.state.nextBillingDate, CalendarDate(2026, 9, 28));
      expect(form.state.trialLengthDays, isNull);

      form.setTrial(on: false);
      expect(form.state.isTrial, isFalse);
      expect(form.state.nextBillingDate, CalendarDate(2026, 10, 18));
    });

    test('off restores the last manually picked date', () async {
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs(serviceKey: 'netflix'),
      );
      form
        ..setNextBillingDate(CalendarDate(2026, 10, 2))
        ..setTrial(on: true);
      expect(form.state.nextBillingDate, CalendarDate(2026, 9, 25));
      form.setTrial(on: false);
      expect(form.state.nextBillingDate, CalendarDate(2026, 10, 2));
    });

    test('picking a date that matches a length selects it', () async {
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs(serviceKey: 'netflix'),
      );
      form
        ..setTrial(on: true)
        ..setTrialLength(null)
        ..setNextBillingDate(CalendarDate(2026, 10, 2));
      expect(form.state.trialLengthDays, 14);
    });

    test('edit mode never changes the start date', () async {
      repository.seed([subscriptionFixture()]);
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs.edit('sub-1'),
      );
      form.setTrial(on: true);
      expect(form.state.startDate, CalendarDate(2026, 9, 1));
      expect(form.state.nextBillingDate, CalendarDate(2026, 9, 25));
      form.setTrial(on: false);
      expect(form.state.startDate, CalendarDate(2026, 9, 1));
      expect(form.state.nextBillingDate, CalendarDate(2026, 10, 1));
    });
  });

  group('period', () {
    test('moves the suggested date on a new subscription', () async {
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs(serviceKey: 'netflix'),
      );
      form.setPeriod(BillingPeriod.weekly);
      expect(form.state.nextBillingDate, CalendarDate(2026, 9, 25));
      form.setPeriod(BillingPeriod.quarterly);
      expect(form.state.nextBillingDate, CalendarDate(2026, 12, 18));
      form.setPeriod(BillingPeriod.customDays);
      expect(form.state.nextBillingDate, CalendarDate(2026, 12, 18));
      form.setCustomDays('10');
      expect(form.state.nextBillingDate, CalendarDate(2026, 9, 28));
    });

    test('keeps a date the user picked', () async {
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs(serviceKey: 'netflix'),
      );
      form
        ..setNextBillingDate(CalendarDate(2026, 10, 3))
        ..setPeriod(BillingPeriod.yearly);
      expect(form.state.nextBillingDate, CalendarDate(2026, 10, 3));
    });

    test('keeps the date in edit mode', () async {
      repository.seed([subscriptionFixture()]);
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs.edit('sub-1'),
      );
      form.setPeriod(BillingPeriod.yearly);
      expect(form.state.nextBillingDate, CalendarDate(2026, 10, 1));
    });
  });

  test('toggleReminder adds and removes offsets', () async {
    final form = await openForm(
      formContainer(repository),
      const SubscriptionFormArgs(),
    );
    form.toggleReminder(3);
    expect(form.state.reminderOffsets, [7, 3, 1]);
    form.toggleReminder(7);
    expect(form.state.reminderOffsets, [3, 1]);
    form.toggleReminder(0);
    expect(form.state.reminderOffsets, [3, 1, 0]);
  });

  group('save', () {
    test('stores a new subscription with the parsed price', () async {
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs(serviceKey: 'netflix'),
      );
      form
        ..setPrice('649.50')
        ..setPaymentMethod(' HBL 4417 ')
        ..setNotes('family plan');

      final saved = await form.save();

      expect(saved, isNotNull);
      expect(saved!.id, 'id-0');
      expect(repository.subscriptions['id-0'], saved);
      expect(saved.price, const Money(64950, 'PKR'));
      expect(saved.name, 'Netflix');
      expect(saved.catalogKey, 'netflix');
      expect(saved.category, 'Entertainment');
      expect(saved.nextBillingDate, CalendarDate(2026, 10, 18));
      expect(saved.anchorDay, 18);
      expect(saved.startDate, formToday);
      expect(saved.paymentMethod, 'HBL 4417');
      expect(saved.notes, 'family plan');
      expect(saved.reminderOffsets, [7, 1]);
      expect(form.state.isSaving, isFalse);
      expect(form.isDirty, isFalse);
    });

    test('saves a trial with custom days', () async {
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs(name: 'Gym'),
      );
      form
        ..setPrice('2500')
        ..setPeriod(BillingPeriod.customDays)
        ..setCustomDays('28')
        ..setTrial(on: true)
        ..setTrialLength(14);

      final saved = await form.save();

      expect(saved!.isTrial, isTrue);
      expect(saved.customDays, 28);
      expect(saved.nextBillingDate, CalendarDate(2026, 10, 2));
      expect(saved.cancelUrl, isNull);
    });

    test('updates an existing subscription in place', () async {
      final original = subscriptionFixture();
      repository.seed([original]);
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs.edit('sub-1'),
      );
      form.setPrice('350');

      final saved = await form.save();

      expect(saved!.id, 'sub-1');
      expect(saved.price, const Money(35000, 'PKR'));
      expect(saved.createdAt, original.createdAt);
      expect(saved.startDate, original.startDate);
      expect(repository.subscriptions.length, 1);
    });

    test('maps validation errors to fields', () async {
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs(serviceKey: 'netflix'),
      );
      form
        ..setPrice('649')
        ..setPaymentMethod('4111 1111 1111 1111')
        ..setCancelUrl('netflix');

      final saved = await form.save();

      expect(saved, isNull);
      expect(repository.subscriptions, isEmpty);
      expect(
        form.state.errors[SubscriptionField.paymentMethod],
        'Only add the last 4 digits',
      );
      expect(form.state.errors, contains(SubscriptionField.cancelUrl));
      expect(form.state.isSaving, isFalse);

      form.setPaymentMethod('Visa 1111');
      expect(
        form.state.errors,
        isNot(contains(SubscriptionField.paymentMethod)),
      );
      expect(form.state.errors, contains(SubscriptionField.cancelUrl));
    });

    test('does nothing when the form cannot be saved', () async {
      final form = await openForm(
        formContainer(repository),
        const SubscriptionFormArgs(),
      );
      expect(await form.save(), isNull);
      expect(repository.subscriptions, isEmpty);
    });
  });

  test('dirty tracking compares with the initial values', () async {
    final form = await openForm(
      formContainer(repository),
      const SubscriptionFormArgs(serviceKey: 'netflix'),
    );
    expect(form.isDirty, isFalse);
    form.setPrice('649');
    expect(form.isDirty, isTrue);
    form.setPrice('');
    expect(form.isDirty, isFalse);
    form.toggleReminder(3);
    expect(form.isDirty, isTrue);
    form.toggleReminder(3);
    expect(form.isDirty, isFalse);
    form.setTrial(on: true);
    expect(form.isDirty, isTrue);
    form.setTrial(on: false);
    expect(form.isDirty, isFalse);
  });
}
