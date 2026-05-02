import 'package:flutter/material.dart';
import '../theme/glassmorphism.dart';
import 'legal_screen.dart';
import '../theme/app_theme.dart';
import 'folders_screen.dart'; 
import 'nominee_screen.dart'; 
import 'scan_document_screen.dart';
import 'smart_scan_screen.dart';
import 'profile_screen.dart';
import 'ai_will_drafter_screen.dart';
import 'smart_alerts_screen.dart';
import 'security_score_screen.dart';
import 'regional_checklist_screen.dart';
import 'legal_assistant_screen.dart';
import 'heartbeat_screen.dart';
import 'vault_health_screen.dart';
import 'video_will_screen.dart';
import 'asset_discovery_screen.dart';
import 'nominee_readiness_screen.dart';
import 'estate_summary_screen.dart';
import 'fraud_detection_screen.dart';
import 'grief_support_screen.dart';
import 'legal_document_screen.dart';
import 'emergency_card_screen.dart';
import 'activity_log_screen.dart';
import 'subscription_screen.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'dart:async';

class SecureDashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  const SecureDashboardScreen({Key? key, this.userProfile}) : super(key: key);

  @override
  _SecureDashboardScreenState createState() => _SecureDashboardScreenState();
}

class _SecureDashboardScreenState extends State<SecureDashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startHeartbeatMonitoring();
  }

  void _startHeartbeatMonitoring() {
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 10), (timer) {});
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String userName = widget.userProfile?['name'] ?? widget.userProfile?['user']?['name'] ?? "COMMANDER";

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Background Depth
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withOpacity(0.01),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  _buildHeader(userName),
                  const SizedBox(height: 48),
                  _buildVaultStatusHero(),
                  const SizedBox(height: 56),
                  _buildSectionHeader("OPERATIONAL PULSE"),
                  const SizedBox(height: 24),
                  _buildHeartbeatPulse(),
                  const SizedBox(height: 56),
                  _buildSectionHeader("CORE PROTOCOLS"),
                  const SizedBox(height: 24),
                  _buildActionQuads(context),
                  const SizedBox(height: 56),
                  _buildSectionHeader("INTELLIGENCE SUITE"),
                  const SizedBox(height: 24),
                  _buildIntelligenceSuite(context),
                  const SizedBox(height: 56),
                  _buildSectionHeader("SYSTEM METRICS"),
                  const SizedBox(height: 24),
                  _buildSystemMetrics(context),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("SECURE SESSION ACTIVE", style: TextStyle(color: AppTheme.accentColor.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userId: 0, userProfile: widget.userProfile))),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accentColor.withOpacity(0.2), width: 1.5),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white.withOpacity(0.01),
              child: const Icon(Icons.shield_rounded, color: AppTheme.accentColor, size: 24),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2));
  }

  Widget _buildVaultStatusHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: AppTheme.slabDecoration.copyWith(
        gradient: LinearGradient(
          colors: [AppTheme.accentColor.withOpacity(0.02), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withOpacity(0.05),
                border: Border.all(color: AppTheme.accentColor.withOpacity(0.1)),
              ),
              child: const Icon(Icons.lock_rounded, color: AppTheme.accentColor, size: 32),
            ),
          ),
          const SizedBox(height: 32),
          const Text("VAULT INTEGRITY", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 8),
          const Text("OPTIMAL", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(backgroundColor: AppTheme.accentColor, radius: 3),
                const SizedBox(width: 12),
                Text("AES-256 ENCRYPTION ACTIVE", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartbeatPulse() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: AppTheme.slabDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          painter: HeartbeatPainter(animation: _pulseController),
        ),
      ),
    );
  }

  Widget _buildActionQuads(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 24,
      mainAxisSpacing: 24,
      childAspectRatio: 1.1,
      children: [
        _buildQuadCard(context, "VAULT", Icons.folder_copy_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FoldersScreen(userId: 0)))),
        _buildQuadCard(context, "NOMINEES", Icons.hub_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NomineeScreen(userId: 0)))),
        _buildQuadCard(context, "HEARTBEAT", Icons.favorite_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HeartbeatScreen(userId: 0)))),
        _buildQuadCard(context, "DRAFTER", Icons.auto_fix_high_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AIWillDrafterScreen(userId: 0)))),
      ],
    );
  }

  Widget _buildQuadCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: AppTheme.slabDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.1), size: 32),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildIntelligenceSuite(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildToolChip("ALERTS", Icons.notifications_active_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SmartAlertsScreen(userId: 0)))),
          _buildToolChip("LEGAL AI", Icons.auto_awesome_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LegalAssistantScreen(userId: 0)))),
          _buildToolChip("DISCOVERY", Icons.radar_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AssetDiscoveryScreen(userId: 0)))),
          _buildToolChip("SURVEILLANCE", Icons.security_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ActivityLogScreen(userId: 0)))),
        ],
      ),
    );
  }

  Widget _buildToolChip(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: AppTheme.slabDecoration,
        child: Row(
          children: [
            Icon(icon, color: AppTheme.accentColor, size: 18),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemMetrics(BuildContext context) {
    return Container(
      decoration: AppTheme.slabDecoration,
      child: Column(
        children: [
          _buildMetricTile("EMERGENCY PROTOCOL", Icons.emergency_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyCardScreen(userId: 0)))),
          _buildDivider(),
          _buildMetricTile("VAULT CAPACITY", Icons.pie_chart_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionScreen(userId: 0)))),
          _buildDivider(),
          _buildMetricTile("SECURITY SCORE", Icons.speed_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SecurityScoreScreen(userId: 0)))),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Icon(icon, color: Colors.white.withOpacity(0.05), size: 18),
      title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.05), size: 12),
    );
  }

  Widget _buildDivider() => Divider(color: Colors.white.withOpacity(0.02), height: 1, indent: 24, endIndent: 24);

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, spreadRadius: 0)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.grid_view_rounded, true),
          _buildNavItem(Icons.shield_rounded, false),
          _buildNavItem(Icons.history_rounded, false),
          _buildNavItem(Icons.settings_rounded, false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool active) {
    return Icon(icon, color: active ? AppTheme.accentColor : Colors.white.withOpacity(0.05), size: 24);
  }
}

class HeartbeatPainter extends CustomPainter {
  final Animation<double> animation;
  HeartbeatPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accentColor.withOpacity(0.2)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height / 2);
    
    for (double x = 0; x <= size.width; x += 1) {
      double y = size.height / 2;
      double relativeX = (x + (animation.value * 150)) % 150;
      if (relativeX > 60 && relativeX < 75) {
        y -= 40 * (relativeX - 60) / 15;
      } else if (relativeX >= 75 && relativeX < 90) {
        y += 20 * (relativeX - 75) / 15;
      } else if (relativeX >= 90 && relativeX < 105) {
        y -= 10 * (relativeX - 90) / 15;
      }
      
      if (x == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
