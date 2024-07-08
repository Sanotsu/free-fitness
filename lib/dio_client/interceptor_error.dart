// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ErrorInterceptor extends Interceptor {
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    print('【onError】进入了dio的错误拦截器');

    print("err is :$err");

    print(
      """-----------------------
err 详情 
  message: ${err.message} 
  type: ${err.type} 
  error: ${err.error} 
  response: ${err.response}
  -----------------------""",
    );

    /// 根据DioError创建HttpException
    // HttpException httpException = HttpException.create(err);
// 2024-06-20 上面的create方法有问题，暂时不用
    HttpException httpException = HttpException(
      code: 1000,
      msg: err.error != null ? err.error.toString() : err.response.toString(),
    );

    /// dio默认的错误实例，如果是没有网络，只能得到一个未知错误，无法精准的得知是否是无网络的情况
    /// 这里对于断网的情况，给一个特殊的code和msg，其他可以识别处理的错误也可以订好
    if (err.type == DioExceptionType.unknown) {
      var connectivityResult = await (Connectivity().checkConnectivity());

      print("connectivityResult这里以前是返回一个，现在是列表里？？？$connectivityResult");

      if (connectivityResult.first == ConnectivityResult.none) {
        httpException = HttpException(code: -100, msg: 'None Network.');
      }
    }

    /// 2024-03-11 旧版本的写法是这样，但会报错，所以下面是新建了一个error
    // 将自定义的HttpException
    // err.error = httpException;
    // // 调用父类，回到dio框架
    // super.onError(err, handler);

    /// 创建一个新的DioException实例，并设置自定义的HttpException
    DioException newErr = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: httpException,
    );

    print("往上抛的newErr：$newErr");
    super.onError(newErr, handler);

    // 2024-03-11 新版本要这样写了吗？？？
    // handler.next(newErr);
  }
}

//
class HttpException implements Exception {
  final int code;
  final String msg;

  HttpException({
    this.code = -1,
    this.msg = 'unknow error',
  });

  @override
  String toString() {
    return 'Http Error [$code]: $msg';
  }

  factory HttpException.create(DioException error) {
    /// dio异常
    switch (error.type) {
      case DioExceptionType.cancel:
        {
          return HttpException(code: -1, msg: 'request cancel');
        }
      case DioExceptionType.connectionTimeout:
        {
          return HttpException(code: -1, msg: 'connect timeout');
        }
      case DioExceptionType.sendTimeout:
        {
          return HttpException(code: -1, msg: 'send timeout');
        }
      case DioExceptionType.receiveTimeout:
        {
          return HttpException(code: -1, msg: 'receive timeout');
        }
      case DioExceptionType.badResponse:
        {
          try {
            int statusCode = error.response?.statusCode ?? 0;
            // String errMsg = error.response.statusMessage;
            // return ErrorEntity(code: errCode, message: errMsg);
            switch (statusCode) {
              case 400:
                {
                  return HttpException(
                      code: statusCode, msg: 'Request syntax error');
                }
              case 401:
                {
                  return HttpException(
                      code: statusCode, msg: 'Without permission');
                }
              case 403:
                {
                  return HttpException(
                      code: statusCode, msg: 'Server rejects execution');
                }
              case 404:
                {
                  return HttpException(
                      code: statusCode, msg: 'Unable to connect to server');
                }
              case 405:
                {
                  return HttpException(
                      code: statusCode, msg: 'The request method is disabled');
                }
              case 500:
                {
                  return HttpException(
                      code: statusCode, msg: 'Server internal error');
                }
              case 502:
                {
                  return HttpException(
                      code: statusCode, msg: 'Invalid request');
                }
              case 503:
                {
                  return HttpException(
                      code: statusCode, msg: 'The server is down.');
                }
              case 505:
                {
                  return HttpException(
                      code: statusCode, msg: 'HTTP requests are not supported');
                }
              default:
                {
                  return HttpException(
                      code: statusCode,
                      msg: error.response?.statusMessage ?? 'unknow error');
                }
            }
          } on Exception catch (_) {
            return HttpException(code: -1, msg: 'unknow error');
          }
        }
      default:
        {
          return HttpException(code: -1, msg: error.message ?? 'unknow error');
        }
    }
  }
}

/// 简单的错误拦截示例
// class ErrorInterceptor extends QueuedInterceptor {
//   final Dio dio;

//   ErrorInterceptor(this.dio);

//   @override
//   Future<void> onError(
//       DioException err, ErrorInterceptorHandler handler) async {
//     print('onError is called');
//     try {
//       // This should throw an error
//       await dio.fetch(err.requestOptions);
//     } catch (e) {
//       // Why cannot I catch the error here?
//       print('onError is called again');
//     }
//     handler.next(err);
//   }
// }