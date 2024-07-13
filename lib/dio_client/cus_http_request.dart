// ignore_for_file: avoid_print

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

//辅助配置
import 'cus_http_options.dart';
import 'intercepter_response.dart';
import 'interceptor_error.dart';
import 'interceptor_request.dart';

class HttpRequest {
  // 单例模式使用Http类，
  static final HttpRequest _instance = HttpRequest._internal();

  factory HttpRequest() => _instance;

  static late final Dio dio;

  /// 内部构造方法
  HttpRequest._internal() {
    // print("*******初始化时候的url:$url");

    /// 初始化dio
    BaseOptions options = BaseOptions(
      connectTimeout: HttpOptions.connectTimeout,
      receiveTimeout: HttpOptions.receiveTimeout,
      sendTimeout: HttpOptions.sendTimeout,
      baseUrl: HttpOptions.baseUrl,
      contentType: HttpOptions.contentType,
      // 2024-03-12 目前需要用的接口就 login成功的返回时text/html,其他的都是application/json。
      // 所以暂时就不全部拍成文本格式了
      // responseType: ResponseType.plain,
    );

    dio = Dio(options);

    // 2024-03-11 因为测试，自签名证书一律放过
    // 参考文档：https://github.com/cfug/dio/blob/main/dio/README-ZH.md#https-%E8%AF%81%E4%B9%A6%E6%A0%A1%E9%AA%8C
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (
          X509Certificate cert,
          String host,
          int port,
        ) {
          return true;
        };
        return client;
      },
    );

    /// 添加各种拦截器
    // 2024-03-11 新的添加多个
    // Add the custom interceptor
    dio.interceptors.addAll([
      const RequestInterceptor(),
      const ResponseIntercepter(),
      ErrorInterceptor(),
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        // responseBody: false, // 响应太多了，不显示
        maxWidth: 150,
      ),
    ]);
  }

  /// 封装request方法
  Future request({
    required String path, //接口地址
    required HttpMethod method, //请求方式
    Map<String, dynamic>? headers, // 可以自定义一些header
    dynamic data, //数据
    Map<String, dynamic>? queryParameters,
    bool showLoading = true, //加载过程
    bool showErrorMessage = true, //返回数据
  }) async {
    const Map methodValues = {
      HttpMethod.get: 'get',
      HttpMethod.post: 'post',
      HttpMethod.put: 'put',
      HttpMethod.delete: 'delete',
      HttpMethod.patch: 'patch',
      HttpMethod.head: 'head'
    };

    //动态添加header头
    // Map<String, dynamic> headers = <String, dynamic>{};
    // headers["version"] = "1.0.0";

    Options options = Options(
      method: methodValues[method],
      headers: headers,
    );

    try {
      if (showLoading) {
        //EasyLoading.show(status: 'loading...');
      }
      Response response = await HttpRequest.dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      return response.data;
    } on DioException catch (error) {
      // 2024-03-11 这里是要取得http的错误，但默认类型时Object?，所以要转一下
      // HttpException httpException = error.error;
      HttpException httpException = error.error as HttpException;

      print("这里是执行HttpRequest的request()方法在报错:");
      print(httpException);
      print(httpException.code);
      print(httpException.msg);
      print(showErrorMessage);
      print("========================");

      // print("code:${httpException.code}");
      // print("msg:${httpException.msg}");
      if (showErrorMessage) {
        EasyLoading.showToast(httpException.msg);
      }

      // 2024-06-20 这里还是要把错误抛出去，在请求的API处方便trycatch拦截处理
      // 否则接口处就只看到一个null了
      throw httpException;
    } finally {
      if (showLoading) {
        EasyLoading.dismiss();
      }
    }
  }
}

enum HttpMethod {
  get,
  post,
  delete,
  put,
  patch,
  head,
}
