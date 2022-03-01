import 'package:flutter/services.dart';

class ApkInfo {
  final String version;
  final String buildNumber;

  ApkInfo(this.version, this.buildNumber);

  String get versionFull =>
      buildNumber == "1" ? version : "$version+$buildNumber";
}

class AppPlatform {
  static const _platform = const MethodChannel('channel:reactor');

  static Future<String?> getUserAgent() {
    return _platform.invokeMethod('getUserAgent');
  }

  static Future<void> installApk(String filePath) async {
    await _platform.invokeMethod('installApk', {'filePath': filePath});
  }

  static Future<ApkInfo?> getApkInfo(String filePath) async {
    final res = await _platform.invokeMethod<Map<dynamic, dynamic>>(
        'getApkInfo', {'filePath': filePath});
    if (res != null) {
      final version = res["versionName"];
      final buildNumber = res["versionCode"];
      if (version != null && buildNumber != null) {
        return ApkInfo(version, buildNumber);
      }
    }
    return null;
  }
}
