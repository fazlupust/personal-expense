import 'package:flutter/material.dart';

enum ScreenSize { mobile, tablet, desktop }

class Responsive {
  Responsive._();

  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 1024;

  static ScreenSize sizeOf(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= desktopBreakpoint) return ScreenSize.desktop;
    if (w >= tabletBreakpoint) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }

  static double maxContentWidth(ScreenSize s) => switch (s) {
        ScreenSize.mobile => double.infinity,
        ScreenSize.tablet => 760,
        ScreenSize.desktop => 1040,
      };

  static double pagePadding(ScreenSize s) => s == ScreenSize.mobile ? 16 : 24;
}

/// Scrollable page body with centered, width-limited content.
class ContentWrap extends StatelessWidget {
  const ContentWrap({super.key, required this.child, this.bottomSpace = 96});
  final Widget child;
  final double bottomSpace;

  @override
  Widget build(BuildContext context) {
    final s = Responsive.sizeOf(context);
    final pad = Responsive.pagePadding(s);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, 14, pad, bottomSpace),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(s)),
          child: child,
        ),
      ),
    );
  }
}

/// One column on phones, two side-by-side columns on tablet/desktop.
class AdaptiveColumns extends StatelessWidget {
  const AdaptiveColumns({super.key, required this.left, required this.right});
  final List<Widget> left;
  final List<Widget> right;

  @override
  Widget build(BuildContext context) {
    if (Responsive.sizeOf(context) == ScreenSize.mobile) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...left, ...right]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: left)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: right)),
      ],
    );
  }
}
