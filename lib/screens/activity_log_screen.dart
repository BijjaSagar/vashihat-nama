import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ActivityLogScreen extends StatefulWidget {
  final int userId;
  const ActivityLogScreen({super.key, required this.userId});

  @override
  _ActivityLogScreenState createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _logs = [];
  bool _isLoading = true;
  bool _showSuspiciousOnly = false;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final logs = await _apiService.getActivityLogs(widget.userId);
      if (mounted) {
        setState(() {
          _logs = logs['logs'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _showSuspiciousOnly 
        ? _logs.where((l) => l['is_suspicious'] == true).toList()
        : _logs;
    
    final suspiciousCount = _logs.where((l) => l['is_suspicious'] == true).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("SENTINEL SURVEILLANCE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildIntegritySlab(suspiciousCount),
          _buildControlStrip(filteredLogs.length),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
                : _buildTimelineStream(filteredLogs),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegritySlab(int suspiciousCount) {
    bool hasThreat = suspiciousCount > 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.slabDecoration.copyWith(
        border: Border.all(color: hasThreat ? Colors.redAccent.withOpacity(0.2) : AppTheme.accentColor.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: hasThreat ? Colors.redAccent.withOpacity(0.05) : AppTheme.accentColor.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: hasThreat ? Colors.redAccent.withOpacity(0.1) : AppTheme.accentColor.withOpacity(0.1)),
            ),
            child: Icon(
              hasThreat ? Icons.radar_rounded : Icons.verified_user_rounded,
              color: hasThreat ? Colors.redAccent : AppTheme.accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasThreat ? "ANOMALIES DETECTED" : "VAULT INTEGRITY OPTIMAL",
                  style: TextStyle(
                    color: hasThreat ? Colors.redAccent : AppTheme.accentColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hasThreat 
                      ? "$suspiciousCount SUSPICIOUS INTERACTIONS FLAGGED."
                      : "SYSTEM INTEGRITY VALIDATED. NO THREATS DETECTED.",
                  style: const TextStyle(color: Colors.white10, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlStrip(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showSuspiciousOnly = !_showSuspiciousOnly),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _showSuspiciousOnly ? Colors.redAccent.withOpacity(0.05) : Colors.white.withOpacity(0.01),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _showSuspiciousOnly ? Colors.redAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_rounded, size: 14, color: _showSuspiciousOnly ? Colors.redAccent : Colors.white12),
                  const SizedBox(width: 12),
                  Text(
                    _showSuspiciousOnly ? "PRIORITY THREATS" : "ALL LOGS",
                    style: TextStyle(
                      color: _showSuspiciousOnly ? Colors.redAccent : Colors.white12,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            "$count ENTRIES RECORDED",
            style: const TextStyle(color: Colors.white10, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStream(List<dynamic> logs) {
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, color: Colors.white.withOpacity(0.01), size: 64),
            const SizedBox(height: 24),
            const Text("NO INTERACTION DATA", style: TextStyle(color: Colors.white10, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        bool isSuspicious = log['is_suspicious'] == true;
        return _buildLogSlab(log, isSuspicious);
      },
    );
  }

  Widget _buildLogSlab(dynamic log, bool isSuspicious) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: isSuspicious ? Colors.redAccent.withOpacity(0.05) : Colors.white.withOpacity(0.01),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSuspicious ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05)),
                  ),
                  child: Icon(
                    _getLogIcon(log['action']),
                    color: isSuspicious ? Colors.redAccent : Colors.white12,
                    size: 18,
                  ),
                ),
                Expanded(child: Container(width: 1, margin: const EdgeInsets.symmetric(vertical: 8), color: Colors.white.withOpacity(0.03))),
              ],
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: AppTheme.slabDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          log['action'].toString().toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                        if (isSuspicious) 
                          const Text("RISK_DETECTED", style: TextStyle(color: Colors.redAccent, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      log['description']?.toString().toUpperCase() ?? "INTERACTION RECORDED",
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 10, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(width: 8),
                        Text(_formatTime(log['created_at']), style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 8, fontWeight: FontWeight.w900)),
                        const Spacer(),
                        Text("IP: ${log['ip_address'] ?? '0.0.0.0'}", style: TextStyle(color: Colors.white.withOpacity(0.05), fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getLogIcon(String action) {
    final a = action.toLowerCase();
    if (a.contains("login")) return Icons.vpn_key_rounded;
    if (a.contains("delete")) return Icons.delete_forever_rounded;
    if (a.contains("create") || a.contains("add")) return Icons.post_add_rounded;
    if (a.contains("view") || a.contains("read")) return Icons.visibility_rounded;
    if (a.contains("download") || a.contains("export")) return Icons.ios_share_rounded;
    return Icons.fingerprint_rounded;
  }

  String _formatTime(String? time) {
    if (time == null) return "UNKNOWN";
    try {
      final d = DateTime.parse(time);
      return "${d.day}/${d.month} ${d.hour}:${d.minute.toString().padLeft(2, '0')}".toUpperCase();
    } catch (e) {
      return time.toUpperCase();
    }
  }
}
