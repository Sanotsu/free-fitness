// 超时时间
class HttpOptions {
  // 请求地址，这个应该别处传来(使用时带上完整地址即可)
  static const String baseUrl = '';
  //单位时间是ms
  static const Duration connectTimeout = Duration(milliseconds: 60 * 1000);
  static const Duration receiveTimeout = Duration(milliseconds: 5 * 60 * 1000);
  static const Duration sendTimeout = Duration(milliseconds: 10 * 1000);
  // 自定义content-type
  static const String contentType = "application/json;charset=utf-8";
}
