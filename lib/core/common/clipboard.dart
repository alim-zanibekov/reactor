import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'snack-bar.dart';

class ClipboardHelper {
  static void setClipboardData(BuildContext context, String? data) {
    Clipboard.setData(ClipboardData(text: data)).then((value) {
      SnackBarHelper.show(context, 'Скопировано');
    }).catchError((_) {
      SnackBarHelper.show(context, 'Не удалось скопировать');
    });
  }
}
