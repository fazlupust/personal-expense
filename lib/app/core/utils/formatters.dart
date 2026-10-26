import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

class Fmt {
  Fmt._();

  static String get _lang => Get.locale?.languageCode ?? 'en';
  static const _bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];

  /// Converts ASCII digits to Bangla digits when the language is Bangla.
  static String digits(String s) => _lang != 'bn'
      ? s
      : s.replaceAllMapped(RegExp(r'[0-9]'), (m) => _bnDigits[int.parse(m[0]!)]);

  static String count(num n) => digits(n.toString());

  static String money(double n) {
    final r = n.round();
    final sign = n < 0 && r != 0 ? '−' : '';
    final body = NumberFormat.decimalPattern('en_IN').format(r.abs());
    return '$sign${AppConstants.currency}${digits(body)}';
  }

  static String date(DateTime d, String pattern) =>
      digits(DateFormat(pattern, _lang).format(d));
}
