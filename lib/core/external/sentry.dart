import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry/sentry.dart';

class SentryReporter {
  static final SentryReporter _sentryReporter = SentryReporter._internal();
  static final DateTime _startTime = DateTime.now();
  static final SentryOptions _options = SentryOptions(
    dsn:
        'https://20004fb264fd46598cc10667f873df42@o410122.ingest.sentry.io/5283781',
  );

  factory SentryReporter() {
    return _sentryReporter;
  }

  SentryReporter._internal();

  final _sentry = SentryClient(_options);
  final _scope = Scope(_options);

  final deviceInfo = DeviceInfoPlugin();

  Future init() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    String? appHash;
    SentryDevice? device;
    Map<String, dynamic> extra = {};
    if (kIsWeb) {
      final WebBrowserInfo webBrowserInfo = await deviceInfo.webBrowserInfo;
      extra = <String, dynamic>{
        'userAgent': webBrowserInfo.userAgent,
        'deviceMemory': webBrowserInfo.deviceMemory,
        'platform': webBrowserInfo.platform,
        'vendor': webBrowserInfo.vendor,
        'vendorSub': webBrowserInfo.vendorSub,
        'appCodeName': webBrowserInfo.appCodeName,
        'appName': webBrowserInfo.appName,
        'appVersion': webBrowserInfo.appVersion,
        'language': webBrowserInfo.language,
        'languages': webBrowserInfo.languages,
        'product': webBrowserInfo.product,
        'productSub': webBrowserInfo.productSub
      };
      appHash = (webBrowserInfo.appName ?? '') +
          ':' +
          (webBrowserInfo.appVersion ?? '');
      device = SentryDevice(
        brand: webBrowserInfo.vendor,
        model: webBrowserInfo.vendor,
        modelId: webBrowserInfo.userAgent,
      );
    } else {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidDeviceInfo =
            await deviceInfo.androidInfo;
        extra = <String, dynamic>{
          'type': androidDeviceInfo.type,
          'model': androidDeviceInfo.model,
          'device': androidDeviceInfo.device,
          'id': androidDeviceInfo.id,
          'androidId': androidDeviceInfo.androidId,
          'brand': androidDeviceInfo.brand,
          'display': androidDeviceInfo.display,
          'hardware': androidDeviceInfo.hardware,
          'manufacturer': androidDeviceInfo.manufacturer,
          'product': androidDeviceInfo.product,
          'version': androidDeviceInfo.version.release,
          'supported32BitAbis': androidDeviceInfo.supported32BitAbis,
          'supported64BitAbis': androidDeviceInfo.supported64BitAbis,
          'supportedAbis': androidDeviceInfo.supportedAbis,
          'isPhysicalDevice': androidDeviceInfo.isPhysicalDevice,
        };
        appHash = androidDeviceInfo.androidId;
        device = SentryDevice(
          brand: androidDeviceInfo.brand,
          model: androidDeviceInfo.model,
          modelId: androidDeviceInfo.device,
          simulator: !(androidDeviceInfo.isPhysicalDevice ?? false),
        );
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
        extra = <String, dynamic>{
          'name': iosDeviceInfo.name,
          'model': iosDeviceInfo.model,
          'systemName': iosDeviceInfo.systemName,
          'systemVersion': iosDeviceInfo.systemVersion,
          'localizedModel': iosDeviceInfo.localizedModel,
          'utsname': iosDeviceInfo.utsname.sysname,
          'identifierForVendor': iosDeviceInfo.identifierForVendor,
          'isPhysicalDevice': iosDeviceInfo.isPhysicalDevice,
        };
        appHash = iosDeviceInfo.identifierForVendor;
        device = SentryDevice(
          brand: 'Apple',
          model: iosDeviceInfo.model,
          simulator: !iosDeviceInfo.isPhysicalDevice,
        );
      }
    }

    extra.forEach((key, value) {
      _scope.setExtra(key, value);
    });

    _scope.setContexts(
      SentryApp.type,
      SentryApp(
        name: packageInfo.appName,
        version: packageInfo.version,
        build: packageInfo.buildNumber,
        identifier: packageInfo.packageName,
        deviceAppHash: appHash,
        startTime: _startTime,
        buildType: 'production',
      ),
    );

    _scope.setContexts(SentryDevice.type, device);
  }

  void setUserContext(String username) {
    _scope.setUser(SentryUser(id: username.toLowerCase(), username: username));
  }

  void resetUserContext() {
    _scope.setUser(null);
  }

  Future<void> capture(dynamic error, dynamic stackTrace) =>
      _sentry.captureException(
        error,
        stackTrace: stackTrace,
        scope: _scope,
      );
}
