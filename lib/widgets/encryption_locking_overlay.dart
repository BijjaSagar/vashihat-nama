import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'dart:ui';

class EncryptionLockingOverlay extends StatefulWidget {
  final String status;
  final VoidCallback onComplete;

  const EncryptionLockingOverlay({
    Key? key, 
    this.status = "Encrypting Data...",
    required this.onComplete,
  }) : super(key: key);

  @override
  _EncryptionLockingOverlayState createState() => _EncryptionLockingOverlayState();
}

class _EncryptionLockingOverlayState extends State<EncryptionLockingOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 2500), vsync: this);
    
    _rotateAnimation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8, curve: Curves.easeInOutCubic)),
    );
    
    _scaleAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward().then((_) {
      HapticFeedback.heavyImpact();
      widget.onComplete();
    });

    // Initial haptic
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blur background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.7)),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotateAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.accentColor.withOpacity(0.3), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentColor.withOpacity(0.1),
                                blurRadius: 40,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: const Icon(Icons.lock_outline_rounded, color: AppTheme.accentColor, size: 80),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                Text(
                  widget.status.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.platinumColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "AES-256-GCM + ARGON2ID",
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
