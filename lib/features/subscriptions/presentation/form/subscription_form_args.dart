import 'package:flutter/foundation.dart';

@immutable
class SubscriptionFormArgs {
  const SubscriptionFormArgs({this.id, this.serviceKey, this.name});

  const SubscriptionFormArgs.edit(String this.id)
    : serviceKey = null,
      name = null;

  final String? id;
  final String? serviceKey;
  final String? name;

  bool get isEdit => id != null;

  @override
  bool operator ==(Object other) =>
      other is SubscriptionFormArgs &&
      other.id == id &&
      other.serviceKey == serviceKey &&
      other.name == name;

  @override
  int get hashCode => Object.hash(id, serviceKey, name);

  @override
  String toString() => isEdit
      ? 'SubscriptionFormArgs.edit($id)'
      : 'SubscriptionFormArgs(service: $serviceKey, name: $name)';
}
