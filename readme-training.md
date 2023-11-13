## 2023-11-05 之后 training 进度放到这里，避免冲突

### 2023-11-05 之前旧的问题整理

（这些问题都可以放在大功能完成之后再考虑）

1. exercise 列表的查询区域，显示更多之后有选择高级选项的值，折叠之后的【重置】无法实际重置折叠之后高级选项选中的值。

   - 解决方案不清楚。

2. exercise 详情页的内容有了，布局和细节都没有

3. exercise 可能需要一个批量导入的功能

   - 是否使用 json 格式？
   - 图片怎么办？
     - 在线地址的话 app 就要连网了，可能不行。
     - 本地图片的话如何批量导入到对应的 exercise 中，图片放在对应缓存地址去？

4. exercise 的修改按钮位置是否合理？

   - 现在是放在 exercise list 点击之后的 showModalBottomSheet 中，里面有【详情】和【修改】按钮。
   - 是不是应该把修改放到详情中，这样才知道具体要修改什么，否则看完详情再返回上一层再修改逻辑不是很顺。

5. showModalBottomSheet 点击图片可以浮出来，但是没有双指放大等功能，太小也可能看不清。

6. 一个 exercise 如果有多个图片，在 showModalBottomSheet 或者详情页都只是默认显示第一张，没有地方看第二张。

7. 新增或者修改 exercise 之后，返回列表页面，现在是重新从 0 开始加载所有，是否只是重新加载当前新增或修改的数据？

---

### 训练计划模块功能

参考手机里“男士减肥健身软件”的“我的锻炼计划”

注意内容 训练计划 Group/workout - 动作 Action - 基础活动 Exercise （这里显示 workout，对应 db 就是 group 表）

基本流程：

计划列表主页 -> 点击新增训练计划 -> 可搜索的 exercise 列表 -> 选中某一 exercise，跳转到 Action 配置页面(设置时间或者个数) -> action 配置页面点击保存，进入 action 列表 -> action 列表点击新增，继续跳转 可搜索的 exercise 列表，之后相同（选择 exercise，配置 action，保存后返回 action list）……

主要页面：

1. 主页锻炼计划列表
   - 右下角悬浮新增按钮
2. 点击训练计划【新增】进入可搜索 exericse 的“基础活动”列表，也是下拉加载更多
   - 选中某个 exercise 之后跳到 action“动作”页面，显示 exercise 的大概信息，和该 exercise 运动的持续时间或者个数
   - 点击【新增】加入到这个新的训练计划的第一条，即返回训练计划的 action 条目列表
   - 更多的条目类似操作，即 action 条目中点击新增按钮
3. 新增训练计划的 action 条目列表，在点击保存时弹窗口给训练计划取个名字（默认为新锻炼、新计划等）

数据库操作：

- 新增 group 的时候，会先带一个 action（关联一个 exercise），所以是 insert 时一次性新增一个 group、多条 action、多条 group_has_action 数据？
  - 还是说，更简单一点，action 不能复用，一个 action 一定属于某个 group（反正也没有单独展示所有 action 列表的地方，内容重复不影响，idb 不同）
    - 即只要 group 和 action 表，group has action 就不要了

**【2023-11-08 更新】**：

不能按照“男士减肥健身软件”的顺序来，因为无论是创建 group 还是 action 都有很多自行输入的栏位，
如果按那个软件来，group 只能填一个名称，action 只有一个时间和次数，和现有数据库设计差距过大。

还是常规顺序：

进入训练计划页面 workout list -> 点击新增训练计划，弹窗输入训练计划的基本信息，显示当前训练计划空白 action list
-> 点击添加动作，弹窗查询 exercise list -> 点击指定 exercise，进入动作配置信息页面 action config
-> 点击保存，返回 action list

**或者说**，之前的设计太麻烦了，就应该 只保留 group 和 action，1 对多，额外栏位也不要了。

--- 这部分，我试一下新的数据库设计 simple group 和 simple action 的 1 对多

### 进度

#### 2023-11-05

- 基本完成训练计划(workout 或者 group)的几个空页面大概需要什么和理清最基础的跳转逻辑。

#### 2023-11-06

- 基础查询 exercise 列表，要调整查询框和显示数量，还有 card 的高度，图片太小了

#### 2023-11-07

- 基本调整了新增训练计划时跳转的插查询的基础 exercise 列表页面。
- 大概有了 action 配置的页面
  - 【问题】
    - 1 exercise 缺少 counting_mode 栏位，无法判断是计时还是计数
    - 2 action 表中的 action_code、action_name、action_level、description 等栏位需要手动输入
      - 能不能简化一下，group 直接关联了 exercise 就好多一些冗余栏位。即不复用 action 和不需要 group_has_action 表

#### 2023-11-09【暂停】

问题：

之前的设置参考"“男士减肥健身软件"目前有个无法解决的问题，就是有 3 种情况会进入 action config 页面，但是添加了 action 之后，要返回到 action list 比较麻烦，因为存在两种情况，1 是新增训练计划(group)时，还不存在 action list，要同时新增 group 和 action list，但是 group 没有用户输入的阶段。如果是选择完所有的 action，再新增时同时新增 group，那么一次性配置一个 action，后配置的从 action config 页面返回之后，旧的就没有了。

最主要是存在 3 种情况

- 新增训练计划 group list > action list > simple exercise list -> action config => 返回新的 action list
- 旧训练计划新增动作配置 group list > action list > simple exercise list -> action config => 返回旧的 action list
- 旧训练计划修改动作配置 group list > action list > action config => 返回旧的 action list

现在放弃了，一步一步来，每步都保存：

- 新增训练计划 group list -> new group form -> 空 action list -> 带入 group id 进入 simple exercise list -> action config => 返回旧的 action list
- 旧训练计划新增动作配置 group list -> 指定 action list -> 带入 group id 进入 simple exercise list -> action config => 返回旧的 action list
- 旧训练计划修改动作配置 group list > action list > action config => 返回旧的 action list

#### 2023-11-10

后续 exercise 称为**运动**，action 称为**动作**， group/workout 称为**训练**，plan 称为**计划**，整个模块 training 称为**锻炼**。

【注意】：看看 action config 从一个页面，换成一个 dailog 看看，能不能解决 pop 两次的问题？？

基本完成 训练主页面点击某想训练进入动作列表

待完成：

- 训练中查询动作列表时，要按照 group id 来排序；当修改该 group id 中的 action 顺序时，点击保存则把每个对应 action 的 action id 替换为当前的 index，然后按 group id 删除已存在的 action，再新增重新排序的 action。
  - 注意，修改除了移动顺序，还行修改配置（时间次数重量等）、删除、新增（弹窗的方式），在点击保存时再重新先删除后新增。

#### 2023-11-12

- 基本完成 action list 中修改、移动顺序、删除的展示（**还没有实现保存修改数据库数据的逻辑**）

  - 这个保存全部删除旧的再新增新的列表的话，如何指定存入 action 编号？

    - 还是说顺序批量保存的，让数据库的自增应该不会出现乱序的？也就是一定不会异步插入？

  - 待完成：
    - action list 中新增 action 的逻辑。
      - 点击新增->跳到 simple exercise list 页面 -> 选中某个 exercise，带数据返回 action list -> 关闭 simple exercise list 页面的同时，展开 action config 弹窗，带入数据，进行配置。
      - 注意，action config 弹窗可能没法全部复用，因为传入的内容参数不一样，也不存在 actiondetail 数据，看怎么修改：
        - 是弹窗前 new 一个 ActionDetail 还是写两个不同参数的弹窗。

#### 2023-11-13

- 基本完成了从训练中新增或点击指定训练，进入动作列表，对动作列表的动作进行修改、删除、新增、调整顺序的功能逻辑。
- 待完成
  - 流程走通了，页面非常粗糙，很多的地方只是占位，没有实际实现。
  - (**2023-11-13 完成**) action list 中点击修改按钮后，再点击某个指定 action 是进入 action config 弹窗；但还应该正常点击时进入 action detail 弹窗，并且想之前的 exercise list 一样可以上下条切换。
    - 参考实现：传入 action list 以及对应的 index。
