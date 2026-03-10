import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/glassmorphism.dart';

class SmartAlertsScreen extends StatefulWidget {
  final int userId;
  const SmartAlertsScreen({Key? key, required this.userId}) : super(key: key);

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Smart Alerts 🔔", style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
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
              : alerts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text("No smart alerts found", style: TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _buildStatsHeader(),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: alerts.length,
                            itemBuilder: (context, index) {
                              final alert = alerts[index];
                              final expiry = DateTime.tryParse(alert['expiry_date'] ?? '');
                              final isExpired = expiry != null && expiry.isBefore(DateTime.now());
                              final isUrgent = expiry != null && !isExpired && expiry.difference(DateTime.now()).inDays < 30;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Dismissible(
                                  key: Key(alert['id'].toString()),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade400,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                                  ),
                                  onDismissed: (_) => _deleteAlert(alert['id']),
                                  child: GlassCard(
                                    opacity: 0.8,
                                    borderRadius: BorderRadius.circular(24),
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: (isExpired ? Colors.red : isUrgent ? Colors.orange : Colors.blue).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Icon(
                                            isExpired ? Icons.error_outline_rounded : isUrgent ? Icons.notification_important_rounded : Icons.verified_user_rounded,
                                            color: isExpired ? Colors.red : isUrgent ? Colors.orange : Colors.blue,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                alert['doc_type'],
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textPrimary),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                alert['doc_number'] ?? "No reference number",
                                                style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 13),
                                              ),
                                              if (expiry != null) ...[
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: (isExpired ? Colors.red : isUrgent ? Colors.orange : Colors.green).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    "${isExpired ? 'Expired' : 'Expires'}: ${DateFormat('dd MMM yyyy').format(expiry)}",
                                                    style: TextStyle(
                                                      color: isExpired ? Colors.red : isUrgent ? Colors.orange : Colors.green.shade700,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ]
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
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
        ),
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
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        children: [
          _buildStatItem("Total", total.toString(), Colors.blue),
          const SizedBox(width: 12),
          _buildStatItem("Urgent", urgent.toString(), Colors.orange),
          const SizedBox(width: 12),
          _buildStatItem("Expired", expired.toString(), Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: GlassCard(
        opacity: 0.6,
        padding: const EdgeInsets.symmetric(vertical: 16),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textSecondary.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }
}
