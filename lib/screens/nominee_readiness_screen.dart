import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class NomineeReadinessScreen extends StatefulWidget {
  final int userId;
  const NomineeReadinessScreen({super.key, required this.userId});

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
    if (mounted) setState(() => _loading = true);
    try {
      final result = await _api.getNomineeReadiness(widget.userId);
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("NOMINEE READINESS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.accentColor,
              backgroundColor: AppTheme.slabColor,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                children: [
                  _buildOverallScoreSlab(),
                  const SizedBox(height: 56),
                  const Text("INDIVIDUAL READINESS REPORTS", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 24),
                  ...(_data!['reports'] as List? ?? []).map((r) => _buildNomineeCard(r)).toList(),
                  const SizedBox(height: 64),
                ],
              ),
            ),
    );
  }

  Widget _buildOverallScoreSlab() {
    final score = _data!['overall_score'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: AppTheme.slabDecoration.copyWith(
        gradient: LinearGradient(
          colors: [AppTheme.accentColor.withOpacity(0.02), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text("SYSTEM-WIDE READINESS", style: TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 48),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 4,
                  backgroundColor: Colors.white.withOpacity(0.02),
                  color: AppTheme.accentColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Text("$score%", style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -2)),
                  const SizedBox(height: 4),
                  Text("GLOBAL INDEX", style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 56),
          Text(
            score >= 80 
              ? "OPTIMAL CONFIGURATION DETECTED. NOMINEES ARE FULLY PREPARED." 
              : score >= 50 
                ? "DEVIATIONS DETECTED. CERTAIN ACCESS NODES REQUIRE CALIBRATION." 
                : "CRITICAL VULNERABILITY: NOMINEE PREPAREDNESS BELOW SECURE THRESHOLD.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildNomineeCard(dynamic report) {
    final score = report['readiness_score'] ?? 0;
    final checks = (report['checks'] as List?) ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: AppTheme.slabDecoration,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          childrenPadding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
          leading: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 2,
                  backgroundColor: Colors.white.withOpacity(0.03),
                  color: AppTheme.accentColor.withOpacity(0.4),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text("$score", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.accentColor)),
            ],
          ),
          title: Text(
            report['name'].toString().toUpperCase(), 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "${report['relationship']?.toString().toUpperCase() ?? 'ACCESS NODE'} | ${report['assigned_items'] ?? 0} ASSETS",
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ),
          trailing: const Icon(Icons.expand_more_rounded, color: Colors.white10),
          children: [
            const Divider(color: Colors.white12, height: 40),
            ...checks.map<Widget>((check) {
              final passed = check['passed'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Icon(
                      passed ? Icons.verified_user_rounded : Icons.warning_amber_rounded, 
                      color: passed ? AppTheme.accentColor : Colors.redAccent.withOpacity(0.6), 
                      size: 16
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        check['label'].toString().toUpperCase(), 
                        style: TextStyle(
                          fontSize: 9, 
                          fontWeight: FontWeight.w800, 
                          letterSpacing: 0.5,
                          color: passed ? Colors.white70 : Colors.redAccent.withOpacity(0.8)
                        )
                      )
                    ),
                    if (!passed && check['fix'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.1))
                        ),
                        child: const Text("RESOLVE", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.redAccent, letterSpacing: 1)),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
