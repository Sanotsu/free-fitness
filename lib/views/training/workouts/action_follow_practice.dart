// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../common/components/dialog_widgets.dart';
import '../../../common/global/constants.dart';
import '../../../common/utils/tools.dart';
import '../../../models/training_state.dart';
import '../reports/index.dart';

class ActionFollowPracticeWithTTS extends StatefulWidget {
  // 跟练需要传入动作组数据
  final List<ActionDetail> actionList;

  const ActionFollowPracticeWithTTS({Key? key, required this.actionList})
      : super(key: key);

  @override
  State<ActionFollowPracticeWithTTS> createState() =>
      _ActionFollowPracticeWithTTSState();
}

enum TtsState { playing, stopped, paused, continued }

class _ActionFollowPracticeWithTTSState
    extends State<ActionFollowPracticeWithTTS> {
  // 一般的倒计时控制器
  final _actionController = CountDownController();
  // 倒计时组件控制器
  final _restController = CountDownController();

  // 当前的动作列表
  late List<ActionDetail> actions;
  // 设置动作开始索引为-1，这时不会匹配任何动作，只是为了有个准备的10秒倒计时
  int _currentIndex = -1;

  // 预设的休息时间(从用户配置表读取的，是不变的。每次休息完成之后都要重置为这个时间)
  final _defaultCusRestTime = 10;
  // 当前休息的倒计时时间(每个跟练间隔的休息时间用户可以调整)
  int _cusRestTime = 10;

  // 当前是否是休息时间
  bool isRestTurn = false;
  // 当前跟练是否已暂停(该组件的控制器没办法获取组件状态，所以自定义标识)
  bool isActionPause = false;

  // 是否点击了增加休息时间的标志
  // 在休息的倒计时点击+10s后，倒计时组件是重新开始的，但是休息的提示音是在onstart的回调函数中发出的。
  // 也就是说，不处理的话，每点击一次+10s就会重复触发休息的语言提示。
  // 因此增加这个是否点击了+10s的标志，如果是true，倒计时的onstart回调中就不触发语音。
  // 【注意】在休息倒计时自然结束或者跳过休息时间时，要重置为false
  bool isClickPlusRestTime = false;

  // 整个动作开始的瞬间，就是进入此页面的时间(开起自动倒计时)或者点击了开始的时间
  DateTime startedMoment = DateTime.now();
  // 点击暂停按钮的瞬间
  DateTime pausedMoment = DateTime.now();

  // 暂停的总时间(单位毫秒)
  int totalPausedTimes = 0;
  // 休息的总时间(单位秒)
  int totalRestTimes = 0;

  ///
  ///  实际运动耗时= 整体耗时 - 休息时间 - 暂停时间
  ///   1 整体耗时 = 进入此页面就自动开始，到动作全部完成弹出弹窗结束。
  ///   2 休息时间 = 累加以下各值
  ///             如果预设休息时间自动完成，倒计时完成时累加
  ///             如果预设休息时间内容点击了跳过休息，累加点击跳过前已经休息的时间
  ///             如果在休息时点击了+10s，累加点击+10s前已经休息的时间
  ///                 如果点击了+10s后有点击了跳过，则累加点击+10s后到点击跳过前这段已经休息的时间
  ///                 如果点击了+10s后等到了休息倒计时完成，在倒计时完成的时候会累加
  ///                 多次点击了+10s操作同上
  ///   3 暂停时间 = 累加以下个只
  ///             如果只点击了暂停按钮，再点击继续按钮时，累加中间暂停的值
  ///             如果先点击了暂停按钮，又点击了上一个按钮，则累加这中间的暂停的值，并修改状态为未暂停。
  ///             如果先点击了暂停按钮，又点击了跳过按钮，则累加这中间的暂停的值，并修改状态为未暂停。
  ///
  ///   跟练过程中不能调节动作的数量和时间，所以被跳过的动作是否需要记录？？？重复的动作是否需要积累？？？
  ///     这点最简单就是在跟练倒计时结束的时候，记录一下此处结束的是哪个动作就好，有重复的就是多次锻炼的，预设动作没在这个列表中就是跳过的。
  ///

  ///
  /// TTS 相关的变量 ===============
  ///
  late FlutterTts flutterTts;
  String? language;
  String? engine;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;

  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  get isPaused => ttsState == TtsState.paused;
  get isContinued => ttsState == TtsState.continued;

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;

  @override
  void initState() {
    super.initState();

    setState(() {
      // 一定要传动作组数据
      actions = widget.actionList;
      // 进入此跟练页面自动开始
      startedMoment = DateTime.now();
    });

    initTts();
  }

  ///
  /// 倒计时相关的操作===============
  ///

  /// 获取当前动作的耗时
  int _getCurrentActionDuration() {
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
      // 如果是计次，次数*单个标准动作耗时
      var temp1 = curAd.action.frequency ?? 1;
      var temp2 = int.tryParse(curAd.exercise.standardDuration ?? "1") ?? 1;
      times = temp1 * temp2;
    }

    // print("跟练动作的倒计时时间---times   $times");
    // 【注意】这个跟练动作为0的时候，倒计时可能会出问题,正常是不一样有0的
    // (在跟练的Countdown的onFInish的回调中使用setState处)
    return times > 0 ? times : 1;
  }

  /// 获取指定动作的次数或者持续时间(休息或者跟练的页面显示有用)
  _getActionCountString(index) {
    // currentActionDetail
    var curAd = actions[index];
    // currentExercisecountingMode
    var cecm = curAd.exercise.countingMode;

    String countString = '';
    // 如果是计时(第一个)
    if (cecm == countingOptions.first.value) {
      // 如果对应的exercise的计数模式是计时的话，那一定有这个值才对。
      countString = "${curAd.action.duration ?? 10}秒";
    } else {
      // 如果是计次，次数*单个标准动作耗时
      var temp1 = curAd.action.frequency ?? 1;
      var temp2 = int.tryParse(curAd.exercise.standardDuration ?? "1") ?? 1;
      countString = "$temp1 x $temp2秒";
    }

    return countString;
  }

  /// 全部重新开始
  void _restartAllExercise() {
    setState(() {
      // 测试时方便看才重置的
      startedMoment = DateTime.now();
      totalPausedTimes = 0;
      totalRestTimes = 0;
      _cusRestTime = _defaultCusRestTime;

      // 修改索引为-1就直接到准备页面了
      _currentIndex = -1;
    });
  }

  ///
  /// TTS 相关的操作===============
  ///
  ///

  // 初始化tts服务
  initTts() {
    flutterTts = FlutterTts();

    _setAwaitOptions();

    if (isAndroid) {
      _getDefaultEngine();
      _getDefaultVoice();
    }

    flutterTts.setStartHandler(() {
      setState(() {
        print("Playing");
        ttsState = TtsState.playing;
      });
    });

    if (isAndroid) {
      flutterTts.setInitHandler(() {
        setState(() {
          print("TTS Initialized");
        });
      });
    }

    flutterTts.setCompletionHandler(() {
      setState(() {
        print("Complete");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        print("Cancel");
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setPauseHandler(() {
      setState(() {
        print("Paused");
        ttsState = TtsState.paused;
      });
    });

    flutterTts.setContinueHandler(() {
      setState(() {
        print("Continued");
        ttsState = TtsState.continued;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        print("error: $msg");
        ttsState = TtsState.stopped;
      });
    });
  }

  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      print(engine);
    }
  }

  Future _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {
      print(voice);
    }
  }

  Future _speak(String voiceText, {double? cusRate}) async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(cusRate ?? rate);
    await flutterTts.setPitch(pitch);
    await flutterTts.speak(voiceText);
  }

  Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future _stop() async {
    var result = await flutterTts.stop();
    if (result == 1) setState(() => ttsState = TtsState.stopped);
  }

  Future _pause() async {
    var result = await flutterTts.pause();
    if (result == 1) setState(() => ttsState = TtsState.paused);
  }

  @override
  void dispose() {
    super.dispose();
    flutterTts.stop();
  }

  @override
  Widget build(BuildContext context) {
    // 完成之后，这里页面点返回按钮，应该和弹窗中跳到报告页面一样。
    // ？？？或者正式的时候，弹窗就直接改为跳到报告页面即可
    // 跟练中点击返回按钮是暂停，然后询问用户是否确定退出，还是继续等等
    return Scaffold(
      appBar: AppBar(title: const Text('跟练示例')),
      body: Padding(
        padding: EdgeInsets.all(10.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 专门的一个预备开始的倒计时(只有当前索引为-1的时候触发)
            if (_currentIndex < 0) ..._buildPrepareScreen(),

            // 跟练的时候，动作不能调整倒计时
            if (!isRestTurn &&
                _currentIndex >= 0 &&
                _currentIndex <= actions.length - 1)
              ..._buildFollowScreen(),

            // 休息的时候，可以增加休息时间，或者跳过休息时间
            if (isRestTurn) ..._buildRestScreen(),
          ],
        ),
      ),
    );
  }

  /// 预备时的主要部件
  _buildPrepareScreen() {
    return [
      Expanded(
        // 这里的盒子，只是单纯区分休息时显示下一个要小点，跟练时图片大点
        flex: 5,
        child: buildExerciseImage(actions[0].exercise),
      ),
      Expanded(
        flex: 2,
        child: Center(
          child: RichText(
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '预备开始\n', // 没有这个换行符两个会放到一行来
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: actions[_currentIndex + 1].exercise.exerciseName,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Expanded(
        flex: 3,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 为了倒计时圈圈居中的左侧占位
            Expanded(flex: 2, child: Container()),
            Expanded(
              flex: 3,
              child: CircularCountDownTimer(
                duration: 10,
                initialDuration: 0,
                width: 0.3.sw,
                height: 0.3.sw,
                ringColor: Colors.grey[300]!,
                ringGradient: null,
                fillColor: Colors.lightBlue,
                fillGradient: null,
                // backgroundColor: const Color.fromARGB(255, 27, 23, 27),
                backgroundColor: Colors.black38,
                backgroundGradient: null,
                strokeWidth: 10.0,
                strokeCap: StrokeCap.round,
                textStyle: const TextStyle(
                  fontSize: 50.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textFormat: CountdownTextFormat.S,
                isReverse: true,
                isReverseAnimation: false,
                isTimerTextShown: true,
                autoStart: true,
                // 当进入预备倒计时时，开始语音提示.
                onStart: () {
                  // Here, do whatever you want
                  debugPrint('Countdown Started');
                  var prepareText =
                      "预备开始，下一个动作：${actions.first.exercise.exerciseName}";
                  _speak(prepareText);
                },
                onComplete: () {
                  debugPrint('休息 Countdown Ended-- $_currentIndex');
                  setState(() {
                    // 预备动作，下一个一定是跟练的第一个，所以设置索引加1,非休息状态。
                    _currentIndex = 0;
                    isRestTurn = false;
                  });
                },
              ),
            ),
            // 点击跳过按钮，就直接开始第一个
            Expanded(
              flex: 2,
              child: IconButton(
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                    isRestTurn = false;
                  });
                  // 跳过预备时也停止语音
                  _stop();
                },
                icon: const Icon(Icons.arrow_forward),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  // 倒计时的tts语言
  void countdownTts(int seconds) {
    if (seconds > 0) {
      print('倒计时剩余时间：$seconds 秒');
      // _pause();
      // 倒计时非常快才有可能能不重复
      // ？？？ 实测跟速度也没关系，就是倒计时的onChange时间的问题？
      if (!isPlaying) {
        _speak("$seconds");
      }
      Future.delayed(const Duration(milliseconds: 1000), () {
        countdownTts(seconds - 1);
      });
    } else {
      print('倒计时结束');
    }
  }

  /// 跟练时的主要部件
  _buildFollowScreen() {
    return [
      Expanded(
        // 这里的盒子，只是单纯区分休息时显示下一个要小点，跟练时图片大点
        flex: 4,
        child: buildExerciseImage(actions[_currentIndex].exercise),
      ),
      // 在跟练页面显示当前训练占全部的进度条
      SizedBox(
        height: 3,
        child: LinearProgressIndicator(
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation(Colors.blue),
          value: (_currentIndex + 1) / actions.length,
        ),
      ),
      Expanded(
        flex: 1,
        child: Row(
          children: [
            // 为了居中的占位
            Expanded(flex: 1, child: Container()),
            Expanded(
              flex: 8,
              child: Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: actions[_currentIndex].exercise.exerciseName,
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // TextSpan(
                      //   text: "\n${_currentIndex + 1}/${actions.length}",
                      //   style: TextStyle(
                      //     color: Colors.black,
                      //     fontSize: 20.sp,
                      //     fontWeight: FontWeight.w400,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.lightGreen),
                onPressed: () {
                  // 点击了帮助按钮，就默认是点击了暂停按钮，要暂停倒计时，并修改状态相关内容
                  _actionController.pause();
                  setState(() {
                    pausedMoment = DateTime.now();
                    isActionPause = true;
                  });

                  showDialog(
                    context: context,
                    // 将该属性设置为false，禁止点击空白关闭弹窗
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('动作技术要点'),
                        // 设置弹窗宽度高度(好像有上限不能全屏，也好想这个sw、sh相对数值也没用)
                        // content: SizedBox(
                        //   width: 1.sw,
                        //   height: 0.5.sh,
                        //   child: SingleChildScrollView(
                        //     child: Text(
                        //       "${actions[_currentIndex].exercise.instructions}",
                        //       style: TextStyle(fontSize: 14.sp),
                        //     ),
                        //   ),
                        // ),
                        content: SingleChildScrollView(
                          child: Text(
                            "${actions[_currentIndex].exercise.instructions}",
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('关闭'),
                            onPressed: () {
                              // 点击了帮助信息的关闭按钮，就默认是点击了继续，则要统计暂停事件，修改状态等
                              _actionController.resume();
                              setState(() {
                                // 点击继续时需要统计该次暂停的时间
                                totalPausedTimes +=
                                    DateTime.now().millisecondsSinceEpoch -
                                        pausedMoment.millisecondsSinceEpoch;
                                // 统计完重置一下(也可能没必要)
                                pausedMoment = DateTime.now();

                                isActionPause = false;
                              });
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      Expanded(
        flex: 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              flex: 1,
              child: Text(
                // ？？？理论是一定有的，这个也需要优化一下这个常量
                '${countingOptions.firstWhere((e) => e.value == actions[_currentIndex].exercise.countingMode).cnLabel} ',
                style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                textAlign: TextAlign.start,
              ),
            ),

            // 跟练的倒计时和休息(含预备)的稍微不一样，用于区分(一个重点在环，一个重点在数字)
            CircularCountDownTimer(
              controller: _actionController,
              duration: _getCurrentActionDuration(),
              initialDuration: 0,
              width: 0.3.sw,
              height: 0.3.sw,
              ringColor: Colors.grey[300]!,
              fillColor: Colors.green,
              strokeWidth: 5.0,
              strokeCap: StrokeCap.round,
              textStyle: TextStyle(
                fontSize: 36.sp,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              textFormat: CountdownTextFormat.MM_SS,
              isReverse: true,
              isReverseAnimation: false,
              isTimerTextShown: true,
              autoStart: true,

              // 【原部件bug】timeFormatterFunction设置之后onChange不会触发
              timeFormatterFunction: (_, duration) {
                // ？？？2023-11-29 实际测试和在onChange中一样，倒计时到2的时候，会重复两次
                // 所以没办法在倒计时等于3时延迟tts语音
                if (duration.inSeconds == 3) {
                  // countdownTts(3);
                  _speak("3");
                }
                // 在小米6上会发两次2的语言，所以这里stop或者pause一下的话，就只有一次2的语音了，当然间隔也不一致了。
                // 也很怪，3、1、和其他文本都没有这个问题
                if (duration.inSeconds == 2) {
                  _speak("2");
                  // _stop();
                  _pause();
                }
                if (duration.inSeconds == 1) {
                  _speak("1");
                }

                // 如果这个时间不准的话，一半时间、语音提示等内容这里也放不出来了
                if (duration.inSeconds ==
                    int.parse(
                        (_getCurrentActionDuration() / 2).toStringAsFixed(0))) {
                  _speak("一半时间了");
                }

                // 倒计时不是从最大的数值开始的，+1才对得上
                return formatSeconds(
                  duration.inSeconds + 1,
                  formatString: "mm:ss",
                );
              },

              // onChange: (String timeStamp) {
              //   print("跟练 ---- timeStamp----------$timeStamp");

              //   print(
              //       "在跟练中---_actionController ${_actionController.getTime()}");

              //   var curCountTime =
              //       convertToDuration(timeStamp, CountdownTextFormat.MM_SS);
              //   // 跟练时间最后3秒，有语音倒计时

              //   /// 2023-11-29 目前这个倒计时2时会重复触发，其他还没有
              //   // ？？？这个change不是按秒变化的，那么这里可能会触发很多次，导致倒计时tts不准确。
              //   if (curCountTime?.inSeconds == 3) {
              //     print("跟练333 timeStamp----------$timeStamp");
              //     countdownTts(3);
              //     // _speak("3");
              //   }

              //   // if (curCountTime?.inSeconds == 1) {
              //   //   print("跟练1111 timeStamp----------$timeStamp");
              //   //   _speak("1");
              //   // }
              //   // 如果这个时间不准的话，一半时间、语音提示等内容这里也放不出来了
              //   if (curCountTime?.inSeconds ==
              //       int.parse(
              //         (_getCurrentActionDuration() / 2).toStringAsFixed(0),
              //       )) {
              //     _speak("一半时间");
              //   }
              // },
              onStart: () {
                // 进入开始倒计时，语音提示开始
                _speak("开始");
              },
              onComplete: () {
                debugPrint('跟练 Countdown Ended-- $_currentIndex');

                // 如果当前跟练动作还不是最后一个，则进行下一个
                if (_currentIndex < actions.length - 1) {
                  // 检查组件是否仍然存在，避免在组件已被销毁时调用 setState
                  if (!mounted) return;
                  setState(() {
                    _currentIndex++;
                    // 跟练完后，休息状态强行改为true
                    isRestTurn = true;
                  });
                } else {
                  // 如果已经是最后一个了，弹窗显示已结束
                  // 所有锻炼完成，显示弹窗
                  _speak("祝贺，锻炼已结束");
                  _showFinishedDialog();
                }
              },
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${_getActionCountString(_currentIndex)}',
                style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),

      /// 暂停继续按钮(注意，在点击上一个和跳过时，把暂停状态修改为false，因为组件是自动开始的)
      Expanded(
        flex: 1,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 设置按钮的宽高
            SizedBox(
              width: 200.sp,
              height: 50.sp,
              child:
                  // 不是暂停状态，才可以点击暂停按钮，并开始暂停时间的及时
                  (!isActionPause)
                      ? ElevatedButton.icon(
                          onPressed: () {
                            _actionController.pause();
                            setState(() {
                              pausedMoment = DateTime.now();
                              isActionPause = true;
                            });
                          },
                          icon: const Icon(Icons.pause),
                          label: const Text('暂停'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () {
                            _actionController.resume();
                            setState(() {
                              // 点击继续时需要统计该次暂停的时间
                              totalPausedTimes +=
                                  DateTime.now().millisecondsSinceEpoch -
                                      pausedMoment.millisecondsSinceEpoch;
                              // 统计完重置一下(也可能没必要)
                              pausedMoment = DateTime.now();

                              isActionPause = false;
                            });
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('继续'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
      Expanded(
        flex: 1,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextButton.icon(
              label: const Text('上一个'),
              icon: const Icon(Icons.skip_previous),
              // 按钮的文字，如果已经是第一个了就显示灰色
              style: ElevatedButton.styleFrom(
                foregroundColor: _currentIndex <= 0 ? Colors.grey : Colors.blue,
              ),
              // 如果已经是第一个了，就不让点击了(实际能点击，只是没有任何操作而已)
              onPressed: _currentIndex <= 0
                  ? () {}
                  : () {
                      // 点击上一个，先停止之前的语言(进入跟练倒计时时会自动播放开始的语音)
                      _stop();

                      //  点击上一个就直接调到上一个去了
                      setState(() {
                        _currentIndex--;
                        isRestTurn = false;

                        // 如果之前是暂停，点击上下一个时会自动开始，也就是暂停时间结束，此时要统计暂停的时间
                        if (isActionPause) {
                          totalPausedTimes +=
                              DateTime.now().millisecondsSinceEpoch -
                                  pausedMoment.millisecondsSinceEpoch;
                          // 统计完重置一下(也可能没必要)
                          pausedMoment = DateTime.now();
                        }

                        // (注意，在点击上一个和跳过时，不管之前是否是暂停，把暂停状态修改为false，因为组件是自动开始的)
                        isActionPause = false;
                      });
                      // ？？？这里有个小问题，如果当前倒计时执行了一部分时间，
                      // 再点击上一个后，虽然索引已经变了，但是时间还是点击上一个动作之前动作剩下的时间
                      // 所以这里要手动调用重新开始
                      _actionController.restart(
                        duration: _getCurrentActionDuration(),
                      );
                    },
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.sp),
              height: 20.sp,
              child: VerticalDivider(thickness: 3.sp, color: Colors.blue),
            ),
            // 如果已经是最后一个了，就不让点击了(实际能点击，只是没有任何操作而已)
            TextButton.icon(
              label: const Text('下一个'),
              icon: const Icon(Icons.skip_next),

              // 如果已经是最后一个了，直接跳到结束弹窗？？？
              onPressed: _currentIndex >= actions.length - 1
                  ? () {
                      _showFinishedDialog();
                      // 已经是最后一个的话，就重置？？？
                      _actionController.pause();
                      // 所有锻炼完成，语音提示
                      _speak("祝贺，锻炼已结束");
                    }
                  : () {
                      // 点击跳过就直接到下一个休息去
                      setState(() {
                        _currentIndex++;
                        isRestTurn = true;

                        // 如果之前是暂停，点击上下一个时会自动开始，也就是暂停时间结束，此时要统计暂停的时间
                        if (isActionPause) {
                          totalPausedTimes +=
                              DateTime.now().millisecondsSinceEpoch -
                                  pausedMoment.millisecondsSinceEpoch;
                          // 统计完重置一下(也可能没必要)
                          pausedMoment = DateTime.now();
                        }

                        // (注意，在点击上一个和跳过时，不管之前是否是暂停，把暂停状态修改为false，因为组件是自动开始的)
                        isActionPause = false;
                      });
                    },
            ),
          ],
        ),
      ),
    ];
  }

  /// 休息时的主要部件
  _buildRestScreen() {
    return [
      Expanded(
        flex: 1,
        child: Center(child: Text('休息', style: TextStyle(fontSize: 32.sp))),
      ),
      Expanded(
        flex: 3,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 出现休息倒计时一定是在跟练中间的(最后一个跟练结束就跳弹窗了),所以不用判断按钮
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () {
                  // 如果点击了+10s休息时间或者预设的休息时间，要做倒计时在完成时才累加。
                  //    注意：在休息已经进行了一段时间后再+10s，因为有restart，所以还要在+10s前累加已经休息的时间
                  setState(() {
                    print(
                        "+10s中累加的休息时间：------${_cusRestTime - (int.tryParse(_restController.getTime() ?? "0") ?? 0)}");

                    totalRestTimes += _cusRestTime -
                        (int.tryParse(_restController.getTime() ?? "0") ?? 0);
                  });

                  // 如果点击了+10s，就需要更新倒计时：旧倒计时剩下的时间+10s。
                  // _controller.getTime() 如果是倒计时，就是剩下的时间；如果是正计时，就是已经运行的时间
                  var newtime =
                      (int.tryParse(_restController.getTime() ?? "0") ?? 0) +
                          10;

                  print("点击了加10s，累加后的倒计时数值newtime $newtime ");
                  setState(() {
                    _cusRestTime = newtime;

                    // 将是否点击了增加休息时间按钮的标志设为true，用于休息的tts的判断
                    isClickPlusRestTime = true;
                  });

                  //  其他不用表，只是修改休息倒计时的显示数字
                  _restController.restart(duration: _cusRestTime);
                },
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.blue),
                ),
                child: const Text('+10s'),
              ),
            ),
            Expanded(
              flex: 2,
              // 这里的倒计时显示不是和设定的宽高一样的话，可以是外面还有Row等进行了限制
              child: CircularCountDownTimer(
                duration: _cusRestTime,
                initialDuration: 0,
                controller: _restController,
                width: 0.4.sw,
                height: 0.4.sw,
                ringColor: Colors.grey[300]!,
                ringGradient: null,
                fillColor: Colors.green,
                fillGradient: null,
                // backgroundColor: const Color.fromARGB(255, 144, 126, 148),
                backgroundColor: Colors.black38,
                backgroundGradient: null,
                strokeWidth: 10.0,
                strokeCap: StrokeCap.round,
                textStyle: TextStyle(
                  fontSize: 30.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textFormat: CountdownTextFormat.S,
                isReverse: true,
                isReverseAnimation: false,
                isTimerTextShown: true,
                autoStart: true,
                timeFormatterFunction: (_, duration) {
                  return '${duration.inSeconds + 1}';
                },
                // 当进入休息倒计时时，开始语音提示下一个动作.
                onStart: () {
                  // Here, do whatever you want
                  debugPrint('Countdown Started');

                  // 只有正常进入休息倒计时才发tts，点击了+10s后的restart不发语音
                  if (!isClickPlusRestTime) {
                    var restText =
                        "休息一下，下一个动作：${actions[_currentIndex].exercise.exerciseName}";
                    _speak(restText);
                  }
                },

                onComplete: () {
                  debugPrint('休息 Countdown Ended-- $_currentIndex');
                  setState(() {
                    print(" 休息时间自动完成时累加的时间：------$_cusRestTime");

                    // 休息完之后，要累加此处休息的时间
                    totalRestTimes += _cusRestTime;

                    // 休息完之后，休息状态强行改为fasle(休息时不能改动作索引)
                    isRestTurn = false;
                    // 注意，休息倒计时可能会被用户手动加一部分时间，所以当前休息倒计时结束时，还原为原始的休息时间
                    _cusRestTime = _defaultCusRestTime;

                    // 正常结束休息倒计时重置是否点击增加休息时间按钮的标志
                    isClickPlusRestTime = false;
                  });
                },
              ),
            ),
            // 出现休息倒计时一定是在跟练中间的(最后一个跟练结束就跳弹窗了),所以不用判断按钮

            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () {
                  // 如果是休息的时候点击跳过休息，则总休息的时间就要跳过之前已经休息的时间
                  // 如果点击了+10s休息时间或者预设的休息时间，要做倒计时在完成时才累加。
                  //    注意：在休息已经进行了一段时间后再+10s，因为有restart，所以还要在+10s前累加已经休息的时间
                  // _controller.getTime() 如果是倒计时，就是剩下的时间；如果是正计时，就是已经运行的时间

                  print(
                      "跳过休息时累加的休息时间：------${_cusRestTime - (int.tryParse(_restController.getTime() ?? "0") ?? 0)}");

                  setState(() {
                    totalRestTimes += _cusRestTime -
                        (int.tryParse(_restController.getTime() ?? "0") ?? 0);
                  });

                  // 休息时点击跳过就直接到下一个跟练去(任何的休息中都不能改动作索引，只需要隐藏休息倒计时部件即可)
                  setState(() {
                    isRestTurn = false;
                    // 在跳过休息前，可能还有+10s的操作，但这里跳过了就不会倒计时完成，所有这里跳过时重置为默认的
                    _cusRestTime = _defaultCusRestTime;
                  });

                  // 跳过休息时也停止语音
                  _stop();

                  // 跳过休息倒计时也要重置是否点击增加休息时间按钮的标志
                  isClickPlusRestTime = false;
                },
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.blue),
                ),
                child: const Text('跳过'),
              ),
            ),
          ],
        ),
      ),
      // 在跟练的完成或者跟练点击下一个时索引已经+1，此时会进入休息阶段，直接取动作的索引已经是下一个动作的信息了
      Expanded(
        flex: 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              flex: 3,
              child: RichText(
                textAlign: TextAlign.left,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '下一个动作',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      // 索引是从0开始的，这里显示的序号，所以+1
                      text: '  ${_currentIndex + 1}/${actions.length}',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: '\n${actions[_currentIndex].exercise.exerciseName}',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${_getActionCountString(_currentIndex)}',
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),

      Expanded(
        flex: 3,
        child: buildExerciseImage(actions[_currentIndex].exercise),
      ),
    ];
  }

  // TODO 跟练完成时的弹窗示例(实际可能是跳到报告页面，并保持数据到数据库)
  _showFinishedDialog() {
    var tempTime = DateTime.now().millisecondsSinceEpoch -
        startedMoment.millisecondsSinceEpoch;

    var totolTime = (tempTime / 1000).toStringAsFixed(0);
    var pausedTime = (totalPausedTimes / 1000).toStringAsFixed(0);
    var workoutTime =
        (tempTime / 1000 - totalPausedTimes / 1000 - totalRestTimes)
            .toStringAsFixed(0);

    showDialog(
      context: context,
      barrierDismissible: false, // 禁止点击空白处隐藏弹窗
      builder: (BuildContext context) => AlertDialog(
        title: const Text('恭喜！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('你已完成所有锻炼\n总耗时 $totolTime 秒，其中：'),
            Text('  暂停耗时约 $pausedTime 秒'),
            Text('  休息耗时约 $totalRestTimes 秒'),
            Text('  锻炼耗时约 $workoutTime 秒'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 实际的时候应该push and replace一个报告页面,然后这里应该在结束时记录数据，保存到数据库等等

              _restartAllExercise();
              Navigator.pop(context);
            },
            child: const Text('好的，再来一次'),
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
