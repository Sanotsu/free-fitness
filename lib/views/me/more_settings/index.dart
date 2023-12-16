import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../common/global/constants.dart';
import '../../../layout/app.dart';

class MoreSettings extends StatefulWidget {
  const MoreSettings({super.key});

  @override
  State<MoreSettings> createState() => _MoreSettingsState();
}

class _MoreSettingsState extends State<MoreSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.moreSettings),
      ),
      body: ListView(
        children: [
          SizedBox(height: 10.sp),
          ExpansionTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.languageSetting),
                Text(
                  box.read("language") == "zh"
                      ? "简体中文"
                      : box.read("language") == "en"
                          ? "English"
                          : AppLocalizations.of(context)!.followSystem,
                ),
              ],
            ),
            children: [
              _buildLanguageListItem(
                AppLocalizations.of(context)!.followSystem,
                'system',
              ),
              _buildLanguageListItem('简体中文', 'zh'),
              _buildLanguageListItem('English', 'en'),
            ],
          ),
          SizedBox(height: 10.sp),
          ExpansionTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.themeSetting),
                Text(
                  box.read("mode") == "dark"
                      ? AppLocalizations.of(context)!.darkMode
                      : box.read("mode") == "light"
                          ? AppLocalizations.of(context)!.lightMode
                          : AppLocalizations.of(context)!.followSystem,
                ),
              ],
            ),
            children: [
              _buildModeListItem(
                const Icon(Icons.sync),
                AppLocalizations.of(context)!.followSystem,
                'system',
              ),
              _buildModeListItem(
                const Icon(Icons.wb_sunny_outlined),
                AppLocalizations.of(context)!.darkMode,
                'dark',
              ),
              _buildModeListItem(
                const Icon(Icons.brightness_2),
                AppLocalizations.of(context)!.lightMode,
                'light',
              ),
            ],
          ),
        ],
      ),
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
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const FreeFitnessApp()),
      (route) => false,
    );
  }
}
