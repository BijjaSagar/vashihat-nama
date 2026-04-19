import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EstateSummaryScreen extends StatefulWidget {
  final int userId;
  const EstateSummaryScreen({Key? key, required this.userId}) : super(key: key);

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
    try {
      final result = await _api.getEstateSummary(widget.userId);
      setState(() { _data = result; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Estate Summary', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('AI is generating your estate summary...', style: TextStyle(color: Colors.grey)),
            ]))
          : _data == null
              ? const Center(child: Text('Failed to load'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildStatsGrid(),
                    const SizedBox(height: 20),
                    _buildAISummary(),
                    const SizedBox(height: 20),
                    _buildStrengthsRisks(),
                    const SizedBox(height: 20),
                    _buildRecommendations(),
                  ],
                ),
    );
  }

  Widget _buildHeader() {
    final user = _data!['data']?['user'];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D47A1), Color(0xFF1976D2)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.description, color: Colors.white, size: 36),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Estate Report', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            Text(user?['name'] ?? 'User', style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ]),
        ]),
        const SizedBox(height: 12),
        Text('Generated on ${DateTime.now().toString().substring(0, 16)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ]),
    );
  }

  Widget _buildStatsGrid() {
    final stats = _data!['stats'] ?? {};
    return Row(children: [
      _statTile('📦', '${stats['total_vault_items'] ?? 0}', 'Vault Items', const Color(0xFF2196F3)),
      const SizedBox(width: 12),
      _statTile('👥', '${stats['total_nominees'] ?? 0}', 'Nominees', const Color(0xFF9C27B0)),
      const SizedBox(width: 12),
      _statTile('📄', '${stats['total_files'] ?? 0}', 'Files', const Color(0xFF4CAF50)),
      const SizedBox(width: 12),
      _statTile('🔔', '${stats['total_alerts'] ?? 0}', 'Alerts', const Color(0xFFFF9800)),
    ]);
  }

  Widget _statTile(String emoji, String count, String label, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)]),
      child: Column(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ]),
    ));
  }

  Widget _buildAISummary() {
    final summary = _data!['ai_summary']?['executive_summary'] ?? 'No summary available';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.auto_awesome, color: Color(0xFF0D47A1)),
          SizedBox(width: 8),
          Text('AI Executive Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        Text(summary, style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)),
      ]),
    );
  }

  Widget _buildStrengthsRisks() {
    final strengths = (_data!['ai_summary']?['strengths'] as List?) ?? [];
    final risks = (_data!['ai_summary']?['risks'] as List?) ?? [];

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF4CAF50).withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('💪 Strengths', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF2E7D32))),
          const SizedBox(height: 8),
          ...strengths.map((s) => Padding(padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('✓ ', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w700)),
              Expanded(child: Text(s.toString(), style: const TextStyle(fontSize: 13)))]))),
        ]),
      )),
      const SizedBox(width: 12),
      Expanded(child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF44336).withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('⚠️ Risks', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFFC62828))),
          const SizedBox(height: 8),
          ...risks.map((r) => Padding(padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('• ', style: TextStyle(color: Color(0xFFF44336), fontWeight: FontWeight.w700)),
              Expanded(child: Text(r.toString(), style: const TextStyle(fontSize: 13)))]))),
        ]),
      )),
    ]);
  }

  Widget _buildRecommendations() {
    final recs = (_data!['ai_summary']?['recommendations'] as List?) ?? [];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('📋 Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...recs.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 24, height: 24, decoration: BoxDecoration(color: const Color(0xFF0D47A1), borderRadius: BorderRadius.circular(8)),
              child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)))),
            const SizedBox(width: 10),
            Expanded(child: Text(e.value.toString(), style: const TextStyle(fontSize: 14, height: 1.4))),
          ]))),
      ]),
    );
  }
}
