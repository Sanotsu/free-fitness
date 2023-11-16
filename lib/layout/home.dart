// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

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
    UserCenter()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  DateTime? _currentBackPressTime;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        DateTime now = DateTime.now();

        if (_currentBackPressTime == null ||
            now.difference(_currentBackPressTime!) >
                const Duration(seconds: 2)) {
          _currentBackPressTime = now;

          print("连续点击两次返回按钮，时间间隔在2秒外");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back button again to exit'),
            ),
          );

          return false;
        }
        print("home 隔在2秒内");
        return true;
      },
      child: Scaffold(
        // home页的背景色(如果下层还有设定其他主题颜色，会被覆盖)
        // backgroundColor: Colors.red,
        body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center), label: '运动'),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: '饮食'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
          ],
          currentIndex: _selectedIndex,
          // 底部导航栏的颜色
          // backgroundColor: dartThemeMaterialColor3,
          backgroundColor: Theme.of(context).primaryColor,
          // 被选中的item的图标颜色和文本颜色
          selectedIconTheme: const IconThemeData(color: Colors.white),
          selectedItemColor: Colors.white,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
