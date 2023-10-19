// 1 大卡 = 4.184 千焦
const double oneCalToKjRatio = 4.18400;

class LocalStorageKey {
  // add a private constructor to prevent this class being instantiated
  // e.g. invoke `LocalStorageKey()` accidentally
  LocalStorageKey._();

  // the properties are static so that we can use them without a class instance
  // e.g. can be retrieved by `LocalStorageKey.saveUserId`.
  static const String saveUserId = 'save_user_id';
  static const String userId = 'user_id';
  static const String language = 'language';
  static const String themeMode = 'theme_mode';
  static const String enablePushNotification = 'enable_push_notification';
}
