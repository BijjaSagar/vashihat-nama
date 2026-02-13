import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/glassmorphism.dart';

class HeartbeatScreen extends StatefulWidget {
  final int userId;
  const HeartbeatScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _HeartbeatScreenState createState() => _HeartbeatScreenState();
}

class _HeartbeatScreenState extends State<HeartbeatScreen> {
  bool isLoading = true;
  bool isCheckInLoading = false;
  
  // Status
  bool isActive = false;
  int frequencyDays = 30;
  DateTime? lastCheckIn;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final status = await ApiService().getHeartbeatStatus(widget.userId);
      if (mounted) {
        setState(() {
          isActive = status['dead_mans_switch_active'] ?? false;
          frequencyDays = status['check_in_frequency_days'] ?? 30;
          lastCheckIn = DateTime.tryParse(status['last_check_in'] ?? '');
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      print("Error loading heartbeat: $e");
    }
  }

  Future<void> _checkIn() async {
    setState(() => isCheckInLoading = true);
    try {
      await ApiService().checkIn(widget.userId);
      // Wait a bit for effect
      await Future.delayed(const Duration(seconds: 1));
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Check-in Successful! You are safe.")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isCheckInLoading = false);
    }
  }

  Future<void> _updateSettings(bool newActive, int newDays) async {
    // Optimistic Update
    setState(() {
      isActive = newActive;
      frequencyDays = newDays;
    });
    
    try {
      await ApiService().updateHeartbeatSettings(widget.userId, newActive, newDays);
    } catch (e) {
       _loadStatus(); // Revert on error
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to update settings: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate Next Due date
    DateTime? nextDue;
    if (lastCheckIn != null) {
      nextDue = lastCheckIn!.add(Duration(days: frequencyDays));
    }

    // Days Remaining
    int daysRemaining = 0;
    if (nextDue != null) {
      daysRemaining = nextDue.difference(DateTime.now()).inDays;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Proof of Life ❤️", style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
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
                    // BIG STATUS CARD
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            isActive ? Icons.favorite : Icons.favorite_border,
                            size: 64,
                            color: isActive ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isActive ? "Active Monitoring" : "Monitoring Inactive",
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isActive 
                              ? "If you don't check in within $frequencyDays days, your nominees will get access."
                              : "Enable to automatically share access in case of emergency.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // CHECK IN BUTTON
                    if (isActive) 
                      Column(
                        children: [
                          GestureDetector(
                            onTap: isCheckInLoading ? null : _checkIn,
                            child: Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  )
                                ],
                                border: Border.all(color: Colors.redAccent, width: 4),
                              ),
                              child: Center(
                                child: isCheckInLoading 
                                  ? const CircularProgressIndicator(color: Colors.red)
                                  : const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.fingerprint, size: 40, color: Colors.red),
                                        Text("I'm Safe", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStat("Last Check-in", lastCheckIn != null ? DateFormat('MMM d').format(lastCheckIn!) : "-"),
                              _buildStat("Next Due", nextDue != null ? DateFormat('MMM d').format(nextDue) : "-"),
                              _buildStat("Days Left", daysRemaining > 0 ? "$daysRemaining" : "OVERDUE", isUrgent: daysRemaining <= 3),
                            ],
                          ),
                        ],
                      ),

                    const SizedBox(height: 40),
                    
                    // SETTINGS
                    const Align(alignment: Alignment.centerLeft, child: Text("Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 16),
                    GlassCard(
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text("Dead Man's Switch"),
                            subtitle: const Text("Grant access if I stop checking in"),
                            value: isActive,
                            activeColor: Colors.red,
                            onChanged: (v) => _updateSettings(v, frequencyDays),
                          ),
                          const Divider(),
                          ListTile(
                            title: const Text("Check-in Frequency"),
                            subtitle: Text("$frequencyDays Days"),
                            trailing: DropdownButton<int>(
                              value: [15, 30, 60, 90].contains(frequencyDays) ? frequencyDays : 30,
                              underline: Container(),
                              onChanged: isActive ? (val) {
                                if (val != null) _updateSettings(isActive, val);
                              } : null,
                              items: const [
                                DropdownMenuItem(value: 15, child: Text("15 Days")),
                                DropdownMenuItem(value: 30, child: Text("30 Days")),
                                DropdownMenuItem(value: 60, child: Text("60 Days")),
                                DropdownMenuItem(value: 90, child: Text("90 Days")),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, {bool isUrgent = false}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isUrgent ? Colors.red : AppTheme.textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}
