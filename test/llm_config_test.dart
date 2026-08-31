import 'package:flutter_test/flutter_test.dart';
import 'package:free_fitness/models/ai/ai_custom_role.dart';
import 'package:free_fitness/models/ai/ai_message.dart';
import 'package:free_fitness/models/ai/ai_role.dart';
import 'package:free_fitness/models/paid_llm/llm_config.dart';
import 'package:free_fitness/services/llm_config_service.dart';

/// 2026-08-27 AI 模块改造的自建单元测试
/// 覆盖：LlmConfig 序列化/extraParams 合并/解析校验、智能选中 pickFromList、
/// AiMessage 多图逗号串、AiRole 解析与自定义角色兜底
void main() {
  group('LlmConfig 序列化', () {
    test('toMap/fromMap 往返一致(含 extraParams)', () {
      var config = LlmConfig(
        id: 'a1',
        name: '硅基流动-Qwen',
        baseUrl: 'https://api.siliconflow.cn/v1/chat/completions',
        apiKey: 'sk-xxx',
        model: 'Qwen/Qwen2.5-VL-32B-Instruct',
        supportsVision: true,
        extraParams: {'temperature': 0.3, 'enable_thinking': true},
        sortOrder: 2,
      );

      var restored = LlmConfig.fromMap(config.toMap());

      expect(restored.id, 'a1');
      expect(restored.name, '硅基流动-Qwen');
      expect(restored.model, 'Qwen/Qwen2.5-VL-32B-Instruct');
      expect(restored.supportsVision, true);
      expect(restored.extraParams?['temperature'], 0.3);
      expect(restored.extraParams?['enable_thinking'], true);
      expect(restored.sortOrder, 2);
      expect(restored.isComplete, true);
    });

    test('三要素缺失时 isComplete 为 false', () {
      var noKey = LlmConfig(
        id: 'a2',
        name: 'n',
        baseUrl: 'https://x/v1',
        apiKey: ' ',
        model: 'm',
      );
      expect(noKey.isComplete, false);
    });
  });

  group('extraParams 合并策略', () {
    test('保留字段 model/messages/stream 被忽略，其余覆盖默认值', () {
      var base = <String, dynamic>{
        'model': 'right-model',
        'messages': [1, 2],
        'stream': true,
        'temperature': 0.7,
      };
      var merged = LlmConfig.mergeExtraParams(base, {
        'model': 'hacked',
        'messages': 'hacked',
        'stream': false,
        'temperature': 0.2,
        'enable_thinking': true,
      });

      expect(merged['model'], 'right-model');
      expect(merged['messages'], [1, 2]);
      expect(merged['stream'], true);
      expect(merged['temperature'], 0.2);
      expect(merged['enable_thinking'], true);
    });

    test('extra 为 null/空时原样返回', () {
      var base = <String, dynamic>{'model': 'm', 'stream': true};
      expect(LlmConfig.mergeExtraParams(base, null), same(base));
      expect(LlmConfig.mergeExtraParams(base, {}), same(base));
    });

    test('parseExtraParams：合法对象/空串/非法抛异常', () {
      expect(LlmConfig.parseExtraParams(null), isEmpty);
      expect(LlmConfig.parseExtraParams('  '), isEmpty);
      expect(LlmConfig.parseExtraParams('{"a":1}'), {'a': 1});
      expect(
        () => LlmConfig.parseExtraParams('[1,2]'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => LlmConfig.parseExtraParams('{bad json'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('pickFromList 智能选中', () {
    var c1 = LlmConfig(
      id: 'c1',
      name: '1',
      baseUrl: 'u1',
      apiKey: 'k1',
      model: 'm1',
      supportsVision: true,
      sortOrder: 0,
    );
    var c2 = LlmConfig(
      id: 'c2',
      name: '2',
      baseUrl: 'u2',
      apiKey: 'k2',
      model: 'm2',
      supportsVision: false,
      sortOrder: 1,
    );
    var broken = LlmConfig(
      id: 'c3',
      name: '3',
      baseUrl: '',
      apiKey: '',
      model: '',
    );

    test('候选为空返回 null', () {
      expect(LlmConfigService.pickFromList([], null), isNull);
      expect(LlmConfigService.pickFromList([broken], null), isNull);
    });

    test('唯一候选自动选中', () {
      expect(LlmConfigService.pickFromList([c1], null)?.id, 'c1');
    });

    test('多个候选：优先上次使用', () {
      expect(LlmConfigService.pickFromList([c1, c2], 'c2')?.id, 'c2');
    });

    test('多个候选：上次使用不存在/未记忆时取排序第一个', () {
      expect(LlmConfigService.pickFromList([c1, c2], null)?.id, 'c1');
      expect(LlmConfigService.pickFromList([c1, c2], 'gone')?.id, 'c1');
    });

    test('图片场景过滤非视觉配置', () {
      expect(
        LlmConfigService.pickFromList([c1, c2], 'c2', needVision: true)?.id,
        'c1',
      );
      expect(
        LlmConfigService.pickFromList([c2], null, needVision: true),
        isNull,
      );
    });
  });

  group('AiMessage 多图字段', () {
    test('逗号分隔字符串与列表互转', () {
      var msg = AiMessage(
        conversationId: 1,
        role: 'user',
        content: 'hi',
        imagePaths: '3/uuid1.jpg,3/uuid2.jpg,3/uuid3.jpg,3/uuid4.jpg',
      );
      expect(msg.imageList.length, 4);
      expect(msg.imageList.first, '3/uuid1.jpg');

      expect(
        AiMessage.joinImagePaths(['1/a.jpg', '1/b.jpg']),
        '1/a.jpg,1/b.jpg',
      );
    });

    test('空图片字段返回空列表', () {
      var msg = AiMessage(conversationId: 1, role: 'user', content: 'hi');
      expect(msg.imageList, isEmpty);
    });
  });

  group('AiRole 解析', () {
    test('内置角色按 key 解析；未知 key 兜底通用助手', () {
      expect(resolveAiRole('dietitian').key, 'dietitian');
      expect(resolveAiRole('coach').key, 'coach');
      expect(resolveAiRole('not_exist').key, 'assistant');
      expect(resolveAiRole(null).key, 'assistant');
    });

    test('自定义角色按 c_{id} 解析，未加载时兜底', () {
      var custom = AiCustomRole(
        roleId: 9,
        name: '跑步教练',
        systemPrompt: '你是跑步教练',
      );
      expect(resolveAiRole('c_9', customRoles: [custom]).nameZh, '跑步教练');
      expect(resolveAiRole('c_9', customRoles: []).key, 'assistant');
      expect(custom.roleKey, 'c_9');
    });
  });
}
