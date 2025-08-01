import 'dart:async';

import '../utils/tools.dart';

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
