import 'dart:convert';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:proste_logger/proste_logger.dart';

import '../dio_client/dio_sse_transformer.dart';
import '../dio_client/interceptor_error.dart';
import '../dio_client/cus_http_client.dart';
import '../dio_client/cus_http_request.dart';
import '../../models/paid_llm/common_chat_completion_state.dart';
import '../../models/paid_llm/llm_config.dart';

///
/// 2026-08-27 大模型调用层改造：
///
/// 不再使用硬编码的平台/端点/AK(_self_keys.dart 为本地留存文件，仅解除运行时引用)，
/// 统一接收用户配置的 LlmConfig(OpenAI 兼容端点)：
///   - URL = config.baseUrl，Authorization = Bearer config.apiKey；
///   - model 恒取 config.model(多模态单模型设计，无按内容分支选择)；
///   - 请求体 = 基础体(含默认采样参数) 浅合并 config.extraParams
///     (model/messages/stream 为程序控制字段，忽略用户同名键)；
///

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
  LlmConfig config,
  List<CCMessage> messages, {
  bool stream = true,
}) async {
  try {
    var body = CCReqBody(
      model: config.model,
      messages: messages,
      stream: stream,
    );

    // 基础请求体：与旧版实际发出的 toJson 内容一致(含默认采样参数)，
    // messages 转为纯 Map 列表方便后续合并
    var base = <String, dynamic>{
      'model': body.model,
      'messages': [
        for (var m in messages) {'role': m.role, 'content': m.content},
      ],
      'stream': body.stream,
      // 'temperature': body.temperature,
      // 'top_p': body.topP,
      // 'max_tokens': body.maxTokens,
    };

    // 浅合并用户自定义高级参数(忽略 model/messages/stream 保留键)
    var requestBody = LlmConfig.mergeExtraParams(base, config.extraParams);

    var header = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${config.apiKey}",
    };

    var respData = await HttpUtils.post(
      path: config.baseUrl,
      headers: header,
      responseType: stream ? CusRespType.stream : CusRespType.json,
      data: requestBody,
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
              // 2026-08-27 修复：心跳/多余空行会产生空数据事件，
              // json.decode("") 会抛异常导致该事件被静默丢弃，这里先跳过
              var dataStr = event.data.trim();
              if (dataStr.isEmpty) {
                if (kDebugMode) {
                  debugPrint('[SSE] 收到空数据事件(心跳/空行)，跳过');
                }
                return;
              }

              // if (kDebugMode) {
              //   // 只打印前100字符，避免刷屏
              //   debugPrint(
              //     '[SSE] ${dataStr.length > 100 ? dataStr.substring(0, 100) : dataStr}',
              //   );
              // }

              // 正常的分段数据
              // 如果包含DONE，是正常获取AI接口的结束
              if (dataStr.contains('[DONE]')) {
                if (!streamController.isClosed) {
                  streamController.add(CCRespBody(customReplyText: '[DONE]'));
                  streamController.close();
                }
              } else {
                try {
                  final jsonData = json.decode(dataStr);
                  if (jsonData is! Map<String, dynamic>) {
                    if (kDebugMode) {
                      debugPrint('[SSE] 数据不是JSON对象，跳过: $dataStr');
                    }
                    return;
                  }
                  final commonRespBody = CCRespBody.fromJson(jsonData);
                  if (!streamController.isClosed) {
                    streamController.add(commonRespBody);
                  }
                } catch (e) {
                  // 单条数据解析失败不影响后续事件(不同平台的心跳/注释行等)
                  if (kDebugMode) {
                    debugPrint('[SSE] 解析失败: $e / 原文: $dataStr');
                  }
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
        // 先发送最后一个手动终止的信息，再实际取消
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
