import 'user-agent-native.dart' if (dart.library.html) 'user-agent-web.dart'
    as ua;

class UserAgent {
  static String? userAgent;

  static Future<void> init() {
    return ua.getUserAgent();
  }
}
