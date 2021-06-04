class InvalidUsernameOrPasswordException implements Exception {
  String cause = 'Invalid username or password';

  InvalidUsernameOrPasswordException();
}

class InvalidStatusCodeException implements Exception {
  String cause = 'Invalid status code';

  InvalidStatusCodeException();
}

class RateLimitException implements Exception {
  String cause = 'Rate limit exceed';

  RateLimitException();
}
