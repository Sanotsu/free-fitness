import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

// 单纯是因为AppLocalizations类名太长了，所以包装了一个短的类名
class CusAL {
  static AppLocalizations of(BuildContext context) {
    return AppLocalizations.of(context)!;
  }
}
