import 'package:flutter_test/flutter_test.dart';
import 'package:free_fitness/core/utils/import_progress.dart';

void main() {
  test('ImportProgress.ratio 计算与边界', () {
    expect(const ImportProgress(title: 't', current: 0, total: 10).ratio, 0.0);
    expect(const ImportProgress(title: 't', current: 5, total: 10).ratio, 0.5);
    // 超出总数时收敛到 1.0
    expect(const ImportProgress(title: 't', current: 20, total: 10).ratio, 1.0);
    // 总数未知(total<=0)时不定态返回 0
    expect(const ImportProgress(title: 't', current: 3, total: 0).ratio, 0.0);
  });

  test('ImportProgressCenter 更新与清空', () {
    const p = ImportProgress(title: '食物成分', detail: 'd', current: 1, total: 2);

    ImportProgressCenter.update(p);
    expect(ImportProgressCenter.notifier.value?.title, '食物成分');
    expect(ImportProgressCenter.notifier.value?.current, 1);

    ImportProgressCenter.update(null);
    expect(ImportProgressCenter.notifier.value, isNull);
  });
}
