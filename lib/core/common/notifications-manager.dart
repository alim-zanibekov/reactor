import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';

class NotificationsManager {
  static final NotificationsManager _notificationsManager =
      NotificationsManager._internal();

  factory NotificationsManager() {
    return _notificationsManager;
  }

  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final _initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('ic_splash'),
    iOS: IOSInitializationSettings(),
  );

  NotificationsManager._internal() {
    _flutterLocalNotificationsPlugin
        .initialize(_initializationSettings)
        .then((value) => print(value))
        .catchError((err) => print(err));
  }

  Future<void> push(int id, String title, String body, {int? progress}) async {
    final packageInfo = await PackageInfo.fromPlatform();
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          "reactor",
          packageInfo.packageName,
          channelDescription: "Reactor notifications",
          showProgress: progress != null,
          playSound: false,
          enableVibration: false,
          maxProgress: 100,
          progress: progress ?? 0,
        ),
        iOS: IOSNotificationDetails(
          presentSound: false,
          presentAlert: false,
        ),
      ),
    );
  }

  Future<void> cancel(int id) {
    return _flutterLocalNotificationsPlugin.cancel(id);
  }
}

class AppNotification {
  final _manager = NotificationsManager();
  static int _ids = 0;
  int _id;
  String _title;
  String _body;
  int? _progress;
  bool _showed = false;

  AppNotification(String title, String body)
      : _title = title,
        _body = body,
        _id = _ids++;

  show() async {
    await _manager.push(_id, _title, _body, progress: _progress);
    _showed = true;
  }

  hide() {
    return _manager.cancel(_id);
  }

  setProgress(int progress) {
    _progress = progress;
    if (_showed) {
      show();
    }
  }
}
