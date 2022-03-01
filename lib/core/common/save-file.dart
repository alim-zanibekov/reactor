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
  static Future<File> _saveToDir(String filePath, Uint8List data, { bool checkPermissions = false }) async {
    if (checkPermissions && !(await Permission.storage.isGranted)) {
      final status = await Permission.storage.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Access denied');
      }
    }

    return File(filePath).writeAsBytes(data);
  }

  static Future<File> _saveToDownloads(String fileUrl, Uint8List data) async {
    var path = '/';
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        path = '/sdcard/Download/';
      } else {
        path = (await getApplicationDocumentsDirectory()).path;
      }
    }

    String fileName = Uri.decodeComponent(fileUrl.split('/').last);

    return _saveToDir('$path/$fileName', data);
  }

  static Future<bool> save(
      BuildContext context, String fileUrl, Uint8List data) async {
    try {
      await SaveFile._saveToDownloads(fileUrl, data);
      SnackBarHelper.show(context,
          Platform.isAndroid ? 'Сохранено в папку Загрузки' : 'Сохранено');
      return true;
    } on Exception {
      SnackBarHelper.show(context, 'Не удалось загрузить');
      return false;
    }
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
      if (file == null) {
        throw Exception("File invalid");
      }
      await SaveFile._saveToDownloads(url, file);
      SnackBarHelper.show(context,
          Platform.isAndroid ? 'Сохранено в папку Загрузки' : 'Сохранено');
    } on Exception {
      SnackBarHelper.show(context, 'Не удалось загрузить');
    }
  }

  static Future<File> downloadAndSaveExternal(
    String url,
    String filePath,
  ) async {
    final notification = AppNotification('Загрузка', url);
    notification.show();
    final file = await Api().downloadFile(url, headers: Headers.videoHeaders,
        onReceiveProgress: (int count, int total) {
      double percent = count.toDouble() / total.toDouble() * 100;
      notification.setProgress(percent.floor());
    });
    notification.hide();
    if (file == null) {
      throw Exception("File invalid");
    }

    return _saveToDir(filePath, file, checkPermissions: false);
  }
}
