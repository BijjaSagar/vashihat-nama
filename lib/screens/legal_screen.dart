import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/glassmorphism.dart';

class LegalScreen extends StatelessWidget {
  const LegalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Legal & Privacy", style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF2F2F7), Color(0xFFE5E5EA)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  title: "GDPR Compliance",
                  content: "We are committed to protecting your privacy. This app complies with General Data Protection Regulation (GDPR) principles:\n\n"
                      "• Your data is encrypted locally before being stored.\n"
                      "• You have the right to access and delete your data at any time.\n"
                      "• We do not share your private keys or sensitive data with any third party.\n"
                      "• All data processing happens securely and transparently.",
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: "Legal Disclaimer",
                  content: "This application is for secure storage purposes only. It is not legally challengeable under Indian law for any purpose.\n\n"
                      "The 'Proof of Life' feature and nominee access are provided as convenience services and do not constitute a legal will or testament. Users are advised to maintain separate legal documentation for inheritance matters.",
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: "Data Security",
                  content: "Your vault items are protected using end-to-end encryption. Only you (and your designated nominees after a confirmed check-in failure) can access the content. The service providers have no technical means to decrypt your data.",
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    "Last Updated: April 2026",
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 14, height: 1.5, color: AppTheme.textPrimary),
          ),
        ],
      ),
    );
  }
}
