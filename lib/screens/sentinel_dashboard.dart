import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'sentinel_lockdown_screen.dart';
import '../widgets/pulse_line.dart';
import 'ai_will_drafter_screen.dart';
import 'asset_discovery_screen.dart';
import 'emergency_card_screen.dart';
import 'heartbeat_screen.dart';
import 'nominee_screen.dart';
import 'smart_scan_screen.dart';
import 'video_will_screen.dart';
import 'folders_screen.dart';
import 'legal_assistant_screen.dart';
import 'profile_screen.dart';
import 'security_score_screen.dart';
import 'fraud_detection_screen.dart';
import 'legal_document_screen.dart';
import 'vault_health_screen.dart';
import 'nominee_readiness_screen.dart';
import 'estate_summary_screen.dart';
import 'smart_alerts_screen.dart';
import 'regional_checklist_screen.dart';
import 'grief_support_screen.dart';

class SentinelDashboard extends StatefulWidget {
  final int userId;
  // scaffoldKey is passed from MainNavigationShell so we can open the drawer
  final GlobalKey<ScaffoldState> scaffoldKey;

  const SentinelDashboard({
    super.key,
    required this.userId,
    required this.scaffoldKey,
  });

  @override
  State<SentinelDashboard> createState() => _SentinelDashboardState();
}

class _SentinelDashboardState extends State<SentinelDashboard> {
  Map<String, dynamic>? _heartbeatStatus;
  bool _isCheckingIn = false;
  String _userName = "USER";
  int _vaultItemCount = 0;
  int _nomineeCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _fetchCounts();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final profileStr = prefs.getString('userProfile');
    if (profileStr != null) {
      final profile = jsonDecode(profileStr);
      if (mounted) {
        setState(() {
          _userName = (profile['name'] ?? "USER").toString().toUpperCase();
        });
      }
    }
  }

  Future<void> _fetchCounts() async {
    try {
      final stats = await ApiService().getVaultStats(userId: widget.userId);
      final nominees = await ApiService().getNominees(widget.userId);
      
      int totalItems = 0;
      stats.forEach((key, value) {
        if (value != null) {
          if (value is int) {
            totalItems += value;
          } else {
            totalItems += int.tryParse(value.toString()) ?? 0;
          }
        }
      });

      if (mounted) {
        setState(() {
          _vaultItemCount = totalItems;
          _nomineeCount = nominees.length;
        });
      }
    } catch (e) {
      if (e.toString().contains('SENTINEL_LOCKED')) {
        _showLockdownScreen();
      }
      debugPrint("ERROR FETCHING COUNTS: $e");
    }
  }

  void _showLockdownScreen() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SentinelLockdownScreen()),
      (route) => false,
    );
  }

  Future<void> _fetchStatus() async {
    try {
      final status = await ApiService().getHeartbeatStatus(widget.userId);
      if (mounted) setState(() => _heartbeatStatus = status);
    } catch (e) {
      debugPrint("ERROR FETCHING STATUS: $e");
    }
  }

  Future<void> _confirmPresence() async {
    setState(() => _isCheckingIn = true);
    try {
      await ApiService().checkIn(widget.userId);
      await _fetchStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("PRESENCE CONFIRMED. SENTINEL STANDING BY."),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ERROR: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  // NOTE: No Scaffold here — we live inside MainNavigationShell's Scaffold.
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Top Bar ──────────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 0),
          sliver: SliverToBoxAdapter(child: _buildTopBar()),
        ),

        // ── Status Card ──────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(child: _buildSystemStatusCard()),
        ),

        // ── Core Infrastructure ───────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(child: _buildSectionHeader("CORE INFRASTRUCTURE")),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          sliver: SliverToBoxAdapter(child: _buildCoreRow()),
        ),

        // ── Operational Modules ───────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 12),
          sliver: SliverToBoxAdapter(child: _buildSectionHeader("OPERATIONAL MODULES")),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: _buildGrid([
              _Mod("LEGAL AI",    Icons.psychology_rounded,       () => _push(LegalAssistantScreen(userId: widget.userId))),
              _Mod("VIDEO WILL",  Icons.videocam_rounded,         () => _push(VideoWillScreen(userId: widget.userId))),
              _Mod("SCAN & OCR",  Icons.qr_code_scanner_rounded,  () => _push(SmartScanScreen(userId: widget.userId))),
              _Mod("WILL DRAFT",  Icons.edit_document,            () => _push(AIWillDrafterScreen(userId: widget.userId))),
            ]),
          ),
        ),

        // ── Protection & Security ─────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 12),
          sliver: SliverToBoxAdapter(child: _buildSectionHeader("PROTECTION & SECURITY")),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: _buildGrid([
              _Mod("PROOF OF LIFE",  Icons.favorite_rounded,      () => _push(HeartbeatScreen(userId: widget.userId))),
              _Mod("HEALTH SCORE",   Icons.shield_rounded,        () => _push(SecurityScoreScreen(userId: widget.userId))),
              _Mod("FRAUD MONITOR",  Icons.radar_rounded,         () => _push(FraudDetectionScreen(userId: widget.userId))),
            ]),
          ),
        ),

        // ── AI Intelligence ───────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 12),
          sliver: SliverToBoxAdapter(child: _buildSectionHeader("AI INTELLIGENCE")),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: _buildGrid([
              _Mod("LEGAL DOCS",  Icons.memory_rounded,       () => _push(LegalDocumentScreen(userId: widget.userId))),
              _Mod("VAULT HEALTH",Icons.query_stats_rounded,  () => _push(VaultHealthScreen(userId: widget.userId))),
              _Mod("READINESS",   Icons.fact_check_rounded,   () => _push(NomineeReadinessScreen(userId: widget.userId))),
              _Mod("SUMMARY",     Icons.bar_chart_rounded,    () => _push(EstateSummaryScreen(userId: widget.userId))),
            ]),
          ),
        ),

        // ── Planning & Personal ───────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 12),
          sliver: SliverToBoxAdapter(child: _buildSectionHeader("PLANNING & PERSONAL")),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
          sliver: SliverToBoxAdapter(
            child: _buildGrid([
              _Mod("SMART ALERTS",  Icons.notifications_active_rounded, () => _push(SmartAlertsScreen(userId: widget.userId))),
              _Mod("DISCOVERY",     Icons.travel_explore_rounded,       () => _push(AssetDiscoveryScreen(userId: widget.userId))),
              _Mod("REGIONAL",      Icons.public_rounded,               () => _push(RegionalChecklistScreen(userId: widget.userId))),
              _Mod("EMERGENCY",     Icons.medical_services_rounded,     () => _push(EmergencyCardScreen(userId: widget.userId))),
              _Mod("GRIEF SUPPORT", Icons.volunteer_activism_rounded,   () => _push(const GriefSupportScreen())),
            ]),
          ),
        ),
      ],
    );
  }

  // ─── TOP BAR ──────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.menu_rounded, color: AppTheme.accentColor, size: 30),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => _push(ProfileScreen(userId: widget.userId)),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3), width: 1),
            ),
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.black,
              child: Icon(Icons.shield_rounded, color: AppTheme.accentColor, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("WELCOME BACK,",
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 2),
              Text(_userName,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white54, size: 24),
          onPressed: () {},
        ),
      ],
    );
  }

  // ─── STATUS CARD ──────────────────────────────────────────────────────────
  Widget _buildSystemStatusCard() {
    // Backend returns: {dead_mans_switch_active: bool, last_check_in: timestamp, ...}
    final bool isActive = _heartbeatStatus?['dead_mans_switch_active'] == true;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.radar_rounded, color: AppTheme.accentColor, size: 14),
            const SizedBox(width: 10),
            const Text("PROOF OF LIFE MONITOR",
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ]),
          const SizedBox(height: 28),
          const SizedBox(height: 90, child: PulseLine()),
          const SizedBox(height: 28),
          Text(
            isActive ? "ALL CLEAR" : "NOT CHECKED IN",
            style: TextStyle(
                color: isActive ? AppTheme.accentColor : Colors.redAccent,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: -1),
          ),
          const SizedBox(height: 6),
          Text(
            isActive
                ? "You have confirmed your presence"
                : "Tap below to confirm you're okay",
            style: const TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _statusRow("LAST CHECK-IN", _formatTimestamp(_heartbeatStatus?['last_check_in'])),
          _statusRow("NEXT CHECK-IN", _heartbeatStatus?['next_check_in'] != null
              ? _formatTimestamp(_heartbeatStatus?['next_check_in'])
              : 'Not scheduled'),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _isCheckingIn ? null : _confirmPresence,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.backgroundColor,
                foregroundColor: AppTheme.accentColor,
                side: BorderSide(color: AppTheme.accentColor.withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: _isCheckingIn
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentColor))
                  : const Text("I'M HERE — CONFIRM PRESENCE",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic raw) {
    if (raw == null) return 'Never';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$min $ampm';
    } catch (_) {
      return raw.toString();
    }
  }

  Widget _statusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text("$label: ", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  // ─── SECTION HEADER ───────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textSecondary, size: 11),
    ]);
  }

  // ─── CORE ROW (Vault + Nominees) ──────────────────────────────────────────
  Widget _buildCoreRow() {
    return Row(children: [
      Expanded(child: _coreSlab("VAULT", "$_vaultItemCount ITEMS SECURED", Icons.folder_copy_rounded,
          () => _push(FoldersScreen(userId: widget.userId)))),
      const SizedBox(width: 16),
      Expanded(child: _coreSlab("HIERARCHY", "$_nomineeCount GUARDIANS", Icons.account_tree_rounded,
          () => _push(NomineeScreen(userId: widget.userId)))),
    ]);
  }

  Widget _coreSlab(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(subtitle,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(icon, color: AppTheme.accentColor.withValues(alpha: 0.15), size: 30),
          ),
        ]),
      ),
    );
  }

  // ─── MODULE GRID — shrinkWrap so height is auto-calculated ──────────────
  Widget _buildGrid(List<_Mod> mods) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: mods.length,
      itemBuilder: (_, i) => _modTile(mods[i]),
    );
  }

  Widget _modTile(_Mod mod) {
    return GestureDetector(
      onTap: mod.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.slabColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(mod.icon, color: AppTheme.accentColor, size: 22),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(mod.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
          ),
        ]),
      ),
    );
  }
}

class _Mod {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _Mod(this.title, this.icon, this.onTap);
}
