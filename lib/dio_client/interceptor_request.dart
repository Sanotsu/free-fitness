// ignore_for_file: avoid_print

import 'package:dio/dio.dart';

class RequestInterceptor extends Interceptor {
  const RequestInterceptor();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    print('【onRequest】进入了dio的请求拦截器');

    // 2024-03-11 请求要带 authorization 自定义头
    // 登录的时候要存入缓存，所以请求时要从缓存中拿，如果缓存中没有，采用登录预设的字符串

    // options.headers['Authorization'] = 'Basic cGhvbmU6cGhvbmU=';

    return handler.next(options);
  }
}
