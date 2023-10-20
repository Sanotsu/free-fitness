import '../../models/training_state.dart';

/// 基础活动的一些分类选项
/// 来源： https://lite.datasette.io/?json=https://github.com/yuhonas/free-exercise-db/blob/main/dist/exercises.json#/data/exercises?_facet=force
List<ExerciseDefaultOption> mechanicOptions = [
  ExerciseDefaultOption(label: "孤立动作", value: 'isolation'),
  ExerciseDefaultOption(label: "复合动作", value: 'compound'),
];

List<ExerciseDefaultOption> forceOptions = [
  ExerciseDefaultOption(label: "拉", value: 'pull'),
  ExerciseDefaultOption(label: "推", value: 'push'),
  ExerciseDefaultOption(label: "静", value: 'static'),
];

List<ExerciseDefaultOption> levelOptions = [
  ExerciseDefaultOption(label: "初级", value: 'beginner'),
  ExerciseDefaultOption(label: "中级", value: 'intermediate'),
  ExerciseDefaultOption(label: "专家", value: 'expert'),
];

List<ExerciseDefaultOption> categoryOptions = [
  ExerciseDefaultOption(label: "力量", value: 'strength'),
  ExerciseDefaultOption(label: "拉伸", value: 'stretching'),
  ExerciseDefaultOption(label: "肌肉增强", value: 'plyometrics'),
  ExerciseDefaultOption(label: "力量举重", value: 'powerlifting'),
  ExerciseDefaultOption(label: "大力士", value: 'strongman'),
  ExerciseDefaultOption(label: "有氧", value: 'cardio'),
  ExerciseDefaultOption(label: "无氧", value: 'anaerobic'),
];

List<ExerciseDefaultOption> equipmentOptions = [
  ExerciseDefaultOption(label: "无器械", value: 'body'),
  ExerciseDefaultOption(label: "杠铃", value: 'barbell'),
  ExerciseDefaultOption(label: "哑铃", value: 'dumbbell'),
  ExerciseDefaultOption(label: "缆绳", value: 'cable'),
  ExerciseDefaultOption(label: "壶铃", value: 'kettlebells'),
  ExerciseDefaultOption(label: "健身带", value: 'bands'),
  ExerciseDefaultOption(label: "健身实心球", value: 'medicine ball'),
  ExerciseDefaultOption(label: "健身球", value: 'exercise ball'),
  ExerciseDefaultOption(label: "泡沫辊", value: 'foam roll'),
  ExerciseDefaultOption(label: "e-z卷曲棒", value: 'e-z curl bar'),
  ExerciseDefaultOption(label: "机器", value: 'machine'),
  ExerciseDefaultOption(label: "其他", value: 'other'),
];

List<ExerciseDefaultOption> standardDurationOptions = [
  ExerciseDefaultOption(label: "1 秒", value: '1'),
  ExerciseDefaultOption(label: "2 秒", value: '2'),
  ExerciseDefaultOption(label: "3 秒", value: '3'),
  ExerciseDefaultOption(label: "4 秒", value: '4'),
  ExerciseDefaultOption(label: "5 秒", value: '5'),
  ExerciseDefaultOption(label: "6 秒", value: '6'),
  ExerciseDefaultOption(label: "7 秒", value: '7'),
  ExerciseDefaultOption(label: "8 秒", value: '8'),
  ExerciseDefaultOption(label: "9 秒", value: '9'),
  ExerciseDefaultOption(label: "10 秒", value: '10'),
];

final List<ExerciseDefaultOption> musclesOptions = [
  ExerciseDefaultOption(label: "四头肌", value: 'quadriceps'),
  ExerciseDefaultOption(label: "肩膀", value: 'shoulders'),
  ExerciseDefaultOption(label: "腹肌", value: 'abdominals'),
  ExerciseDefaultOption(label: "胸部", value: 'chest'),
  ExerciseDefaultOption(label: "腘绳肌腱", value: 'hamstrings'),
  ExerciseDefaultOption(label: "三头肌", value: 'triceps'),
  ExerciseDefaultOption(label: "二头肌", value: 'biceps'),
  ExerciseDefaultOption(label: "背阔肌", value: 'lats'),
  ExerciseDefaultOption(label: "中背", value: 'middle back'),
  ExerciseDefaultOption(label: "小腿肌", value: 'calves'),
  ExerciseDefaultOption(label: "下背肌肉", value: 'lower back'),
  ExerciseDefaultOption(label: "前臂", value: 'forearms'),
  ExerciseDefaultOption(label: "臀肌", value: 'glutes'),
  ExerciseDefaultOption(label: "斜方肌", value: 'trapezius'),
  ExerciseDefaultOption(label: "内收肌", value: 'adductors'),
  ExerciseDefaultOption(label: "展肌", value: 'abductors'),
  ExerciseDefaultOption(label: "脖子", value: 'neck'),
];
