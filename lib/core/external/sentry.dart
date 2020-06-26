import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:package_info/package_info.dart';
import 'package:sentry/sentry.dart';

class SentryReporter {
  static final SentryReporter _sentryReporter = SentryReporter.internal();
  static final DateTime _startTime = DateTime.now();

  factory SentryReporter() {
    return _sentryReporter;
  }

  SentryReporter.internal();

  final SentryClient _sentry = SentryClient(
    dsn:
        'https://20004fb264fd46598cc10667f873df42@o410122.ingest.sentry.io/5283781',
  );

  Map<String, dynamic> _extra;
  User _userContext;
  Contexts _contexts;

  Future init() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    String appHash;
    Device device;
    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
      _extra = <String, dynamic>{
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
      device = Device(
        brand: androidDeviceInfo.brand,
        model: androidDeviceInfo.model,
        modelId: androidDeviceInfo.device,
        simulator: !androidDeviceInfo.isPhysicalDevice,
      );
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      _extra = <String, dynamic>{
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
      device = Device(
        brand: 'Apple',
        model: iosDeviceInfo.model,
        simulator: !iosDeviceInfo.isPhysicalDevice,
      );
    }

    _contexts = Contexts(
      app: App(
        name: packageInfo.appName,
        version: packageInfo.version,
        build: packageInfo.buildNumber,
        identifier: packageInfo.packageName,
        deviceAppHash: appHash,
        startTime: _startTime,
        buildType: 'production',
      ),
      device: device,
    );
  }

  void setUserContext(String username) {
    _userContext = User(id: username.toLowerCase(), username: username);
  }

  void resetUserContext() {
    _userContext = null;
  }

  Future<void> capture(dynamic error, dynamic stackTrace) => _sentry.capture(
        event: Event(
          environment: 'production',
          exception: error,
          stackTrace: stackTrace,
          contexts: _contexts,
          userContext: _userContext,
          extra: _extra,
        ),
      );
}
