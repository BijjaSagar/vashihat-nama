import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/glassmorphism.dart';
import '../services/notification_service.dart';
import '../services/background_alarm_service.dart';

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
  int frequencyHours = 0;
  int frequencyMinutes = 0;
  DateTime? lastCheckIn;

  // Biometric
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      final available = await _localAuth.getAvailableBiometrics();
      if (mounted) {
        setState(() {
          _biometricAvailable = canAuthenticate;
          _availableBiometrics = available;
        });
      }
    } catch (e) {
      debugPrint("Biometric check error: $e");
    }
  }

  Future<void> _loadStatus() async {
    try {
      final status = await ApiService().getHeartbeatStatus(widget.userId);
      if (mounted) {
        setState(() {
          isActive = status['dead_mans_switch_active'] ?? false;
          if (!isActive) {
            NotificationService().cancelHeartbeatReminder();
          }
          frequencyDays = status['check_in_frequency_days'] ?? 30;
          frequencyHours = status['check_in_frequency_hours'] ?? 0;
          frequencyMinutes = status['check_in_frequency_minutes'] ?? 0;
          lastCheckIn = DateTime.tryParse(status['last_check_in'] ?? '');
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
      print("Error loading heartbeat: $e");
    }
  }

  Future<void> _authenticateAndCheckIn() async {
    if (isCheckInLoading) return;

    // Use real biometric authentication
    if (_biometricAvailable) {
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Verify your identity to confirm you are safe',
          biometricOnly: false, // Allow PIN/pattern as fallback
          persistAcrossBackgrounding: true,
        );

        if (!authenticated) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Authentication failed. Please try again.")),
            );
          }
          return;
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Authentication error: $e")),
          );
        }
        return;
      }
    }

    // If biometric passed (or not available), proceed with check-in
    setState(() => isCheckInLoading = true);
    try {
      // ✅ BUG FIX: checkIn() now returns next_check_in directly — no extra _loadStatus() needed
      final result = await ApiService().checkIn(widget.userId);

      // Update local state from response
      final newLastCheckIn = DateTime.tryParse(result['last_check_in']?.toString() ?? '');
      final nextDue = result['next_check_in'] != null
          ? DateTime.tryParse(result['next_check_in'].toString())
          : newLastCheckIn?.add(Duration(days: frequencyDays, hours: frequencyHours, minutes: frequencyMinutes));

      if (mounted && nextDue != null) {
        setState(() {
          if (newLastCheckIn != null) lastCheckIn = newLastCheckIn;
        });
        // Schedule local notification (backup)
        NotificationService().scheduleHeartbeatReminder(nextDue: nextDue);
        // Update background service with new nextDue + dismiss any active alarm
        await saveNextDueToPrefs(nextDue);
        await dismissAlarm();
        await startHeartbeatMonitor();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Check-in Successful! You are safe.")),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isCheckInLoading = false);
    }
  }

  Future<void> _updateSettings(bool newActive, int newDays, int newHours, {int newMinutes = 0}) async {
    // Optimistic Update
    setState(() {
      isActive = newActive;
      frequencyDays = newDays;
      frequencyHours = newHours;
      frequencyMinutes = newMinutes;
    });
    
    try {
      await ApiService().updateHeartbeatSettings(
        widget.userId, 
        newActive, 
        newDays, 
        frequencyHours: newHours,
        frequencyMinutes: newMinutes,
      );

      // Update local scheduled notifications based on new settings
      if (newActive && lastCheckIn != null) {
        final nextDue = lastCheckIn!.add(Duration(days: newDays, hours: newHours, minutes: newMinutes));
        // Reschedule local notification (backup)
        NotificationService().scheduleHeartbeatReminder(nextDue: nextDue);
        // Start background alarm service with updated nextDue
        await saveNextDueToPrefs(nextDue);
        await startHeartbeatMonitor();
      } else if (!newActive) {
        NotificationService().cancelHeartbeatReminder();
        await clearNextDue();
        await stopHeartbeatMonitor();
      }
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
      nextDue = lastCheckIn!.add(Duration(days: frequencyDays, hours: frequencyHours, minutes: frequencyMinutes));
    }

    // Days Remaining
    int daysRemaining = 0;
    int hoursRemaining = 0;
    int minutesRemaining = 0;
    if (nextDue != null) {
      final diff = nextDue.difference(DateTime.now());
      daysRemaining = diff.inDays;
      hoursRemaining = diff.inHours.remainder(24);
      minutesRemaining = diff.inMinutes.remainder(60);
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
                              ? "If you don't check in within $frequencyDays days, $frequencyHours hours and $frequencyMinutes mins, your nominees will get access."
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
                            onTap: isCheckInLoading ? null : _authenticateAndCheckIn,
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
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(_biometricAvailable ? Icons.fingerprint : Icons.verified_user, size: 40, color: Colors.red),
                                        const Text("I'm Safe", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _biometricAvailable 
                              ? "Tap to verify with biometrics" 
                              : "Tap to check-in",
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withOpacity(0.7)),
                          ),
                          const SizedBox(height: 24),
                          // Stats
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStat("Last Check-in", lastCheckIn != null ? DateFormat('MMM d, HH:mm').format(lastCheckIn!.toLocal()) : "-"),
                              _buildStat("Next Due", nextDue != null ? DateFormat('MMM d, HH:mm').format(nextDue.toLocal()) : "-"),
                              _buildStat(
                                "Time Left", 
                                nextDue != null && nextDue.isBefore(DateTime.now()) 
                                  ? "OVERDUE" 
                                  : (daysRemaining > 0 
                                      ? "$daysRemaining d" 
                                      : (hoursRemaining > 0 ? "$hoursRemaining h" : "$minutesRemaining m")), 
                                isUrgent: nextDue != null && nextDue.isBefore(DateTime.now())
                              ),
                            ],
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // TEST NOTIFICATION BUTTON
                    if (isActive)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await NotificationService().showTestNotification();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("🔔 Test notification sent! Check your notifications.")),
                              );
                            }
                          },
                          icon: const Icon(Icons.notifications_active_rounded, color: Colors.orange),
                          label: const Text("Test Notification", style: TextStyle(fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                    
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
                            onChanged: (v) => _updateSettings(v, frequencyDays, frequencyHours, newMinutes: frequencyMinutes),
                          ),
                          const Divider(),
                          ListTile(
                            title: const Text("Check-in Days"),
                            subtitle: Text("$frequencyDays Days"),
                            trailing: DropdownButton<int>(
                              value: [0, 15, 30, 60, 90].contains(frequencyDays) ? frequencyDays : 30,
                              underline: Container(),
                              onChanged: isActive ? (val) {
                                if (val != null) _updateSettings(isActive, val, frequencyHours, newMinutes: frequencyMinutes);
                              } : null,
                              items: const [
                                DropdownMenuItem(value: 0, child: Text("0 Days")),
                                DropdownMenuItem(value: 15, child: Text("15 Days")),
                                DropdownMenuItem(value: 30, child: Text("30 Days")),
                                DropdownMenuItem(value: 60, child: Text("60 Days")),
                                DropdownMenuItem(value: 90, child: Text("90 Days")),
                              ],
                            ),
                          ),
                          const Divider(),
                          ListTile(
                            title: const Text("Internal Tracking (Hours)"),
                            subtitle: Text("$frequencyHours Hours"),
                            trailing: DropdownButton<int>(
                              value: [0, 2, 4, 8, 12, 24].contains(frequencyHours) ? frequencyHours : 0,
                              underline: Container(),
                              onChanged: isActive ? (val) {
                                if (val != null) _updateSettings(isActive, frequencyDays, val, newMinutes: frequencyMinutes);
                              } : null,
                              items: const [
                                DropdownMenuItem(value: 0, child: Text("0 Hours")),
                                DropdownMenuItem(value: 2, child: Text("2 Hours")),
                                DropdownMenuItem(value: 4, child: Text("4 Hours")),
                                DropdownMenuItem(value: 8, child: Text("8 Hours")),
                                DropdownMenuItem(value: 12, child: Text("12 Hours")),
                                DropdownMenuItem(value: 24, child: Text("24 Hours")),
                              ],
                            ),
                          ),
                          const Divider(),
                          ListTile(
                            title: const Text("Internal Tracking (Minutes)"),
                            subtitle: Text("$frequencyMinutes Minutes"),
                            trailing: DropdownButton<int>(
                              value: [0, 1, 5, 10, 30].contains(frequencyMinutes) ? frequencyMinutes : 0,
                              underline: Container(),
                              onChanged: isActive ? (val) {
                                if (val != null) _updateSettings(isActive, frequencyDays, frequencyHours, newMinutes: val);
                              } : null,
                              items: const [
                                DropdownMenuItem(value: 0, child: Text("0 Mins")),
                                DropdownMenuItem(value: 1, child: Text("1 Min")),
                                DropdownMenuItem(value: 5, child: Text("5 Mins")),
                                DropdownMenuItem(value: 10, child: Text("10 Mins")),
                                DropdownMenuItem(value: 30, child: Text("30 Mins")),
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
