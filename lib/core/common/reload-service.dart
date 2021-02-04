import 'dart:async';

class ReloadService {
  static final _messages = StreamController<bool>.broadcast();

  static StreamController<bool> get onReload$ {
    return _messages;
  }

  static reload() {
    _messages.add(true);
  }
}
