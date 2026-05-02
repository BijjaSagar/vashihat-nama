import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class SubscriptionScreen extends StatefulWidget {
  final int userId;
  const SubscriptionScreen({super.key, required this.userId});

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool isLoading = true;
  Map<String, dynamic>? subscription;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    if (mounted) setState(() => isLoading = true);
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          subscription = {
            'subscription_plan': 'free',
            'storage_limit_gb': 1,
            'current_storage_bytes': 1024 * 1024 * 250, // 250MB
            'subscription_expires_at': null,
          };
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _upgradeAction(String plan, double price) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32), 
          side: const BorderSide(color: Colors.white10)
        ),
        title: Text("INITIATE ${plan.toUpperCase()} ACCESS", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
        content: Text("Confirm transmission of \$$price for premium vault expansion.", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("AUTHORIZE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1))
          ),
        ],
      ),
    );

    if (confirm == true) {
       setState(() => isLoading = true);
       try {
         await Future.delayed(const Duration(seconds: 2));
         if (mounted) {
           setState(() {
             subscription = {
               'subscription_plan': plan,
               'storage_limit_gb': plan == 'premium' ? 50 : 500,
               'current_storage_bytes': subscription!['current_storage_bytes'],
               'subscription_expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
             };
             isLoading = false;
           });
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
             content: Text("AUTHORIZATION GRANTED: ${plan.toUpperCase()} PROTOCOLS ACTIVE."),
             backgroundColor: AppTheme.accentColor,
           ));
         }
       } catch (e) {
         if (mounted) {
           setState(() => isLoading = false);
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AUTHORIZATION FAILURE: TRANSACTION REJECTED."), backgroundColor: Colors.redAccent));
         }
       }
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
        title: const Text("VAULT CAPACITY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
        centerTitle: true,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentStatus(),
                const SizedBox(height: 56),
                const Text("AVAILABLE EXPANSIONS", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 24),
                _buildPlanOption(
                  "Sentinel Premium", 
                  "50 GB VAULT", 
                  "\$9.99/MO", 
                  AppTheme.accentColor, 
                  ['Unlimited artifacts', 'Biometric inheritance', 'AI legal assistant', 'Cross-device sync'],
                  'premium',
                  9.99
                ),
                const SizedBox(height: 24),
                _buildPlanOption(
                  "Continuum Elite", 
                  "500 GB VAULT", 
                  "\$29.99/MO", 
                  const Color(0xFFE5E5EA), // Premium Silver
                  ['Everything in Premium', 'Priority Sentinel support', 'Legal counsel audit', 'Multi-jurisdiction'],
                  'enterprise',
                  29.99
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
    );
  }

  Widget _buildCurrentStatus() {
    final plan = subscription?['subscription_plan'] ?? 'free';
    final limit = subscription?['storage_limit_gb'] ?? 1;
    final used = (subscription?['current_storage_bytes'] ?? 0) / (1024 * 1024 * 1024);
    final percent = used / limit;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.toUpperCase(), style: const TextStyle(color: AppTheme.accentColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  const Text("CURRENT STATUS", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ],
              ),
              const Icon(Icons.verified_user_rounded, color: AppTheme.accentColor, size: 32),
            ],
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("METRIC STORAGE", style: TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              Text("${(used * 1024).toStringAsFixed(0)}MB / ${limit}GB", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white.withOpacity(0.02),
              color: AppTheme.accentColor,
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption(String title, String storage, String price, Color color, List<String> perks, String planKey, double priceVal) {
    bool isElite = planKey == 'enterprise';
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: AppTheme.slabDecoration.copyWith(
        border: Border.all(color: color.withOpacity(0.1), width: isElite ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5)),
              Text(price, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          Text(storage, style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 40),
          ...perks.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, color: color.withOpacity(0.3), size: 14),
                const SizedBox(width: 16),
                Text(p.toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              ],
            ),
          )).toList(),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: () => _upgradeAction(planKey, priceVal),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text("INITIATE UPGRADE", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}
