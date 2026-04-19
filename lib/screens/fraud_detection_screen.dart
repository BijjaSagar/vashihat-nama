import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FraudDetectionScreen extends StatefulWidget {
  final int userId;
  const FraudDetectionScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<FraudDetectionScreen> createState() => _FraudDetectionScreenState();
}

class _FraudDetectionScreenState extends State<FraudDetectionScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _logs = [];
  int _suspiciousCount = 0;
  bool _loading = true;
  bool _showSuspiciousOnly = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final result = await _api.getActivityLogs(widget.userId, suspiciousOnly: _showSuspiciousOnly);
      setState(() {
        _logs = result['logs'] ?? [];
        _suspiciousCount = result['suspicious_count'] ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  IconData _getActionIcon(String action) {
    if (action.contains('login')) return Icons.login;
    if (action.contains('upload')) return Icons.upload;
    if (action.contains('delete')) return Icons.delete;
    if (action.contains('view')) return Icons.visibility;
    if (action.contains('share')) return Icons.share;
    return Icons.touch_app;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Security Monitor', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(_showSuspiciousOnly ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () { setState(() { _showSuspiciousOnly = !_showSuspiciousOnly; _loading = true; }); _loadData(); }),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildStatusCard(),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_showSuspiciousOnly ? '🚨 Suspicious Activity' : '📋 Recent Activity',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  Text('${_logs.length} events', style: const TextStyle(color: Colors.grey)),
                ]),
                const SizedBox(height: 12),
                if (_logs.isEmpty) 
                  Container(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_outline, size: 60, color: Colors.green[300]),
                    const SizedBox(height: 12),
                    Text(_showSuspiciousOnly ? 'No suspicious activity detected!' : 'No activity logs yet',
                      style: const TextStyle(color: Colors.grey, fontSize: 16)),
                  ]))
                else
                  ..._logs.map((log) => _buildLogItem(log)).toList(),
              ],
            ),
    );
  }

  Widget _buildStatusCard() {
    final isClean = _suspiciousCount == 0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: isClean ? [const Color(0xFF2E7D32), const Color(0xFF43A047)] : [const Color(0xFFB71C1C), const Color(0xFFE53935)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16)),
          child: Icon(isClean ? Icons.shield : Icons.warning, color: Colors.white, size: 36)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isClean ? 'All Clear' : 'Attention Required', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(isClean ? 'No suspicious activity on your account' : '$_suspiciousCount suspicious event(s) detected',
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ])),
      ]),
    );
  }

  Widget _buildLogItem(dynamic log) {
    final isSus = log['is_suspicious'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSus ? Colors.red.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isSus ? Border.all(color: Colors.red.withOpacity(0.3)) : null,
        boxShadow: [if (!isSus) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: (isSus ? Colors.red : const Color(0xFF2196F3)).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(_getActionIcon(log['action'] ?? ''), color: isSus ? Colors.red : const Color(0xFF2196F3), size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(log['action'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
            if (isSus) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
              child: const Text('⚠️ SUSPICIOUS', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 4),
          if (log['device_info'] != null) Text(log['device_info'], style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(_formatDate(log['created_at']), style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ])),
      ]),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    try {
      final d = DateTime.parse(date);
      return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (e) { return date; }
  }
}
