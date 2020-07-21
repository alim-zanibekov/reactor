import '../../variables.dart';
import '../preferences/preferences.dart';
import 'sentry.dart';

class ErrorReporter {
  static final Preferences _preferences = Preferences();
  static final SentryReporter _sentryReporter = SentryReporter();

  static Future<void> reportError(dynamic error, dynamic stackTrace) async {
    print('Caught error: $error');
    if (isInDebugMode || !_preferences.sendErrorStatistics) {
      print(stackTrace);
    } else {
      await _sentryReporter.capture(error, stackTrace);
    }
  }
}
