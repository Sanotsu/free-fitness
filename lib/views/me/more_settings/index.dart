import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/constants.dart';
import '../../../models/cus_app_localizations.dart';
import '../../../models/paid_llm/llm_config.dart';
import '../../../services/app_restart_service.dart';
import '../../../services/llm_config_service.dart';
import '../llm_config/index.dart';

class MoreSettings extends StatefulWidget {
  const MoreSettings({super.key});

  @override
  State<MoreSettings> createState() => _MoreSettingsState();
}

class _MoreSettingsState extends State<MoreSettings> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
  );

  final LlmConfigService _llmConfigService = LlmConfigService();

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    // 大模型配置状态值(右侧显示"已配置 N 个/未配置")
    _llmConfigService.load();
  }

  Future<void> _initPackageInfo() async {
    WidgetsFlutterBinding.ensureInitialized();

    final info = await PackageInfo.fromPlatform();

    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(CusAL.of(context).moreSettings)),
      body: Column(
        children: [
          Expanded(child: buildSettingList()),
          Center(
            child: Padding(
              padding: EdgeInsets.all(16.sp),
              child: Text(
                '${_packageInfo.appName} v${_packageInfo.version}+${_packageInfo.buildNumber}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  ListView buildSettingList() {
    return ListView(
      children: [
        SizedBox(height: 10.sp),
        ExpansionTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(CusAL.of(context).languageSetting),
              Text(
                box.read("language") == 'zh'
                    ? "简体中文"
                    : box.read("language") == 'en'
                    ? "English"
                    : CusAL.of(context).followSystem,
              ),
            ],
          ),
          children: [
            _buildLanguageListItem(CusAL.of(context).followSystem, 'system'),
            _buildLanguageListItem('简体中文', 'zh'),
            _buildLanguageListItem('English', 'en'),
          ],
        ),
        SizedBox(height: 10.sp),
        ExpansionTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(CusAL.of(context).themeSetting),
              Text(
                box.read("mode") == "dark"
                    ? CusAL.of(context).darkMode
                    : box.read("mode") == "light"
                    ? CusAL.of(context).lightMode
                    : CusAL.of(context).followSystem,
              ),
            ],
          ),
          children: [
            _buildModeListItem(
              const Icon(Icons.sync),
              CusAL.of(context).followSystem,
              'system',
            ),
            _buildModeListItem(
              const Icon(Icons.wb_sunny_outlined),
              CusAL.of(context).darkMode,
              'dark',
            ),
            _buildModeListItem(
              const Icon(Icons.brightness_2),
              CusAL.of(context).lightMode,
              'light',
            ),
          ],
        ),

        // 2026-08-27 大模型配置入口(AI 助手的配置管理)
        // 风格对齐上方语言/主题设置项：左标题 + 右侧当前状态值，无 leading 图标
        ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(CusAL.of(context).llmConfigTitle),
              ValueListenableBuilder<List<LlmConfig>>(
                valueListenable: _llmConfigService.configsNotifier,
                builder: (context, configs, _) {
                  return Text(
                    configs.isEmpty
                        ? CusAL.of(context).llmConfigStatusNone
                        : CusAL.of(
                            context,
                          ).llmConfigStatusCount(configs.length),
                  );
                },
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LlmConfigListPage(),
              ),
            );
          },
        ),

        ListTile(
          title: Text(CusAL.of(context).appNote),
          trailing: const Icon(Icons.info_outlined),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'Free Fitness',
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(flex: 1, child: Text("Author")),
                    Expanded(flex: 2, child: Text("SanotSu")),
                  ],
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(flex: 1, child: Text("Wechat")),
                    Expanded(flex: 2, child: Text("SanotSu")),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Expanded(flex: 1, child: Text("Email")),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "callmedavidsu@gmail.com",
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.sp),
                Text(
                  "Not for commercial use.",
                  style: TextStyle(fontSize: 20.sp, color: Colors.blue),
                ),
              ],
            );
          },
        ),

        // SizedBox(height: 10.sp),
        // ListTile(
        //   leading: const Icon(Icons.description),
        //   title: Text(
        //     "${CusAL.of(context).userGuide}(todo)",
        //     style: TextStyle(
        //       fontSize: CusFontSizes.pageSubTitle,
        //       fontWeight: FontWeight.bold,
        //       color: Theme.of(context).primaryColor,
        //     ),
        //   ),
        //   onTap: null,
        // ),
        // SizedBox(height: 10.sp),
        // ListTile(
        //   leading: const Icon(Icons.question_answer),
        //   title: Text(
        //     "${CusAL.of(context).questionAndAnswer}(todo)",
        //     style: TextStyle(
        //       fontSize: CusFontSizes.pageSubTitle,
        //       fontWeight: FontWeight.bold,
        //       color: Theme.of(context).primaryColor,
        //     ),
        //   ),
        //   onTap: null,
        // ),
      ],
    );
  }

  Widget _buildLanguageListItem(String text, String value) {
    return Container(
      padding: EdgeInsets.only(left: 15.sp, right: 15.sp, top: 0, bottom: 0),
      child: ListTile(
        leading: const Icon(Icons.drag_handle),
        title: Container(
          // 缩小 leading 和 title之的间隔
          transform: Matrix4.translationValues(-20, 0.0, 0.0),
          child: Text(text),
        ),
        trailing: value == box.read("language") ? const Icon(Icons.done) : null,
        onTap: () async {
          await box.write('language', value);
          if (!mounted) return;
          _reloadApp(context);
        },
      ),
    );
  }

  Widget _buildModeListItem(Icon icon, String text, String value) {
    return Container(
      padding: EdgeInsets.only(left: 15.sp, right: 15.sp, top: 0, bottom: 0),
      child: ListTile(
        leading: icon,
        title: Container(
          // 缩小 leading 和 title之的间隔
          transform: Matrix4.translationValues(-20, 0.0, 0.0),
          child: Text(text),
        ),
        trailing: value == box.read("mode") ? const Icon(Icons.done) : null,
        onTap: () async {
          await box.write('mode', value);
          if (!mounted) return;
          _reloadApp(context);
        },
      ),
    );
  }

  // 重新加载应用程序以更新UI
  void _reloadApp(BuildContext context) {
    // 使用新的重启方式，不再创建新的应用实例
    AppRestartService.restartApp(context);

    // 显示一个提示，告诉用户设置已更改
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          box.read("language") == 'zh' ? "设置已更新" : "Settings updated",
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}
