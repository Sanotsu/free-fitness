// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../common/global/constants.dart';
import '../../../models/training_state.dart';
import '../reports/index.dart';

class ActionFollowPractice extends StatefulWidget {
  // 跟练需要传入动作组数据
  final List<ActionDetail> actionList;

  const ActionFollowPractice({Key? key, required this.actionList})
      : super(key: key);

  @override
  State<ActionFollowPractice> createState() => _ActionFollowPracticeState();
}

class _ActionFollowPracticeState extends State<ActionFollowPractice> {
  // 设置动作开始索引为-1，这时不会匹配任何动作，只是为了有个准备的10秒倒计时
  int _currentIndex = -1;

  // 当前的动作列表
  late List<ActionDetail> actions;

  // （这个默认的时间应该是用户自己设置的，不让改的那个）
  final _defaultRestTime = 5;

  // 当前动作之间的休息时间
  int restTime = 5;

  // 当前是否是休息时间
  bool isRestTurn = false;

  // 倒计时组件控制器
  late CountDownController _controller;

  // 整个动作开始的时间，就是进入此页面的时间(开起自动倒计时)或者点击了开始的时间
  DateTime started = DateTime.now();

  // 点击暂停按钮的时刻
  DateTime paused = DateTime.now();

  // 暂停的总时间(单位毫秒？)
  int totalPausedTimes = 0;

  // 休息的总时间(单位毫秒？)
  int totalRestTimes = 0;

  ///
  /// 实际耗时的计算比较麻烦，如果还要记录跳过的动作或者重复的动作，那么做到一般就跳的怎么处理呢？
  /// 简单的，点击跳过或者重复，都会加一次休息时间；如果当前就是休息时间，点击加10s和减10s也是调整休息时间
  /// 实际运动耗时=整个过程的耗时-总的休息的时间
  ///
  /// 关键点：每个休息时间的统计。
  ///
  /// 实际功能会简单点，就加10s减10s、上一个下一个、暂停继续几个按钮，默认进入跟练页面就计时，索引走完就停止计时统计时间。
  /// ？？？暂停期间的时间怎么算的？？？
  ///
  /// 点击暂停，开始计时；点击继续，统计这段时间，并清楚暂停的时间；再点暂停又计时，重复整个过程。最后累加每个暂停的时间。
  ///  注意：休息时间的暂停加到总的休息时间去
  ///
  /// 这时 实际运动耗时=整个过程的时间-休息时间-暂停时间
  ///

  @override
  void initState() {
    super.initState();
    _controller = CountDownController();

    // 进入此跟练页面自动开始
    setState(() {
      started = DateTime.now();
    });

    formatActionList();
  }

  // TODO 这里的跟练其实也要分计次和计数的动作，细节看需要显示什么之后再确定
  formatActionList() {
    // 为了统一用倒计时，所以计数的动作有个标准动作耗时，就次数*标准动作耗时即可

    // 一定要传动作组数据
    setState(() {
      actions = widget.actionList;
    });
  }

  // 获取当前动作的耗时
  _getCurrentActionDuration() {
    // currentActionDetail
    var curAd = actions[_currentIndex];
    // currentExercisecountingMode
    var cecm = curAd.exercise.countingMode;

    int times = 0;
    // 如果是计时(第一个)
    if (cecm == countingOptions.first.value) {
      // 如果对应的exercise的计数模式是计时的话，那一定有这个值才对。
      times = curAd.action.duration ?? 10;
    } else {
      // 如果是计次
      var temp1 = curAd.action.frequency ?? 1;
      var temp2 = int.tryParse(curAd.exercise.standardDuration ?? "1") ?? 1;
      times = temp1 * temp2;
    }

    return times;
  }

  /// 全部重新开始
  /// 还是先进入10秒钟的准备(休息)时间，设置索引为-1。
  /// 休息的倒计时完了，进入下一个动作时，直接-1++，就从第一个开始了。
  void _restartAllExercise() {
    print("进入了 _restartAllExercise, 当前索引 $_currentIndex");

    setState(() {
      isRestTurn = true;
      _currentIndex = -1;

      // 测试时方便看才重置的
      started = DateTime.now();
      totalPausedTimes = 0;
      totalRestTimes = 0;
      restTime = _defaultRestTime;
    });

    _controller.restart(duration: restTime);
  }

  // 上一个动作
  void _buttonLastExercise() {
    print("进入了 _startLastExercise, 当前索引333 $_currentIndex");

    // 如果是暂停点击了上一个，那么这里会重置暂停的状态，所以要先累加暂停的时间(如果是休息中，就加到休息时间去)
    if (_controller.isPaused) {
      if (isRestTurn) {
        totalRestTimes += DateTime.now().millisecondsSinceEpoch -
            paused.millisecondsSinceEpoch;
      } else {
        totalPausedTimes += DateTime.now().millisecondsSinceEpoch -
            paused.millisecondsSinceEpoch;
      }

      // 如果当前本来就是休息时间，点击上一个，因为会再次进入休息时间，所以要先算上这一次已经休息过的时间
      if (isRestTurn) {
        // _controller.getTime() 如果是倒计时，就是剩下的时间；如果是正计时，就是已经运行的时间
        // 所以已经休息的时间 = (整个休息时间-已经休息时间)*1000 毫秒
        totalRestTimes +=
            (restTime - (int.tryParse(_controller.getTime() ?? "0") ?? 0)) *
                1000;
      }
    }

    // 点击上一个按钮时，先修改休息状态为true，这样会进行倒计时休息时间。
    // 同时，修改当前锻炼的编号，如果已经是第一个了就继续从0开始；如果不是第一个，就减一。
    // 因为点击【上一个】时，重置了休息状态为true，也改了索引；所以当圆形倒计时组件完成后执行 _startNextExercise 时，
    // 会进入非休息时间的分支，并执行新的索引(0或者减一)的锻炼。
    setState(() {
      isRestTurn = true;
      // 不管如何，重置休息时间为预设时间，弥补之前有手动延长或缩减
      restTime = _defaultRestTime;

      // 【注意】执行 _startNextExercise后索引会加一，所以这里的判断要先减一，所以开始索引从-1开始。
      // 如果已经是第一个了，重新开始第一个
      if (_currentIndex <= -1) {
        _currentIndex = -1;
      } else {
        _currentIndex--;
      }
    });

    _controller.restart(duration: restTime);
  }

  void _buttonNextExercise() {
    print("进入了 _buttonNextExercise, 当前索引111 $_currentIndex");

    // 如果当前已经是最后一个了，点击下一个就直接完结，后面的逻辑就不看了。
    if (_currentIndex >= actions.length - 1) {
      _currentIndex = actions.length - 1;
      // 如果已经是最后一个了，倒计时停止，直接开始下一个动作(其实是进入下一个动作的已完成分支，弹窗显示已完成)
      _controller.pause();
      _startNextExercise();

      return;
    }

    print("点击了下一个  ${_controller.isPaused}  ");

    // 同上一个，如果是暂停点击了下一个，那么这里会重置暂停的状态，所以要先累加暂停的时间(如果是休息中，就加到休息时间去)
    if (_controller.isPaused) {
      print(
          "在_buttonLastExercise中，已经[暂停]的时间 ${DateTime.now().millisecondsSinceEpoch - paused.millisecondsSinceEpoch}");

      if (isRestTurn) {
        totalRestTimes += DateTime.now().millisecondsSinceEpoch -
            paused.millisecondsSinceEpoch;
      } else {
        totalPausedTimes += DateTime.now().millisecondsSinceEpoch -
            paused.millisecondsSinceEpoch;
      }
    }

    // 同上一个，如果当前本来就是休息时间，点击下一个，因为会再次进入休息时间，所以要先算上这一次已经休息过的时间
    if (isRestTurn) {
      // _controller.getTime() 如果是倒计时，就是剩下的时间；如果是正计时，就是已经运行的时间
      // 所以已经休息的时间 = (整个休息时间-已经休息时间)*1000 毫秒

      print(
          "在 _buttonNextExercise 中，已经休息的时间 ${(restTime - (int.tryParse(_controller.getTime() ?? "0") ?? 0)) * 1000}");

      totalRestTimes +=
          (restTime - (int.tryParse(_controller.getTime() ?? "0") ?? 0)) * 1000;
    }

    // 点击下一个按钮时，先修改休息状态为true，这样会进行倒计时休息时间。
    // 同时，修改当前锻炼的编号，如果已经是最后一个了，重复最后一个（或者直接结束？）；不是最后一个索引就加一。
    // 因为点击【下一个/跳过】时，重置了休息状态为true，也改了索引；所以当圆形倒计时组件完成后执行 _startNextExercise 时，
    // 会进入非休息时间的分支，并执行新的索引(最后一个或者加一)的锻炼。
    setState(() {
      isRestTurn = true;

      // 不管如何，重置休息时间为预设时间，弥补之前有手动延长或缩减
      restTime = _defaultRestTime;

      if (_currentIndex >= actions.length - 1) {
        _currentIndex = actions.length - 1;
        // 如果已经是最后一个了，倒计时停止，直接开始下一个动作(其实是进入下一个动作的已完成分支，弹窗显示已完成)
        _controller.pause();
        _startNextExercise();
      } else {
        _currentIndex++;
        _controller.restart(duration: restTime);
      }
    });
  }

  void _startNextExercise() {
    // 如果动作组还没有做完
    if (_currentIndex < actions.length - 1) {
      // 恰好是休息时间，那就休息一下
      if (isRestTurn) {
        _controller.restart(duration: restTime);
      } else {
        // 已经不是休息时间了，执行下一个动作
        setState(() {
          _currentIndex++;
        });
        _controller.restart(duration: _getCurrentActionDuration());
      }
    } else {
      // 所有锻炼完成，显示弹窗

      var tempTime = DateTime.now().millisecondsSinceEpoch -
          started.millisecondsSinceEpoch;

      showDialog(
        context: context,
        barrierDismissible: false, // 禁止点击空白处隐藏弹窗
        builder: (BuildContext context) => AlertDialog(
          title: const Text('恭喜你！'),
          content: Text(
              '你已完成所有锻炼。耗时 ${(tempTime / 1000).toStringAsFixed(2)} 秒\n 其中暂停时间 ${(totalPausedTimes / 1000).toStringAsFixed(2)} 秒\n 休息时间${(totalRestTimes / 1000).toStringAsFixed(2)} 秒 '),
          actions: [
            TextButton(
              onPressed: () {
                //TODO 测试时，完成是个弹窗，点击确认后重置数据，重新开始。
                // 实际的时候应该push and replace一个报告页面,然后这里应该在结束时记录数据，保存到数据库等等

                _restartAllExercise();
                Navigator.pop(context);
              },
              child: const Text('再跟练一次'),
            ),
            // 测试的
            TextButton(
              onPressed: () {
                // ？？？这个pushReplacement 为什么跳到报告之后，点击返回还是回到这个跟练页面呢
                // Navigator.of(context).pushReplacement(
                //   MaterialPageRoute(builder: (_) => const TrainingReports()),
                // );
                // ？？？这样的 奇技淫巧先到最外层，再跳转到报告页面
                // 要在workout和plan的index中，getGroupList()的setstate前先 if (!mounted) return; 否则会报错
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TrainingReports()),
                );
              },
              child: const Text('查看报告（测试）'),
            ),
          ],
        ),
      );
    }
  }

  void _toggleTimer() {
    if (_controller.isPaused) {
      _controller.resume();
    } else {
      _controller.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 完成之后，这里页面点返回按钮，应该和弹窗中跳到报告页面一样。
    // ？？？或者正式的时候，弹窗就直接改为跳到报告页面即可
    // 跟练中点击返回按钮，时暂停，然后询问用户是否确定退出，还是继续等等
    return Scaffold(
      appBar: AppBar(title: const Text('Circular Countdown Timer')),
      body: ListView(
        children: [
          GestureDetector(
            onTap: _toggleTimer,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //  如果是预备，就显示预备的样式
                if (_currentIndex <= -1) ..._buildPrepareActionArea(),

                // 如果是休息，就显示休息的样式
                if (_currentIndex >= 0 &&
                    _currentIndex < actions.length - 1 &&
                    isRestTurn)
                  ..._buildRestActionArea(),

                // 如果是跟练，就显示跟练的样式
                if (_currentIndex >= 0 &&
                    _currentIndex <= actions.length - 1 &&
                    !isRestTurn)
                  ..._buildFollowActionArea(),

                const SizedBox(height: 20),
                // ..._buildActionTitleArea(),
                const SizedBox(height: 20),
                _buildCountDownWithExtraTime(),
                const SizedBox(height: 20),
                _buildPauseAndResumeButton(),
                const SizedBox(height: 20),
                _buildLastNextButtonRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _button({
    required String title,
    MaterialStateProperty<Color?>? backgroundColor,
    VoidCallback? onPressed,
  }) {
    return Expanded(
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor:
              backgroundColor ?? MaterialStateProperty.all(Colors.purple),
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  /// 预备、休息时和跟练时标题和图片显示样式不一样
  _buildPrepareActionArea() {
    return [
      SizedBox(
        // 这里的盒子，只是单纯区分休息时显示下一个要小点，跟练时图片大点
        height: 0.2.sh,
        child: Image.file(
          // 预备的时候，肯定显示第一个动作的图片
          File(actions[0].exercise.images?.split(",")[0] ?? ""),
          errorBuilder:
              (BuildContext context, Object exception, StackTrace? stackTrace) {
            return Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown);
          },
        ),
      ),
      Center(
        child: Text(
          ' 预备开始\n ${actions[_currentIndex + 1].exercise.exerciseName}',
          style: TextStyle(fontSize: 20.sp),
        ),
      ),
    ];
  }

  _buildRestActionArea() {
    return [
      Text(
        '休息',
        style: TextStyle(fontSize: 32.sp),
      ),
      Row(
        children: [
          Expanded(
            child: Text(
              '下一个动作\n${actions[_currentIndex + 1].exercise.exerciseName}',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          Expanded(
            child: SizedBox(
              // 这里的盒子，只是单纯区分休息时显示下一个要小点，跟练时图片大点
              height: 0.2.sh,
              child: Image.file(
                File(
                    actions[_currentIndex + 1].exercise.images?.split(",")[0] ??
                        ""),
                errorBuilder: (BuildContext context, Object exception,
                    StackTrace? stackTrace) {
                  return Image.asset(placeholderImageUrl,
                      fit: BoxFit.scaleDown);
                },
              ),
            ),
          )
        ],
      ),
    ];
  }

  _buildFollowActionArea() {
    return [
      SizedBox(
        // 这里的盒子，只是单纯区分休息时显示下一个要小点，跟练时图片大点
        height: 0.2.sh,
        child: Image.file(
          // 预备的时候，肯定显示第一个动作的图片
          File(actions[_currentIndex].exercise.images?.split(",")[0] ?? ""),
          errorBuilder:
              (BuildContext context, Object exception, StackTrace? stackTrace) {
            return Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown);
          },
        ),
      ),
      Center(
        child: Text(
          ' 当前跟练动作 ${_currentIndex + 1}/${actions.length} \n ${actions[_currentIndex].exercise.exerciseName}',
          style: TextStyle(fontSize: 20.sp),
        ),
      ),
    ];
  }

  _buildActionImageArea() {
    return Padding(
      padding: EdgeInsets.all(10.sp),

      /// 如果是预备动作或者休息时间，则显示下一个
      /// 1 如果索引在正常范围内，且目前是预备或者休息时间，则显示下一个动作的图
      child: ((_currentIndex <= -1 || isRestTurn) &&
              _currentIndex < actions.length - 1)
          ? SizedBox(
              // 这里的盒子，只是单纯区分休息时显示下一个要小点，跟练时图片大点
              height: 0.2.sh,
              child: Image.file(
                File(
                    actions[_currentIndex + 1].exercise.images?.split(",")[0] ??
                        ""),
                errorBuilder: (BuildContext context, Object exception,
                    StackTrace? stackTrace) {
                  return Image.asset(placeholderImageUrl,
                      fit: BoxFit.scaleDown);
                },
              ),
            )
          // 如果是正常索引值且在跟练时间，则显示当前动作的体
          : (_currentIndex < actions.length - 1)
              ? SizedBox(
                  // 这里的盒子，只是单纯区分休息时显示下一个要小点，跟练时图片大点
                  height: 0.4.sh,
                  child: Image.file(
                    File(
                        actions[_currentIndex].exercise.images?.split(",")[0] ??
                            ""),
                    errorBuilder: (BuildContext context, Object exception,
                        StackTrace? stackTrace) {
                      return Image.asset(placeholderImageUrl,
                          fit: BoxFit.scaleDown);
                    },
                  ),
                )
              // 如果索引不正常，则显示预设的图
              : SizedBox(
                  height: 0.1.sh,
                  child:
                      Image.asset(placeholderImageUrl, fit: BoxFit.scaleDown),
                ),
    );
  }

  _buildActionTitleArea() {
    return [
      _currentIndex <= -1
          ? Text(
              ' 预备开始，下一个动作\n ${actions[_currentIndex + 1].exercise.exerciseName}',
              style: TextStyle(fontSize: 20.sp),
            )
          : isRestTurn
              ? ((_currentIndex < actions.length - 1)
                  ? Text(
                      '  休息，下一个动作\n:  ${actions[_currentIndex + 1].exercise.exerciseName}',
                      style: const TextStyle(fontSize: 20),
                    )
                  : const Text(
                      '  没有下一个动作了\n 恭喜，已完成本次训练！',
                      style: TextStyle(fontSize: 20),
                    ))
              : Text(
                  ' 当前跟练动作\n ${actions[_currentIndex].exercise.exerciseName}',
                  style: const TextStyle(fontSize: 20),
                ),
    ];
  }

  _buildCountDownWithExtraTime() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _button(
          title: "-10秒",
          onPressed: () {
            // _controller.getTime() 如果是倒计时，就是剩下的时间；如果是正计时，就是已经运行的时间

            var newtime =
                (int.tryParse(_controller.getTime() ?? "0") ?? 0) - 10;

            // 注意，如果当前状态时休息时间，减10s，就是当前的倒计时理论上的时间减少
            // 如果在休息中点击了上下一个按钮，需要再上下一个按钮的逻辑中处理已经休息的时间。
            // 而这里理论上增加或减少的休息时间，只有在倒计时完成的时候，才算是真的休息过了
            setState(() {
              if (isRestTurn) {
                // 注意如果当前剩余休息时间不足10秒，是整个跳过的
                if (newtime <= 0) {
                  restTime -= (newtime + 10);
                } else {
                  restTime -= 10;
                }
              }
            });

            // 还有一点注意，如果是计次的动作，这里减10s，其实中间显示减少的次数，还是“10s/动作标准耗时”再向上取整的次数，在timeFormatterFunction中处理的

            // 如果剩余的时间已经小于10秒了，要么就不允许再减少，要么就直接跳到下一个动作去，要么直接置为0秒？
            _controller.restart(duration: newtime <= 0 ? 0 : newtime);
          },
        ),
        const SizedBox(width: 10),
        CircularCountDownTimer(
          duration:
              _currentIndex == -1 ? restTime : _getCurrentActionDuration(),
          controller: _controller,
          width: 120,
          height: 120,
          // 如果是休息时间，改变一下圆环样式
          ringColor: Colors.grey[300]!,
          fillColor: Colors.purpleAccent[100]!,
          // 设置背景色，预备时间时灰色、休息时绿色、运动时蓝色
          backgroundColor: _currentIndex == -1
              ? Colors.grey
              : isRestTurn
                  ? Colors.green
                  : Colors.blue,
          strokeWidth: 5.0,
          strokeCap: StrokeCap.round,
          textStyle: const TextStyle(
            fontSize: 33.0,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          // 这里格式是秒，如果换成其他的了，那么在个个统计时间时的逻辑就都要变了
          // 因为_controller.getTime()的数据变了，就不是简单的取值后加减了
          textFormat: CountdownTextFormat.S,
          isReverse: true,
          isReverseAnimation: false,
          isTimerTextShown: true,
          autoStart: true, // 是否自动开始
          onStart: () {
            print('Countdown Started isRestTime---$isRestTurn');
          },
          onComplete: () {
            // 每次动作或者休息倒计时完成之后，先转换状态，再确定下一个动作是休息还是动作加一

            setState(() {
              // 注意，如果当前状态时休息时间/准备时间，那么到这里了，就是整个休息时间都完成了，所以累加整个休息时间
              // 还要注意，这里用的是预设的休息时间，如果点击了加10s或者减10s，还要在那个地方另算
              if (isRestTurn || _currentIndex == -1) {
                totalRestTimes += restTime * 1000;
                // 注意：加10s或者减10s可能修改过 _restTime 的时间，这里累加完之后要重置为默认的
                restTime = 5;
              }

              // 如果当前是准备时间，下一个就是第一个动作而不是休息时间。
              isRestTurn = _currentIndex == -1 ? false : !isRestTurn;
            });

            print('Countdown Ended isRestTime 后---$isRestTurn $_currentIndex');

            _startNextExercise(); // 开始下一个锻炼
          },
          // This Callback will execute when the Countdown Changes.
          onChange: (String timeStamp) {
            // Here, do whatever you want
            // debugPrint('Countdown Changed $timeStamp');
          },
          timeFormatterFunction: (defaultFormatterFunction, duration) {
            // 如果是动作跟练中，
            if (!isRestTurn) {
              // 索引是正常范围内
              if (_currentIndex >= 0 && _currentIndex <= actions.length - 1) {
                // 且当前动作计数方式为“计时”时，这里加个秒字
                if (actions[_currentIndex].exercise.countingMode ==
                    countingOptions.first.value) {
                  return "${duration.inSeconds}秒";
                  // 如果是动作跟练中，且当前动作计数方式为“计数”时，这里加个次字
                } else if (actions[_currentIndex].exercise.countingMode ==
                    countingOptions.last.value) {
                  // return "${(duration.inSeconds / (int.tryParse(actions[_currentIndex].exercise.standardDuration ?? "2") ?? 1)).ceil()}次";
                  // 测试用，看看计数时，动作预设耗时（即次数/重复次数）/标准耗时 的倒计时对不对
                  // 注意：计数的总耗时在初始化的时候一定要计算的，这里只不过取整了，才看起来在一个标准耗时中只倒计了一个数，其实一直在变
                  return "${(duration.inSeconds / 2).ceil()}次";
                }
              }
            }
            // 其他情况就默认显示
            return Function.apply(defaultFormatterFunction, [duration]);
          },
        ),
        const SizedBox(width: 10),
        _button(
          title: "+10秒",
          onPressed: () {
            // _controller.getTime() 如果是倒计时，就是剩下的时间；如果是正计时，就是已经运行的时间
            var newtime =
                10 + (int.tryParse(_controller.getTime() ?? "0") ?? 0);

            // 注意，如果当前状态时休息时间，加10s，只是理论上当次倒计时的休息时间加10s，
            // 如果点击了其他按钮(比如上下一个)，已经休息的时间在上下一个按钮中处理，
            // 而这里的理论休息的时间要在倒计时完成的回调中处理
            setState(() {
              if (isRestTurn) {
                restTime += 10;
              }
            });

            print("加10秒的后的时间 ; ${_controller.getTime()} --- $newtime");

            // 还有一点，如果是计次的动作，这里加10s，其实中间显示增加的次数，还是“10s/动作标准耗时”再向上取整的次数，在timeFormatterFunction中处理的

            _controller.restart(duration: newtime);
          },
        ),
      ],
    );
  }

  _buildPauseAndResumeButton() {
    return Row(
      children: [
        //  因为倒计时不止暂停和继续两种状态，
        // 在当前动作的倒计时中可以判断暂停和继续的复用，但到了下一个动作就既不是暂停又不是继续了。
        // 所以暂停和继续按钮就一直显示好了，用正向来绘制不同颜色
        _button(
            title: "暂停",
            // 如果已经是暂停了，就灰色；否则就默认颜色
            backgroundColor: _controller.isPaused
                ? MaterialStateProperty.all(Colors.grey)
                : null,
            onPressed: () {
              // 注意：已经是暂停的状态了(重复点击暂停按钮)，就不要继续更新时间点了
              if (!_controller.isPaused) {
                setState(() {
                  paused = DateTime.now();
                });
                _controller.pause();
              }
            }),
        const SizedBox(width: 10),

        _button(
          title: "继续",
          // 如果已经是暂停了，就灰色；否则就默认颜色
          backgroundColor: _controller.isResumed
              ? MaterialStateProperty.all(Colors.grey)
              : null,
          onPressed: () {
            // 注意：已经是继续的状态了(重复点击继续按钮)，就不要继续更新暂停总时间了

            print("_controller.isResumed  ${_controller.isResumed}");
            if (!_controller.isResumed) {
              setState(() {
                // 点击继续时计算这次暂停的时间
                // 如果是在休息时间的暂停，算在休息时间内
                if (isRestTurn) {
                  totalRestTimes += DateTime.now().millisecondsSinceEpoch -
                      paused.millisecondsSinceEpoch;
                } else {
                  totalPausedTimes += DateTime.now().millisecondsSinceEpoch -
                      paused.millisecondsSinceEpoch;
                }

                paused = DateTime.now();
              });

              _controller.resume();
            }
          },
        ),
        // const SizedBox(
        //   width: 10,
        // ),
        // _button(
        //   title: "从头再来",
        //   onPressed: () {
        //     _restartAllExercise();
        //   },
        // ),
      ],
    );
  }

  _buildLastNextButtonRow() {
    return Row(
      children: [
        // 点击上下一个，为了避免点击了按钮就计时没有准备时间，索引变化，并置为是休息时间
        _button(
          title: "上一个",
          // 如果已经是暂停了，就灰色；否则就默认颜色
          backgroundColor:
              _currentIndex < 0 ? MaterialStateProperty.all(Colors.grey) : null,
          onPressed: _currentIndex < 0
              ? () {}
              : () {
                  // 点击上一个按钮，就先执行一个休息倒计时，然后再执行上一个动作的倒计时
                  // (是不是第一个的逻辑在函数内去判断)。

                  _buttonLastExercise();
                },
        ),
        const SizedBox(width: 10),
        _button(
          title: "下一个",
          backgroundColor: _currentIndex >= actions.length - 1
              ? MaterialStateProperty.all(Colors.grey)
              : null,
          onPressed: _currentIndex >= actions.length - 1
              ? () {
                  print("点击下一个了---$_currentIndex");
                }
              : () {
                  // 如果没有下一个了
                  _buttonNextExercise();
                },
        ),
      ],
    );
  }
}
