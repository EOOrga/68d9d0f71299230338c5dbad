import 'package:flutter/material.dart';

import 'operations_app.dart';
import 'operations_store.dart';

const bool _screenshotMode = bool.fromEnvironment('SCREENSHOT_MODE');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    GaronDeniseApp(
      store: _screenshotMode
          ? MemoryOperationsStore.seeded()
          : SharedPreferencesOperationsStore(),
      screenshotMode: _screenshotMode,
    ),
  );
}
