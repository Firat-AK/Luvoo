import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Liquid Glass widget - iOS 26 tarzı cam efekti
/// 
/// Kullanım:
/// ```dart
/// LiquidGlass(
///   child: YourWidget(),
///   blur: 20.0,
///   opacity: 0.15,
/// )
/// ```
class LiquidGlass extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? tintColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final List<BoxShadow>? shadows;
  final Border? border;

  const LiquidGlass({
    super.key,
    required this.child,
    this.blur = 20.0,
    this.opacity = 0.15,
    this.tintColor,
    this.borderRadius,
    this.padding,
    this.shadows,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (tintColor ?? Colors.white).withOpacity(opacity),
            borderRadius: borderRadius,
            border: border ?? Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.0,
            ),
            boxShadow: shadows ?? [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Glass Container - Daha basit kullanım için
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final double opacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 15.0,
    this.opacity = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: LiquidGlass(
        blur: blur,
        opacity: opacity,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Glass AppBar - Header için özel widget
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final double height;
  final double blur;
  final double opacity;
  final Color? backgroundColor;

  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.height = 64.0,
    this.blur = 20.0,
    this.opacity = 0.15,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      blur: blur,
      opacity: opacity,
      tintColor: backgroundColor,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      shadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SafeArea(
          child: Row(
            children: [
              if (leading != null) leading!,
              if (leading != null) const SizedBox(width: 16),
              if (title != null) Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: title!,
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}

/// Glass Bottom Bar - Bottom navigation için
class GlassBottomBar extends StatelessWidget {
  final List<Widget> children;
  final double blur;
  final double opacity;
  final EdgeInsets? padding;

  const GlassBottomBar({
    super.key,
    required this.children,
    this.blur = 20.0,
    this.opacity = 0.15,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      blur: blur,
      opacity: opacity,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(26),
        topRight: Radius.circular(26),
      ),
      shadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 20,
          offset: const Offset(0, -8),
        ),
      ],
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: children,
        ),
      ),
    );
  }
}
