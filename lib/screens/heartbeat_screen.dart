import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class HeartbeatScreen extends StatefulWidget {
  final int userId;
  const HeartbeatScreen({super.key, required this.userId});

  @override
  _HeartbeatScreenState createState() => _HeartbeatScreenState();
}

class _HeartbeatScreenState extends State<HeartbeatScreen> {
  bool isLoading = true;
  bool isCheckInLoading = false;
  bool isActive = false;
  int frequencyDays = 30;
  int frequencyHours = 0;
  int frequencyMinutes = 0;
  DateTime? lastCheckIn;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    if (mounted) setState(() => isLoading = true);
    try {
      final status = await ApiService().getHeartbeatStatus(widget.userId);
      if (mounted) {
        setState(() {
          isActive = status['dead_mans_switch_active'] ?? false;
          frequencyDays = status['check_in_frequency_days'] ?? 30;
          frequencyHours = status['check_in_frequency_hours'] ?? 0;
          frequencyMinutes = status['check_in_frequency_minutes'] ?? 0;
          lastCheckIn = DateTime.tryParse(status['last_check_in'] ?? '');
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _checkIn() async {
    if (isCheckInLoading) return;
    setState(() => isCheckInLoading = true);
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'CONFIRM LIFE-STATE SIGNAL TO MAINTAIN VAULT SECURITY',
      );
      if (authenticated) {
        final result = await ApiService().checkIn(widget.userId);
        if (mounted) {
          setState(() {
            lastCheckIn = DateTime.tryParse(result['last_check_in'] ?? '');
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("SIGNAL RECEIVED. VIGILANCE MAINTAINED.", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            backgroundColor: AppTheme.accentColor,
          ));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("TRANSMISSION FAILURE: $e")));
    } finally {
      if (mounted) setState(() => isCheckInLoading = false);
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
        title: const Text("DIGITAL HEARTBEAT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
        centerTitle: true,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                _buildPulseIndicator(),
                const SizedBox(height: 56),
                _buildStatusSlab(),
                const SizedBox(height: 56),
                _buildProtocolSettings(),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildPulseIndicator() {
    return Center(
      child: GestureDetector(
        onLongPress: isCheckInLoading ? null : _checkIn,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _PulseRipple(active: isActive),
            Container(
              height: 220,
              width: 220,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: isActive ? AppTheme.accentColor : Colors.white.withOpacity(0.05), width: 1.5),
                boxShadow: isActive ? [
                  BoxShadow(color: AppTheme.accentColor.withOpacity(0.05), blurRadius: 60, spreadRadius: 0),
                ] : [],
              ),
              child: Center(
                child: isCheckInLoading 
                  ? const CircularProgressIndicator(color: AppTheme.accentColor, strokeWidth: 2)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fingerprint_rounded, color: isActive ? AppTheme.accentColor : Colors.white10, size: 64),
                        const SizedBox(height: 20),
                        Text(
                          isActive ? "LONG PRESS\nTO SIGNAL" : "SENTINEL\nOFFLINE", 
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isActive ? AppTheme.accentColor : Colors.white10, 
                            fontSize: 10, 
                            fontWeight: FontWeight.w900, 
                            letterSpacing: 2
                          )
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

  Widget _buildStatusSlab() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.slabDecoration.copyWith(
        border: Border.all(color: isActive ? AppTheme.accentColor.withOpacity(0.1) : Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: isActive ? Colors.greenAccent : Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: isActive ? Colors.greenAccent : Colors.redAccent, blurRadius: 8)],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                isActive ? "VIGILANCE PROTOCOL ARMED" : "LEGACY MONITOR DISARMED", 
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 11, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 1.5
                )
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            isActive 
              ? "YOUR DIGITAL HEARTBEAT IS BEING MONITORED. SILENCE EXCEEDING $frequencyDays DAYS WILL INITIATE LEGACY TRANSMISSION." 
              : "ACTIVATE THE DEAD MAN'S SWITCH TO AUTOMATE YOUR LEGACY TRANSFER IF YOU BECOME UNRESPONSIVE.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, height: 1.6, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("PROTOCOL CONFIGURATION", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 20),
        Container(
          decoration: AppTheme.slabDecoration,
          child: Column(
            children: [
              _buildSettingsTile(
                "MONITOR STATE", 
                isActive ? "ACTIVE" : "DISABLED", 
                Icons.radar_rounded, 
                () => _toggleSwitch(!isActive)
              ),
              _buildDivider(),
              _buildSettingsTile(
                "SILENCE THRESHOLD", 
                "$frequencyDays DAYS", 
                Icons.timer_rounded, 
                () => _showFrequencyDialog()
              ),
              _buildDivider(),
              _buildSettingsTile(
                "LAST PULSE CONFIRMED", 
                lastCheckIn != null ? DateFormat('MMM d, HH:mm').format(lastCheckIn!.toLocal()).toUpperCase() : "NO SIGNAL DATA", 
                Icons.history_rounded, 
                () {}
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() => Divider(color: Colors.white.withOpacity(0.02), height: 1, indent: 24, endIndent: 24);

  Widget _buildSettingsTile(String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: Icon(icon, color: AppTheme.accentColor.withOpacity(0.4), size: 18),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w900)),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 12),
        ],
      ),
    );
  }

  Future<void> _toggleSwitch(bool active) async {
    setState(() => isLoading = true);
    try {
      await ApiService().syncSentinelHeartbeat(
        userId: widget.userId,
        active: active,
        frequencyDays: frequencyDays,
        frequencyHours: frequencyHours,
        frequencyMinutes: frequencyMinutes,
      );
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(active ? "DEAD MAN'S SWITCH ARMED." : "VIGILANCE DISARMED.", style: const TextStyle(fontWeight: FontWeight.w900)),
          backgroundColor: active ? Colors.green.shade900 : Colors.red.shade900,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("CONFIGURATION FAILURE: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showFrequencyDialog() {
    final TextEditingController _daysController = TextEditingController(text: frequencyDays.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), 
          side: BorderSide(color: Colors.white.withOpacity(0.05))
        ),
        title: const Text("CALIBRATE THRESHOLD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("DEFINE THE MAXIMUM DURATION OF SILENCE BEFORE THE VAULT INITIATES ITS LEGACY PROTOCOL.", 
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, height: 1.6)),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.01), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
              child: TextField(
                controller: _daysController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.accentColor, fontSize: 32, fontWeight: FontWeight.w900),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 24),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text("SILENCE LIMIT (DAYS)", style: TextStyle(color: Colors.white10, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.white10, fontWeight: FontWeight.w900))),
          ElevatedButton(
            onPressed: () {
              final days = int.tryParse(_daysController.text) ?? frequencyDays;
              Navigator.pop(context);
              _updateFrequency(days, 0, 0);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, foregroundColor: Colors.black),
            child: const Text("CALIBRATE", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateFrequency(int days, int hours, int mins) async {
    setState(() => isLoading = true);
    try {
      await ApiService().syncSentinelHeartbeat(
        userId: widget.userId,
        active: isActive,
        frequencyDays: days,
        frequencyHours: hours,
        frequencyMinutes: mins,
      );
      await _loadStatus();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("CALIBRATION FAILURE: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
}

class _PulseRipple extends StatefulWidget {
  final bool active;
  const _PulseRipple({required this.active});

  @override
  State<_PulseRipple> createState() => _PulseRippleState();
}

class _PulseRippleState extends State<_PulseRipple> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            _buildRipple(1.0),
            _buildRipple(0.5),
          ],
        );
      },
    );
  }

  Widget _buildRipple(double delay) {
    final value = (_controller.value + delay) % 1.0;
    return Container(
      width: 220 + (160 * value),
      height: 220 + (160 * value),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.accentColor.withOpacity((1 - value) * 0.2),
          width: 1,
        ),
      ),
    );
  }
}
