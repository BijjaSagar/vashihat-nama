import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Legal Sovereignty", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegalSlab(
              "GDPR & DATA SOVEREIGNTY",
              "We operate under a strict Zero-Knowledge mandate. Your data is encrypted locally on your device before reaching our sanctuary. We have no technical means to access, read, or share your private keys or vault content."
            ),
            const SizedBox(height: 24),
            _buildLegalSlab(
              "LEGACY EXECUTION DISCLAIMER",
              "Ever Keep is a secure storage and monitoring platform. While we provide advanced tools for legacy preservation, this application does not replace formal legal counsel or statutory wills. Users are advised to integrate this platform into their broader estate planning."
            ),
            const SizedBox(height: 24),
            _buildLegalSlab(
              "PROOFS OF VIGILANCE",
              "The 'Dead Man's Switch' mechanism is a digital convenience service. Access is granted to nominees only upon a verified failure of the 'Heartbeat' signal. Ever Keep is not liable for data loss resulting from forgotten passwords or lost recovery keys."
            ),
            const SizedBox(height: 48),
            const Center(
              child: Text(
                "VERIFIED SECURE • APRIL 2026",
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalSlab(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.slabDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
