// ignore_for_file: avoid_print

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../utils/toast_utils.dart';
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
    );

    dio = Dio(options);

    // 2024-03-11 因为测试，自签名证书一律放过
    // 参考文档：https://github.com/cfug/dio/blob/main/dio/README-ZH.md#https-%E8%AF%81%E4%B9%A6%E6%A0%A1%E9%AA%8C
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) {
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
        error: true,
        compact: true,
        maxWidth: 380,
        enabled: kDebugMode,
        requestHeader: true,
        responseHeader: true,
        requestBody: true,
        responseBody: true,
        // requestBody: false,
        // responseBody: false,
        // filter: (options, args) {
        //   // don't print requests with uris containing '/posts'
        //   if (options.path.contains('/posts')) {
        //     return false;
        //   }
        //   // don't print responses with unit8 list data
        //   return !args.isResponse || !args.hasUint8ListData;
        // },
      ),
    ]);
  }

  /// 封装request方法
  Future request({
    required String path, // 接口地址
    // 都是属于Options的属性
    required CusHttpMethod method, // 请求方式
    Map<String, dynamic>? headers, // 可以自定义一些header
    CusRespType? responseType, // 可以自定义返回类型(默认是json)
    CancelToken? cancelToken,
    dynamic data, // 数据
    Map<String, dynamic>? queryParameters,
    bool showLoading = true, // 加载过程
    bool showErrorMessage = true, // 显示错误信息
    // 2025-04-16
    String? contentType,
  }) async {
    //动态添加header头
    // Map<String, dynamic> headers = <String, dynamic>{};
    // headers["version"] = "1.0.0";

    Options options = Options(
      method: methodValues[method],
      headers: headers,
      responseType: responseTypeValues[responseType],
      contentType: contentType,
    );

    // 如果响应类型不是stream，则设置超时时间为10分钟
    if (responseTypeValues[responseType] != ResponseType.stream) {
      options.receiveTimeout = Duration(seconds: 10 * 60);
    }

    dynamic closeToast;
    try {
      if (showLoading) {
        closeToast = ToastUtils.showLoading('【等待响应中...】');
      }
      Response response = await HttpRequest.dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return response.data;
    } on DioException catch (error) {
      // 2024-03-11 这里是要取得http的错误，但默认类型时Object?，所以要转一下
      CusHttpException cusHttpException = error.error as CusHttpException;

      print("这里是执行HttpRequest的request()方法在报错:");
      print(cusHttpException);
      print(cusHttpException.cusCode);
      print(cusHttpException.cusMsg);
      print(showErrorMessage);
      print("========================");

      if (showErrorMessage) {
        ToastUtils.showToast(cusHttpException.cusMsg);
      }

      // 2024-06-20 这里还是要把错误抛出去，在请求的API处方便trycatch拦截处理
      // 否则接口处就只看到一个null了
      throw cusHttpException;
    } finally {
      if (showLoading && closeToast != null) {
        closeToast();
      }
    }
  }
}

// 自定义的请求方法和响应类型，方便调用时使用
enum CusHttpMethod { get, post, delete, put, patch, head }

const Map methodValues = {
  CusHttpMethod.get: 'get',
  CusHttpMethod.post: 'post',
  CusHttpMethod.put: 'put',
  CusHttpMethod.delete: 'delete',
  CusHttpMethod.patch: 'patch',
  CusHttpMethod.head: 'head',
};

enum CusRespType { bytes, json, plain, stream }

const Map responseTypeValues = {
  CusRespType.bytes: ResponseType.bytes,
  CusRespType.json: ResponseType.json,
  CusRespType.plain: ResponseType.plain,
  CusRespType.stream: ResponseType.stream,
};
