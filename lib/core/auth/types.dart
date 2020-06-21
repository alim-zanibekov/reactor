class UnauthorizedException implements Exception {
  String cause;

  UnauthorizedException(this.cause);
}
