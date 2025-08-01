// 超时时间
class HttpOptions {
  // 请求地址，这个应该别处传来(使用时带上完整地址即可)
  static const String baseUrl = '';
  //单位时间是ms
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 10 * 60);
  static const Duration sendTimeout = Duration(seconds: 3 * 60);
  // 自定义content-type
  static const String contentType = "application/json;charset=utf-8";
}
