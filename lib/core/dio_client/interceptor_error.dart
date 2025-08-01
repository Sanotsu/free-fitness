// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 简单的错误拦截示例
class ErrorInterceptor extends Interceptor {
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    print('【onError】进入了dio的错误拦截器');

    print("err is :$err");

    print("""-----------------------
err 详情 
  【message】: ${err.message} 
  【type】: ${err.type} 
  【error】: ${err.error} 
  【response】: ${err.response}
  【response.statusCode】: ${(err.response?.statusCode)}
  【response.statusMessage】: ${(err.response?.statusMessage)}
  -----------------------""");

    /// 根据DioError创建 CusHttpException
    CusHttpException cusHttpException = CusHttpException.create(err);

    /// dio默认的错误实例，如果是没有网络，只能得到一个未知错误，无法精准的得知是否是无网络的情况
    /// 这里对于断网的情况，给一个特殊的code和msg，其他可以识别处理的错误也可以定好
    if (err.type == DioExceptionType.unknown) {
      var connectivityResult = await (Connectivity().checkConnectivity());

      if (connectivityResult.first == ConnectivityResult.none) {
        cusHttpException = CusHttpException(cusCode: -100, cusMsg: '【无网络】');
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
      error: cusHttpException,
    );

    print("往上抛的newErr：$newErr");
    super.onError(newErr, handler);

    // 2024-03-11 新版本要这样写了吗？？？
    // handler.next(newErr);
  }
}

/// 自定义的错误类
class CusHttpException implements Exception {
  final int cusCode;
  final String cusMsg;
  final String errMessage;
  final String errRespString;

  static const String defaultCusMsg = '【未知自定义错误】';
  static const String defaultRespString = '【未知响应字符串】';
  static const String defaultMessage = '【未知错误信息】';

  CusHttpException({
    this.cusCode = -1,
    this.cusMsg = defaultCusMsg,
    this.errMessage = defaultMessage,
    this.errRespString = defaultRespString,
  });

  Map<String, dynamic> toJson() {
    return {
      'cusCode': cusCode,
      'cusMsg': cusMsg,
      'errMessage': errMessage,
      'errRespString': errRespString,
      // 方便大模型响应体转型
      'code': cusCode.toString(),
      'messgae': errRespString,
    };
  }

  @override
  String toString() {
    return '''Cus Http Error: 
    [$cusCode]:$cusMsg 
    $errMessage
    $errRespString
    ''';
  }

  factory CusHttpException.create(DioException error) {
    String response = error.response?.toString() ?? error.error.toString();
    String message = error.message ?? defaultMessage;

    // print("error.response?.toString()--$response");
    // print("error.message?.toString()--$message");

    /// 自定义处理 dio 异常
    switch (error.type) {
      case DioExceptionType.badCertificate:
        return _createError(-1, '证书异常', message, response);
      case DioExceptionType.cancel:
        return _createError(-2, '请求被取消', message, response);
      case DioExceptionType.connectionError:
        return _createError(-3, '连接错误', message, response);
      case DioExceptionType.connectionTimeout:
        return _createError(-4, '连接超时', message, response);
      case DioExceptionType.sendTimeout:
        return _createError(-5, '发送超时', message, response);
      case DioExceptionType.receiveTimeout:
        return _createError(-6, '接收超时', message, response);
      case DioExceptionType.badResponse:
        // 针对错误响应再单独区分
        return _handleBadResponse(error);
      default:
        return _createError(-999, error.message ?? '未知错误', message, response);
    }
  }

  // 构建自定义错误实例
  static CusHttpException _createError(
    int cusCode,
    String cusMsg,
    String errMessage,
    String errRespString,
  ) {
    return CusHttpException(
      cusCode: cusCode,
      cusMsg: cusMsg,
      errMessage: errMessage,
      errRespString: errRespString,
    );
  }

  static CusHttpException _handleBadResponse(DioException error) {
    int? statusCode = error.response?.statusCode;
    String statusMsg = error.response?.statusMessage ?? '未知错误';
    String respStr = error.response?.toString() ?? error.error.toString();

    switch (statusCode) {
      case 400:
        return _createError(400, '请求语法错误', statusMsg, respStr);
      case 401:
        return _createError(401, '请求权限异常(可尝试检查密钥)', statusMsg, respStr);
      case 403:
        return _createError(403, '后台拒绝执行', statusMsg, respStr);
      case 404:
        return _createError(404, '无法连接到服务器', statusMsg, respStr);
      case 405:
        return _createError(405, '请求方法被禁用', statusMsg, respStr);
      case 500:
        return _createError(500, '服务器内部错误', statusMsg, respStr);
      case 502:
        return _createError(502, '无效的请求', statusMsg, respStr);
      case 503:
        return _createError(503, '服务器已关闭', statusMsg, respStr);
      case 505:
        return _createError(505, '不支持的HTTP请求', statusMsg, respStr);
      case 529:
        return _createError(529, '系统繁忙，请稍后重试', statusMsg, respStr);
      default:
        return _createError(statusCode ?? -1, statusMsg, statusMsg, respStr);
    }
  }
}
