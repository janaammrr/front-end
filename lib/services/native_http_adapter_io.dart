import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

const _railwayBackendHost = 'flame-app-backend-production.up.railway.app';

void configureNativeHttpAdapter(Dio dio) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      return HttpClient()
        ..badCertificateCallback = (certificate, host, port) {
          return host == _railwayBackendHost;
        };
    },
  );
}
