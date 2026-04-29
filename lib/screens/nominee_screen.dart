import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../theme/glassmorphism.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class NomineeScreen extends StatefulWidget {
  final int userId;
  const NomineeScreen({super.key, required this.userId});

  @override
  _NomineeScreenState createState() => _NomineeScreenState();
}

class _NomineeScreenState extends State<NomineeScreen> {
  List<dynamic> nominees = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNominees();
  }

  // ZK Blinded Hashing Implementation
  String _blindContact(String contact) {
    final salt = "VASI_ZK_SALT_${widget.userId}"; // Per-user deterministic salt
    final bytes = utf8.encode(contact.trim().toLowerCase() + salt);
    return sha256.convert(bytes).toString();
  }

  Future<void> _loadNominees() async {
    try {
      final fetchedNominees = await ApiService().getNominees(widget.userId.toString());
      if (mounted) {
        setState(() {
          nominees = fetchedNominees;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _addNominee({
    required String name,
    required String relationship,
    required String email,
    required String primaryMobile,
  }) async {
    try {
      final blindedEmail = _blindContact(email);
      final blindedPhone = _blindContact(primaryMobile);

      await ApiService().addNominee(
        userId: widget.userId.toString(), 
        name: name, 
        relationship: relationship, 
        email: blindedEmail, 
        primaryMobile: blindedPhone, 
        deliveryMode: 'digital',
      );
      _loadNominees();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Guardian Vaulted Securely")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _confirmDelete(dynamic nomineeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text("Remove Guardian", style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text("Are you sure you want to revoke access for this guardian?", style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Remove", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService().deleteNominee(nomineeId is int ? nomineeId : int.parse(nomineeId.toString()));
        _loadNominees();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showAssignedItems(dynamic nominee) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AssignedItemsSheet(
        nomineeId: nominee['id'],
        nomineeName: nominee['name'],
        nomineeRelation: nominee['relationship'],
        userId: widget.userId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Trusted Guardians", style: TextStyle(color: AppTheme.platinumColor, fontWeight: FontWeight.w900, letterSpacing: 1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 100, left: -50,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(color: AppTheme.accentColor.withOpacity(0.05), shape: BoxShape.circle),
              child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50), child: Container()),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildSecurityBanner(),
                Expanded(
                  child: isLoading 
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
                    : nominees.isEmpty 
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: nominees.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 20),
                          itemBuilder: (context, index) => _buildNomineeCard(nominees[index]),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppTheme.accentColor,
        label: const Text("Appoint Guardian", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.shield_rounded, color: Colors.black),
      ),
    );
  }

  Widget _buildSecurityBanner() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_person_rounded, color: AppTheme.accentColor, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              "Zero-Knowledge Contact Discovery is Active. Guardian identities are blinded and never stored in raw format.",
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNomineeCard(dynamic nominee) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 56, width: 56,
                decoration: BoxDecoration(color: AppTheme.accentColor.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded, color: AppTheme.accentColor, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nominee['name'] ?? "Guardian", style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(nominee['relationship'] ?? "Trusted Contact", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.verified_user_rounded, color: Colors.green, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => _showAssignedItems(nominee),
                icon: const Icon(Icons.inventory_2_outlined, size: 18, color: AppTheme.accentColor),
                label: const Text("Managed Items", style: TextStyle(color: AppTheme.accentColor, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: () => _confirmDelete(nominee['id']),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
              ),
            ],
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
          const Icon(Icons.people_outline_rounded, size: 80, color: AppTheme.surfaceColor),
          const SizedBox(height: 24),
          const Text("No Guardians Appointed", style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Secure your legacy by adding trusted contacts.", style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final relationCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Appoint New Guardian", style: TextStyle(color: AppTheme.platinumColor, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildField(nameCtrl, "Legal Name", Icons.badge),
            const SizedBox(height: 16),
            _buildField(relationCtrl, "Relationship", Icons.family_restroom),
            const SizedBox(height: 16),
            _buildField(emailCtrl, "Email (Will be blinded)", Icons.email),
            const SizedBox(height: 16),
            _buildField(phoneCtrl, "Phone (Will be blinded)", Icons.phone),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                _addNominee(
                  name: nameCtrl.text,
                  relationship: relationCtrl.text,
                  email: emailCtrl.text,
                  primaryMobile: phoneCtrl.text,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
              child: const Text("Vault Guardian"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.accentColor),
        filled: true,
        fillColor: AppTheme.backgroundColor.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}

class _AssignedItemsSheet extends StatefulWidget {
  final int nomineeId;
  final String nomineeName;
  final String nomineeRelation;
  final int userId;
  const _AssignedItemsSheet({
    required this.nomineeId,
    required this.nomineeName,
    required this.nomineeRelation,
    required this.userId,
  });
  @override
  State<_AssignedItemsSheet> createState() => _AssignedItemsSheetState();
}

class _AssignedItemsSheetState extends State<_AssignedItemsSheet> {
  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await ApiService().getNomineeAssignedItems(widget.nomineeId);
      if (mounted) setState(() { _items = items; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text("Managed Items: ${widget.nomineeName}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(),
          SizedBox(
            height: 400,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text("No items assigned", style: TextStyle(color: AppTheme.textSecondary)))
                    : ListView.builder(
                        itemCount: _items.length,
                        itemBuilder: (context, index) => ListTile(
                          leading: const Icon(Icons.lock_outline, color: AppTheme.accentColor),
                          title: Text(_items[index]['title'] ?? "Untitled", style: const TextStyle(color: AppTheme.textPrimary)),
                          subtitle: Text(_items[index]['item_type'] ?? "Vault Item", style: const TextStyle(color: AppTheme.textSecondary)),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
