import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/glassmorphism.dart';
import 'heartbeat_screen.dart';
import 'nominee_screen.dart';
import 'smart_scan_screen.dart';
import 'vault_items_screen.dart';

class SecurityScoreScreen extends StatefulWidget {
  final int userId;
  const SecurityScoreScreen({Key? key, required this.userId}) : super(key: key);

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
    } else if (label.contains("Vault")) {
      // Need folder id, just go back for now or show snackbar
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Go to Safe Folders to add items.")));
    } else if (label.contains("Document")) {
      Navigator.push(context, MaterialPageRoute(builder: (c) => SmartScanScreen(userId: widget.userId))).then((_) => _loadScore());
    }
  }

  @override
  Widget build(BuildContext context) {
    Color scoreColor = score >= 80 ? Colors.green : (score >= 50 ? Colors.orange : Colors.red);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Security Health 🛡️", style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF2F2F7), Color(0xFFE5E5EA)],
          ),
        ),
        child: SafeArea(
          child: isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // SCORE CARD
                    GlassCard(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 120, 
                                height: 120,
                                child: CircularProgressIndicator(
                                  value: score / 100,
                                  strokeWidth: 10,
                                  color: scoreColor,
                                  backgroundColor: Colors.grey[300],
                                ),
                              ),
                              Text(
                                "$score%",
                                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: scoreColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            score >= 80 ? "Your Vault is Secure" : "Action Required",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    const Align(alignment: Alignment.centerLeft, child: Text("Security Checklist", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 16),

                    // CHECKS LIST
                    ...checks.map((check) {
                      final bool passed = check['passed'];
                      return GlassCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            passed ? Icons.check_circle : Icons.warning_amber_rounded,
                            color: passed ? Colors.green : Colors.orange,
                          ),
                          title: Text(check['label'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: passed 
                            ? Text("+${check['points']} pts")
                            : Text(check['fix'] ?? "Tap to fix"),
                          trailing: passed 
                            ? null 
                            : ElevatedButton(
                                onPressed: () => _handleFix(check['label']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                ),
                                child: const Text("Fix", style: TextStyle(fontSize: 12, color: Colors.white)),
                              ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}
