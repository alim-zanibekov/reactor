import '../platform.dart';

Future<String?> getUserAgent() {
  return AppPlatform.getUserAgent();
}
