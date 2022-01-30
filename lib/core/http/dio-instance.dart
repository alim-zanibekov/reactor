import 'package:dio/dio.dart';

final interceptor = InterceptorsWrapper(onRequest: (options, handler) {
  // options.path =
  //     'http://localhost:8080?url=${Uri.encodeComponent(options.uri.toString())}';
  return handler.next(options);
});

Dio getDioInstance() {
  final client = Dio();
  client.interceptors.add(interceptor);
  return client;
}
