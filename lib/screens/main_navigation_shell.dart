import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'sentinel_dashboard.dart';
import 'folders_screen.dart';
import 'nominee_screen.dart';
import 'system_security_screen.dart';
import 'legal_assistant_screen.dart';
import 'video_will_screen.dart';
import 'smart_scan_screen.dart';
import 'ai_will_drafter_screen.dart';
import 'heartbeat_screen.dart';
import 'fraud_detection_screen.dart';
import 'legal_document_screen.dart';
import 'vault_health_screen.dart';
import 'nominee_readiness_screen.dart';
import 'estate_summary_screen.dart';
import 'smart_alerts_screen.dart';
import 'asset_discovery_screen.dart';
import 'regional_checklist_screen.dart';
import 'emergency_card_screen.dart';
import 'grief_support_screen.dart';
import 'security_score_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final int userId;
  const MainNavigationShell({super.key, required this.userId});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      SentinelDashboard(userId: widget.userId, scaffoldKey: _scaffoldKey),
      FoldersScreen(userId: widget.userId),
      NomineeScreen(userId: widget.userId),
      SystemSecurityScreen(userId: widget.userId),
    ];
  }

  // ── Pop the drawer route, then push a new screen immediately
  void _navigateTo(Widget screen) {
    // Pop closes the drawer overlay, then we push the destination
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  // ── Switch bottom tab after closing the drawer
  void _switchTab(int index) {
    Navigator.of(context).pop(); // close drawer
    setState(() => _currentIndex = index);
  }

  // ── Show quit confirmation dialog on back press from root shell
  Future<bool> _onWillPop() async {
    final shouldQuit = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.slabColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: AppTheme.accentColor, size: 20),
            SizedBox(width: 12),
            Text("LEAVE SENTINEL?",
                style: TextStyle(color: Colors.white, fontSize: 15,
                    fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
        content: const Text(
          "Are you sure you want to exit EverSafe? Your vault remains protected.",
          style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white38,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text("STAY",
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
              foregroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text("EXIT",
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ],
      ),
    );
    return shouldQuit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // If drawer is open, close it instead of quitting
        if (_scaffoldKey.currentState?.isDrawerOpen == true) {
          _scaffoldKey.currentState?.closeDrawer();
          return;
        }
        final quit = await _onWillPop();
        if (quit && context.mounted) {
          // Actually exit the app
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundColor,
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.04), width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppTheme.backgroundColor,
          selectedItemColor: AppTheme.accentColor,
          unselectedItemColor: Colors.white24,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 1),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.radar_rounded, size: 20)),
              label: 'PULSE',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.shield_rounded, size: 20)),
              label: 'VAULT',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.account_tree_rounded, size: 20)),
              label: 'FLOW',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.settings_input_component_rounded, size: 20)),
              label: 'SYSTEM',
            ),
          ],
        ),
      ),
      ), // close Scaffold
    ); // close PopScope
  }

  // ────────────────────────────── DRAWER ────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.backgroundColor,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                // ─ Core Services ─
                _sectionLabel("CORE SERVICES"),
                _tabTile("Dashboard",  Icons.radar_rounded,         0),
                _tabTile("My Vault",   Icons.folder_rounded,        1),
                _tabTile("Nominees",   Icons.people_rounded,        2),
                _tabTile("System",     Icons.settings_input_component_rounded, 3),

                // ─ Operations ─
                _sectionLabel("OPERATIONS"),
                _navTile("Legal Assistant", Icons.psychology_rounded,      LegalAssistantScreen(userId: widget.userId)),
                _navTile("Smart Scan",      Icons.qr_code_scanner_rounded, SmartScanScreen(userId: widget.userId)),
                _navTile("Video Will",      Icons.videocam_rounded,        VideoWillScreen(userId: widget.userId)),
                _navTile("AI Will Drafter", Icons.edit_document,           AIWillDrafterScreen(userId: widget.userId)),

                // ─ Protection ─
                _sectionLabel("PROTECTION"),
                _navTile("Proof of Life",   Icons.favorite_rounded,        HeartbeatScreen(userId: widget.userId)),
                _navTile("Security Health", Icons.verified_user_rounded,   SecurityScoreScreen(userId: widget.userId)),
                _navTile("Fraud Detection", Icons.warning_rounded,         FraudDetectionScreen(userId: widget.userId)),

                // ─ AI Intelligence ─
                _sectionLabel("AI INTELLIGENCE"),
                _navTile("Legal Documents",   Icons.memory_rounded,       LegalDocumentScreen(userId: widget.userId)),
                _navTile("Vault Health",      Icons.query_stats_rounded,  VaultHealthScreen(userId: widget.userId)),
                _navTile("Nominee Readiness", Icons.fact_check_rounded,   NomineeReadinessScreen(userId: widget.userId)),
                _navTile("Estate Summary",    Icons.bar_chart_rounded,    EstateSummaryScreen(userId: widget.userId)),

                // ─ Planning & Personal ─
                _sectionLabel("PLANNING & PERSONAL"),
                _navTile("Smart Alerts",       Icons.notifications_active_rounded, SmartAlertsScreen(userId: widget.userId)),
                _navTile("Asset Discovery",    Icons.travel_explore_rounded,       AssetDiscoveryScreen(userId: widget.userId)),
                _navTile("Regional Compliance",Icons.public_rounded,               RegionalChecklistScreen(userId: widget.userId)),
                _navTile("Emergency Card",     Icons.medical_services_rounded,     EmergencyCardScreen(userId: widget.userId)),
                _navTile("Grief Support",      Icons.volunteer_activism_rounded,   const GriefSupportScreen()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_rounded, color: AppTheme.accentColor, size: 26),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("EVERSAFE",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
              Text("SENTINEL SYSTEM",
                  style: TextStyle(color: AppTheme.accentColor.withValues(alpha: 0.6),
                      fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 28, 8, 8),
      child: Text(label,
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
    );
  }

  /// Tile that switches a bottom tab (no push)
  Widget _tabTile(String name, IconData icon, int tabIndex) {
    final bool active = _currentIndex == tabIndex;
    return ListTile(
      onTap: () => _switchTab(tabIndex),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon,
          color: active ? AppTheme.accentColor : AppTheme.accentColor.withValues(alpha: 0.35),
          size: 22),
      title: Text(name,
          style: TextStyle(
              color: active ? Colors.white : Colors.white60,
              fontSize: 15,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
      trailing: active
          ? const Icon(Icons.circle, color: AppTheme.accentColor, size: 7)
          : null,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  /// Tile that pushes a new screen
  Widget _navTile(String name, IconData icon, Widget screen) {
    return ListTile(
      onTap: () => _navigateTo(screen),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Icon(icon, color: AppTheme.accentColor.withValues(alpha: 0.4), size: 22),
      title: Text(name,
          style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500)),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}
