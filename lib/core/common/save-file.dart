import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

// import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../variables.dart';
import '../api/api.dart';
import 'notifications-manager.dart';

class SaveFile {
  static Future<File> save(String fileUrl, Uint8List data) async {
    if (!(await Permission.storage.isGranted)) {
      final status = await Permission.storage.request();
      if (status != PermissionStatus.granted) {
        throw 'denied';
      }
    }
    // final path = await ExtStorage.getExternalStoragePublicDirectory(
    //     ExtStorage.DIRECTORY_DOWNLOADS);
    final path = 'dsds';
    String fileName =
        Uri.decodeComponent(fileUrl?.split('/')?.last ?? 'reactor.file');

    return File('$path/$fileName').writeAsBytes(data);
  }

  static downloadAndSave(BuildContext context, String url) async {
    try {
      final notification = AppNotification('Загрузка', url);
      notification.show();
      final file = await Api().downloadFile(url, headers: Headers.videoHeaders,
          onReceiveProgress: (int count, int total) {
        double percent = count.toDouble() / total.toDouble() * 100;
        notification.setProgress(percent.floor());
      });
      notification.hide();
      SaveFile.save(url, file);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сохранено')),
      );
    } on Exception {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось загрузить')),
      );
    }
  }
}
