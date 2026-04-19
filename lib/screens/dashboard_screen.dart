import 'package:flutter/material.dart';
import '../theme/glassmorphism.dart';
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
  final Map<String, dynamic>? userProfile; // Accept profile data directly

  const SecureDashboardScreen({Key? key, this.userProfile}) : super(key: key);

  @override
  _SecureDashboardScreenState createState() => _SecureDashboardScreenState();
}

class _SecureDashboardScreenState extends State<SecureDashboardScreen> {
  Map<String, dynamic>? userProfile;
  late int userId;
  Timer? _heartbeatTimer;
  bool _isOverdueReminded = false;

  @override
  void initState() {
    super.initState();
    userProfile = widget.userProfile;
    _setupUserId();
    _startHeartbeatMonitoring();
  }

  void _setupUserId() {
    if (userProfile != null) {
      if (userProfile!.containsKey('id')) {
        userId = userProfile!['id'] is int ? userProfile!['id'] : int.tryParse(userProfile!['id'].toString()) ?? 0;
      } else if (userProfile!.containsKey('user') && userProfile!['user'] is Map) {
         userId = userProfile!['user']['id'] is int ? userProfile!['user']['id'] : int.tryParse(userProfile!['user']['id'].toString()) ?? 0;
      } else {
        userId = 0;
      }
    } else {
      userId = 0;
    }
  }

  void _startHeartbeatMonitoring() {
    // Initial check
    _checkHeartbeatStatus();
    _checkSmartAlerts();
    // Periodic check every 10 minutes while app is active
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _checkHeartbeatStatus();
      _checkSmartAlerts();
    });
  }

  Future<void> _checkSmartAlerts() async {
    if (userId == 0) return;
    try {
      final alerts = await ApiService().getSmartAlerts(userId, upcomingOnly: true);
      if (alerts.isNotEmpty) {
        // Find if any are EXPIRED or EXPIRING SOON
        int urgentCount = 0;
        for (var alert in alerts) {
           final expiry = DateTime.tryParse(alert['expiry_date'] ?? '');
           if (expiry != null && expiry.difference(DateTime.now()).inDays < 30) {
             urgentCount++;
           }
        }
        
        if (urgentCount > 0) {
          // Show a local notification for smart alerts
          NotificationService().showNotification(
            2001,
            'Urgent: Smart Alerts 🔔',
            'You have $urgentCount documents expiring soon. Please check your Smart Alerts.',
          );
        }
      }
    } catch (e) {
      print("Error checking smart alerts: $e");
    }
  }

  Future<void> _checkHeartbeatStatus() async {
    if (userId == 0) return;
    try {
      final status = await ApiService().getHeartbeatStatus(userId);
      final bool isActive = status['dead_mans_switch_active'] ?? false;
      
      if (isActive) {
        final DateTime? lastCheckIn = DateTime.tryParse(status['last_check_in'] ?? '');
        final int days = status['check_in_frequency_days'] ?? 30;
        final int hours = status['check_in_frequency_hours'] ?? 0;
        final int minutes = status['check_in_frequency_minutes'] ?? 0;

        DateTime? nextDue;
        if (lastCheckIn != null) {
          nextDue = lastCheckIn.add(Duration(days: days, hours: hours, minutes: minutes));
          if (nextDue.isBefore(DateTime.now())) {
            _showOverdueReminder();
          }
        }

        NotificationService().scheduleHeartbeatReminder(nextDue: nextDue);
      } else {
        NotificationService().cancelHeartbeatReminder();
      }
    } catch (e) {
      print("Error checking heartbeat: $e");
    }
  }

  void _showOverdueReminder() {
    if (_isOverdueReminded) return;
    _isOverdueReminded = true;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => PopScope(
        canPop: false,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                "Proof of Life Overdue!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 12),
              const Text(
                "Your heartbeat check-in is overdue. If you don't check-in soon, your nominees will be notified and granted access to your vault.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HeartbeatScreen(userId: userId)),
                    );
                    _isOverdueReminded = false;
                    _checkHeartbeatStatus();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Perform Check-In Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine Display Name
    String userName = "User";
    if (userProfile != null) {
        userName = userProfile!['name'] ?? userProfile!['user']?['name'] ?? "User";
    }
    
    return Scaffold(
      extendBody: true, // Important for glass bottom bar
      backgroundColor: AppTheme.backgroundColor, // Use light background
      body: Container(
        decoration: const BoxDecoration(
          // Subtle Apple-like Mesh Gradient (Light Blue / White)
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF2F2F7), // System Gray 6 (Light)
              Color(0xFFE5E5EA), // System Gray 5 (Slightly darker for depth)
              Color(0xFFF2F2F7),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome Back,",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$userName's Vault", 
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.textPrimary, // Black text
                            letterSpacing: -0.5, // Apple style tightness
                          ),
                        ),
                      ],
                    ),
                    // Profile Icon in Glass (White frosted)
                    GestureDetector(
                      onTap: () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userProfile: userProfile)));
                      },
                      child: GlassCard(
                        borderRadius: BorderRadius.circular(50),
                        padding: const EdgeInsets.all(8),
                        blur: 6,
                        opacity: 0.95,
                        color: Colors.white,
                        child: const Icon(Icons.person, color: AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GlassCard(
                  opacity: 0.95,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: const TextField(
                    style: TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      icon: Icon(Icons.search, color: Colors.grey),
                      hintText: "Search encrypted files...",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Quick Actions Grid
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(24),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildActionCard(
                      context,
                      "Secure Folders",
                      Icons.folder_shared_rounded,
                      Colors.blueAccent,
                      () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => FoldersScreen(userId: userId)));
                      },
                    ),
                    _buildActionCard(
                      context,
                      "Nominees",
                      Icons.people_alt_rounded,
                      Colors.purpleAccent,
                      () {
                         Navigator.push(context, MaterialPageRoute(builder: (context) => NomineeScreen(userId: userId)));
                      },
                    ),
                    _buildActionCard(
                      context,
                      "AI Will Drafter",
                      Icons.psychology_rounded,
                      Colors.cyan,
                      () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => AIWillDrafterScreen(userId: userId)));
                      },
                    ),
                      _buildActionCard(
                        context,
                        "Smart Scan",
                        Icons.document_scanner_rounded,
                        Colors.orangeAccent,
                        () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => SmartScanScreen(userId: userId)));
                        },
                      ),
                      _buildActionCard(
                        context,
                        "Smart Alerts",
                        Icons.notifications_active_rounded,
                        Colors.redAccent,
                        () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => SmartAlertsScreen(userId: userId)));
                        },
                      ),
                      _buildActionCard(
                        context,
                        "Proof of Life",
                        Icons.favorite_rounded,
                        Colors.pinkAccent,
                        () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => HeartbeatScreen(userId: userId)));
                        },
                      ),
                      _buildActionCard(
                        context,
                        "Security Health",
                        Icons.shield_rounded,
                        Colors.green,
                        () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => SecurityScoreScreen(userId: userId)));
                        },
                      ),
                      _buildActionCard(
                        context,
                        "Regional Compliance",
                        Icons.public_rounded,
                        Colors.teal,
                        () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => RegionalChecklistScreen(userId: userId)));
                        },
                      ),
                       _buildActionCard(
                        context,
                        "AI Legal Assistant",
                        Icons.auto_awesome_rounded,
                        Colors.deepPurple,
                        () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => LegalAssistantScreen(userId: userId)));
                        },
                      ),
                      // ===== 10 NEW AI FEATURES =====
                      _buildActionCard(
                        context,
                        "Vault Health",
                        Icons.health_and_safety_rounded,
                        const Color(0xFF1A237E),
                        () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => VaultHealthScreen(userId: userId)));
                        },
                      ),
                      _buildActionCard(
                        context,
                        "Video Will",
                        Icons.videocam_rounded,
                        const Color(0xFF880E4F),
                        () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => VideoWillScreen(userId: userId)));
                        },
                      ),
                      _buildActionCard(
                        context,
                        "Asset Discovery",
                        Icons.search_rounded,
                        const Color(0xFF00695C),
                        () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => AssetDiscoveryScreen(userId: userId)));
                        },
                      ),
                      _buildActionCard(
                        context,
                        "Nominee Readiness",
                        Icons.assignment_turned_in_rounded,
                        const Color(0xFF4A148C),
                        () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => NomineeReadinessScreen(userId: userId)));
                        },
                      ),
                      _buildActionCard(
                        context,
                        "Estate Summary",
                        Icons.assessment_rounded,
                        const Color(0xFF0D47A1),
                        () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => EstateSummaryScreen(userId: userId)));
                        },
                      ),
                      _buildActionCard(
                        context,
                        "Security Monitor",
                        Icons.security_rounded,
                        const Color(0xFFB71C1C),
                        () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => FraudDetectionScreen(userId: userId)));
                        },
                      ),
                      _buildActionCard(
                        context,
                        "Grief Support",
                        Icons.favorite_border_rounded,
                        const Color(0xFF5C6BC0),
                        () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const GriefSupportScreen()));
                        },
                      ),
                      _buildActionCard(
                        context,
                        "Legal Documents",
                        Icons.description_rounded,
                        const Color(0xFF00695C),
                        () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => LegalDocumentScreen(userId: userId)));
                        },
                      ),
                      _buildActionCard(
                        context,
                        "Emergency Card",
                        Icons.emergency_rounded,
                        const Color(0xFFD84315),
                        () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => EmergencyCardScreen(userId: userId)));
                        },
                      ),
                    const SizedBox(height: 32),
                    // LEGAL DISCLAIMER & GDPR
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Text(
                            "This application is for secure storage purposes only. It is not legally challengeable under Indian law for any purpose.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textSecondary.withOpacity(0.7),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const LegalScreen()));
                            },
                            child: const Text(
                              "GDPR Compliance & Privacy Policy",
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // Extra space for bottom nav
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Glass Bottom Navigation Bar
      bottomNavigationBar: GlassCard(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
        borderRadius: BorderRadius.circular(30),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        opacity: 0.96, // Nearly solid white
        color: Colors.white, 
        blur: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.home_filled, color: AppTheme.primaryColor), onPressed: () {}),
            IconButton(icon: const Icon(Icons.upload_file, color: Colors.grey), onPressed: () {}),
            IconButton(icon: const Icon(Icons.settings, color: Colors.grey), onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(userProfile: userProfile)));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        opacity: 0.95, // Nearly solid white tiles
        color: Colors.white,
        blur: 6,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

