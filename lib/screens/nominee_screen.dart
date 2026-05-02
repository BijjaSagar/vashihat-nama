import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
  String viewMode = "GRAPH_VIEW";
  String _userName = "USER";

  @override
  void initState() {
    super.initState();
    _loadNominees();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final profileStr = prefs.getString('userProfile');
    if (profileStr != null) {
      final profile = jsonDecode(profileStr);
      if (mounted) setState(() => _userName = profile['name'] ?? "USER");
    }
  }

  Future<void> _loadNominees() async {
    if (mounted) setState(() => isLoading = true);
    try {
      final fetchedNominees = await ApiService().getNominees(widget.userId);
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
        title: const Text("ACCESS HIERARCHY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildViewToggleStrip(),
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
              : viewMode == "GRAPH_VIEW" 
                ? _buildGraphView()
                : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: Container(
        height: 64,
        width: 64,
        margin: const EdgeInsets.only(bottom: 16, right: 8),
        child: FloatingActionButton(
          heroTag: "nominee_action_btn",
          onPressed: () => _showAddNomineeSheet(),
          backgroundColor: AppTheme.accentColor,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.person_add_rounded, color: Colors.black, size: 28),
        ),
      ),
    );
  }

  Widget _buildViewToggleStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      child: Container(
        height: 60,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.01),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Expanded(child: _buildToggleButton("GRAPH_VIEW", Icons.hub_rounded)),
            Expanded(child: _buildToggleButton("LIST_VIEW", Icons.format_list_bulleted_rounded)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, IconData icon) {
    final isSelected = viewMode == label;
    return GestureDetector(
      onTap: () => setState(() => viewMode = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor.withOpacity(0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.accentColor.withOpacity(0.1) : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppTheme.accentColor : Colors.white12, size: 18),
            const SizedBox(width: 12),
            Text(
              label, 
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white10, 
                fontSize: 9, 
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 32),
          _buildProtocolNode("ORIGINATOR", _userName, Icons.shield_rounded, isMain: true),
          if (nominees.isNotEmpty) ...[
            const SizedBox(height: 48),
            Container(
              width: 1, 
              height: 64, 
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accentColor.withOpacity(0.3), AppTheme.accentColor.withOpacity(0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            const SizedBox(height: 48),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: nominees.map((n) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _buildProtocolNode(
                    n['relationship']?.toString().toUpperCase() ?? "NOMINEE", 
                    n['name'] ?? "UNKNOWN", 
                    Icons.verified_user_rounded
                  ),
                )).toList(),
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Text("NO ACCESS NODES DETECTED", style: TextStyle(color: Colors.white10, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ),
          const SizedBox(height: 80),
          _buildHierarchyInsightsSlab(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProtocolNode(String role, String name, IconData icon, {bool isMain = false}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.accentColor.withOpacity(isMain ? 0.3 : 0.05), width: 1.5),
            boxShadow: isMain ? [BoxShadow(color: AppTheme.accentColor.withOpacity(0.02), blurRadius: 40, spreadRadius: 0)] : [],
          ),
          child: CircleAvatar(
            radius: isMain ? 56 : 40,
            backgroundColor: Colors.white.withOpacity(0.01),
            child: Icon(icon, color: AppTheme.accentColor, size: isMain ? 36 : 28),
          ),
        ),
        const SizedBox(height: 24),
        Text(role, style: const TextStyle(color: AppTheme.accentColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 8),
        Text(name.toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildHierarchyInsightsSlab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(40),
      decoration: AppTheme.slabDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("HIERARCHY ANALYTICS", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 40),
          _buildInsightRow(Icons.groups_rounded, "${nominees.length} NODES", "CONFIGURED ACCESS POINTS"),
          const SizedBox(height: 32),
          _buildInsightRow(Icons.verified_user_rounded, "SECURED", "ACCESS PROTOCOL STATUS"),
        ],
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String value, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.01), 
            borderRadius: BorderRadius.circular(14), 
            border: Border.all(color: Colors.white.withOpacity(0.05))
          ),
          child: Icon(icon, color: AppTheme.accentColor, size: 20),
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ],
        ),
      ],
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 80),
      itemCount: nominees.length,
      itemBuilder: (context, index) {
        final nominee = nominees[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(32),
          decoration: AppTheme.slabDecoration,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.05), 
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentColor.withOpacity(0.1)),
                ),
                child: const Icon(Icons.person_rounded, color: AppTheme.accentColor, size: 20),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nominee['name']?.toString().toUpperCase() ?? "UNKNOWN_SUBJECT", 
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                    ),
                    const SizedBox(height: 6),
                    Text(
                      nominee['relationship']?.toString().toUpperCase() ?? "FAMILY", 
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white24),
                color: const Color(0xFF161922),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showEditNomineeSheet(nominee);
                  } else if (val == 'delete') {
                    _confirmDelete(nominee['id']);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, color: Colors.white54, size: 18),
                      SizedBox(width: 12),
                      Text("Edit Profile", style: TextStyle(color: Colors.white, fontSize: 13)),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      SizedBox(width: 12),
                      Text("Remove Node", style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditNomineeSheet(Map<String, dynamic> nominee) {
    final id = nominee['id'];
    final nameCtrl = TextEditingController(text: nominee['name']);
    final emailCtrl = TextEditingController(text: nominee['email']);
    final mobileCtrl = TextEditingController(text: nominee['primary_mobile'] ?? nominee['mobile_number']);
    final optMobileCtrl = TextEditingController(text: nominee['optional_mobile']);
    final addressCtrl = TextEditingController(text: nominee['address']);
    final idProofCtrl = TextEditingController(text: nominee['identity_proof']);
    final handDeliveryCtrl = TextEditingController(text: nominee['hand_delivery_rules']);
    
    String selectedRelationship = nominee['relationship'] ?? 'Spouse';
    String deliveryMode = nominee['delivery_mode'] ?? 'digital';
    bool requireOtp = nominee['require_otp_for_access'] == true;
    bool isProofOfLifeContact = nominee['is_proof_of_life_contact'] == true;
    bool isSubmitting = false;

    final relationships = [
      'Spouse', 'Son', 'Daughter', 'Father', 'Mother',
      'Brother', 'Sister', 'Friend', 'Lawyer', 'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F1117),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                  child: Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("EDIT NOMINEE", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          SizedBox(height: 4),
                          Text("Update trusted person details", style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white54, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
                    children: [
                      _sectionLabel2("BASIC INFORMATION"),
                      const SizedBox(height: 12),
                      _sheetField(nameCtrl, "Full Name *", Icons.person_rounded),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.08))),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: relationships.contains(selectedRelationship) ? selectedRelationship : 'Other',
                            dropdownColor: const Color(0xFF0F1117),
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.accentColor),
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            items: relationships.map((r) => DropdownMenuItem(
                              value: r,
                              child: Row(children: [
                                const Icon(Icons.people_outline_rounded, color: AppTheme.accentColor, size: 18),
                                const SizedBox(width: 12),
                                Text(r, style: const TextStyle(color: Colors.white)),
                              ]),
                            )).toList(),
                            onChanged: (val) { if (val != null) setSheetState(() => selectedRelationship = val); },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionLabel2("CONTACT DETAILS"),
                      const SizedBox(height: 12),
                      _sheetField(emailCtrl, "Email Address *", Icons.email_rounded, inputType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _sheetField(mobileCtrl, "Primary Mobile *", Icons.phone_rounded, inputType: TextInputType.phone),
                      const SizedBox(height: 12),
                      _sheetField(optMobileCtrl, "Optional Mobile", Icons.phone_outlined, inputType: TextInputType.phone),
                      const SizedBox(height: 12),
                      _sheetField(addressCtrl, "Address", Icons.location_on_outlined, maxLines: 2),
                      const SizedBox(height: 24),
                      _sectionLabel2("IDENTITY & DELIVERY"),
                      const SizedBox(height: 12),
                      _sheetField(idProofCtrl, "Identity Proof (e.g. Aadhaar, PAN)", Icons.badge_outlined),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _modeBtn("Digital", "digital", deliveryMode, (v) => setSheetState(() => deliveryMode = v))),
                        const SizedBox(width: 12),
                        Expanded(child: _modeBtn("Physical", "physical", deliveryMode, (v) => setSheetState(() => deliveryMode = v))),
                      ]),
                      if (deliveryMode == 'physical') ...[
                        const SizedBox(height: 12),
                        _sheetField(handDeliveryCtrl, "Hand Delivery Instructions", Icons.handshake_outlined, maxLines: 2),
                      ],
                      const SizedBox(height: 24),
                      _sectionLabel2("SECURITY OPTIONS"),
                      const SizedBox(height: 12),
                      _toggleTile("Require OTP for Access", "Nominee must verify via OTP", Icons.lock_outline_rounded, requireOtp, (val) => setSheetState(() => requireOtp = val)),
                      const SizedBox(height: 10),
                      _toggleTile("Proof of Life Contact", "Notify this person for heartbeat check", Icons.favorite_border_rounded, isProofOfLifeContact, (val) => setSheetState(() => isProofOfLifeContact = val)),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : () async {
                            setSheetState(() => isSubmitting = true);
                            try {
                              await ApiService().updateNominee(
                                nomineeId: id,
                                name: nameCtrl.text.trim(),
                                relationship: selectedRelationship,
                                email: emailCtrl.text.trim(),
                                primaryMobile: mobileCtrl.text.trim(),
                                optionalMobile: optMobileCtrl.text.trim().isEmpty ? null : optMobileCtrl.text.trim(),
                                address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                                identityProof: idProofCtrl.text.trim().isEmpty ? null : idProofCtrl.text.trim(),
                                handDeliveryRules: handDeliveryCtrl.text.trim().isEmpty ? null : handDeliveryCtrl.text.trim(),
                                deliveryMode: deliveryMode,
                                requireOtpForAccess: requireOtp,
                                isProofOfLifeContact: isProofOfLifeContact,
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                _loadNominees();
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nominee updated successfully."), backgroundColor: Colors.green));
                              }
                            } catch (e) {
                              setSheetState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Update failed: $e"), backgroundColor: Colors.redAccent));
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                          child: isSubmitting ? const CircularProgressIndicator(color: Colors.black) : const Text("UPDATE NOMINEE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
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

  Future<void> _confirmDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161922),
        title: const Text("Remove Nominee?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: const Text("This person will lose all future access to your vault nodes.", style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text("REMOVE"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService().deleteNominee(id);
        _loadNominees();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nominee removed."), backgroundColor: Colors.orange));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e"), backgroundColor: Colors.redAccent));
      }
    }
  }


  void _showAddNomineeSheet() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final optMobileCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final idProofCtrl = TextEditingController();
    final handDeliveryCtrl = TextEditingController();
    String selectedRelationship = 'Spouse';
    String deliveryMode = 'digital';
    bool requireOtp = false;
    bool isProofOfLifeContact = false;
    bool isSubmitting = false;

    final relationships = [
      'Spouse', 'Son', 'Daughter', 'Father', 'Mother',
      'Brother', 'Sister', 'Friend', 'Lawyer', 'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F1117),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                // Handle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                  child: Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("ADD NOMINEE",
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          SizedBox(height: 4),
                          Text("Add a trusted person to receive your vault",
                              style: TextStyle(color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), shape: BoxShape.circle),
                          child: const Icon(Icons.close, color: Colors.white54, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white10, height: 1),
                // Scrollable form
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
                    children: [
                      _sectionLabel2("BASIC INFORMATION"),
                      const SizedBox(height: 12),
                      _sheetField(nameCtrl, "Full Name *", Icons.person_rounded),
                      const SizedBox(height: 12),
                      // Relationship Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedRelationship,
                            dropdownColor: const Color(0xFF0F1117),
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.accentColor),
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            items: relationships.map((r) => DropdownMenuItem(
                              value: r,
                              child: Row(children: [
                                const Icon(Icons.people_outline_rounded, color: AppTheme.accentColor, size: 18),
                                const SizedBox(width: 12),
                                Text(r, style: const TextStyle(color: Colors.white)),
                              ]),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) setSheetState(() => selectedRelationship = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _sectionLabel2("CONTACT DETAILS"),
                      const SizedBox(height: 12),
                      _sheetField(emailCtrl, "Email Address *", Icons.email_rounded, inputType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _sheetField(mobileCtrl, "Primary Mobile *", Icons.phone_rounded, inputType: TextInputType.phone),
                      const SizedBox(height: 12),
                      _sheetField(optMobileCtrl, "Optional Mobile", Icons.phone_outlined, inputType: TextInputType.phone),
                      const SizedBox(height: 12),
                      _sheetField(addressCtrl, "Address", Icons.location_on_outlined, maxLines: 2),
                      const SizedBox(height: 24),
                      _sectionLabel2("IDENTITY & DELIVERY"),
                      const SizedBox(height: 12),
                      _sheetField(idProofCtrl, "Identity Proof (e.g. Aadhaar, PAN)", Icons.badge_outlined),
                      const SizedBox(height: 16),
                      // Delivery Mode
                      Row(children: [
                        Expanded(child: _modeBtn("Digital", "digital", deliveryMode, (v) => setSheetState(() => deliveryMode = v))),
                        const SizedBox(width: 12),
                        Expanded(child: _modeBtn("Physical", "physical", deliveryMode, (v) => setSheetState(() => deliveryMode = v))),
                      ]),
                      if (deliveryMode == 'physical') ...[
                        const SizedBox(height: 12),
                        _sheetField(handDeliveryCtrl, "Hand Delivery Instructions", Icons.handshake_outlined, maxLines: 2),
                      ],
                      const SizedBox(height: 24),
                      _sectionLabel2("SECURITY OPTIONS"),
                      const SizedBox(height: 12),
                      _toggleTile(
                        "Require OTP for Access",
                        "Nominee must verify via OTP",
                        Icons.lock_outline_rounded,
                        requireOtp,
                        (val) => setSheetState(() => requireOtp = val),
                      ),
                      const SizedBox(height: 10),
                      _toggleTile(
                        "Proof of Life Contact",
                        "Notify this person for heartbeat check",
                        Icons.favorite_border_rounded,
                        isProofOfLifeContact,
                        (val) => setSheetState(() => isProofOfLifeContact = val),
                      ),
                      const SizedBox(height: 32),
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : () async {
                            final name = nameCtrl.text.trim();
                            final email = emailCtrl.text.trim();
                            final mobile = mobileCtrl.text.trim();

                            if (name.isEmpty || email.isEmpty || mobile.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Name, email and primary mobile are required."), backgroundColor: Colors.redAccent),
                              );
                              return;
                            }

                            setSheetState(() => isSubmitting = true);
                            try {
                              await ApiService().addNominee(
                                userId: widget.userId,
                                name: name,
                                relationship: selectedRelationship,
                                email: email,
                                primaryMobile: mobile,
                                optionalMobile: optMobileCtrl.text.trim().isEmpty ? null : optMobileCtrl.text.trim(),
                                address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                                identityProof: idProofCtrl.text.trim().isEmpty ? null : idProofCtrl.text.trim(),
                                handDeliveryRules: handDeliveryCtrl.text.trim().isEmpty ? null : handDeliveryCtrl.text.trim(),
                                deliveryMode: deliveryMode,
                                requireOtpForAccess: requireOtp,
                                isProofOfLifeContact: isProofOfLifeContact,
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                _loadNominees();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Nominee added successfully."), backgroundColor: Colors.green),
                                );
                              }
                            } catch (e) {
                              setSheetState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Failed: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.redAccent),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 0,
                          ),
                          child: isSubmitting
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : const Text("CONFIRM & ADD NOMINEE",
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5)),
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

  Widget _sectionLabel2(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(label,
        style: const TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
  );

  Widget _modeBtn(String label, String value, String current, Function(String) onTap) {
    final isSelected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppTheme.accentColor.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.07)),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                color: isSelected ? AppTheme.accentColor : Colors.white38,
                fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  Widget _toggleTile(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(children: [
        Icon(icon, color: AppTheme.accentColor.withValues(alpha: 0.5), size: 20),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ])),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.accentColor,
          inactiveTrackColor: Colors.white12,
        ),
      ]),
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: inputType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.accentColor.withValues(alpha: 0.5), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }
}
