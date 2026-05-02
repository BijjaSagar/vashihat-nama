import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'heartbeat_screen.dart';
import 'nominee_screen.dart';
import 'smart_scan_screen.dart';

class SecurityScoreScreen extends StatefulWidget {
  final int userId;
  const SecurityScoreScreen({super.key, required this.userId});

  @override
  _SecurityScoreScreenState createState() => _SecurityScoreScreenState();
}

class _SecurityScoreScreenState extends State<SecurityScoreScreen> {
  bool isLoading = true;
  int score = 0;
  List<dynamic> checks = [];

  @override
  void initState() {
    super.initState();
    _loadScore();
  }

  Future<void> _loadScore() async {
    if (mounted) setState(() => isLoading = true);
    try {
      final data = await ApiService().getSecurityScore(widget.userId);
      if (mounted) {
        setState(() {
          score = data['score'] ?? 0;
          checks = data['checks'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _handleFix(String label) {
    if (label.contains("Dead Man")) {
      Navigator.push(context, MaterialPageRoute(builder: (c) => HeartbeatScreen(userId: widget.userId))).then((_) => _loadScore());
    } else if (label.contains("Nominee")) {
      Navigator.push(context, MaterialPageRoute(builder: (c) => NomineeScreen(userId: widget.userId))).then((_) => _loadScore());
    } else if (label.contains("Document")) {
      Navigator.push(context, MaterialPageRoute(builder: (c) => SmartScanScreen(userId: widget.userId))).then((_) => _loadScore());
    }
  }

  @override
  Widget build(BuildContext context) {
    Color scoreColor = score >= 80 ? Colors.greenAccent : (score >= 50 ? Colors.orangeAccent : Colors.redAccent);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Security Intelligence", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildScoreSlab(scoreColor),
                const SizedBox(height: 48),
                const Text("VULNERABILITY ASSESSMENT", style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 16),
                ...checks.map((check) => _buildCheckSlab(check)).toList(),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildScoreSlab(Color color) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.slabDecoration.copyWith(
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 140, 
                height: 140,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 4,
                  color: color,
                  backgroundColor: Colors.white.withOpacity(0.02),
                ),
              ),
              Column(
                children: [
                  Text(
                    "$score%",
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: color, letterSpacing: -1),
                  ),
                  Text("RATING", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: color.withOpacity(0.5), letterSpacing: 2)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            score >= 80 ? "INTEGRITY SECURED" : "VULNERABILITIES DETECTED",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            score >= 80 
              ? "All core security protocols are operational and verified."
              : "Manual intervention required to stabilize vault integrity.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckSlab(dynamic check) {
    final bool passed = check['passed'];
    final color = passed ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.slabDecoration,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(
              passed ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(check['label'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  passed ? "+${check['points']} PROTOCOL POINTS" : (check['fix'] ?? "NEEDS RESOLUTION"), 
                  style: TextStyle(color: color.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                ),
              ],
            ),
          ),
          if (!passed)
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: () => _handleFix(check['label']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text("RESOLVE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
              ),
            ),
        ],
      ),
    );
  }
}
