import 'package:flutter/foundation.dart';

import 'count-formatter.dart';

class DateTimeFormatter {
  final DateTime dateTime;
  final String _ago = 'назад';
  static final _formatSeconds =
      CountFormatter(one: 'сукунду', two: 'секунды', few: 'секунд');
  static final _formatMinutes =
      CountFormatter(one: 'минуту', two: 'минуты', few: 'минут');
  static final _formatHours =
      CountFormatter(one: 'час', two: 'часа', few: 'часов');
  static final _formatDays =
      CountFormatter(one: 'день', two: 'дня', few: 'дней');

  DateTimeFormatter({@required this.dateTime});

  String withHourPrecision() {
    final now = DateTime.now();
    final duration = now.difference(dateTime);
    int diff = duration.inSeconds;
    if (diff < 60) {
      return '$diff ${_formatSeconds.format(diff)} $_ago';
    }
    diff = duration.inMinutes;
    if (diff < 60) {
      return '$diff ${_formatMinutes.format(diff)} $_ago';
    }
    diff = duration.inHours;
    if (diff < 24) {
      return '$diff ${_formatHours.format(diff)} $_ago';
    }
    diff = duration.inDays;
    return '$diff ${_formatDays.format(diff)} $_ago в ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
