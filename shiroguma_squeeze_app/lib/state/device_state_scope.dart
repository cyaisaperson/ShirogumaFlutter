import 'package:flutter/widgets.dart';

import 'device_state.dart';

class DeviceStateScope extends InheritedNotifier<DeviceState> {
  const DeviceStateScope({
    super.key,
    required DeviceState deviceState,
    required super.child,
  }) : super(notifier: deviceState);

  static DeviceState watch(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<DeviceStateScope>();
    assert(scope != null, 'No DeviceStateScope found in context.');
    return scope!.notifier!;
  }

  static DeviceState read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<DeviceStateScope>();
    final scope = element?.widget as DeviceStateScope?;
    assert(scope != null, 'No DeviceStateScope found in context.');
    return scope!.notifier!;
  }
}
