import 'cus_http_request.dart';

// 来源：https://www.cnblogs.com/luoshang/p/16987781.html

/// 调用底层的request，重新提供get，post等方便方法

class HttpUtils {
  static HttpRequest httpRequest = HttpRequest();

  /// get
  static Future get({
    required String path,
    Map<String, dynamic>? queryParameters,
    CusRespType? responseType,
    bool showLoading = true,
    bool showErrorMessage = true,
  }) {
    return httpRequest.request(
      path: path,
      method: HttpMethod.get,
      queryParameters: queryParameters,
      responseType: responseType,
      showLoading: showLoading,
      showErrorMessage: showErrorMessage,
    );
  }

  /// post
  static Future post({
    required String path,
    required HttpMethod method,
    dynamic headers,
    CusRespType? responseType, // 可以自定义返回类型(默认是json)
    dynamic data,
    bool showLoading = true,
    bool showErrorMessage = true,
  }) {
    return httpRequest.request(
      path: path,
      method: HttpMethod.post,
      headers: headers,
      responseType: responseType,
      data: data,
      showLoading: showLoading,
      showErrorMessage: showErrorMessage,
    );
  }
}

/*
使用方法: 
import 'cus_dio_client.dart';

HttpUtils.get(
　　path: '11111'
);

　HttpUtils.post(
　　path: '1111',
　　method: HttpMethod.post //可以更改其他的
);
*/