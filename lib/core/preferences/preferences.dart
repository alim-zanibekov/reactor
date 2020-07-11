import 'package:shared_preferences/shared_preferences.dart';

import '../http/session.dart';

enum AppTheme { AUTO, DARK, LIGHT }
enum AppPostsType { NEW, GOOD, BEST, ALL }

class Preferences {
  static final Preferences _preferences = Preferences._internal();
  static final Session _session = Session();

  factory Preferences() {
    return _preferences;
  }

  AppTheme _theme;
  AppPostsType _postsType;
  bool _sfw;
  bool _sendErrorStatistics;

  Preferences._internal();

  Future init() => SharedPreferences.getInstance().then((prefs) {
        final theme = prefs.getInt('theme') ?? 0;
        _theme = AppTheme.values[theme];
        final openDefault = prefs.getInt('open-default') ?? 0;
        _postsType = AppPostsType.values[openDefault];
        final sfw = prefs.getBool('sfw') ?? false;
        _sfw = sfw;
        final sendErrorStatistics =
            prefs.getBool('send-error-statistics') ?? true;
        _sendErrorStatistics = sendErrorStatistics;

        _session.setSFW(_sfw);
      });

  AppPostsType get postsType => _postsType;

  AppTheme get theme => _theme;

  bool get sfw => _sfw;

  bool get sendErrorStatistics => _sendErrorStatistics;

  setTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('theme', AppTheme.values.indexOf(theme));
    _theme = theme;
  }

  setDefaultPostType(AppPostsType postsType) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('open-default', AppPostsType.values.indexOf(postsType));
    _postsType = postsType;
  }

  setSFW(bool state) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('sfw', state);
    _sfw = state;
    _session.setSFW(state);
  }

  setSendErrorStatistics(bool state) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('send-error-statistics', state);
    _sendErrorStatistics = state;
  }
}
