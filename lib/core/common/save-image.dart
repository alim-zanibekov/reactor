import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ext_storage/ext_storage.dart';
import 'package:permission_handler/permission_handler.dart';

class SaveImage {
  static Future<File> saveImage(String imageUrl, Uint8List data) async {
    if (!(await Permission.storage.isGranted)) {
      final status = await Permission.storage.request();
      if (status != PermissionStatus.granted) {
        throw 'denied';
      }
    }
    final path = await ExtStorage.getExternalStoragePublicDirectory(
        ExtStorage.DIRECTORY_DOWNLOADS);
    String fileName =
        Uri.decodeComponent(imageUrl?.split('/')?.last ?? 'reactor.file');
    return File('$path/$fileName').writeAsBytes(data);
  }
}
