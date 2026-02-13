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
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        final expiry = DateTime.tryParse(alert['expiry_date'] ?? '');
                        final isExpired = expiry != null && expiry.isBefore(DateTime.now());
                        
                        return Dismissible(
                          key: Key(alert['id'].toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => _deleteAlert(alert['id']),
                          child: GlassCard(
                            margin: const EdgeInsets.bottom(12),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isExpired ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isExpired ? Icons.warning : Icons.check_circle,
                                  color: isExpired ? Colors.red : Colors.green,
                                ),
                              ),
                              title: Text(alert['doc_type'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (alert['doc_number'] != null) Text("ID: ${alert['doc_number']}"),
                                  if (expiry != null) 
                                    Text(
                                      "Expires: ${DateFormat('dd MMM yyyy').format(expiry)}",
                                      style: TextStyle(color: isExpired ? Colors.red : AppTheme.textSecondary),
                                    ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondary),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
