import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;

  const GlassCard({
    Key? key,
    required this.child,
    this.blur = 8.0,
    this.opacity = 0.92, // Much more opaque by default — almost solid white
    this.borderRadius,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(20.0);
    final baseColor = color ?? Colors.white;

    return Container(
      margin: margin ?? const EdgeInsets.all(0),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: radius,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              // Solid background with slight transparency for glass feel
              color: baseColor.withOpacity(opacity),
              borderRadius: radius,
              border: Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.6),
                width: 0.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
