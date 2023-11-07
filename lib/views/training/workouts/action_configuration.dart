import 'package:flutter/material.dart';

class ActionConfiguration extends StatefulWidget {
  // 进入action配置页面，一定要有配置信息

  const ActionConfiguration({super.key});

  @override
  State<ActionConfiguration> createState() => _ActionConfigurationState();
}

class _ActionConfigurationState extends State<ActionConfiguration> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 页面的内容（appbar可有可无，看有没有必要显示什么把）
      body: const Center(
        child: Text(
          'ActionConfiguration. 动作配置页面，显示exercise的大概信息，选择个数或持续时间，点保存，返回到action list页面.这里点击保存之后，应该返回该group的action list页面，不管是新增训练计划group还是修改等',
        ),
      ),
      // 悬浮按钮,正式的时候是一个放在底部的普通保存按钮即可
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 处理保存按钮点击事件之后返回
          // 但这里的返回比较麻烦，
          // 因为workout(index)的主页点击新增进入simple exercise list，选中指定exercise再到这里；
          // 或者在action list 点击新增进入simple exercise list，选中指定exercise再到这里；
          // 还是在action list 点击指定action进行修改，直接进入这里；
          // 三者不相同，比较难统一处理，跨级别的带参数还不好在app出使用route配置
          //    前两者甚至都是返回action list主页，不过前者是db先新增成功之后才有数据（group和action list数据先都不存在），后者是已有现成数据
          // 这里根据不同传入的值，返回不同属性，，各自层的逻辑不关心这个属性，就在pop到上一层去，在各自上层组件中去判断吧。

          // 这是示例，返回上一层去

          Navigator.pop(context, "parent widget map?");
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.save),
      ),
      // 悬浮按钮位置
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
