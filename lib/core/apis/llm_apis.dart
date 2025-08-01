import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:proste_logger/proste_logger.dart';

import '../dio_client/dio_sse_transformer.dart';
import '../dio_client/interceptor_error.dart';
import '../dio_client/cus_http_client.dart';
import '../dio_client/cus_http_request.dart';
import '../../models/paid_llm/common_chat_completion_state.dart';
import '../../models/paid_llm/common_chat_model_spec.dart';
import '_self_keys.dart';

///
/// 这里 _self_keys.dart 就是自己AI大模型API平台所在的AK，代码内容如下:
///

// final Map<ApiPlatform, String> cusAKMap = {
//   ApiPlatform.lingyiwanwu: 'xxx',
// };
//

/// 添加流式响应的类
class StreamWithCancel<T> {
  final Stream<T> stream;
  final Future<void> Function() cancel;

  StreamWithCancel(this.stream, this.cancel);

  static StreamWithCancel<T> empty<T>() {
    return StreamWithCancel(const Stream.empty(), () async {});
  }
}

final logger = ProsteLogger();

/// 获取流式响应数据
Future<StreamWithCancel<CCRespBody>> getChatRespStream(
  ApiPlatform platform,
  List<CCMessage> messages, {
  String? model,
  bool stream = true,
}) async {
  try {
    var body = CCReqBody(model: model, messages: messages, stream: stream);

    var spec = platformUrls.where((e) => e.platform == platform).toList();
    if (spec.isEmpty) {
      throw Exception("未找到${platform.name}的配置");
    }

    var path = spec.first.url;
    var header = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${cusAKMap[platform]!}",
    };

    var respData = await HttpUtils.post(
      path: path,
      headers: header,
      responseType: stream ? CusRespType.stream : CusRespType.json,
      // data: body.toRequestBody(),
      data: body,
    );

    if (stream) {
      var responseStream = (respData as ResponseBody).stream;

      var streamController = StreamController<CCRespBody>();
      StreamTransformer<Uint8List, List<int>> unit8Transformer =
          StreamTransformer.fromHandlers(
            handleData: (data, sink) {
              sink.add(List<int>.from(data));
            },
          );

      var subscription = responseStream
          // 创建一个自定义的 StreamTransformer 来处理 Uint8List 到 String 的转换。
          .transform(unit8Transformer)
          .transform(const Utf8Decoder())
          // 将输入的 Stream<String> 按照行（即换行符 \n 或 \r\n）进行分割，并将每一行作为一个单独的事件发送到输出流中。
          .transform(const LineSplitter())
          .transform(const SseTransformer())
          .listen(
            (event) {
              // print(
              //   "【Event】 ${event.id}, ${event.event}, ${event.retry}, ${event.data}",
              // );

              // 正常的分段数据
              // 如果包含DONE，是正常获取AI接口的结束
              if ((event.data).contains('[DONE]')) {
                if (!streamController.isClosed) {
                  streamController.add(CCRespBody(customReplyText: '[DONE]'));
                  streamController.close();
                }
              } else {
                final jsonData = json.decode(event.data);
                final commonRespBody = CCRespBody.fromJson(jsonData);
                if (!streamController.isClosed) {
                  streamController.add(commonRespBody);
                }
              }
            },
            onDone: () {
              // 流处理完手动补一个结束子串
              if (!streamController.isClosed) {
                streamController.add(
                  CCRespBody(customReplyText: '[DONE]-onDone'),
                );
                streamController.close();
              }
            },
            onError: (error) {
              if (!streamController.isClosed) {
                streamController.addError(error);
                streamController.close();
              }
            },
          );

      Future<void> cancel() async {
        // ？？？占位用的，先发送最后一个手动终止的信息，再实际取消(手动的更没有token信息了)
        if (!streamController.isClosed) {
          streamController.add(CCRespBody(customReplyText: '[手动终止]'));
        }

        await subscription.cancel();
        if (!streamController.isClosed) {
          streamController.close();
        }
      }

      // 返回可取消的流
      return StreamWithCancel(streamController.stream, cancel);
    } else {
      // 如果不是流式的，直接返回结果
      if (respData.runtimeType == String) {
        respData = json.decode(respData);
      }

      return StreamWithCancel(
        Stream.value(CCRespBody.fromJson(respData)),
        () async {},
      );
    }
  } on CusHttpException catch (e) {
    // 报错时也要当作正常流程流式返回，并手动添加一条结束标志
    final streamErrorController = StreamController<CCRespBody>();

    // 添加错误响应
    streamErrorController.add(
      CCRespBody(
        error: RespError(
          code: 'HTTP请求响应异常:\n\n错误代码: ${e.cusCode}\n',
          message:
              """\n错误信息: ${e.cusMsg}
            \n错误原文: ${e.errMessage}
            \n原始信息: ${e.errRespString}
            \n""",
        ),
      ),
    );
    streamErrorController.close();
    return StreamWithCancel(streamErrorController.stream, () async {});
  } catch (e) {
    // 其他错误时，流式返回错误
    final streamErrorController = StreamController<CCRespBody>();
    streamErrorController.addError(e);
    streamErrorController.close();
    return StreamWithCancel(streamErrorController.stream, () async {});
  }
}
