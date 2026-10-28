import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.card,
    required this.ink,
    required this.mute,
    required this.line,
    required this.income,
    required this.expense,
    required this.acc,
    required this.onAcc,
  });

  final Color bg, card, ink, mute, line, income, expense, acc, onAcc;

  bool get isDark => bg == dark.bg;

  static const light = AppPalette(
    bg: Color(0xFFF3F5F1),
    card: Colors.white,
    ink: Color(0xFF1D2A24),
    mute: Color(0xFF6B7A72),
    line: Color(0xFFE1E6E0),
    income: Color(0xFF1F8A5B),
    expense: Color(0xFFC2492F),
    acc: Color(0xFF1F8A5B), // Primary Emerald Green
    onAcc: Colors.white,
  );

  static const dark = AppPalette(
    bg: Color(0xFF121815),
    card: Color(0xFF1B241F),
    ink: Color(0xFFE8EFE9),
    mute: Color(0xFF8FA097),
    line: Color(0xFF2A362F),
    income: Color(0xFF4FCF94),
    expense: Color(0xFFF0866C),
    acc: Color(0xFF4FCF94),
    onAcc: Color(0xFF121815),
  );

  @override
  AppPalette copyWith({
    Color? bg, Color? card, Color? ink, Color? mute, Color? line,
    Color? income, Color? expense, Color? acc, Color? onAcc,
  }) =>
      AppPalette(
        bg: bg ?? this.bg,
        card: card ?? this.card,
        ink: ink ?? this.ink,
        mute: mute ?? this.mute,
        line: line ?? this.line,
        income: income ?? this.income,
        expense: expense ?? this.expense,
        acc: acc ?? this.acc,
        onAcc: onAcc ?? this.onAcc,
      );

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      mute: Color.lerp(mute, other.mute, t)!,
      line: Color.lerp(line, other.line, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      acc: Color.lerp(acc, other.acc, t)!,
      onAcc: Color.lerp(onAcc, other.onAcc, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get pal =>
      Theme.of(this).extension<AppPalette>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppPalette.dark
          : AppPalette.light);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light, AppPalette.light);
  static ThemeData get dark => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness b, AppPalette p) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c),
        );
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: p.bg,
      extensions: [p],
      colorScheme: ColorScheme.fromSeed(seedColor: p.income, brightness: b)
          .copyWith(primary: p.income, surface: p.card, onSurface: p.ink),
      dividerColor: p.line,
      textTheme: TextTheme(
        bodyLarge: TextStyle(fontSize: 16.5, color: p.ink),
        bodyMedium: TextStyle(fontSize: 15, color: p.ink),
        bodySmall: TextStyle(fontSize: 13.5, color: p.mute),
        labelLarge: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: p.ink),
        labelMedium: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: p.mute),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: p.mute),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.income,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.income,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.bg,
        foregroundColor: p.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.card,
        indicatorColor: p.income.withOpacity(.15),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: p.card,
        indicatorColor: p.income.withOpacity(.15),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.bg,
        contentPadding: const EdgeInsets.all(12),
        border: border(p.line),
        enabledBorder: border(p.line),
        focusedBorder: border(p.income),
        errorBorder: border(p.expense),
        focusedErrorBorder: border(p.expense),
      ),
    );
  }
}
