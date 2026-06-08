import 'package:flutter/widgets.dart';

import 'sd_card_sync_state.dart';

class SdCardSyncStateScope extends InheritedNotifier<SdCardSyncState> {
  const SdCardSyncStateScope({
    super.key,
    required SdCardSyncState syncState,
    required super.child,
  }) : super(notifier: syncState);

  static SdCardSyncState watch(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<SdCardSyncStateScope>();
    assert(scope != null, 'SdCardSyncStateScope not found.');
    return scope!.notifier!;
  }

  static SdCardSyncState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<SdCardSyncStateScope>();
    assert(scope != null, 'SdCardSyncStateScope not found.');
    return scope!.notifier!;
  }
}
