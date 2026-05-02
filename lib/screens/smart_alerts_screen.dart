import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SmartAlertsScreen extends StatefulWidget {
  final int userId;
  const SmartAlertsScreen({super.key, required this.userId});

  @override
  _SmartAlertsScreenState createState() => _SmartAlertsScreenState();
}

class _SmartAlertsScreenState extends State<SmartAlertsScreen> {
  List<dynamic> alerts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    if (mounted) setState(() => isLoading = true);
    try {
      final fetchedAlerts = await ApiService().getSmartAlerts(widget.userId, upcomingOnly: false);
      if (mounted) {
        setState(() {
          alerts = fetchedAlerts;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _deleteAlert(int id) async {
    try {
      await ApiService().deleteSmartAlert(id, widget.userId);
      _loadAlerts();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ALERT DISMISSED FROM INTELLIGENCE STREAM'), backgroundColor: AppTheme.accentColor));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('OPERATION ERROR: $e'), backgroundColor: Colors.redAccent));
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
        title: const Text("INTELLIGENCE ALERTS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : alerts.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildStatsHeader(),
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemCount: alerts.length,
                        itemBuilder: (context, index) {
                          final alert = alerts[index];
                          final expiry = DateTime.tryParse(alert['expiry_date'] ?? '');
                          final isExpired = expiry != null && expiry.isBefore(DateTime.now());
                          final isUrgent = expiry != null && !isExpired && expiry.difference(DateTime.now()).inDays < 30;
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Dismissible(
                              key: Key(alert['id'].toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 32),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 28),
                              ),
                              onDismissed: (_) => _deleteAlert(alert['id']),
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: AppTheme.slabDecoration.copyWith(
                                  border: Border.all(
                                    color: (isExpired ? Colors.redAccent : isUrgent ? Colors.orangeAccent : AppTheme.accentColor).withOpacity(0.05)
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: (isExpired ? Colors.redAccent : isUrgent ? Colors.orangeAccent : AppTheme.accentColor).withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: (isExpired ? Colors.redAccent : isUrgent ? Colors.orangeAccent : AppTheme.accentColor).withOpacity(0.1)),
                                      ),
                                      child: Icon(
                                        isExpired ? Icons.report_problem_rounded : isUrgent ? Icons.notification_important_rounded : Icons.info_outline_rounded,
                                        color: isExpired ? Colors.redAccent : isUrgent ? Colors.orangeAccent : AppTheme.accentColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            alert['doc_type'].toString().toUpperCase(),
                                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white, letterSpacing: 0.5),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            alert['doc_number']?.toString().toUpperCase() ?? "UNAVAILABLE",
                                            style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                                          ),
                                          if (expiry != null) ...[
                                            const SizedBox(height: 24),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.02),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: Colors.white.withOpacity(0.03)),
                                              ),
                                              child: Text(
                                                "${isExpired ? 'EXPIRED' : 'EXPIRES'}: ${DateFormat('dd MMM yyyy').format(expiry).toUpperCase()}",
                                                style: TextStyle(
                                                  color: isExpired ? Colors.redAccent : isUrgent ? Colors.orangeAccent : AppTheme.accentColor,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.5,
                                                ),
                                              ),
                                            ),
                                          ]
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: Colors.white.withOpacity(0.01)),
          const SizedBox(height: 32),
          const Text("NO ACTIVE ALERTS", style: TextStyle(color: Colors.white10, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    int total = alerts.length;
    int urgent = 0;
    int expired = 0;

    for (var a in alerts) {
      final expiry = DateTime.tryParse(a['expiry_date'] ?? '');
      if (expiry != null) {
        if (expiry.isBefore(DateTime.now())) {
          expired++;
        } else if (expiry.difference(DateTime.now()).inDays < 30) {
          urgent++;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          _buildStatItem("TOTAL", total.toString(), Colors.white24),
          const SizedBox(width: 16),
          _buildStatItem("URGENT", urgent.toString(), Colors.orangeAccent),
          const SizedBox(width: 16),
          _buildStatItem("EXPIRED", expired.toString(), Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: AppTheme.slabDecoration,
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color == Colors.white24 ? Colors.white : color, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}
