import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

class VaultHealthScreen extends StatefulWidget {
  final int userId;
  const VaultHealthScreen({super.key, required this.userId});

  @override
  State<VaultHealthScreen> createState() => _VaultHealthScreenState();
}

class _VaultHealthScreenState extends State<VaultHealthScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  late AnimationController _animController;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _scoreAnim = Tween<double>(begin: 0, end: 0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _loading = true);
    try {
      final result = await _api.getVaultHealth(widget.userId);
      if (mounted) {
        setState(() {
          _data = result;
          _loading = false;
          _scoreAnim = Tween<double>(begin: 0, end: (result['score'] ?? 0).toDouble()).animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
          );
        });
        _animController.forward(from: 0);
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
        title: const Text("Vault Health", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : _data == null
              ? const Center(child: Text('COULD NOT SYNC HEALTH', style: TextStyle(color: Colors.white24)))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppTheme.accentColor,
                  backgroundColor: AppTheme.backgroundColor,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _buildScoreSlab(),
                      const SizedBox(height: 32),
                      const Text("VAULT STATISTICS", style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 16),
                      _buildStatsGrid(),
                      const SizedBox(height: 48),
                      const Text("SAFETY RECOMMENDATIONS", style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 16),
                      ..._buildRecommendations(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildScoreSlab() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: AppTheme.slabDecoration,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _scoreAnim,
            builder: (ctx, child) {
              final score = _scoreAnim.value;
              final color = score >= 80 ? Colors.greenAccent : (score >= 50 ? Colors.orangeAccent : Colors.redAccent);
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160, height: 160,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 4,
                      color: color,
                      backgroundColor: Colors.white.withOpacity(0.02),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${score.toInt()}%', style: TextStyle(color: color, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1)),
                      Text('HEALTH', style: TextStyle(color: color.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            "VAULT CONTAINS ${_data!['total_items'] ?? 0} SECURED DOCUMENTS",
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = _data!['stats'] ?? {};
    return Row(
      children: [
        _statSlab(Icons.folder_rounded, 'FOLDERS', '${stats['folders'] ?? 0}'),
        const SizedBox(width: 12),
        _statSlab(Icons.group_rounded, 'FAMILY', '${stats['nominees'] ?? 0}'),
        const SizedBox(width: 12),
        _statSlab(Icons.file_present_rounded, 'DOCUMENTS', '${stats['files'] ?? 0}'),
      ],
    );
  }

  Widget _statSlab(IconData icon, String label, String count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: AppTheme.slabDecoration,
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppTheme.accentColor),
            const SizedBox(height: 12),
            Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecommendations() {
    final recs = (_data!['recommendations'] as List?) ?? [];
    if (recs.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: AppTheme.slabDecoration,
          child: const Row(
            children: [
              Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 24),
              SizedBox(width: 16),
              Expanded(
                child: Text('VAULT PROTECTION IS OPTIMAL.', 
                  style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)
                ),
              ),
            ],
          ),
        )
      ];
    }
    return recs.map<Widget>((rec) {
      final priority = rec['priority'] ?? 'low';
      final color = priority == 'high' ? Colors.redAccent : (priority == 'medium' ? Colors.orangeAccent : AppTheme.accentColor);
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.slabDecoration,
        child: Row(
          children: [
            Text(rec['icon'] ?? '⚡', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(rec['title'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(priority.toString().toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(rec['description'] ?? '', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
