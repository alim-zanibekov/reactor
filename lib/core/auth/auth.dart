import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as parser;
import 'package:shared_preferences/shared_preferences.dart';

import '../common/pair.dart';
import '../external/sentry.dart';
import '../http/session.dart';
import 'types.dart';

StreamController<bool> _authState = StreamController<bool>.broadcast();

class Auth {
  static final Auth _auth = Auth._internal();
  static final Session _session = Session();
  static final SentryReporter _sentryReporter = SentryReporter();

  factory Auth() {
    return _auth;
  }

  Auth._internal();

  String _token;
  String _username;
  bool _authorized = false;

  bool get authorized => _authorized;

  String get username => _username;

  Future init() {
    return SharedPreferences.getInstance().then((prefs) {
      if (prefs.getBool('auth') ?? false) {
        _token = prefs.getString('auth-token');
        _username = prefs.getString('username');
        _sentryReporter.setUserContext(_username);
        _session.setToken(_token);
        _authorized = true;
      }
    });
  }

  Stream<bool> get authorized$ {
    return _authState.stream;
  }

  Future<Pair<String, String>> _getCSRFAndToken() async {
    final res = await _session.get('http://joyreactor.cc/login');
    final document = parser.parse(res.data);
    final token =
        document.querySelector('#signin__csrf_token')?.attributes['value'];
    return Pair(token, _getTokenHeader(res));
  }

  String _getTokenHeader(Response res) {
    final setCookieHeader = res.headers[HttpHeaders.setCookieHeader];
    if (setCookieHeader == null ||
        setCookieHeader.isEmpty ||
        setCookieHeader[0].indexOf('joyreactor_sess3') == -1) {
      throw UnauthorizedException('Invalid Username or Password');
    } else {
      return setCookieHeader[0]
          .replaceFirst('joyreactor_sess3=', '')
          .split(';')
          .first;
    }
  }

  Future login(String username, String password) async {
    try {
      final csrfAndToken = await _getCSRFAndToken();
      final formData = FormData.fromMap({
        'signin[username]': username,
        'signin[password]': password,
        'signin[_csrf_token]': csrfAndToken.left
      });
      final sessionToken = csrfAndToken.right;
      _session.setToken(sessionToken);
      final res = await _session.post('http://joyreactor.cc/login', formData);

      if (res.statusCode != 302) {
        throw UnauthorizedException('Invalid Username or Password');
      }

      final token = _getTokenHeader(res);

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('auth-token', token);
      prefs.setString('username', username);
      prefs.setBool('auth', true);

      _token = token;
      _authorized = true;
      _session.setToken(_token);
      _username = username;
      _authState.add(authorized);

      _sentryReporter.setUserContext(username);
    } on Exception {
      _logout();
      rethrow;
    }
  }

  Future _logout() async {
    _token = null;
    _authorized = false;
    _username = null;
    _session.removeToken();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('auth', false);
    prefs.remove('auth-token');
    prefs.remove('username');

    _sentryReporter.resetUserContext();
  }

  Future logout() async {
    _logout();
    _authState.add(false);
  }
}
