import 'package:flutter/foundation.dart';

GlobalNotifier globalNotifierCounter = GlobalNotifier(0);

class GlobalNotifier extends ValueNotifier {
  GlobalNotifier(super.value);
  void incrementValue() {
    value++;
    if (kDebugMode) {
      debugPrint('value = $value');
    }
  }
}
