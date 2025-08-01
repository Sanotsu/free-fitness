import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/constants/constants.dart';
import '../models/cus_app_localizations.dart';
import '../services/service_initializer.dart';
import 'home.dart';
import 'init_guide_page.dart';
import 'themes/cus_font_size.dart';

/// 应用启动时的加载屏幕，负责初始化所有必要的服务
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    // 内置数据初始化成功之后，才会进入初始化导航页面InitGuidePage
    // 进入初始化导航页面之后，只要同意使用进入了主页面，那就一定会有用户信息了
    // 有用户信息了，就不必重新初始化了
    if (!(box.read(LocalStorageKey.userId) != null)) {
      // 获取当前系统语言
      Locale currentLocale = Localizations.localeOf(context);
      String languageCode = currentLocale.languageCode; // 例如: 'en', 'zh'

      // 写入当前语言到本地存储
      await box.write('language', languageCode);

      // 初始化所有服务
      await ServiceInitializer().initializeServices(languageCode);
    }

    // 标记初始化完成
    setState(() {
      _isInitialized = true;
    });

    // 导航到相应页面
    if (!mounted) return;

    // 如果没有在缓存获取到用户信息，就要用户输入；否则就直接进入首页
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => box.read(LocalStorageKey.userId) != null
            ? const HomePage()
            : const InitGuidePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 应用Logo和名称
            SizedBox(
              height: 250.sp,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 100.sp,
                    width: 100.sp,
                    child: Image.asset(appLogoImageUrl, fit: BoxFit.cover),
                  ),
                  SizedBox(height: 5.sp),
                  Text(
                    CusAL.of(context).appTitle,
                    style: TextStyle(
                      fontSize: CusFontSizes.flagMediumBig,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            // 中间空出来给service中的loading显示
            Spacer(),

            // 加载指示器
            SizedBox(
              height: 0.3.sh,
              width: 0.8.sw,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: _isInitialized ? 1 : null),
                  SizedBox(height: 10.h),
                  Text(
                    _isInitialized
                        ? CusAL.of(context).initFinished
                        : CusAL.of(context).initializing,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
