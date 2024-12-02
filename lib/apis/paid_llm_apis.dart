import 'dart:convert';

import '../dio_client/cus_http_client.dart';
import '../dio_client/cus_http_request.dart';
import '../dio_client/interceptor_error.dart';
import '../models/paid_llm/common_chat_completion_state.dart';
import '../models/paid_llm/common_chat_model_spec.dart';
import '_self_keys.dart';

///
/// 这里 _self_keys 都是用自己的账号,要付费的
/// final Map<ApiPlatform, String> cusAKMap = {
///   ApiPlatform.lingyiwanwu: 'xxxxx',
/// };
///

/// 获取流式响应数据
Future<List<CCRespBody>> getChatResp(
  ApiPlatform platform,
  List<CCMessage> messages, {
  String? model,
}) async {
  var body = CCReqBody(model: model, messages: messages);

  try {
    // 如果选择的平台不存在，抛错
    var spec = platformUrls.where((e) => e.platform == platform).toList();

    if (spec.isEmpty) {
      return throw Exception("未找到${platform.name}的配置");
    }

    // 存在，则拼接访问的地址
    var path = spec.first.url;

    var header = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${cusAKMap[platform]!}",
    };

    var respData = await HttpUtils.post(
      path: path,
      method: HttpMethod.post,
      headers: header,
      data: body,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return [CCRespBody.fromJson(respData)];
  } on HttpException catch (e) {
    // 这里是拦截器抛出的http异常的处理
    return [
      CCRespBody(
        customReplyText: e.toString(),
        error: RespError(code: "10001", type: "http异常", message: e.toString()),
      )
    ];
  } catch (e) {
    // 这里是其他异常处理
    // API请求报错，显示报错信息
    return [
      CCRespBody(
        customReplyText: e.toString(),
        // 这里的code和msg就不是api返回的，是自行定义的，应该抽出来
        error: RespError(code: "10000", type: "其他异常", message: e.toString()),
      )
    ];
  }
}
