import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'activity_log_screen.dart';
import 'profile_screen.dart';

class SystemSecurityScreen extends StatelessWidget {
  final int userId;
  const SystemSecurityScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(context),
              _buildSecurityScoreSlab(),
              _buildRecentActivitySection(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("SYSTEM INTEGRITY", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.01),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_input_component_rounded, color: AppTheme.accentColor, size: 20),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ProfileScreen(userId: userId))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityScoreSlab() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(40),
      decoration: AppTheme.slabDecoration,
      child: Column(
        children: [
          const Text("INTEGRITY INDEX", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 48),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: 0.92,
                  strokeWidth: 3,
                  backgroundColor: Colors.white.withOpacity(0.02),
                  color: AppTheme.accentColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  const Text("92%", style: TextStyle(color: AppTheme.accentColor, fontSize: 42, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  const SizedBox(height: 4),
                  Text("OPTIMIZED", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 56),
          _buildCheckItem(Icons.lock_rounded, "ENCRYPTION LAYER", "AES-256 ACTIVE"),
          _buildDivider(),
          _buildCheckItem(Icons.devices_rounded, "TRUSTED NODES", "3 CONNECTED"),
          _buildDivider(),
          _buildCheckItem(Icons.backup_rounded, "VAULT SYNC", "STABLE"),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(color: Colors.white.withOpacity(0.02), height: 32);

  Widget _buildCheckItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.01),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white.withOpacity(0.2), size: 16),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const Icon(Icons.verified_rounded, color: AppTheme.accentColor, size: 14),
      ],
    );
  }

  Widget _buildRecentActivitySection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ACCESS LOGS", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 24),
          _buildLogEntry("AUTHENTICATION SUCCESS", "IPHONE 14 PRO | 08:21 AM"),
          _buildLogEntry("ARTIFACT ACCESSED", "AADHAAR_CARD.PDF | 11:15 PM"),
          _buildLogEntry("PROTOCOL UPDATED", "BACKUP_FREQUENCY | 09:45 AM"),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ActivityLogScreen(userId: userId))),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.05)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("EXPAND ACTIVITY LOGS", style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(String action, String detail) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.accentColor),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(action, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
