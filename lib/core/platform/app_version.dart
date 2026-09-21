import 'package:flutter/foundation.dart';

@immutable
class AppVersion {
  const AppVersion({required this.name, required this.build});

  final String name;
  final String build;

  String get label => '$name ($build)';

  @override
  bool operator ==(Object other) =>
      other is AppVersion && other.name == name && other.build == build;

  @override
  int get hashCode => Object.hash(name, build);

  @override
  String toString() => 'AppVersion($label)';
}
