import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import '../common/utils/tools.dart';
import '../dio_client/cus_http_client.dart';
import '../dio_client/cus_http_request.dart';
import '../models/paid_llm/common_chat_completion_state.dart';
import '../models/paid_llm/common_chat_model_spec.dart';
import '_self_keys.dart';

///
/// 这里 _self_keys 都是用自己的账号,要付费的
/// final Map<ApiPlatform, String> cusAKMap = {
///   ApiPlatform.lingyiwanwu: 'xxxxx',
/// };
///

/// 添加流式响应的类
class StreamWithCancel<T> {
  final Stream<T> stream;
  final Future<void> Function() cancel;

  StreamWithCancel(this.stream, this.cancel);

  static StreamWithCancel<T> empty<T>() {
    return StreamWithCancel(
      const Stream.empty(),
      () async {},
    );
  }
}

///
/// dio 中处理SSE的解析器
/// 来源: https://github.com/cfug/dio/issues/1279#issuecomment-1326121953
///
class SseTransformer extends StreamTransformerBase<String, SseMessage> {
  const SseTransformer();
  @override
  Stream<SseMessage> bind(Stream<String> stream) {
    return Stream.eventTransformed(stream, (sink) => SseEventSink(sink));
  }
}

class SseEventSink implements EventSink<String> {
  final EventSink<SseMessage> _eventSink;

  String? _id;
  String _event = "message";
  String _data = "";
  int? _retry;

  SseEventSink(this._eventSink);

  @override
  void add(String event) {
    if (event.startsWith("id:")) {
      _id = event.substring(3);
      return;
    }
    if (event.startsWith("event:")) {
      _event = event.substring(6);
      return;
    }
    if (event.startsWith("data:")) {
      _data = event.substring(5);
      return;
    }
    if (event.startsWith("retry:")) {
      _retry = int.tryParse(event.substring(6));
      return;
    }
    if (event.isEmpty) {
      _eventSink.add(
        SseMessage(id: _id, event: _event, data: _data, retry: _retry),
      );
      _id = null;
      _event = "message";
      _data = "";
      _retry = null;
    }

    // 自己加的，请求报错时不是一个正常的流的结构，是个json,直接添加即可
    if (isJsonString(event)) {
      _eventSink.add(
        SseMessage(id: _id, event: _event, data: event, retry: _retry),
      );

      _id = null;
      _event = "message";
      _data = "";
      _retry = null;
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _eventSink.addError(error, stackTrace);
  }

  @override
  void close() {
    _eventSink.close();
  }
}

class SseMessage {
  final String? id;
  final String event;
  final String data;
  final int? retry;

  const SseMessage({
    this.id,
    required this.event,
    required this.data,
    this.retry,
  });
}

/// 获取流式响应数据
Future<StreamWithCancel<CCRespBody>> getChatRespStream(
  ApiPlatform platform,
  List<CCMessage> messages, {
  String? model,
  bool stream = true,
}) async {
  var body = CCReqBody(
    model: model,
    messages: messages,
    stream: stream,
  );

  try {
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
      method: HttpMethod.post,
      headers: header,
      responseType: stream ? CusRespType.stream : CusRespType.json,
      data: body,
    );

    if (stream) {
      var responseStream = respData.stream as Stream<List<int>>;

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
            streamController.add(CCRespBody(customReplyText: '[DONE]-onDone'));
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
  } catch (e) {
    rethrow;
  }
}
