import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../variables.dart';
import '../api/api.dart';
import 'notifications-manager.dart';
import 'snack-bar.dart';

class SaveFile {
  static Future<File> save(String fileUrl, Uint8List data) async {
    if (!(await Permission.storage.isGranted)) {
      final status = await Permission.storage.request();
      if (status != PermissionStatus.granted) {
        throw 'denied';
      }
    }
    String path;
    if (kIsWeb) {
      path = '/';
    } else {
      if (Platform.isAndroid) {
        path = '/sdcard/Download/';
      } else {
        path = (await getApplicationDocumentsDirectory()).path;
      }
    }

    String fileName = Uri.decodeComponent(fileUrl.split('/').last);

    return File('$path/$fileName').writeAsBytes(data);
  }

  static downloadAndSave(BuildContext context, String url) async {
    try {
      final notification = AppNotification('Загрузка', url);
      notification.show();
      final file = await (Api().downloadFile(url, headers: Headers.videoHeaders,
          onReceiveProgress: (int count, int total) {
        double percent = count.toDouble() / total.toDouble() * 100;
        notification.setProgress(percent.floor());
      }) as FutureOr<Uint8List>);
      notification.hide();
      SaveFile.save(url, file);
      SnackBarHelper.show(context, 'Сохранено');
    } on Exception {
      SnackBarHelper.show(context, 'Не удалось загрузить');
    }
  }
}
