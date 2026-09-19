import 'package:lapse/features/settings/domain/entities/app_settings.dart';
import 'package:lapse/features/settings/domain/repositories/settings_repository.dart';

class InMemorySettingsRepository implements SettingsRepository {
  InMemorySettingsRepository([AppSettings? initial])
    : _settings = initial ?? AppSettings(defaultCurrency: 'PKR');

  AppSettings _settings;
  int saveCount = 0;

  @override
  AppSettings load() => _settings;

  @override
  Future<void> save(AppSettings settings) async {
    _settings = settings;
    saveCount++;
  }
}
