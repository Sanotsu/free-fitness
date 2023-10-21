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

- exercise 页面条件查询可以分页，上拉加载新一页。
- done 2023-10-10 查询条件重置，如果还显示的“更少”，重置的时候在“更多”时选择的条件还会保留住。
  - X 方案:重置时先把查询条件还原到最小的样子,此时因为高级查询表单栏位没绘制,已经时默认值了,所以重置时也不需要重置高级选项.
    - 不行,折叠之后高级查询没有渲染,但值还在,重置 reset'didChange(null)都没用...
- done 2023-10-18 要显示总数量
- done 2023-10-18 许多 setState 中的查询，没有带上查询条件，如果用户有传，则需要带上，初始化时默认可以没有。
- 卡片详情页。

2023-10-19 进度

修复:exercise query 组件因为 expended 和 SingleChildScrollView 层级关系不对导致的布局错误
简单调整 exercise 查询表单的按钮布局（折叠后重置高级选项选中的值目前没法做到）

明日注意，exercise 的查询和新增的 db 操作都有问题，模糊查询不对、分页查询没做，新增肌肉数据格式不对，没有分隔符。

2023-10-19

完成 饮食模块主要布局的修改
完成 饮食模块相关的数据库创建和常规的 sql 语句，对应的类等。
完成 食物列表显示、详情页、新增页的示例。
