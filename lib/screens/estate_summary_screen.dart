import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class EstateSummaryScreen extends StatefulWidget {
  final int userId;
  const EstateSummaryScreen({super.key, required this.userId});

  @override
  State<EstateSummaryScreen> createState() => _EstateSummaryScreenState();
}

class _EstateSummaryScreenState extends State<EstateSummaryScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _loading = true);
    try {
      final result = await _api.getEstateSummary(widget.userId);
      if (mounted) {
        setState(() { 
          _data = result; 
          _loading = false; 
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

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
        title: const Text("Estate Intel", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : _data == null
              ? const Center(child: Text("SECURE DATA RETRIEVAL FAILURE", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildSectionHeader("QUANTUM METRICS"),
                    const SizedBox(height: 16),
                    _buildStatsGrid(),
                    const SizedBox(height: 40),
                    _buildSectionHeader("EXECUTIVE ANALYSIS"),
                    const SizedBox(height: 16),
                    _buildAISummary(),
                    const SizedBox(height: 40),
                    _buildSectionHeader("SECURITY POSTURE"),
                    const SizedBox(height: 16),
                    _buildStrengthsRisks(),
                    const SizedBox(height: 40),
                    _buildSectionHeader("STRATEGIC RECOMMENDATIONS"),
                    const SizedBox(height: 16),
                    _buildRecommendations(),
                    const SizedBox(height: 64),
                  ],
                ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2));
  }

  Widget _buildHeader() {
    final user = _data!['data']?['user'];
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.slabDecoration.copyWith(
        gradient: LinearGradient(
          colors: [AppTheme.accentColor.withOpacity(0.05), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          const Icon(Icons.insights_rounded, color: AppTheme.accentColor, size: 40),
          const SizedBox(height: 24),
          const Text("ESTATE AUDIT", style: TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 3)),
          const SizedBox(height: 12),
          Text(user?['name']?.toString().toUpperCase() ?? "SUBJECT ALPHA", 
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          Text("GENERATED: ${DateTime.now().toString().substring(0, 10)}  |  STATUS: VALIDATED", 
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = _data!['stats'] ?? {};
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _statTile("VAULT ITEMS", stats['total_vault_items']?.toString() ?? "0", Icons.inventory_2_outlined),
        _statTile("NOMINEES", stats['total_nominees']?.toString() ?? "0", Icons.people_outline_rounded),
        _statTile("SECURE FILES", stats['total_files']?.toString() ?? "0", Icons.description_outlined),
        _statTile("ACTIVE ALERTS", stats['total_alerts']?.toString() ?? "0", Icons.shield_outlined, color: Colors.orangeAccent),
      ],
    );
  }

  Widget _statTile(String label, String value, IconData icon, {Color color = AppTheme.accentColor}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.slabDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color.withOpacity(0.5), size: 16),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildAISummary() {
    final summary = _data!['ai_summary']?['executive_summary'] ?? "Analyzing vault metrics...";
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.slabDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentColor, size: 16),
              const SizedBox(width: 12),
              const Text("AI SYNTHESIS", style: TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 24),
          Text(summary, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.8, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStrengthsRisks() {
    final strengths = (_data!['ai_summary']?['strengths'] as List?) ?? [];
    final risks = (_data!['ai_summary']?['risks'] as List?) ?? [];

    return Column(
      children: [
        _buildListSlab("PROTECTION STRENGTHS", strengths, Colors.greenAccent),
        const SizedBox(height: 24),
        _buildListSlab("CRITICAL VULNERABILITIES", risks, Colors.redAccent),
      ],
    );
  }

  Widget _buildListSlab(String title, List<dynamic> items, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.slabDecoration.copyWith(
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 24),
          if (items.isEmpty)
            const Text("NO DATA AVAILABLE", style: TextStyle(color: Colors.white12, fontSize: 11, fontWeight: FontWeight.w800))
          else
            ...items.map((i) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start, 
                children: [
                  Text("• ", style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(i.toString(), style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6, fontWeight: FontWeight.w500))),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recs = (_data!['ai_summary']?['recommendations'] as List?) ?? [];
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.slabDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, 
        children: [
          ...recs.map((r) => Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                const Icon(Icons.bolt_rounded, color: AppTheme.accentColor, size: 20),
                const SizedBox(width: 16),
                Expanded(child: Text(r.toString(), style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.6, fontWeight: FontWeight.w600))),
              ],
            ),
          )),
          if (recs.isEmpty)
            const Center(child: Text("NO RECOMMENDATIONS", style: TextStyle(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.w900))),
        ],
      ),
    );
  }
}
