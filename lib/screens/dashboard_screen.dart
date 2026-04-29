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
  bool _isOverdueReminded = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startHeartbeatMonitoring();
  }

  void _startHeartbeatMonitoring() {
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      // Background checks for notifications
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String userName = widget.userProfile?['name'] ?? widget.userProfile?['user']?['name'] ?? "User";

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Premium Mesh Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.8),
                    AppTheme.backgroundColor,
                  ],
                ),
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
                  const SizedBox(height: 20),
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Welcome Back,", style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                          Text("$userName's Vault", style: AppTheme.darkTheme.textTheme.headlineMedium),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userProfile: widget.userProfile))),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.accentColor, width: 2),
                          ),
                          child: const CircleAvatar(
                            backgroundColor: AppTheme.surfaceColor,
                            child: Icon(Icons.person, color: AppTheme.platinumColor),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // PILLAR 1: THE HERO (Vault Status)
                  _buildVaultStatusHero(),

                  const SizedBox(height: 40),

                  // PILLAR 2: THE PULSE (Dead Man's Switch)
                  _buildHeartbeatPulse(),

                  const SizedBox(height: 40),

                  // PILLAR 3: THE QUADS (Primary Actions)
                  _buildActionQuads(context),

                  const SizedBox(height: 40),

                  // Category: AI & Legal Suite
                  const Text("AI Security Suite", style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildToolChip("Smart Alerts", Icons.notifications_active, () => Navigator.push(context, MaterialPageRoute(builder: (context) => SmartAlertsScreen(userId: 0)))),
                        _buildToolChip("Legal AI", Icons.auto_awesome, () => Navigator.push(context, MaterialPageRoute(builder: (context) => LegalAssistantScreen(userId: 0)))),
                        _buildToolChip("Asset Scan", Icons.search, () => Navigator.push(context, MaterialPageRoute(builder: (context) => AssetDiscoveryScreen(userId: 0)))),
                        _buildToolChip("Video Will", Icons.videocam, () => Navigator.push(context, MaterialPageRoute(builder: (context) => VideoWillScreen(userId: 0)))),
                      ],
                    ),
                  ),
                  
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

  Widget _buildVaultStatusHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.1),
            blurRadius: 40,
            spreadRadius: -10,
          )
        ],
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentColor.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: const Icon(Icons.shield_rounded, color: AppTheme.accentColor, size: 40),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Vault Status", style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          const Text("SECURE", style: TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(backgroundColor: Colors.green, radius: 4),
                SizedBox(width: 8),
                Text("Argon2id + AES-256 Active", style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartbeatPulse() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Dead Man's Switch Pulse", style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text("ARMED", style: TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: CustomPaint(
              painter: HeartbeatPainter(animation: _pulseController),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionQuads(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildQuadCard(context, "Documents", Icons.folder_copy_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => FoldersScreen(userId: 0)))),
        _buildQuadCard(context, "Nominees", Icons.group_add_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => NomineeScreen(userId: 0)))),
        _buildQuadCard(context, "Check-In", Icons.favorite_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => HeartbeatScreen(userId: 0)))),
        _buildQuadCard(context, "AI Drafter", Icons.auto_fix_high_rounded, () => Navigator.push(context, MaterialPageRoute(builder: (context) => AIWillDrafterScreen(userId: 0)))),
      ],
    );
  }

  Widget _buildQuadCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.platinumColor, size: 36),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildToolChip(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.accentColor, size: 22),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, spreadRadius: -5)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Icon(Icons.home_filled, color: AppTheme.accentColor, size: 28),
          Icon(Icons.shield_moon_rounded, color: AppTheme.textSecondary.withOpacity(0.5), size: 28),
          Icon(Icons.grid_view_rounded, color: AppTheme.textSecondary.withOpacity(0.5), size: 28),
          Icon(Icons.settings_rounded, color: AppTheme.textSecondary.withOpacity(0.5), size: 28),
        ],
      ),
    );
  }
}

class HeartbeatPainter extends CustomPainter {
  final Animation<double> animation;
  HeartbeatPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accentColor.withOpacity(0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height / 2);
    
    for (double x = 0; x <= size.width; x += 1) {
      double y = size.height / 2;
      
      // The Heartbeat spike logic
      double relativeX = (x + (animation.value * 100)) % 100;
      if (relativeX > 40 && relativeX < 50) {
        y -= 40 * (relativeX - 40) / 10;
      } else if (relativeX >= 50 && relativeX < 60) {
        y += 20 * (relativeX - 50) / 10;
      } else if (relativeX >= 60 && relativeX < 70) {
        y -= 10 * (relativeX - 60) / 10;
      }
      
      if (x == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    
    // Add glow effect
    canvas.drawShadow(path, AppTheme.accentColor, 4, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

