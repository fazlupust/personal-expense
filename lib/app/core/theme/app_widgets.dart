import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/responsive.dart';
import 'app_theme.dart';

class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.sizeOf(context) == ScreenSize.mobile;
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 12),
      child: Text(
        text.tr,
        style: TextStyle(
          fontSize: mobile ? 20 : 24,
          fontWeight: FontWeight.w700,
          color: context.pal.ink,
        ),
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text.tr,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: context.pal.mute,
      ),
    ),
  );
}

/// Rounded bordered card with optional title + action link.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.title,
    this.action,
    this.onAction,
    this.trailing,
    this.flush = false,
  });

  final Widget child;
  final String? title;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;
  final bool flush;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title!.tr,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                  ),
                  if (trailing != null)
                    trailing!
                  else if (action != null)
                    InkWell(
                      onTap: onAction,
                      child: Text(
                        action!.tr,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: p.income,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: flush
                ? EdgeInsets.zero
                : EdgeInsets.fromLTRB(14, title == null ? 14 : 0, 14, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class StatItem {
  const StatItem(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;
}

class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.items, this.columns = 2});
  final List<StatItem> items;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return LayoutBuilder(
      builder: (context, c) {
        final w = (c.maxWidth - 10 * (columns - 1)) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final i in items)
              SizedBox(
                width: w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.label.tr,
                      style: TextStyle(fontSize: 15, color: p.mute),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      i.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w700,
                        color: i.color ?? p.ink,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Row of equal-width toggle buttons (labels must already be translated).
class SegmentBar<T> extends StatelessWidget {
  const SegmentBar({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.colorOf,
  });

  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;
  final Color Function(T)? colorOf;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          for (final e in options.entries)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Builder(
                  builder: (context) {
                    final sel = e.key == value;
                    final selBg = colorOf?.call(e.key) ?? p.income;
                    const selFg = Colors.white;
                    return Material(
                      color: sel ? selBg : p.card,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: sel ? selBg : p.line),
                      ),
                      child: InkWell(
                        customBorder: shape,
                        onTap: () => onChanged(e.key),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Text(
                              e.value,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: sel
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: sel ? selFg : p.mute,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum AppButtonStyle { filled, outlined, danger, cancel }

class AppButton extends StatelessWidget {
  const AppButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.style = AppButtonStyle.filled,
    this.icon,
    this.isLoading = false,
    this.height = 48,
    this.width,
    this.margin = const EdgeInsets.only(bottom: 8),
    this.fontSize = 15.5,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonStyle style;
  final IconData? icon;
  final bool isLoading;
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? margin;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final textStyle = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700);

    final Widget content = isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: fontSize + 2,
                height: fontSize + 2,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
            ],
          )
        : (icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: fontSize + 2),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label.tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                    ),
                  ),
                ],
              )
            : Text(
                label.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ));

    final effectiveOnPressed = isLoading ? null : onPressed;

    final Widget button = switch (style) {
      AppButtonStyle.filled => Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withOpacity(0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: shape,
              textStyle: textStyle,
            ),
            child: content,
          ),
        ),
      AppButtonStyle.cancel => Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE11D48), Color(0xFFF43F5E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE11D48).withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: shape,
              textStyle: textStyle,
            ),
            child: content,
          ),
        ),
      AppButtonStyle.outlined => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: p.ink,
            backgroundColor: p.bg,
            side: BorderSide(color: p.line),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: shape,
            textStyle: textStyle,
          ),
          child: content,
        ),
      AppButtonStyle.danger => OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: p.expense,
            side: BorderSide(color: p.expense),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: shape,
            textStyle: textStyle,
          ),
          child: content,
        ),
    };
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: SizedBox(width: width ?? double.infinity, height: height, child: button),
    );
  }
}
