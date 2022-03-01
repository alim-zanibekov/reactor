import 'dart:convert';

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

  late AppTheme _theme;
  late AppPostsType _postsType;
  late bool _sfw;
  late bool _sendErrorStatistics;
  late bool _gifAutoPlay;
  late List<String> _hostList;
  late String _host;
  String? _lastAlertVersion;

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

        final gifAutoPlay = prefs.getBool('gif-auto-play') ?? false;
        _gifAutoPlay = gifAutoPlay;

        final hostListRaw = prefs.getString('host-list');
        final hostList = hostListRaw != null
            ? jsonDecode(hostListRaw)
                .map<String>((str) => str as String)
                .toList()
            : ['joyreactor.cc', 'old.reactor.cc', 'reactor.cc'];
        _hostList = hostList;

        final host = prefs.getString('host') ?? _hostList[0];
        _host = host;

        _lastAlertVersion = prefs.getString('last-alert-version');

        _session.setSFW(_sfw);
      });

  AppPostsType get postsType => _postsType;

  AppTheme get theme => _theme;

  bool get sfw => _sfw;

  bool get sendErrorStatistics => _sendErrorStatistics;

  bool get gifAutoPlay => _gifAutoPlay;

  String get host => _host;

  String? get lastAlertVersion => _lastAlertVersion;

  List<String> get hostList => _hostList;

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

  setGifAutoPlay(bool state) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('gif-auto-play', state);
    _gifAutoPlay = state;
  }

  setHost(String host) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('host', host);
    _host = host;
  }

  setHostList(List<String> hostList) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('host-list', jsonEncode(hostList));
    _hostList = hostList;
  }

  setLastAlertVersion(String? version) async {
    final prefs = await SharedPreferences.getInstance();
    if (version != null) {
      prefs.setString('last-alert-version', version);
    } else {
      prefs.remove('last-alert-version');
    }
    _lastAlertVersion = version;
  }
}
