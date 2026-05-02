import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class FraudDetectionScreen extends StatefulWidget {
  final int userId;
  const FraudDetectionScreen({super.key, required this.userId});

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
    if (mounted) setState(() => _loading = true);
    try {
      final result = await _api.getActivityLogs(widget.userId, suspiciousOnly: _showSuspiciousOnly);
      if (mounted) {
        setState(() {
          _logs = result['logs'] ?? [];
          _suspiciousCount = result['suspicious_count'] ?? 0;
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
        title: const Text("Security Monitor", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: Icon(_showSuspiciousOnly ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, color: AppTheme.accentColor),
            onPressed: () { 
              setState(() { _showSuspiciousOnly = !_showSuspiciousOnly; }); 
              _loadData(); 
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusSlab(),
                  const SizedBox(height: 40),
                  _buildSectionHeader(_showSuspiciousOnly ? "PRIORITY THREATS" : "RECENT SECURITY EVENTS"),
                  const SizedBox(height: 16),
                  if (_logs.isEmpty) 
                    _buildEmptyState()
                  else
                    ..._logs.map((log) => _buildSecurityItem(log)).toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2));
  }

  Widget _buildStatusSlab() {
    final isClean = _suspiciousCount == 0;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.slabDecoration.copyWith(
        border: Border.all(color: isClean ? AppTheme.accentColor.withOpacity(0.2) : Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isClean ? AppTheme.accentColor.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isClean ? Icons.gpp_good_rounded : Icons.gpp_maybe_rounded, 
              color: isClean ? AppTheme.accentColor : Colors.redAccent, size: 40),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isClean ? "SCAN COMPLETE" : "THREAT DETECTED", 
                  style: TextStyle(color: isClean ? AppTheme.accentColor : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(isClean ? "System integrity is optimal." : "$_suspiciousCount anomalous interactions found.",
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Icon(Icons.verified_user_outlined, size: 64, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 24),
          Text(
            _showSuspiciousOnly ? "NO ACTIVE THREATS" : "NO LOGGED EVENTS", 
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(dynamic log) {
    final isSus = log['is_suspicious'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.slabDecoration.copyWith(
        border: Border.all(color: isSus ? Colors.redAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _getLogIcon(log['action'] ?? ''),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(log['action']?.toString().toUpperCase() ?? 'EVENT', 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                    if (isSus) 
                      const Text("HIGH RISK", style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 12),
                if (log['device_info'] != null) 
                  Text(log['device_info'], style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(_formatDate(log['created_at']), 
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getLogIcon(String action) {
    IconData icon = Icons.security_rounded;
    Color color = AppTheme.accentColor;
    
    if (action.contains('login')) icon = Icons.key_rounded;
    if (action.contains('upload')) icon = Icons.cloud_upload_rounded;
    if (action.contains('delete')) { icon = Icons.delete_forever_rounded; color = Colors.redAccent; }
    if (action.contains('view')) icon = Icons.visibility_rounded;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    try {
      final d = DateTime.parse(date);
      return "${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
    } catch (e) { return date; }
  }
}
