import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/cus_app_localizations.dart';
import '../../../models/paid_llm/llm_config.dart';
import '../../../services/llm_config_service.dart';
import 'modify_config.dart';

/// 2026-08-27 大模型配置列表页(我的→更多设置→AI 大模型配置)
///
/// 多配置存管(平台+地址+AK+模型名 完整成档)；
/// 使用时智能选中：唯一自动选中；多个默认"上次使用/第一个"，聊天页可切换。
/// 列表交互(2026-08-27 改版)：无 leading 图标、无更多按钮——
/// 点击行直接进入详情页(详情内可修改/删除)；
/// 向左滑动某条弹出确认删除；
/// 支持视觉理解的配置在标题文字后显示亮的眼睛图标，不支持则不显示。
class LlmConfigListPage extends StatefulWidget {
  const LlmConfigListPage({super.key});

  @override
  State<LlmConfigListPage> createState() => _LlmConfigListPageState();
}

class _LlmConfigListPageState extends State<LlmConfigListPage> {
  final LlmConfigService _configService = LlmConfigService();

  @override
  void initState() {
    super.initState();
    _configService.load();
  }

  // 删除确认弹窗(列表右滑与详情页删除共用同一确认语义)
  Future<bool> _confirmDelete(LlmConfig config) async {
    var confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(CusAL.of(context).tipsTitle),
          content: Text(CusAL.of(context).llmConfigDeleteNote(config.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(CusAL.of(context).cancelLabel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(CusAL.of(context).confirmLabel),
            ),
          ],
        );
      },
    );

    return confirmed ?? false;
  }

  // 进入编辑详情页
  void _openDetail(LlmConfig config) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ModifyLlmConfig(config: config)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(CusAL.of(context).llmConfigTitle)),
      body: ValueListenableBuilder<List<LlmConfig>>(
        valueListenable: _configService.configsNotifier,
        builder: (context, configs, _) {
          if (configs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.smart_toy_outlined,
                    size: 50.sp,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 10.sp),
                  Text(
                    CusAL.of(context).llmConfigEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13.sp),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: configs.length,
            // 垂直间距交给列表统一控制；卡片自身不留边距(与滑动手势区域重合)
            padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 8.sp),
            itemBuilder: (context, index) {
              var config = configs[index];
              var host = Uri.tryParse(config.baseUrl)?.host ?? config.baseUrl;

              // 向左滑出红色删除背景；确认后从服务删除(notifier 驱动列表自动刷新)
              return Dismissible(
                key: ValueKey(config.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20.sp),
                  color: Colors.red,
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                confirmDismiss: (direction) async {
                  var ok = await _confirmDelete(config);
                  if (ok) await _configService.delete(config.id);
                  return ok;
                },
                child: Card(
                  elevation: 1.sp,
                  margin: EdgeInsets.zero,
                  // 裁剪圆角，避免滑动删除的红色背景从卡片圆角处露出
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            config.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 仅支持视觉理解的配置才显示亮眼睛图标(跟在标题后)
                        if (config.supportsVision) ...[
                          SizedBox(width: 4.sp),
                          Icon(
                            Icons.visibility,
                            size: 16.sp,
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      "${config.model}\n$host",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    onTap: () => _openDetail(config),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ModifyLlmConfig()),
          );
        },
        tooltip: CusAL.of(context).llmConfigAddTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }
}
