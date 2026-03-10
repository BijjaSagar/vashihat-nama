import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
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
      print("Error loading nominees: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _addNominee({
    required String name,
    required String relationship,
    required String email,
    required String primaryMobile,
    String? optionalMobile,
    String? address,
    String? identityProof,
    String? handDeliveryRules,
    String deliveryMode = 'digital',
    int handoverWaitingDays = 0,
    bool requireOtpForAccess = false,
  }) async {
    try {
      await ApiService().addNominee(
        userId: widget.userId.toString(), 
        name: name, 
        relationship: relationship, 
        email: email, 
        primaryMobile: primaryMobile,
        optionalMobile: optionalMobile,
        address: address,
        identityProof: identityProof,
        handDeliveryRules: handDeliveryRules,
        deliveryMode: deliveryMode,
        handoverWaitingDays: handoverWaitingDays, // Added
        requireOtpForAccess: requireOtpForAccess, // Added
      );
      _loadNominees(); // Refresh list
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nominee Added")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _updateNominee({
    required int id,
    required String name,
    required String relationship,
    required String email,
    required String primaryMobile,
    String? optionalMobile,
    String? address,
    String? identityProof,
    String? handDeliveryRules,
    String deliveryMode = 'digital',
    int handoverWaitingDays = 0,
    bool requireOtpForAccess = false,
  }) async {
    try {
      await ApiService().updateNominee(
        nomineeId: id,
        name: name,
        relationship: relationship,
        email: email,
        primaryMobile: primaryMobile,
        optionalMobile: optionalMobile,
        address: address,
        identityProof: identityProof,
        handDeliveryRules: handDeliveryRules,
        deliveryMode: deliveryMode,
        handoverWaitingDays: handoverWaitingDays, // Added
        requireOtpForAccess: requireOtpForAccess, // Added
      );
      _loadNominees();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nominee Updated")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _confirmDelete(dynamic nomineeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Nominee"),
        content: const Text("Are you sure you want to remove this nominee? access will be revoked."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService().deleteNominee(nomineeId is int ? nomineeId : int.parse(nomineeId.toString()));
        _loadNominees();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nominee Removed")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showAssignedItems(dynamic nominee) {
    final int nomineeId = nominee['id'] is int ? nominee['id'] : int.tryParse(nominee['id'].toString()) ?? 0;
    final String nomineeName = nominee['name'] ?? "Nominee";
    final String nomineeRelation = nominee['relationship'] ?? "";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _AssignedItemsSheet(
          nomineeId: nomineeId,
          nomineeName: nomineeName,
          nomineeRelation: nomineeRelation,
          userId: widget.userId,
        );
      },
    );
  }

  void _showAddEditNomineeDialog({Map<String, dynamic>? nominee}) {
    final isEdit = nominee != null;
    final nameCtrl = TextEditingController(text: nominee?['name'] ?? '');
    final relationCtrl = TextEditingController(text: nominee?['relationship'] ?? '');
    final emailCtrl = TextEditingController(text: nominee?['email'] ?? '');
    final primaryMobileCtrl = TextEditingController(text: nominee?['primary_mobile'] ?? '');
    final optionalMobileCtrl = TextEditingController(text: nominee?['optional_mobile'] ?? '');
    final addressCtrl = TextEditingController(text: nominee?['address'] ?? '');
    final idProofCtrl = TextEditingController(text: nominee?['identity_proof'] ?? '');
    final deliveryRulesCtrl = TextEditingController(text: nominee?['hand_delivery_rules'] ?? '');
    final landmarkCtrl = TextEditingController(text: nominee?['landmark'] ?? '');
    final waitingDaysCtrl = TextEditingController(text: (nominee?['handover_waiting_days'] ?? 0).toString());
    bool localRequireOtp = nominee?['require_otp_for_access'] ?? false;
    String localDeliveryMode = nominee?['delivery_mode'] ?? 'digital';
    bool acceptedTerms = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.5,
            maxChildSize: 0.97,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FE),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Premium gradient header
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isEdit
                              ? [const Color(0xFF1A73E8), const Color(0xFF0D47A1)]
                              : [const Color(0xFF00897B), const Color(0xFF00695C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (isEdit ? const Color(0xFF1A73E8) : const Color(0xFF00897B)).withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              isEdit ? Icons.edit_rounded : Icons.person_add_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? "Update Nominee" : "Add New Nominee",
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Text(
                                isEdit ? "Edit trusted contact details" : "Add a trusted contact to inherit your vault",
                                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Scrollable form body
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          // Basic info card
                          _buildFormCard(
                            title: "Basic Information",
                            icon: Icons.person_outline_rounded,
                            iconColor: const Color(0xFF1A73E8),
                            children: [
                              _buildInputField(controller: nameCtrl, label: "Full Name", icon: Icons.badge_rounded),
                              const SizedBox(height: 14),
                              _buildInputField(controller: relationCtrl, label: "Relationship", icon: Icons.family_restroom_rounded, hint: "e.g. Spouse, Sibling"),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Contact card
                          _buildFormCard(
                            title: "Contact Details",
                            icon: Icons.contacts_outlined,
                            iconColor: const Color(0xFF9C27B0),
                            children: [
                              _buildInputField(controller: emailCtrl, label: "Email Address", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                              const SizedBox(height: 14),
                              _buildInputField(
                                controller: primaryMobileCtrl,
                                label: "Primary Mobile",
                                icon: Icons.phone_android_rounded,
                                keyboardType: TextInputType.phone,
                                formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                              ),
                              const SizedBox(height: 14),
                              _buildInputField(
                                controller: optionalMobileCtrl,
                                label: "Optional Mobile",
                                icon: Icons.phone_callback_rounded,
                                keyboardType: TextInputType.phone,
                                formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Physical Handover card
                          _buildFormCard(
                            title: "Delivery Preference",
                            icon: Icons.local_shipping_outlined,
                            iconColor: const Color(0xFFF57C00),
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Physical Handover", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                                        SizedBox(height: 2),
                                        Text("Doorstep delivery of physical documents", style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: localDeliveryMode == 'physical',
                                    activeColor: const Color(0xFFF57C00),
                                    onChanged: (val) async {
                                      if (val == true) {
                                        final agree = await _showPhysicalTerms();
                                        if (agree == true) {
                                          setDialogState(() {
                                            localDeliveryMode = 'physical';
                                            acceptedTerms = true;
                                          });
                                        }
                                      } else {
                                        setDialogState(() {
                                          localDeliveryMode = 'digital';
                                          acceptedTerms = false;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              if (localDeliveryMode == 'physical') ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          "Physical Delivery Cost: ₹500 (\$7.00)\nIncludes hardcopy notarization & courier fees.",
                                          style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500, height: 1.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _buildInputField(controller: addressCtrl, label: "Full Delivery Address", icon: Icons.location_on_outlined, maxLines: 3),
                                const SizedBox(height: 14),
                                _buildInputField(controller: landmarkCtrl, label: "Landmark (Optional)", icon: Icons.near_me_outlined),
                                const SizedBox(height: 14),
                                _buildInputField(controller: idProofCtrl, label: "Identity Proof & No.", icon: Icons.badge_outlined, hint: "Aadhaar / Passport Number"),
                                const SizedBox(height: 14),
                                _buildInputField(controller: deliveryRulesCtrl, label: "Special Instructions", icon: Icons.gavel_rounded, maxLines: 2),
                              ],
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Handover Rules card
                          _buildFormCard(
                            title: "Handover Rules",
                            icon: Icons.gavel_rounded,
                            iconColor: Colors.deepOrange,
                            children: [
                              _buildInputField(
                                controller: waitingDaysCtrl,
                                label: "Waiting Period (Days)",
                                icon: Icons.timer_outlined,
                                keyboardType: TextInputType.number,
                                hint: "0 = Immediate access",
                                formatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Secondary Verification", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                                        SizedBox(height: 2),
                                        Text("Nominee must verify OTP to unlock", style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: localRequireOtp,
                                    activeColor: AppTheme.primaryColor,
                                    onChanged: (val) {
                                      setDialogState(() => localRequireOtp = val);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                    // Bottom action bar
                    Container(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () => _handleNomineeSubmit(
                                isEdit: isEdit,
                                nominee: nominee,
                                name: nameCtrl.text,
                                relation: relationCtrl.text,
                                email: emailCtrl.text,
                                primaryMobile: primaryMobileCtrl.text,
                                optionalMobile: optionalMobileCtrl.text,
                                address: addressCtrl.text,
                                idProof: idProofCtrl.text,
                                deliveryRules: deliveryRulesCtrl.text,
                                mode: localDeliveryMode,
                                acceptedTerms: acceptedTerms,
                                handoverWaitingDays: int.tryParse(waitingDaysCtrl.text) ?? 0,
                                requireOtpForAccess: localRequireOtp,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEdit ? const Color(0xFF1A73E8) : const Color(0xFF00897B),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(isEdit ? Icons.check_rounded : Icons.person_add_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    isEdit ? "Update Nominee" : "Verify & Add",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFormCard({required String title, required IconData icon, required Color iconColor, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700], letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: formatters,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(icon, color: AppTheme.primaryColor.withOpacity(0.5), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Future<bool?> _showPhysicalTerms() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Terms for Physical Handover"),
        content: const Text(
          "By enabling physical handover, you grant Vasihat Nama the right to access, print, and securely handle your documents for the purpose of notarization and physical delivery. A one-time processing fee will be charged upon trigger.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("I Agree", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _handleNomineeSubmit({
    required bool isEdit,
    Map<String, dynamic>? nominee,
    required String name,
    required String relation,
    required String email,
    required String primaryMobile,
    required String optionalMobile,
    required String address,
    required String idProof,
    required String deliveryRules,
    required String mode,
    required bool acceptedTerms,
    required int handoverWaitingDays,
    required bool requireOtpForAccess,
  }) {
    if (name.isEmpty || relation.isEmpty || email.isEmpty || primaryMobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all mandatory fields")));
      return;
    }

    if (mode == 'physical') {
      if (address.isEmpty || idProof.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Address and ID Proof are mandatory for physical delivery")));
        return;
      }
    }

    if (isEdit) {
      _updateNominee(
        id: nominee!['id'],
        name: name,
        relationship: relation,
        email: email,
        primaryMobile: primaryMobile,
        optionalMobile: optionalMobile.isEmpty ? null : optionalMobile,
        address: mode == 'physical' ? address : null,
        identityProof: mode == 'physical' ? idProof : null,
        handDeliveryRules: mode == 'physical' ? deliveryRules : null,
        deliveryMode: mode,
        handoverWaitingDays: handoverWaitingDays,
        requireOtpForAccess: requireOtpForAccess,
      );
    } else {
      _addNominee(
        name: name,
        relationship: relation,
        email: email,
        primaryMobile: primaryMobile,
        optionalMobile: optionalMobile.isEmpty ? null : optionalMobile,
        address: mode == 'physical' ? address : null,
        identityProof: mode == 'physical' ? idProof : null,
        handDeliveryRules: mode == 'physical' ? deliveryRules : null,
        deliveryMode: mode,
        handoverWaitingDays: handoverWaitingDays,
        requireOtpForAccess: requireOtpForAccess,
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          "Trusted Nominees", 
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF2F2F7), Color(0xFFE5E5EA), Color(0xFFF2F2F7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildStatsDashboard(),
              
              Expanded(
                child: isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : nominees.isEmpty 
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: nominees.length,
                        physics: const BouncingScrollPhysics(),
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final nominee = nominees[index];
                          return _buildNomineeCard(nominee);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditNomineeDialog(),
        backgroundColor: AppTheme.primaryColor,
        elevation: 4,
        highlightElevation: 8,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text("Add Nominee", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _buildStatsDashboard() {
    int verifiedCount = nominees.where((n) => n['access_granted'] == true).length;
    int pendingCount = nominees.length - verifiedCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        children: [
          _buildStatCard("Total", nominees.length.toString(), Colors.blue),
          const SizedBox(width: 12),
          _buildStatCard("Verified", verifiedCount.toString(), Colors.green),
          const SizedBox(width: 12),
          _buildStatCard("Pending", pendingCount.toString(), Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
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
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary.withOpacity(0.5), letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_alt_rounded, size: 80, color: AppTheme.primaryColor.withOpacity(0.2)),
          ),
          const SizedBox(height: 24),
          const Text(
            "No Nominees Yet",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              "Add trusted family members or friends to ensure your legacy is protected.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 14),
            ),
          ),
        ],
      ),
    );
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
