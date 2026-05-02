import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SentinelLockdownScreen extends StatelessWidget {
  const SentinelLockdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
                ),
                child: const Icon(Icons.security_rounded, color: Colors.redAccent, size: 64),
              ),
              const SizedBox(height: 48),
              const Text(
                "SENTINEL LOCKDOWN",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "SYSTEM ACCESS HAS BEEN FROZEN DUE TO MULTIPLE SECURITY ANOMALIES DETECTED BY THE INTELLIGENCE ENGINE.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.6,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.slabDecoration.copyWith(
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: const Column(
                  children: [
                    Text(
                      "REQUIRED ACTION",
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "PLEASE USE YOUR SECONDARY HARDWARE RECOVERY KEY TO UNLOCK THE SYSTEM VIA THE WEB SUPERADMIN CONSOLE.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 64),
              TextButton(
                onPressed: () {
                  // This would normally trigger a hardware-key validation flow
                },
                child: const Text(
                  "RETRY HANDSHAKE",
                  style: TextStyle(color: Colors.white10, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
