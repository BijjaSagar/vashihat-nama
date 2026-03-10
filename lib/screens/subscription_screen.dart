import 'package:flutter/material.dart';
import '../theme/glassmorphism.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class SubscriptionScreen extends StatefulWidget {
  final int userId;
  const SubscriptionScreen({Key? key, required this.userId}) : super(key: key);

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
    try {
      final res = ApiService.baseUrl; // Accessing static getter correctly
      // In real app, call a specific endpoint
      // For now mock response as per the new backend migration
      setState(() {
        subscription = {
          'subscription_plan': 'free',
          'storage_limit_gb': 1,
          'current_storage_bytes': 1024 * 1024 * 250, // 250MB
          'subscription_expires_at': null,
        };
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _upgradeAction(String plan, double price) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Upgrade to ${plan.toUpperCase()}"),
        content: Text("Total cost: \$$price/month. Proceed to payment?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Pay Now")),
        ],
      ),
    );

    if (confirm == true) {
       setState(() => isLoading = true);
       try {
         // Mock Payment Flow
         await Future.delayed(const Duration(seconds: 2));
         // Update backend (this should really happen via a webhook or callback)
         // For now we'll just show success
          setState(() {
            subscription = {
              'subscription_plan': plan,
              'storage_limit_gb': plan == 'premium' ? 50 : 500,
              'current_storage_bytes': subscription!['current_storage_bytes'],
              'subscription_expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
            };
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upgraded to $plan successfully!")));
       } catch (e) {
         setState(() => isLoading = false);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Payment Failed: $e")));
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Subscription", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
                    // Current Plan Card
                    _buildCurrentPlanCard(),
                    const SizedBox(height: 32),
                    
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Upgrade your plan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildPlanOption(
                      "Premium Plan", 
                      "50 GB Secure Storage", 
                      "\$9.99/mo", 
                      Colors.indigo, 
                      ['Unlimited documents', 'Direct Legacy Handover', 'AI-Powered Will Drafter', 'Cloud Sync Across Devices'],
                      'premium',
                      9.99
                    ),
                    const SizedBox(height: 20),
                    _buildPlanOption(
                      "Enterprise Plan", 
                      "500 GB Secure Storage", 
                      "\$29.99/mo", 
                      Colors.black87, 
                      ['Everything in Premium', 'Priority Support', 'Legal Consultation Discount', 'Multi-country Compliance'],
                      'enterprise',
                      29.99
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard() {
    final plan = subscription?['subscription_plan'] ?? 'free';
    final limit = subscription?['storage_limit_gb'] ?? 1;
    final used = (subscription?['current_storage_bytes'] ?? 0) / (1024 * 1024 * 1024);
    final percent = used / limit;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Current Plan: ${plan.toUpperCase()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("Individual Account", style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
              const Icon(Icons.verified, color: Colors.blue, size: 32),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Storage Usage"),
              Text("${(used * 1024).toStringAsFixed(1)} MB / $limit GB", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey[300],
            color: percent > 0.9 ? Colors.red : AppTheme.primaryColor,
            minHeight: 10,
          ),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerRight,
            child: Text("Additional storage available", style: TextStyle(fontSize: 11, color: AppTheme.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildPlanOption(String title, String storage, String price, Color color, List<String> perks, String planKey, double priceVal) {
    return GlassCard(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(storage, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...perks.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(p, style: const TextStyle(fontSize: 13)),
              ],
            ),
          )).toList(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _upgradeAction(planKey, priceVal),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Select Plan", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
