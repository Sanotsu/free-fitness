# 说明

Free Fitness，一个使用 flutter 开发的、包含运动健身训练和日常饮食记录的 app。

## 功能列表(todo)

unclear

## 开发进度

2023-10-12

- 初始步骤，完成大体的页面功能的布局框架和项目文件夹结构。

2023-10-14

在使用 file_picker 的时候有卡住，看 flutter run -v 之后，看到是在

```
C:\Users\swmlee\AppData\Local\Pub\Cache\hosted\pub.flutter-io.cn\flutter_plugin_android_lifecycle-2.0.16\android\build.gradle
```

中的

```
buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath 'com.android.tools.build:gradle:7.2.1'
    }
}

rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

所以同样和项目中的`android\build.gradle`改为国内镜像即可

```
repositories {
        // google()
        // mavenCentral()
        maven {
            url 'https://maven.aliyun.com/repository/public/'
        }
        maven {
            url 'https://maven.aliyun.com/repository/central/'
        }
        maven {
            url 'https://maven.aliyun.com/repository/google/'
        }
        maven {
            url 'https://maven.aliyun.com/repository/gradle-plugin/'
        }
    }
```

2023-10-15 进度

完成都是初稿，知道功能怎么做而已：
暂时完成“基础活动”的创建，已经“动作库”主页的基本信息卡片显示
暂时完成 card 右滑可删除（删除的逻辑细节没做，比如只有创建者才能删除，这个可以在控制是否可以删，不用等滑动时才判断）

明天预计：
基础活动的条件查询，每次显示 10 条，滚动加载更多
点击 card 跳转的详情页面

2023-10-16 进度

exercise 基础数据库新增标准动作耗时栏位 standard_duration，并修改相关逻辑。

2023-10-18 进度

exercise 的条件查询表单雏形有了

明天要做:

- done 2023-10-21 exercise 页面条件查询可以分页，上拉加载新一页。
- done 2023-10-19 查询条件重置，如果还显示的“更少”，重置的时候在“更多”时选择的条件还会保留住。
  - X 方案:重置时先把查询条件还原到最小的样子,此时因为高级查询表单栏位没绘制,已经时默认值了,所以重置时也不需要重置高级选项.
    - 不行,折叠之后高级查询没有渲染,但值还在,重置 reset'didChange(null)都没用...
- done 2023-10-18 要显示总数量
- done 2023-10-18 许多 setState 中的查询，没有带上查询条件，如果用户有传，则需要带上，初始化时默认可以没有。
- done 2023-10-21 卡片详情页。

showModalBottomSheet()的默认高度上限是 9/16，需要设置设置滚动控制为 true`isScrollControlled: true,`才能自定义更高。

参看：https://blog.csdn.net/qq_42351033/article/details/125180767

2023-10-19 进度

修复:exercise query 组件因为 expended 和 SingleChildScrollView 层级关系不对导致的布局错误
简单调整 exercise 查询表单的按钮布局（折叠后重置高级选项选中的值目前没法做到）

明日注意，exercise 的查询和新增的 db 操作都有问题，模糊查询不对、分页查询没做，新增肌肉数据格式不对，没有分隔符。

2023-10-19

完成 饮食模块主要布局的修改
完成 饮食模块相关的数据库创建和常规的 sql 语句，对应的类等。
完成 食物列表显示、详情页、新增页的示例。

2023-10-22

注意：pubspec.yaml 在配置 assets 路径时，没有办法统配文件夹，每个子文件夹都得加一个配置：
https://flutter.cn/docs/development/ui/assets-and-images#specifying-assets

完成 exercise 详情弹窗的基本结构和内容

待完成：

(done 2023-10-23) exercise 详情弹窗中，点击图片后，再弹出一个放大图片看细节。

exercise 详情页内容可以更丰富一点，毕竟很多栏位都没显示出来。

- (done 2023-10-23) 或者显示一个【更多信息】按钮，跳转的一个新页面，在新页面还可以加【修改】按钮，也没有篇幅限制。

考虑是不是有个批量导入预设动作列表的功能，例如预设好 json 或者 excel 表格，除了图片批量导入。及时有图片，网络图片可以直接加载，**本地图片这里再解析去找然后放到缓存文件夹？**--这个比较麻烦。

在 exercise 详情弹窗，添加【修改】按钮，点击跳转到修改页面，修改完成返回的主页面。

- 这其实有两个问题：1 是没有其他地方可以用来触发修改了，因为 list 中使用了 Dismissible 去包裹它。
- 2 是修改完如果只返回修改后的那一条（查询 exercise_id），重新查询时候条件不好重置.
  - 修改完也不可能返回到之前的详情弹窗取，因为还是需要重新查询，而查询不在详情页中。
- 这个和新增应该是同一个表单，新增完成返回 list 同样没有定位到新增的那一条。

2023-10-23

完成：基本的在 exercise detail 弹窗中显示更多袭击的 exercise detail more 页面布局(**细节一塌糊涂**)。

待完成：同时加一个修改按钮和表单跳转（不放在 detail more 中，不然嵌套太深了。但是也可能应该在 detail more 中跳转才合理。先完成功能，后续从哪里跳在说）

基本完成：在 exercise detail 弹窗中有个修改按钮，点击跳转到修改表单

- （done 2023-11-05）还有问题：跳转到修改表单后，没有正确带上已有的主要肌肉和次要肌肉的信息---
