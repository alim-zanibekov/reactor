import 'package:reactor/core/common/platform.dart';

Future<String?> getUserAgent() {
  return AppPlatform.getUserAgent();
}
