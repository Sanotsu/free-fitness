import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../common/utils/tools.dart';
import '../models/cus_app_localizations.dart';
import '../views/diary/index_table_calendar.dart';
import '../views/dietary/index.dart';
import '../views/me/index.dart';
import '../views/training/index.dart';

/// 主页面

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    Training(),
    Dietary(),
    DiaryTableCalendar(),
    UserAndSettings()
  ];

  @override
  void initState() {
    super.initState();
    initPermission();
  }

  initPermission() async {
    var state = await requestStoragePermission();

    if (!state) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(CusAL.of(context).permissionRequest),
            content: Text(CusAL.of(context).featuresRestrictionNote),
            actions: <Widget>[
              TextButton(
                child: Text(CusAL.of(context).cancelLabel),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              ElevatedButton(
                child: Text(CusAL.of(context).confirmLabel),
                onPressed: () async {
                  var state = await requestStoragePermission();
                  if (!context.mounted) return;
                  Navigator.of(context).pop(state);
                },
              ),
            ],
          );
        },
      ).then((value) {
        if (value == false) {
          if (!mounted) return;
          EasyLoading.showToast(CusAL.of(context).noStorageHint);
        }
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 点击返回键时暂停返回
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        final NavigatorState navigator = Navigator.of(context);
        // 如果确认弹窗点击确认返回true，否则返回false
        final bool? shouldPop = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(CusAL.of(context).closeLabel),
              content: Text(CusAL.of(context).appExitInfo),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: Text(CusAL.of(context).cancelLabel),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: Text(CusAL.of(context).confirmLabel),
                ),
              ],
            );
          },
        ); // 只有当对话框返回true 才 pop(返回上一层)
        if (shouldPop ?? false) {
          // 如果还有可以关闭的导航，则继续pop
          if (navigator.canPop()) {
            navigator.pop();
          } else {
            // 如果已经到头来，则关闭应用程序
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        // home页的背景色(如果下层还有设定其他主题颜色，会被覆盖)
        // backgroundColor: Colors.red,
        body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
        bottomNavigationBar: BottomNavigationBar(
          // 当item数量小于等于3时会默认fixed模式下使用主题色，大于3时则会默认shifting模式下使用白色。
          // 为了使用主题色，这里手动设置为fixed
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.fitness_center),
              label: CusAL.of(context).training,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.restaurant),
              label: CusAL.of(context).dietary,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.note),
              label: CusAL.of(context).diary,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: CusAL.of(context).me,
            ),
          ],
          currentIndex: _selectedIndex,
          // 底部导航栏的颜色
          // backgroundColor: dartThemeMaterialColor3,
          // backgroundColor: Theme.of(context).primaryColor,
          // // 被选中的item的图标颜色和文本颜色
          // selectedIconTheme: const IconThemeData(color: Colors.white),
          // selectedItemColor: Colors.white,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
