import 'dart:io';

import 'package:dio/dio.dart';

class Session {
  static final Session _session = Session._internal();

  factory Session() {
    return _session;
  }

  String _apiToken = '';

  get apiToken => _apiToken;

  String _authToken;
  bool _sfw = false;

  Dio _dio;
  Map<String, dynamic> _headers;

  void setToken(String token) {
    _authToken = token;
    _generateCookie();
  }

  void setSFW(bool state) {
    _sfw = state;
    _generateCookie();
  }

  void removeToken() {
    _authToken = null;
    _generateCookie();
  }

  void _generateCookie() {
    var cookie = '';

    if (_authToken != null) {
      cookie = 'joyreactor_sess3=$_authToken';
    }

    if (_sfw) {
      cookie += (_authToken != null ? ';' : '') + 'sfw=1';
    }
    if (cookie.length > 0) {
      _headers = {HttpHeaders.cookieHeader: cookie};
    } else {
      _headers = null;
    }
  }

  Session._internal() {
    _dio = Dio();
  }

  Future<Response> get(String url) async {
    final res = await _dio.get(url, options: Options(headers: _headers));
    if (url.contains('reactor.cc') &&
        res.data is String &&
        _authToken != null) {
      final pattern = 'var token = \'';
      final data = res.data.toString();
      final index = data.indexOf(pattern);
      if (index != -1) {
        final endIndex = data.indexOf('\'', index + pattern.length + 1);
        if (endIndex != -1) {
          _apiToken = data.substring(index + pattern.length, endIndex);
        }
      }
    }
    return res;
  }

  Future<Response> post(String url, dynamic data,
      {ProgressCallback onSendProgress}) async {
    return _dio.post(
      url,
      data: data,
      onSendProgress: onSendProgress,
      options: Options(
        followRedirects: false,
        validateStatus: (status) {
          return status < 400;
        },
        headers: _headers,
      ),
    );
  }
}
