import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/global/constants.dart';
import '../../../layout/app.dart';
// import '../../../layout/themes/cus_font_size.dart';
import '../../../models/cus_app_localizations.dart';

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
        title: Text(CusAL.of(context).moreSettings),
      ),
      body: ListView(
        children: [
          SizedBox(height: 10.sp),
          ExpansionTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(CusAL.of(context).languageSetting),
                Text(
                  box.read("language") == "zh"
                      ? "简体中文"
                      : box.read("language") == "en"
                          ? "English"
                          : CusAL.of(context).followSystem,
                ),
              ],
            ),
            children: [
              _buildLanguageListItem(
                CusAL.of(context).followSystem,
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
