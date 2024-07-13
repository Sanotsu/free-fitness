<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
<!-- **Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)* -->

- [开发更新记录](#%E5%BC%80%E5%8F%91%E6%9B%B4%E6%96%B0%E8%AE%B0%E5%BD%95)
  - [2024-07-06](#2024-07-06)
    - [升级 flutter 版本，更新兼容依赖](#%E5%8D%87%E7%BA%A7-flutter-%E7%89%88%E6%9C%AC%E6%9B%B4%E6%96%B0%E5%85%BC%E5%AE%B9%E4%BE%9D%E8%B5%96)
    - [Android 环境配置的修改](#android-%E7%8E%AF%E5%A2%83%E9%85%8D%E7%BD%AE%E7%9A%84%E4%BF%AE%E6%94%B9)
    - [主要修改代码部分](#%E4%B8%BB%E8%A6%81%E4%BF%AE%E6%94%B9%E4%BB%A3%E7%A0%81%E9%83%A8%E5%88%86)
    - [flutter 升级到 3.22 后打包 apk 的体积增加很多](#flutter-%E5%8D%87%E7%BA%A7%E5%88%B0-322-%E5%90%8E%E6%89%93%E5%8C%85-apk-%E7%9A%84%E4%BD%93%E7%A7%AF%E5%A2%9E%E5%8A%A0%E5%BE%88%E5%A4%9A)
  - [2024-07-08](#2024-07-08)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## 开发更新记录

这是无关紧要的东西，记录一些开发过程中的细节，防止以为我忘记了。

### 2024-07-06

#### 升级 flutter 版本，更新兼容依赖

```sh
# 更新flutter
flutter upgrade

# 把 pubspec.yaml 文件里列出的所有依赖更新到 最新的兼容版本
# flutter pub upgrade

# 把 pubspec.yaml 文件里列出的所有依赖更新到 最新的版本
flutter pub upgrade --major-versions

# 自动判断那些过时了的 package 依赖以及获取更新建议，但手动去更新
# flutter pub outdated
```

之前的 flutter 版本是`v3.16.2`，当前 flutter 版本：

```sh
$ flutter --version
Flutter 3.22.2 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 761747bfc5 (4 周前) • 2024-06-05 22:15:13 +0200
Engine • revision edd8546116
Tools • Dart 3.4.3 • DevTools 2.34.3
```

---

<details>
<summary>依赖版本变化:</summary>

```sh
xxx$ flutter pub outdated
Showing outdated packages.
[*] indicates versions that are not the latest available.

Package Name              Current   Upgradable  Resolvable  Latest

direct dependencies:
archive                   *3.4.9    -           3.6.1       3.6.1
cupertino_icons           *1.0.6    -           1.0.8       1.0.8
device_info_plus          *9.1.1    -           10.1.0      10.1.0
file_picker               *5.5.0    -           *5.5.0      8.0.6
fl_chart                  *0.64.0   -           0.68.0      0.68.0
flutter_form_builder      *9.1.1    -           9.3.0       9.3.0
flutter_quill             *8.6.3    -           9.5.6       9.5.6
flutter_quill_extensions  *0.7.1    -           9.5.6       9.5.6
flutter_screenutil        *5.9.0    -           5.9.3       5.9.3
flutter_tts               *3.8.5    -           4.0.2       4.0.2
form_builder_validators   *9.1.0    -           10.0.1      10.0.1
image_picker              *1.0.4    -           1.1.2       1.1.2
intl                      *0.18.1   -           0.19.0      0.19.0
logger                    *2.0.2+1  -           2.3.0       2.3.0
path                      *1.8.3    -           1.9.0       1.9.0
path_provider             *2.1.1    -           2.1.3       2.1.3
pdf                       *3.10.7   -           3.11.0      3.11.0
permission_handler        *11.1.0   -           11.3.1      11.3.1
photo_view                *0.14.0   -           0.15.0      0.15.0
printing                  *5.11.1   -           5.13.1      5.13.1
sqflite                   *2.3.0    -           2.3.3+1     2.3.3+1
table_calendar            *3.0.9    -           3.1.2       3.1.2
wakelock_plus             *1.1.4    -           1.2.5       1.2.5

dev_dependencies:
flutter_lints             *2.0.3    -           4.0.0       4.0.0
No resolution was found. Try running `flutter pub upgrade --dry-run` to explore why.
```

</details>

---

<details>
<summary>实际全部更新了版本:</summary>

```sh
$ flutter pub upgrade --major-versions
Resolving dependencies... (3.4s)
Downloading packages... (1:34.5s)
> archive 3.6.1 (was 3.4.9)
> args 2.5.0 (was 2.4.2)
> barcode 2.2.8 (was 2.2.4)
  collection 1.18.0 (1.19.0 available)
> cross_file 0.3.4+1 (was 0.3.3+7)
> cupertino_icons 1.0.8 (was 1.0.6)
+ dart_quill_delta 9.5.6
> device_info_plus 10.1.0 (was 9.1.1)
> ffi 2.1.2 (was 2.1.0)
  file_picker 5.5.0 (8.0.6 available)
> file_selector_macos 0.9.4 (was 0.9.3+3)
> file_selector_platform_interface 2.6.2 (was 2.6.1)
+ fixnum 1.1.0
> fl_chart 0.68.0 (was 0.64.0)
> flex_seed_scheme 1.5.0 (was 1.4.0) (3.0.0 available)
> flutter_colorpicker 1.1.0 (was 1.0.3)
> flutter_form_builder 9.3.0 (was 9.1.1)
> flutter_inappwebview 6.0.0 (was 5.8.0)
+ flutter_inappwebview_android 1.0.13
+ flutter_inappwebview_internal_annotations 1.1.1
+ flutter_inappwebview_ios 1.0.13
+ flutter_inappwebview_macos 1.0.11
+ flutter_inappwebview_platform_interface 1.0.10
+ flutter_inappwebview_web 1.0.8
> flutter_keyboard_visibility 6.0.0 (was 5.4.1)
> flutter_lints 4.0.0 (was 2.0.3)
> flutter_plugin_android_lifecycle 2.0.20 (was 2.0.16)
> flutter_quill 9.5.6 (was 8.6.3)
> flutter_quill_extensions 9.5.6 (was 0.7.1)
> flutter_screenutil 5.9.3 (was 5.9.0)
> flutter_tts 4.0.2 (was 3.8.5)
> form_builder_validators 10.0.1 (was 9.1.0)
+ freezed_annotation 2.4.2
> gal 2.3.0 (was 2.1.3)
+ gal_linux 0.1.0
+ html2md 1.3.2
> http 1.2.1 (was 1.1.0)
  http_parser 4.0.2 (4.1.0 available)
> image 4.2.0 (was 4.1.3)
> image_picker 1.1.2 (was 1.0.4)
> image_picker_android 0.8.12+3 (was 0.8.8+2)
> image_picker_for_web 3.0.4 (was 3.0.1)
> image_picker_ios 0.8.12 (was 0.8.8+4)
> image_picker_platform_interface 2.10.0 (was 2.9.1)
> intl 0.19.0 (was 0.18.1)
+ irondash_engine_context 0.5.4
+ irondash_message_channel 0.7.0
  js 0.6.7 (0.7.1 available)
+ json_annotation 4.9.0
+ leak_tracker 10.0.4 (10.0.5 available)
+ leak_tracker_flutter_testing 3.0.3 (3.0.5 available)
+ leak_tracker_testing 3.0.1
> lints 4.0.0 (was 2.1.1)
> logger 2.3.0 (was 2.0.2+1)
+ markdown 7.2.2
> matcher 0.12.16+1 (was 0.12.16)
> material_color_utilities 0.8.0 (was 0.5.0) (0.12.0 available)
> meta 1.12.0 (was 1.10.0) (1.15.0 available)
> mime 1.0.5 (was 1.0.4)
> package_info_plus 8.0.0 (was 5.0.1)
> package_info_plus_platform_interface 3.0.0 (was 2.0.1)
> path 1.9.0 (was 1.8.3)
> path_provider 2.1.3 (was 2.1.1)
> path_provider_android 2.2.6 (was 2.2.0)
> path_provider_foundation 2.4.0 (was 2.3.1)
> path_provider_platform_interface 2.1.2 (was 2.1.1)
> pdf 3.11.0 (was 3.10.7)
+ pdf_widget_wrapper 1.0.4
> permission_handler 11.3.1 (was 11.1.0)
> permission_handler_android 12.0.7 (was 12.0.1)
> permission_handler_apple 9.4.5 (was 9.2.0)
> permission_handler_html 0.1.1 (was 0.1.0+1)
> permission_handler_platform_interface 4.2.1 (was 4.0.2)
> permission_handler_windows 0.2.1 (was 0.2.0)
> petitparser 6.0.2 (was 6.0.1)
> photo_view 0.15.0 (was 0.14.0)
+ pixel_snap 0.1.5
> platform 3.1.5 (was 3.1.3)
> plugin_platform_interface 2.1.8 (was 2.1.6)
> printing 5.13.1 (was 5.11.1)
> simple_gesture_detector 0.2.1 (was 0.2.0)
+ sprintf 7.0.0
> sqflite 2.3.3+1 (was 2.3.0)
> sqflite_common 2.5.4 (was 2.5.0)
+ super_clipboard 0.8.17
+ super_native_extensions 0.8.17
> synchronized 3.1.0+1 (was 3.1.0)
> table_calendar 3.1.2 (was 3.0.9)
> test_api 0.7.0 (was 0.6.1) (0.7.3 available)
> url_launcher 6.3.0 (was 6.2.1)
> url_launcher_android 6.3.3 (was 6.2.0)
> url_launcher_ios 6.3.0 (was 6.2.1)
> url_launcher_linux 3.1.1 (was 3.1.0)
> url_launcher_macos 3.2.0 (was 3.1.0)
> url_launcher_platform_interface 2.3.2 (was 2.2.0)
> url_launcher_web 2.3.1 (was 2.2.1)
> url_launcher_windows 3.1.1 (was 3.1.0)
+ uuid 4.4.0
> video_player 2.9.1 (was 2.8.1)
> video_player_android 2.5.2 (was 2.4.10)
> video_player_avfoundation 2.6.1 (was 2.5.2)
> video_player_platform_interface 6.2.2 (was 6.2.1)
> video_player_web 2.3.1 (was 2.1.2)
+ vm_service 14.2.1 (14.2.4 available)
> wakelock_plus 1.2.5 (was 1.1.4)
> wakelock_plus_platform_interface 1.2.1 (was 1.1.0)
> web 0.5.1 (was 0.3.0)
> win32 5.5.1 (was 5.0.9)
> win32_registry 1.1.3 (was 1.1.2)
> xdg_directories 1.0.4 (was 1.0.3)
> xml 6.5.0 (was 6.4.2)
+ youtube_explode_dart 2.2.1
> youtube_player_flutter 9.0.1 (was 8.1.2)
These packages are no longer being depended on:
- convert 3.1.1
- flutter_animate 4.2.0+1
- pasteboard 0.2.0
- pointycastle 3.7.3
Changed 113 dependencies!
11 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.

Changed 9 constraints in pubspec.yaml:
  intl: ^0.18.0 -> ^0.19.0
  form_builder_validators: ^9.0.0 -> ^10.0.1
  fl_chart: ^0.64.0 -> ^0.68.0
  flutter_quill: ^8.6.1 -> ^9.5.6
  flutter_quill_extensions: ^0.7.0 -> ^9.5.6
  flutter_tts: ^3.8.5 -> ^4.0.2
  device_info_plus: ^9.1.1 -> ^10.1.0
  photo_view: ^0.14.0 -> ^0.15.0
  flutter_lints: ^2.0.0 -> ^4.0.0
```

</details>

---

<br/>

#### Android 环境配置的修改

**1** 因为依赖更新，`this project's minSdk version to at least 23`。

对应 Flutter Fix 内容有 `The plugin super_native_extensions requires a higher Android SDK version.`

**所以修改 `android/app/build.gradle`中 `minSdkVersion 23`**

**2** 而`:device_info_plus:compileDebugJavaWithJavac`需要 JDK17，

所以在`android/gradle.properties`中添加 jdk17 的地址：

```
org.gradle.java.home=/home/david/.jdks/temurin-17.0.6
```

**3** 错误日志有 [applying-flutters-app-plugin-loader-gradle-plugin](https://stackoverflow.com/questions/78032396/applying-flutters-app-plugin-loader-gradle-plugin-imperatively-using-the-apply-s)

参看官方文档[Deprecated imperative apply of Flutter's Gradle plugins](https://docs.flutter.dev/release/breaking-changes/flutter-gradle-plugin-apply) 进行修改:

依次修改以下 3 个文件:

```sh
android/settings.gradle
android/build.gradle
android/app/build.gradle
```

<br/>

#### 主要修改代码部分

- 1 **在异步函数中对 context 进行修改**。

之前是：

```dart
if (!mounted) return;
Navigator.of(context).pop();
```

现在是：

```dart
if (!context.mounted) return;
Navigator.of(context).pop();
```

注意：并不是所有 mounted 都要这样修改的，注意是**State 的 context 属性**还是**BuildContext 实例**。

参看：[use_build_context_synchronously](https://dart.dev/tools/linter-rules/use_build_context_synchronously)

- 2 **弃用的类`MaterialStateProperty` 和 `MaterialState`**

对应改成`WidgetStateProperty` 和 `WidgetState` 即可。

- 3 一些 `Unnecessary use of 'toList' in a spread.Try removing the invocation of 'toList'.`

- 4 一些以`///`开头的文件会提示`Dangling library doc comment.Add a 'library' directive after the library comment.`

- 5 一些`Convert 'key' to a super parameter.`

- 6 **fl_chart 0.64.0 升级到 0.68.0**

参看[changelog](https://github.com/imaNNeo/fl_chart/blob/main/CHANGELOG.md#0670)

原本的 `tooltipBgColor: Colors.blueGrey,`

改为了 `getTooltipColor: (_) => Colors.blueGrey,`

- 7 **flutter_tts 3.8.5 升级到 4.0.2**

参看[changelog](https://github.com/dlutton/flutter_tts/blob/master/CHANGELOG.md#fixes-2) 和 [441 合并请求](https://github.com/dlutton/flutter_tts/pull/441) 以及[issues 407](https://github.com/dlutton/flutter_tts/issues/407)

原本代码中的:

```dart
if (isAndroid) {
    flutterTts.setInitHandler(() {
        setState(() {
            print("TTS Initialized");
        });
    });
}
```

直接移除即可。

- 8 **flutter_quill 8.6.1 升级到 9.5.6**

相关的扩展也从`0.7.0`升级到了`9.5.6`。

[v8 到 v9 的升级文档](https://github.com/singerdmx/flutter-quill/blob/master/doc/migration/8_9.md)

之前 8.6.1：

```dart
QuillProvider(
    configurations: QuillConfigurations(
    controller: _controller,
    ……
    child: Column(...)
)
```

现在 9.5.6 移除了 QuillProvider，直接使用工具栏和编辑器即可，具体参看[富文本编辑组件](lib/views/diary/diary_modify_rich_text.dart)的相关代码。

之前编辑器 QuillEditor 有 readOnly 属性，现在是在 ` _controller.readOnly = !isEditing;` 设定了，所以在改动是否可以编辑的地方，修改控制器的只读属性。

#### flutter 升级到 3.22 后打包 apk 的体积增加很多

我看 0.0.1-beta 的时候，只有不到 18M，但升级到 3.22 后打包就到了 将近 37M。使用以下命令查看:

```sh
flutter build apk --target-platform android-arm64 --analyze-size
```

得到结果:

<details>
<summary>分析 flutter 的 apk 打包体积:</summary>

```sh
Running Gradle task 'assembleRelease'...                          523.0s
✓ Built build/app/outputs/flutter-apk/app-release.apk (36.6MB)
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
app-release.apk (total compressed)                                         35 MB
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  META-INF/
    CERT.SF                                                                20 KB
    CERT.RSA                                                                1 KB
    MANIFEST.MF                                                            17 KB
  assets/
    dexopt                                                                  1 KB
    flutter_assets                                                          6 MB
  classes.dex                                                               2 MB
  lib/
    arm64-v8a                                                              24 MB
    Dart AOT symbols accounted decompressed size                           13 MB
      package:flutter                                                       4 MB
      package:free_fitness                                                  1 MB
      package:image                                                       805 KB
      package:flutter_quill                                               682 KB
      package:flutter_localizations                                       412 KB
      dart:core                                                           332 KB
      package:pdf                                                         265 KB
      package:html                                                        246 KB
      dart:typed_data                                                     238 KB
      dart:ui                                                             227 KB
      package:bidi/
        bidi.dart                                                         219 KB
      package:fl_chart                                                    209 KB
      dart:collection                                                     189 KB
      dart:io                                                             174 KB
      dart:async                                                          138 KB
      package:archive                                                     111 KB
      package:intl                                                         89 KB
      package:youtube_explode_dart                                         89 KB
      package:xml                                                          83 KB
      package:flutter_quill_extensions                                     74 KB
    armeabi-v7a                                                           953 KB
    x86_64                                                                  1 MB
  AndroidManifest.xml                                                       3 KB
  res/
    33.9.png                                                                2 KB
    CG.png                                                                  4 KB
    D2.png                                                                  3 KB
    ER.9.png                                                                2 KB
    FM.9.png                                                                1 KB
    J6.9.png                                                                2 KB
    Mr.9.png                                                                1 KB
    Pi.9.png                                                                3 KB
    Q11.9.png                                                               3 KB
    SD.png                                                                  2 KB
    Vq.png                                                                  1 KB
    color-v23                                                               2 KB
    color                                                                   2 KB
    e1.xml                                                                  1 KB
    eB.9.png                                                                2 KB
    gV.9.png                                                                1 KB
    jy.png                                                                  2 KB
    tj.9.png                                                                2 KB
    u3.png                                                                  1 KB
    wi.9.png                                                                2 KB
    wi1.9.png                                                               1 KB
  resources.arsc                                                          317 KB
  kotlin/
    collections                                                             1 KB
    kotlin.kotlin_builtins                                                  5 KB
    ranges                                                                  1 KB
    reflect                                                                 1 KB
  org/
    apache                                                                  5 KB
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
A summary of your APK analysis can be found at: /home/david/.flutter-devtools/apk-code-size-analysis_08.json

To analyze your app size in Dart DevTools, run the following command:
dart devtools --appSizeBase=apk-code-size-analysis_08.json
```

</details>

得到了类似`/home/david/.flutter-devtools/apk-code-size-analysis_08.json`的分析文件后，假如使用的是 VSCode，就在“查看”->“命令面板”，输入"devtool"，找到“Flutter: Open DevTools”，找到打开开发工具的位置。

我是在网页打开，然后点击网页上方的“App Size”按钮，把刚刚的`apk-code-size-analysis_08.json`打开，分析 apk 的体积问题。

而这个体积增加的问题，参看 stackoverflow 的 [Flutter App Size İncrease Too much after Updating Dependencies](https://stackoverflow.com/questions/78550965/flutter-app-size-%C4%B0ncrease-too-much-after-updating-dependencies) 问题。

**在`android/app/build.gradle` 的`android`对应配置中添加以下代码(没有就新增)**：

```gradle
android {
    packagingOptions {
        jniLibs {
            useLegacyPackaging true
        }
    }
}
```

此时 3 个体积的变化为:

- 0.0.1.bata：17.7M
- 升级到 flutter 3.22 默认： 36.6M
- 升级到 flutter 3.22 打包压缩的原生库：19.7M

<details>
<summary>压缩后分析 flutter 的 apk 打包体积:</summary>

```sh
Running Gradle task 'assembleRelease'...                          469.4s
✓ Built build/app/outputs/flutter-apk/app-release.apk (19.7MB)
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
app-release.apk (total compressed)                                         19 MB
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  META-INF/
    CERT.SF                                                                20 KB
    CERT.RSA                                                                1 KB
    MANIFEST.MF                                                            17 KB
  assets/
    dexopt                                                                  1 KB
    flutter_assets                                                          6 MB
  classes.dex                                                               2 MB
  lib/
    arm64-v8a                                                              10 MB
    Dart AOT symbols accounted decompressed size                           13 MB
      package:flutter                                                       4 MB
      package:free_fitness                                                  1 MB
      package:image                                                       805 KB
      package:flutter_quill                                               682 KB
      package:flutter_localizations                                       412 KB
      dart:core                                                           332 KB
      package:pdf                                                         265 KB
      package:html                                                        246 KB
      dart:typed_data                                                     238 KB
      dart:ui                                                             227 KB
      package:bidi/
        bidi.dart                                                         219 KB
      package:fl_chart                                                    209 KB
      dart:collection                                                     189 KB
      dart:io                                                             174 KB
      dart:async                                                          138 KB
      package:archive                                                     111 KB
      package:intl                                                         89 KB
      package:youtube_explode_dart                                         89 KB
      package:xml                                                          83 KB
      package:flutter_quill_extensions                                     74 KB
  AndroidManifest.xml                                                       3 KB
  res/
    33.9.png                                                                2 KB
    CG.png                                                                  4 KB
    D2.png                                                                  3 KB
    ER.9.png                                                                2 KB
    FM.9.png                                                                1 KB
    J6.9.png                                                                2 KB
    Mr.9.png                                                                1 KB
    Pi.9.png                                                                3 KB
    Q11.9.png                                                               3 KB
    SD.png                                                                  2 KB
    Vq.png                                                                  1 KB
    color-v23                                                               2 KB
    color                                                                   2 KB
    e1.xml                                                                  1 KB
    eB.9.png                                                                2 KB
    gV.9.png                                                                1 KB
    jy.png                                                                  2 KB
    tj.9.png                                                                2 KB
    u3.png                                                                  1 KB
    wi.9.png                                                                2 KB
    wi1.9.png                                                               1 KB
  resources.arsc                                                          317 KB
  kotlin/
    collections                                                             1 KB
    kotlin.kotlin_builtins                                                  5 KB
    ranges                                                                  1 KB
    reflect                                                                 1 KB
  org/
    apache                                                                  5 KB
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
A summary of your APK analysis can be found at: /home/david/.flutter-devtools/apk-code-size-analysis_09.json

To analyze your app size in Dart DevTools, run the following command:
dart devtools --appSizeBase=apk-code-size-analysis_09.json
```

</details>

### 2024-07-08

- feat:添加了 dio http client 的自定义封装；添加在“饮食”-“饮食日记”页面中“AI 对话助手”功能。

### 2024-07-12

- fix:修正较新版本 Android 下存储权限未正常获取的问题.
- feat:添加了对饮食模块下“餐食相册”和“饮食日记”页面中指定餐次的食物图片，进行“AI 分析”的功能。

#### 餐食相册的备份还原

问题描述：

- 因为餐次的照片的上传是使用`FormBuilderFilePicker`实现的，底层是`file_picker`，实际是把图片缓存到了该库默认的位置，类似`/data/user/0/com.swm.free_fitness/cache/file_picker/菜品识别1.jpg`；
- 所以在重新安装 app，再恢复饮食日志的时候，餐次图片的地址就是上述缓存的位置；
- 但由于卸载了 app，应用缓存的数据都丢了，也就无法再看到餐次图片了，那这个图片地址的备份实际没有作用了；
  - 当然，食物摄入量等其他信息不受影响。

TODO 思路：

- 第一种：
  - 上传时，把图片文件存入 db；
  - 展示、备份恢复等直接处理图片文件数据
- 第二种：
  - 上传时，依旧把图片放到`FormBuilderFilePicker`的默认到缓存中；
  - 备份时，把图片文件从缓存中获取(比如存为单独的图片 zip)，连同 db 中的其他导出的 json 数据一起备份到压缩包；
  - 恢复时，把图片放到缓存路径，然后把 json 数据中的图片地址替换为缓存路径；
- 第三种(预计使用这种**就跟导入基础动作的图片一样**，但同样的问题有 2：1 权限、2 直接在文件管理器中误删)：
  - 上传时，把图片放到外部路径，卸载 app 不删除图片缓存；
  - 展示、备份恢复等使用外部存储的路径；
  - 现在上传的餐食图片会保留在`/storage/emulated/0/FREE-FITNESS/MealPhotos`，应用卸载后该位置的图片也不会被删除。

### TODO

- i18n 的中英文不全，很多地方使用的是` box.read('language') == "en" ? "AI analysis" : 'AI分析',`投机方式，如果系统就是英文那显示的还是中文。
