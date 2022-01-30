import 'package:flutter/services.dart';

const platform = const MethodChannel('channel:reactor');

Future<String?> getUserAgent() {
  return platform.invokeMethod('getUserAgent');
}
