import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NomineeReadinessScreen extends StatefulWidget {
  final int userId;
  const NomineeReadinessScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<NomineeReadinessScreen> createState() => _NomineeReadinessScreenState();
}

class _NomineeReadinessScreenState extends State<NomineeReadinessScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final result = await _api.getNomineeReadiness(widget.userId);
      setState(() { _data = result; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 50) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Nominee Readiness', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('Failed to load'))
              : RefreshIndicator(onRefresh: _loadData, child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildOverallScore(),
                    const SizedBox(height: 24),
                    ...(_data!['reports'] as List? ?? []).map((r) => _buildNomineeCard(r)).toList(),
                  ],
                )),
    );
  }

  Widget _buildOverallScore() {
    final score = _data!['overall_score'] ?? 0;
    final color = _getScoreColor(score);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: [
        const Text('Overall Readiness', style: TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 12),
        Stack(alignment: Alignment.center, children: [
          SizedBox(width: 120, height: 120,
            child: CircularProgressIndicator(value: score / 100, strokeWidth: 10, backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation(color))),
          Text('$score%', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 16),
        Text(score >= 80 ? '✅ Your nominees are well-prepared!' : score >= 50 ? '⚠️ Some nominees need attention' : '🔴 Critical gaps in nominee setup',
          style: const TextStyle(color: Colors.white, fontSize: 15)),
      ]),
    );
  }

  Widget _buildNomineeCard(dynamic report) {
    final score = report['readiness_score'] ?? 0;
    final color = _getScoreColor(score);
    final checks = (report['checks'] as List?) ?? [];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          leading: Stack(alignment: Alignment.center, children: [
            SizedBox(width: 48, height: 48,
              child: CircularProgressIndicator(value: score / 100, strokeWidth: 4, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation(color))),
            Text('$score', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color)),
          ]),
          title: Text(report['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          subtitle: Text('${report['relationship'] ?? 'N/A'} • ${report['assigned_items'] ?? 0} items',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
          children: checks.map<Widget>((check) {
            final passed = check['passed'] == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Icon(passed ? Icons.check_circle : Icons.cancel, color: passed ? const Color(0xFF4CAF50) : const Color(0xFFF44336), size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(check['label'] ?? '', style: TextStyle(fontSize: 14, color: passed ? Colors.black87 : Colors.red[700]))),
                if (!passed && check['fix'] != null)
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('Fix', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.orange[700]))),
              ]),
            );
          }).toList(),
        ),
      ),
    );
  }
}
