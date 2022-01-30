import 'package:flutter/material.dart';

class SnackBarHelper {
  static void show(BuildContext context, String text) {
    final snackBar = SnackBar(content: Text(text));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
