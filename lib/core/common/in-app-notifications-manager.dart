import 'dart:async';

class InAppNotificationsManager {
  static final _messages = StreamController<String>.broadcast();

  static get messages$ {
    return _messages.stream;
  }

  static show(String text) {
    _messages.add(text);
  }
}
