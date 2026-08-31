import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('内置食物成分数据可通过新版 AssetManifest API 发现并加载', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    const embeddedFoodsDir = 'assets/datasets/china-food-composition';
    final foodJsonFiles = manifest
        .listAssets()
        .where(
          (key) => key.startsWith(embeddedFoodsDir) && key.endsWith('.json'),
        )
        .toList();

    // 清单中应能发现分册数据文件
    expect(
      foodJsonFiles,
      isNotEmpty,
      reason: 'AssetManifest.listAssets 应包含 $embeddedFoodsDir 下的 json',
    );
    for (final f in foodJsonFiles) {
      expect(f.endsWith('.json'), isTrue);
    }

    // 每个发现的文件都应能正常以文本方式读取并解析为数组
    for (final filePath in foodJsonFiles) {
      final content = await rootBundle.loadString(filePath);
      final decoded = content.trim();
      expect(decoded.startsWith('['), isTrue, reason: '$filePath 应为 JSON 数组');
    }
  });
}
