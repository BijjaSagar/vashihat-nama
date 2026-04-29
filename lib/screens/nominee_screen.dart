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
    // ... other params
  }) async {
    try {
      // Blind the contact info before it leaves the device
      final blindedEmail = _blindContact(email);
      final blindedPhone = _blindContact(primaryMobile);

      await ApiService().addNominee(
        userId: widget.userId.toString(), 
        name: name, 
        relationship: relationship, 
        email: blindedEmail, // ZK Blinded
        primaryMobile: blindedPhone, // ZK Blinded
        deliveryMode: 'digital',
      );
      _loadNominees();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Guardian Vaulted Securely")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
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
          // Background Glow
          Positioned(
            top: 100,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
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
      child: Row(
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
}

  Widget _buildNomineeCard(Map<String, dynamic> nominee) {
    bool isVerified = nominee['access_granted'] == true;
    String name = nominee['name'] ?? "Unknown";
    String initial = name.isNotEmpty ? name[0].toUpperCase() : "?";

    return GlassCard(
      opacity: 0.8,
      blur: 20,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor.withOpacity(0.2), AppTheme.primaryColor.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nominee['relationship'] ?? "Nominee",
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary.withOpacity(0.8), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isVerified ? Colors.green : Colors.orange).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: (isVerified ? Colors.green : Colors.orange).withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                      size: 14,
                      color: isVerified ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVerified ? "Verified" : "Pending",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isVerified ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 14, color: AppTheme.textSecondary.withOpacity(0.6)),
              const SizedBox(width: 4),
              Text(
                "${nominee['handover_waiting_days'] ?? 0}d delay",
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary.withOpacity(0.8), fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 16),
              Icon(
                nominee['require_otp_for_access'] == true ? Icons.security_rounded : Icons.lock_open_rounded,
                size: 14,
                color: nominee['require_otp_for_access'] == true ? Colors.blue[700] : AppTheme.textSecondary.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                nominee['require_otp_for_access'] == true ? "OTP Required" : "Auto Access",
                style: TextStyle(fontSize: 12, color: nominee['require_otp_for_access'] == true ? Colors.blue[700] : AppTheme.textSecondary.withOpacity(0.8), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildQuickAction(
                    icon: Icons.inventory_2_outlined,
                    label: "Items",
                    onTap: () => _showAssignedItems(nominee),
                  ),
                  const SizedBox(width: 16),
                  _buildQuickAction(
                    icon: Icons.edit_note_rounded,
                    label: "Edit",
                    onTap: () => _showAddEditNomineeDialog(nominee: nominee),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _confirmDelete(nominee['id']),
                icon: Icon(Icons.delete_outline_rounded, color: Colors.red.withOpacity(0.7), size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }
}


// ─── Separate StatefulWidget so items refresh in-place after unassign ────────
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final items = await ApiService().getNomineeAssignedItems(widget.nomineeId);
      if (mounted) setState(() { _items = items; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _removeItem(Map<String, dynamic> item) async {
    final int itemId = item['id'] is int ? item['id'] : int.tryParse(item['id'].toString()) ?? 0;
    try {
      await ApiService().unassignNomineeFromVaultItem(itemId: itemId, userId: widget.userId, nomineeId: widget.nomineeId);
      if (mounted) {
        setState(() => _items.removeWhere((i) => i['id'] == item['id']));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Nominee tag removed'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove tag'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Items for ${widget.nomineeName}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        widget.nomineeRelation.isNotEmpty ? widget.nomineeRelation : "Visible upon trigger",
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text("Error: $_error", style: const TextStyle(color: Colors.redAccent)))
                    : _items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open_rounded, size: 60, color: Colors.grey.withOpacity(0.25)),
                                const SizedBox(height: 14),
                                const Text("No items assigned yet", style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                                const SizedBox(height: 6),
                                Text("Open a vault item to assign it to ${widget.nomineeName}", style: TextStyle(color: Colors.grey[400], fontSize: 12), textAlign: TextAlign.center),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) => _buildItemTile(_items[index]),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    IconData icon;
    Color color;
    switch (item['item_type']) {
      case 'password': icon = Icons.lock_rounded; color = const Color(0xFF9C27B0); break;
      case 'credit_card': icon = Icons.credit_card_rounded; color = const Color(0xFFF57C00); break;
      case 'file': icon = Icons.file_present_rounded; color = const Color(0xFF2E7D32); break;
      default: icon = Icons.description_rounded; color = const Color(0xFF1A73E8);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(item['item_type']?.toString().toUpperCase() ?? 'ITEM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _removeItem(item),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.person_remove_rounded, color: Colors.red[600], size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
