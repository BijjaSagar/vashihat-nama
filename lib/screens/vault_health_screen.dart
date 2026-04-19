import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/glassmorphism.dart';
import 'dart:math' as math;

class VaultHealthScreen extends StatefulWidget {
  final int userId;
  const VaultHealthScreen({Key? key, required this.userId}) : super(key: key);

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
    try {
      final result = await _api.getVaultHealth(widget.userId);
      setState(() {
        _data = result;
        _loading = false;
        _scoreAnim = Tween<double>(begin: 0, end: (result['score'] ?? 0).toDouble()).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
      });
      _animController.forward();
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 50) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return const Color(0xFFF44336);
      case 'medium': return const Color(0xFFFF9800);
      default: return const Color(0xFF2196F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Vault Health', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('Failed to load'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildScoreCard(),
                      const SizedBox(height: 20),
                      _buildStatsRow(),
                      const SizedBox(height: 24),
                      const Text('🎯 Recommendations', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      ..._buildRecommendations(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _scoreAnim,
            builder: (ctx, child) {
              return SizedBox(
                width: 160, height: 160,
                child: CustomPaint(
                  painter: _ScorePainter(_scoreAnim.value / 100, _getScoreColor(_scoreAnim.value)),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${_scoreAnim.value.toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
                        const Text('Complete', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text('Your vault has ${_data!['total_items'] ?? 0} items', style: const TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = _data!['stats'] ?? {};
    return Row(
      children: [
        _statCard('📁', 'Folders', '${stats['folders'] ?? 0}', const Color(0xFF2196F3)),
        const SizedBox(width: 12),
        _statCard('👥', 'Nominees', '${stats['nominees'] ?? 0}', const Color(0xFF9C27B0)),
        const SizedBox(width: 12),
        _statCard('📄', 'Files', '${stats['files'] ?? 0}', const Color(0xFF4CAF50)),
      ],
    );
  }

  Widget _statCard(String emoji, String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecommendations() {
    final recs = (_data!['recommendations'] as List?) ?? [];
    if (recs.isEmpty) {
      return [Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: const Row(children: [Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 32), SizedBox(width: 12), Expanded(child: Text('🎉 Your vault is perfectly healthy!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))]),
      )];
    }
    return recs.map<Widget>((rec) {
      final color = _getPriorityColor(rec['priority'] ?? 'low');
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Text(rec['icon'] ?? '📌', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(rec['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text((rec['priority'] ?? '').toString().toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 4),
              Text(rec['description'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ])),
          ],
        ),
      );
    }).toList();
  }
}

class _ScorePainter extends CustomPainter {
  final double progress;
  final Color color;
  _ScorePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final bg = Paint()..color = Colors.white24..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    final fg = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 12..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, 2 * math.pi * progress, false, fg);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
