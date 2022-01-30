import 'package:flutter/widgets.dart';

class ReloadNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}
