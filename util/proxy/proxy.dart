import 'dart:io';

import 'package:dio/dio.dart' as dio;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': '*',
};

final port = 8080;
final address = InternetAddress.anyIPv4;

void main() async {
  final client = dio.Dio();
  HttpServer.bind(address, port).then((server) {
    server.listen((HttpRequest request) async {
      if (request.method == 'OPTIONS') {
        corsHeaders.forEach((key, value) {
          request.response.headers.add(key, value);
        });
        request.response.statusCode = HttpStatus.ok;
        request.response.close();
        return;
      }

      final url = request.uri.queryParameters['url'];
      if (url == null) {
        request.response.statusCode = HttpStatus.notFound;
        request.response.close();
        return;
      }
      final uri = Uri.parse(url);
      final outHeaders = Map<String, Object>();
      request.headers.forEach((key, value) {
        outHeaders[key] = value;
      });
      outHeaders[HttpHeaders.hostHeader] = uri.host;
      outHeaders[HttpHeaders.refererHeader] = uri.toString();

      dio.Response<dio.ResponseBody> res;
      try {
        res = await client.requestUri(uri,
            options: dio.Options(
              headers: outHeaders,
              responseType: dio.ResponseType.stream,
              method: request.method,
            ));
      } catch (e) {
        return;
      }
      final stream = res.data?.stream;
      if (stream == null) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.close();
        return;
      }
      res.headers.forEach((key, value) {
        if (key.toLowerCase() == 'content-encoding') return;
        request.response.headers.add(key, value);
      });
      corsHeaders.forEach((key, value) {
        request.response.headers.add(key, value);
      });
      await request.response.addStream(stream);
      request.response.close();
    });
  });

  print('Serving at http://${address.address}:$port');
}
