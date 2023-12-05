<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
<!-- **Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)* -->

- [(旧的内容，问题和进度记录先不看了)](#%E6%97%A7%E7%9A%84%E5%86%85%E5%AE%B9%E9%97%AE%E9%A2%98%E5%92%8C%E8%BF%9B%E5%BA%A6%E8%AE%B0%E5%BD%95%E5%85%88%E4%B8%8D%E7%9C%8B%E4%BA%86)
- [新的记录(以此份优先)](#%E6%96%B0%E7%9A%84%E8%AE%B0%E5%BD%95%E4%BB%A5%E6%AD%A4%E4%BB%BD%E4%BC%98%E5%85%88)
  - [之前的未完成的问题和细节](#%E4%B9%8B%E5%89%8D%E7%9A%84%E6%9C%AA%E5%AE%8C%E6%88%90%E7%9A%84%E9%97%AE%E9%A2%98%E5%92%8C%E7%BB%86%E8%8A%82)
  - [dietary 功能的 todo](#dietary-%E5%8A%9F%E8%83%BD%E7%9A%84-todo)
  - [进度记录](#%E8%BF%9B%E5%BA%A6%E8%AE%B0%E5%BD%95)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

2023-10-26 起来在这里更新 dietary 的进度，避免合并冲突

## (旧的内容，问题和进度记录先不看了)

饮食日记设计思路记录

- 1、直接点击左上角的搜索，则默认是为“早餐”添加食物摄入 item。
  - 如果该日“早餐”已有 item：查询已有的 meal，直接新增 item；如果没有：新增 meal，新增 item。
  - 如果直接在搜索主页面点击添加指定食物，食物摄入 item 的量就是预设的量(就算添加成功，也可以到食物详情页面去修改)
  - 如果搜索到食物之后点击，进入详情页面，可以修改食物份量和单位，然后“保存”或“移除”
    - 如果不添加了，直接返回按钮；移除应该是在主页面直接点击了某一餐的 item 只会跳转的详情页面使用的。
    - 所以显示的按钮：
      - 移除、添加(保存)
- 2、在主页面选中“早中晚夜”各自 tab 的“+”添加按钮，操作和上一步一样，除了对应的餐次。
- 3、可以记录早中晚夜餐次最近的食物及其份量，可以在 meal 表中添加该 meal 属于早中晚夜的哪一顿，或者直接到 meal food item 中新增栏位来标识属于早中晚夜哪一餐的摄入。
  - 或者大改数据库，早中晚夜 4 餐，4 张表，在 daily log 的 4 个栏位分别指定对应其中一个表的数据，关联查询和查询指定内容可能会方便点。
    - 但也只是把 meal 表分成 3 个而已。
  - 如果都不改数据库表的话，查询早中晚夜餐次最近摄入记录的话，直接查询 daily loy 表，指定早中晚夜 meal id，在 date 的最近 7 天能够带出指定 meal 中的那些 meal food item 即可。

基本完成 饮食记录的首页显示以及该日记录和细节栏位的数据库查询函数。

2023-10-27

基本完成 在饮食日记主页面点击“早中晚夜”餐次新增 item 按钮时，跳转到 food list 页面，并在 food list 页面直接添加预设单份食物的值。

删除了一些查询饮食日记的 db helper 方法（因为嵌套太多，这个方法不是很好写，但大体能用，要优化的点还比较多……）

(done) 待完成 饮食记录主页面没有日期选择器来指定添加不同日期饮食记录  
待完成 主页面的显示完全没有对应的细节，只是说能找到对应的数据了  
待完成 在 food list 页面只能新增单个，且点击新增、完成新增之后没有返回到主页面，手动返回主页面也没有刷新当日日记的数据。

(基本 done) 完全没开始做 进入 foodlist 之后，点击查询结果的食物进入 food detail，然后再修改数量、单位，加入日记餐次列表。

**【日记餐次条目的处理逻辑】**：
-- `2023-10-31 数据库结构改动，此处逻辑完全变化`

- 1、删除：左右滑动即可
- 2、修改：在主页面点击进入详情页，可以修改数量、单位、和 **【餐次】**。
  - 数量和单位还好，直接修改 db 中对应 meal food item 的 food_intake_size 和 serving_info_id 栏位而已；
  - 但是修改餐次就比较麻烦了（**偏向于先不加这个功能，修改餐次直接删除该条目换个餐次新增**）：
    - 首先 要把修改后的 meal food item 添加到新的 meal：
      - 如果新的餐次没有数据：新增 meal 和 item，绑定到 log 对应餐次（因为是修改，当日的 log 一定存在）；
      - 新的餐次有数据：查询 meal 取得 meal id，修改 item 再添加；
    - 其次 要删除旧的餐次的该条 item 数据：
      - 如果删除该 item 之后该餐次还有其他 item，该 item 删除完就完了；
      - 如果删除该 item 之后还餐次没有其他 item，则删除该 meal，再删除该 meal 对应的 log 中的餐次；
- 3、新增：
  - 大概流程：
    - 点击在主页面对应餐次的右侧按钮（或者顶部的搜索按钮，默认为新增到早餐），进入 food list 搜索页面。
    - 在 food list 中再点击需要添加的食物，进入 food detial 页面。
    - 在 food detail 中修改数量、单位、和 **【餐次】**。
  - 问题：
    - 在涉及餐次时和“修改”有点类似，要先查询要移动到的目标餐次有没有数据（没有要移除旧的）
      - 目标餐次有 item，获取该餐次的 meal id 直接新增 item 即可；
      - 目标餐次没有 item，新增 meal，新增 item，
        - 如果连 log 都还没有，还再新增 log，再绑定其餐次的 meal id；
        - 如果有 log，则直接绑定其餐次的 meal id；

条目调到详情页的区分(可用来判断显示不同的按钮)：

- 主页面点击条目 -> 跳转到详情；
- 主页面点击添加 -> 调到食物搜索页面，食物列表选择某一个食物 -> 跳转到详情；

2023-10-30 暂存

pause: log index 和 food list 点击跳转到 food detail 的逻辑有了，但发现了更优的 serving info 的数据库设计，所以暂停目前的内容，修改新的数据库设计。

基本完成: 修改了数据库表 serving_info 的栏位设计，并修改了目前涉及到的所有逻辑部分（主要是 food detail 营养素展示部件）

2023-10-31 暂存

pause：修改旧的某一天某一餐次的条目，需要从早餐移到晚餐非常麻烦，然后重新思考了一下数据库结构，发现被“一天饮食记录只存一条数据”的想法限制住了，所以重新修改数据库，删除原本的 meal 和 meal food item，直接把把一餐的每一个食物摄入留存记录，原本`log-meal-item 1：（4*1）：N` 的设计，直接 `daily_food_item` 一个表搞定，以空间换时间。

注意：巨大结构改动，大量已经完成的功能会被修改

2023-11-01

基本完成：饮食记录数据库结构和栏位的设计，并更新了相关代码
基本完成：log index 添加饮食日记条目，先到 food list，再到 food detail，点击返回后直接回到 log index，并刷新 log index 页面

- 注意：这里参考了 stackoverflow 的 [Flutter - Pass Data Back with .popUntil](https://stackoverflow.com/questions/52075130/flutter-pass-data-back-with-popuntil) 想 popUntil 时带上参数进行刷新，但是没有成功，获取不到返回的数据。
  - popUntil 带返回值的需求一直有，但没有提供，参看[issue](https://github.com/flutter/flutter/issues/30112)。
  - 目前返回上上层并刷新其页面的实现最简单如下(都不用使用命名路由)：
  ```dart
  Navigator.of(context)
        ..pop()
        ..pop(true);
  Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DietaryRecords()),
      );
  ```

2023-11-02

基本完成：log index 滑动移除饮食日记条目，log index 点击 item 进入 food detail 中移除条目。

(done) 待完成：新增食物和食物单份营养素的表单页面

(done) 待完成：饮食记录主页的日期选择器

- 基本完成 2023-11-02
- done 2023-11-02（命名路由 RouteSetting 传参）【存在问题】，切换了日期再进入 food list 或者 food detail 之后返回主页面，日期会被重置为今天，因为是整个重新加载部件而不是指定更新状态。
  - 无法 setstate 是因为跨级返回时(log index - food list - food detail 返回)无法带参数，这个找办法。

待完成：饮食记录主页的显示，和饮食数据的多种展示方式（精简、具体……）

待完成：导出饮食记录(这个功能靠后)

考虑：一个导入表格或者 json 文件的接口，一次性导入多个食物及其各项单份营养素信息

2023-11-03

基本完成：新增食物带上单份营养素的表单

- 还有问题：
  - 1 没有单位 (done 2023-11-06)
  - 2 没有限制只能输入数据 (done 2023-11-06)
  - 3 品牌和名称唯一的报错处理 (done 2023-11-06)

2023-11-06

基本完成 新增食物带上单份营养素的表单（查一些显示的细节优化了）

## 新的记录(以此份优先)

### 之前的未完成的问题和细节

1. 待完成 主页面的显示完全没有对应的细节，只是说能找到对应的数据了(没有概要视图、详细视图等切换)
   - 即饮食记录主页的显示，和饮食数据的多种展示方式（精简、具体……）
2. 在 food list 页面只能新增单个食物（是否需要一个食物基本信息页面维护食物和营养素信息）
3. 待完成：导出饮食记录(这个功能靠后)
4. 考虑：一个导入表格或者 json 文件的接口，一次性导入多个食物及其各项单份营养素信息

### dietary 功能的 todo

- 【2023-11-09 明确的待完成】
  - 范围为上周、本周时，要显示 7 条的条状图和目标虚线，以及对应表格数据，没做。
  - 当天或者当周无数据时，应该有个空白占位，目前就只显示了表格标题和 NaN 的图例。
  - 个人配置 RDA 和每日营养素目标的功能
  - 添加每日每餐食物条目，可以上传图片
  - **饮食报告导出和食物营养素文件导入是个大工程**

#### 个人配置

- 个人信息页面
- 目标配置
- 体重输入，折线图

### 进度记录

- 2023-11-07
  - 基本完成饮食日记的主页的显示布局效果
- 2023-11-08
  - 饮食日记的主页添加三大营养素的饼状图和摄入量列表
- 2023-11-09
  - 基本完成饮食记录报告模块中选中今天、昨天时，卡路里 tabview 中的饼图和食物摄入表格的内容。
  - 基本完成饮食记录报告模块中选中今天、昨天时，宏量素 tabview 中的饼图和食物摄入表格的内容。
  - 营养素 tabview 占位有了，但因为要和摄入目标对比，暂时没有摄入目标功能，所以只是占位。
- 2023-11-13
  - 基本完成 dietary 设置页面的个人基本信息修改功能。
- 2023-11-14
  - 基本完成 dietary 设置页面的营养素目标设定的功能。
- 2023-11-15
  - 基本完成 dietary 设置页面的每日营养素目标条状图。
  - 重构了饮食记录报告中卡路里和宏量素 tabview 中饼图和表格的设计，并添加了切换到上周本周时显示条状图。

tobed: 目标卡路里折线图是实际摄入的条状图放到一起？

- 2023-11-22

  - dev_ubt 下 flutter 升级到了 3.16.0, WillPopScope 将被弃用，【目前迁移工作还没做】。
  - 2023-11-23 已处理

- 2023-11-23

  - 完成手记用富文本组件进行新增、编辑、预览的初版。

- 2023-11-24

  - 添加了手记日历，基本完成整个'手记'模块的初始功能。
  - 同时添加了插入随机手记的测试数据。

- 2023-11-27

  - 修复了手记富文本编辑页面 textField 和 quillEditor 聚焦冲突的问题；修正了手记编辑页面的细节，移除了一些备用组件代码。
  - 添加了手机时间线展示页面(背景色没有调得比较好看)
  - 2023-11-27 修复小问题：手记进入编辑页面后，返回主页没有重新加载。

**饮食记录报告的导出？数据库的导出？图片怎么保存和导出？**

**我的设置页面还没搞，待运动完成后，各项配置、报告导出、照片等都要放在这里**

- 2023-11-29

  - 完成"运动"模块的训练跟练的 tts 功能雏形。
  - 完成 [yuhonas/free-exercise-db](https://github.com/yuhonas/free-exercise-db)格式的 json 文件导入的功能，并修改了图片显示组件。

- 2023-11-30

  - 完善动作和食物营养素 json 文件导入页面的细节，修复 json 文件解析未正确解析的问题。
  - 将所有锻炼动作展示本地图片使用轮播组件以便展示多张图;设置在跟练页面时屏幕保持常亮。

- 2023-12-05
  - 重构了饮食记录中设计食物选择部分的组件结构，完成食物成分模块的食物详情基本页面和新增食物的相关表单页面。
  - 完成饮食日志首页跳转的日历统计概述报告页面。

### 问题记录

1. 同样的 Text()大小的中英文看起来不在一条线上。

原因：

- 中文和英文字体默认的 leading 不一样。
- StrutStyle 的 leading 属性是指字体的倍数，比如：0.5 就是 0.5\*字体的高度,而且这个高度要分成两半，上下各分一半。

解决方法：

Text()中设置 leading 属性，如下

```dart
  TableCell(child: Text('蛋白质')),
  TableCell(
    child: Text(
      'RDA',
      strutStyle: StrutStyle(
        forceStrutHeight: true,
        leading: 0.5,
      ),
    ),
  ),
```

参看：

- https://blog.csdn.net/gaoyp/article/details/122121739
- https://stackoverflow.com/questions/56799068/what-is-the-strutstyle-in-the-flutter-text-widget

---

2. 命名路由的寻找顺序

```sh
Make sure your root app widget has provided a way to generate this route.
Generators for routes are searched for in the following order:
 1. For the "/" route, the "home" property, if non-null, is used.
 2. Otherwise, the "routes" table is used, if it has an entry for the route.
 3. Otherwise, onGenerateRoute is called. It should return a non-null value for any valid route not handled by "home" and "routes".
 4. Finally if all else fails onUnknownRoute is called.
Unfortunately, onUnknownRoute was not set.
```

3. ListTile 的 leading/trailing 无法设置高度

截止到 2023-11-20 时，组件还是默认限制了高度 48/56，目前无法修改。

参看 issue: https://github.com/flutter/flutter/issues/98178

4. 下方 BottomNavigationBar 的 item 超过 4 个后，背景色消失

解决: 给他指定类型 : type: BottomNavigationBarType.fixed,

参看： https://blog.csdn.net/weixin_46005137/article/details/107049867

5. 好像是 flutter 更新到 3.16.0 后 AppBar 背景色消失

解决：因为 3.16 主题默认启用 material3,手动修改为 false 即可。

```dart
MaterialApp(
   theme: ThemeData(
        primarySwatch: Colors.blue,
        // ？？？2023-11-22：升级到flutter 3.16 之后默认为true，现在还没有兼容修改部件，后续再启用
        useMaterial3: false,
    ),
    // ……
)
```

6. 【unsolved】2023-11-22 不知道什么原因，使用 formbuilder 构建文本输入框，一定是安全键盘，无法切换。即便手动设置`keyboardType: TextInputType.text,`也不行。原因不明

但是使用自带的 TextField 就不会有这个问题。

2023-12-04,无法解决，MIUI 什么的可以关闭安全键盘，这样打开后还是英文输入法，但可以切成中文；如果没关安全键盘，则一定弹出小米安全键盘，无法输入中文。

但 FormBuilderTextField 的 keyboardType 改为"`TextInputType.number`"它就是正常键盘的数字键而已，就不会弹安全键盘，原因不明。

**改为`keyboardType: TextInputType.name`可以启用正常键盘。**

7. Chip 部件的默认高度

对于 chip 也有设置默认 MaterialTapTargetSize.padded, 也就是说 chip 有个最小高度 48px。

所以为了缩小尺寸，可以修改为 MaterialTapTargetSize.shrinkWrap ,这将移除额外的空间。

参看：https://stackoverflow.com/questions/51440984/how-to-adjust-the-size-of-a-chip-in-flutter.

8. 【unsolved】2023-11-25 一个很严重的 bug：在手记修改页面，标题或者标签的文本输入框中是编辑状态，打开了键盘，点击收起键盘之后，又会立马聚焦到输入框，然后弹出键盘，重复收起又弹窗很多次键盘后，才会不自动聚焦到输入框。

同样，只要点击了这两个输入框进行文本修改，再点击 rich text 修改正文也无法聚焦，要重复点击多次，鼠标跳过去了，但完成 rich text 编辑收起键盘，还是会聚焦到标题或者标签的文本输入框去，然后弹出键盘。再点击收起又弹出多次，才失去焦点。

文本输入框换成 Formbuilder 的也一样，**原因不知**。

有可能是类似这个 issue: https://github.com/flutter-form-builder-ecosystem/flutter_form_builder/discussions/1297

9. 【unsolved】2023-12-02 image_gallery_saver 保存图片时报错，3.13 有升级到 3.16.0

表现和 https://stackoverflow.com/questions/69883867/flutter-unhandled-exception-missingpluginexceptionno-implementation-found-f
差不多。

后来找了很多方法，肯定不是权限问题，初步分析是在 Android9 上无法正常工作了，后续用更高级的 Android 版本的试一下。
