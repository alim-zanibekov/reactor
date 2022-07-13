import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:reactor/core/common/user-agent/user-agent.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../external/sentry.dart';
import '../http/dio-instance.dart';
import '../http/session.dart';
import 'types.dart';

class Auth {
  static final Auth _auth = Auth._internal();
  static final Session _session = Session();
  static final SentryReporter _sentryReporter = SentryReporter();
  static final _authState = StreamController<bool>.broadcast();

  factory Auth() {
    return _auth;
  }

  Auth._internal();

  final _dio = getDioInstance();

  String? _token;
  String? _username;
  bool _authorized = false;

  bool get authorized => _authorized;

  String? get username => _username;

  Stream<bool> get authorized$ {
    return _authState.stream;
  }

  Future init() {
    return SharedPreferences.getInstance().then((prefs) {
      if (prefs.getBool('auth') ?? false) {
        final token = prefs.getString('auth-token');
        final username = prefs.getString('username');
        if (token != null && username != null) {
          _token = token;
          _username = username;
          _sentryReporter.setUserContext(username);
          _session.setToken(token);
          _authorized = true;
        }
      }
    });
  }

  String? _parseSessionCookie(Response res) {
    final setCookieHeader = res.headers[HttpHeaders.setCookieHeader];
    if (setCookieHeader != null && setCookieHeader.isNotEmpty) {
      for (final value in setCookieHeader) {
        if (value.startsWith('joyreactor_sess3=')) {
          return value.replaceFirst('joyreactor_sess3=', '').split(';').first;
        }
      }
    }
    return null;
  }

  void updateTokenIfNeed(Response res) {
    if (authorized) {
      final token = _parseSessionCookie(res);
      if (token != null && token != _token) {
        _token = token;
        _session.setToken(token);
        SharedPreferences.getInstance()
            .then((prefs) => prefs.setString('auth-token', token));
      }
    }
  }

  Future login(String username, String password) async {
    try {
      final init = await _dio.get(
        'https://joyreactor.cc/login',
        options: Options(headers: {
          HttpHeaders.pragmaHeader: 'no-cache',
          'User-Agent': UserAgent.userAgent,
          'Referer': 'https://joyreactor.cc',
        }),
      );
      var sessionToken = _parseSessionCookie(init);
      if (sessionToken == null) {
        throw InvalidUsernameOrPasswordException();
      }

      final pre = await _dio.post(
        'https://api.joyreactor.cc/graphql',
        options: Options(headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.pragmaHeader: 'no-cache',
          'Origin': 'https://joyreactor.cc',
          'User-Agent': UserAgent.userAgent,
          'Referer': 'https://joyreactor.cc/login',
        }),
        data: jsonEncode({
          'query': 'mutation Login(\$login: String!, \$pass: String!) '
              '{login(password: \$pass, name: \$login) { me { token } }}',
          'variables': {
            'login': username,
            'pass': password,
          },
        }),
      );

      if (!(pre.data as Map).containsKey('data')) {
        if (!(pre.data as Map).containsKey('errors')) {
          final category = pre.data['errors'][0]['extensions']['category'];
          if (category == 'rate-limit') {
            throw RateLimitException();
          }
        }
        throw InvalidUsernameOrPasswordException();
      }

      final jwt = pre.data['data']['login']['me']['token'];

      final res = await _dio.get(
        'https://joyreactor.cc/login',
        options: Options(
          validateStatus: (status) => (status ?? 500) < 400,
          headers: {
            HttpHeaders.pragmaHeader: 'no-cache',
            HttpHeaders.connectionHeader: 'keep-alive',
            'User-Agent': UserAgent.userAgent,
            'Cookie': 'joyreactor_sess3=$sessionToken; jr_jwt=$jwt',
            'Referer': 'https://joyreactor.cc/login',
          },
          followRedirects: false,
          maxRedirects: 0,
        ),
      );

      if (res.statusCode != 302) {
        throw InvalidStatusCodeException();
      }

      final token = _parseSessionCookie(res);
      if (token == null) {
        throw InvalidStatusCodeException();
      }

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('auth-token', token);
      prefs.setString('username', username);
      prefs.setBool('auth', true);

      _token = token;
      _authorized = true;
      _session.setToken(token);
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
