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
        child: Text(text.tr, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: context.pal.mute)),
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
    this.flush = false,
  });

  final Widget child;
  final String? title;
  final String? action;
  final VoidCallback? onAction;

  /// When true the body has no padding (lists, tables).
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
                    child: Text(title!.tr,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.ink)),
                  ),
                  if (action != null)
                    InkWell(
                      onTap: onAction,
                      child: Text(action!.tr, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.income)),
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
    return LayoutBuilder(builder: (context, c) {
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
                  Text(i.label.tr, style: TextStyle(fontSize: 13, color: p.mute)),
                  const SizedBox(height: 2),
                  Text(
                    i.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w700, color: i.color ?? p.ink),
                  ),
                ],
              ),
            ),
        ],
      );
    });
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
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          for (final e in options.entries)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Builder(builder: (context) {
                  final sel = e.key == value;
                  final selBg = colorOf?.call(e.key) ?? p.ink;
                  final selFg = colorOf != null ? Colors.white : p.bg;
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
                            style: TextStyle(fontSize: 13, color: sel ? selFg : p.mute),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

enum AppButtonStyle { filled, outlined, danger, cancel }

class AppButton extends StatelessWidget {
  const AppButton(this.label, {super.key, required this.onPressed, this.style = AppButtonStyle.filled});
  final String label;
  final VoidCallback onPressed;
  final AppButtonStyle style;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    const textStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    final child = Text(label.tr);
    final Widget button = switch (style) {
      AppButtonStyle.filled => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
              backgroundColor: p.income, foregroundColor: Colors.white, shape: shape, textStyle: textStyle),
          child: child,
        ),
      AppButtonStyle.cancel => FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
              backgroundColor: p.expense, foregroundColor: Colors.white, shape: shape, textStyle: textStyle),
          child: child,
        ),
      AppButtonStyle.outlined => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
              foregroundColor: p.ink, backgroundColor: p.bg, side: BorderSide(color: p.line),
              shape: shape, textStyle: textStyle),
          child: child,
        ),
      AppButtonStyle.danger => OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
              foregroundColor: p.expense, side: BorderSide(color: p.expense),
              shape: shape, textStyle: textStyle),
          child: child,
        ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(width: double.infinity, height: 50, child: button),
    );
  }
}
