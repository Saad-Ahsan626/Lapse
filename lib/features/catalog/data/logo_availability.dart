import 'package:flutter/services.dart';

class LogoAvailability {
  LogoAvailability(Set<String> assetPaths)
    : _assetPaths = Set.unmodifiable(assetPaths);

  final Set<String> _assetPaths;

  static Future<LogoAvailability> load(AssetBundle bundle) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    return LogoAvailability(manifest.listAssets().toSet());
  }

  bool hasLogo(String key) => _assetPaths.contains('assets/logos/$key.svg');
}
