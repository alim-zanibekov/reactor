import 'dart:io';

class Headers {
  static final reactorHeaders = {
    HttpHeaders.userAgentHeader: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_'
        '7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.83 Safari/537.36',
    HttpHeaders.acceptHeader: '*/*',
    HttpHeaders.refererHeader: 'http://joyreactor.cc/',
  };

  static final videoHeaders = {
    HttpHeaders.pragmaHeader: 'no-cache',
    HttpHeaders.cacheControlHeader: 'no-cache',
    HttpHeaders.cookieHeader: 'showVideoGif3=1',
    HttpHeaders.acceptEncodingHeader: 'identity;q=1, *;q=0',
    HttpHeaders.userAgentHeader: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_'
        '7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.83 Safari/537.36',
    HttpHeaders.acceptHeader: '*/*',
    HttpHeaders.refererHeader: 'http://joyreactor.cc/'
  };

  static updateUserAgent(String userAgent) {
    videoHeaders[HttpHeaders.userAgentHeader] = userAgent;
    reactorHeaders[HttpHeaders.userAgentHeader] = userAgent;
  }
}

bool get isInDebugMode {
  bool inDebugMode = false;
  assert(inDebugMode = true);
  return inDebugMode;
}
