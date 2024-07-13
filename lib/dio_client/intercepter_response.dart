// ignore_for_file: avoid_print

import 'package:dio/dio.dart';

class ResponseIntercepter extends Interceptor {
  const ResponseIntercepter();

  @override
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    print('【onResponse】进入了dio的响应拦截器');

    // ??? 这里打印response和response.data是一样的

    // print("************************** ${response}");
    // print("************************** ${response.data}");

    // 判断返回数据中是否包含"token失效"的信息
    // if (response.data.contains("token失效")) {
    //   // 导航到登录页面
    //   navigatorKey.currentState!.pushReplacementNamed('/login');
    // }

    handler.next(response);
  }
}
