import 'user-agent-native.dart' if (dart.library.html) 'user-agent-web.dart'
    as ua;

class UserAgent {
  static String? _userAgent;

  static String? get userAgent => _userAgent;

  static Future<void> init() async {
    _userAgent = await ua.getUserAgent();
  }
}
