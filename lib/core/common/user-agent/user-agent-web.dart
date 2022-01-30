import 'package:device_info_plus/device_info_plus.dart';

Future<String?> getUserAgent() async {
  final info = await DeviceInfoPlugin().webBrowserInfo;
  return info.userAgent;
}
