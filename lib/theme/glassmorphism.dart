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
    this.blur = 15.0,
    this.opacity = 0.15,
    this.borderRadius,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(0),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: (color ?? Colors.white).withOpacity(opacity),
              borderRadius: borderRadius ?? BorderRadius.circular(20.0),
              border: Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.5), 
                width: 1.0,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (color ?? Colors.white).withOpacity(opacity + 0.1),
                  (color ?? Colors.white).withOpacity(opacity > 0.1 ? opacity - 0.1 : 0.0),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
