import 'package:sentry/sentry.dart';

import '../../variables.dart';

final SentryClient _sentry = SentryClient(
  dsn:
      'https://20004fb264fd46598cc10667f873df42@o410122.ingest.sentry.io/5283781',
);

Future<void> reportError(dynamic error, dynamic stackTrace) async {
  print('Caught error: $error');
  if (isInDebugMode) {
    print(stackTrace);
  } else {
    _sentry.captureException(
      exception: error,
      stackTrace: stackTrace,
    );
  }
}
