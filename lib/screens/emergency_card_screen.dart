import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class EmergencyCardScreen extends StatefulWidget {
  final int userId;
  const EmergencyCardScreen({super.key, required this.userId});

  @override
  _EmergencyCardScreenState createState() => _EmergencyCardScreenState();
}

class _EmergencyCardScreenState extends State<EmergencyCardScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic> _cardData = {};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSuggesting = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bloodGroupController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCard();
  }

  Future<void> _fetchCard() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final data = await _apiService.getEmergencyCard(widget.userId);
      if (mounted) {
        setState(() {
          _cardData = data;
          _nameController.text = (data['name'] ?? "").toString().toUpperCase();
          _bloodGroupController.text = (data['blood_group'] ?? "").toString().toUpperCase();
          _allergiesController.text = (data['allergies'] ?? "").toString().toUpperCase();
          _conditionsController.text = (data['conditions'] ?? "").toString().toUpperCase();
          _medicationsController.text = (data['medications'] ?? "").toString().toUpperCase();
          _contactNameController.text = (data['emergency_contact1_name'] ?? "").toString().toUpperCase();
          _contactPhoneController.text = (data['emergency_contact1_phone'] ?? "").toString();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCard() async {
    if (mounted) setState(() => _isSaving = true);
    try {
      final data = {
        'name': _nameController.text,
        'blood_group': _bloodGroupController.text,
        'allergies': _allergiesController.text,
        'conditions': _conditionsController.text,
        'medications': _medicationsController.text,
        'emergency_contact1_name': _contactNameController.text,
        'emergency_contact1_phone': _contactPhoneController.text,
      };
      await _apiService.updateEmergencyCard(widget.userId, data);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("EMERGENCY PROTOCOL SECURED"), backgroundColor: AppTheme.accentColor));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("FAILED TO SECURE PROTOCOL"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _getAiSuggestions() async {
    if (mounted) setState(() => _isSuggesting = true);
    try {
      final currentData = {
        'blood_group': _bloodGroupController.text,
        'allergies': _allergiesController.text,
        'conditions': _conditionsController.text,
        'medications': _medicationsController.text,
      };
      final suggestions = await _apiService.getEmergencyCardSuggestions(widget.userId, currentData);
      if (suggestions.isNotEmpty) {
        setState(() {
          if (suggestions['blood_group'] != null) _bloodGroupController.text = suggestions['blood_group'].toString().toUpperCase();
          if (suggestions['allergies'] != null) _allergiesController.text = suggestions['allergies'].toString().toUpperCase();
          if (suggestions['conditions'] != null) _conditionsController.text = suggestions['conditions'].toString().toUpperCase();
        });
      }
    } catch (e) {} finally {
      if (mounted) setState(() => _isSuggesting = false);
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
        actions: [
          IconButton(
            icon: _isSuggesting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppTheme.accentColor, strokeWidth: 1))
                : const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentColor, size: 20),
            onPressed: _isSuggesting ? null : _getAiSuggestions,
          ),
          const SizedBox(width: 16),
        ],
        title: const Text("SURVIVAL PROTOCOL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("SECURE PREVIEW"),
                  const SizedBox(height: 24),
                  _buildEmergencyProtocolCard(),
                  const SizedBox(height: 56),
                  _buildSectionHeader("CRITICAL METADATA"),
                  const SizedBox(height: 24),
                  Container(
                    decoration: AppTheme.slabDecoration,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        _buildSlabInput("PRIMARY IDENTITY", _nameController, Icons.person_rounded),
                        const SizedBox(height: 32),
                        _buildSlabInput("BIOLOGICAL GROUP", _bloodGroupController, Icons.water_drop_rounded, hint: "E.G. A+, O-"),
                        const SizedBox(height: 32),
                        _buildSlabInput("ALLERGIC RISKS", _allergiesController, Icons.warning_rounded, hint: "E.G. PENICILLIN"),
                        const SizedBox(height: 32),
                        _buildSlabInput("CHRONIC CONDITIONS", _conditionsController, Icons.monitor_heart_rounded, hint: "E.G. DIABETES"),
                        const SizedBox(height: 32),
                        _buildSlabInput("CRITICAL MEDICATIONS", _medicationsController, Icons.medication_rounded, hint: "E.G. INSULIN"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 56),
                  _buildSectionHeader("RESCUE COORDINATES"),
                  const SizedBox(height: 24),
                  Container(
                    decoration: AppTheme.slabDecoration,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        _buildSlabInput("GUARDIAN DESIGNATION", _contactNameController, Icons.contact_phone_rounded),
                        const SizedBox(height: 32),
                        _buildSlabInput("EMERGENCY COMMS", _contactPhoneController, Icons.phone_android_rounded, type: TextInputType.phone),
                      ],
                    ),
                  ),
                  const SizedBox(height: 64),
                  SizedBox(
                    width: double.infinity,
                    height: 72,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveCard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _isSaving 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Text("COMMIT TO SECURE STORAGE", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2));
  }

  Widget _buildEmergencyProtocolCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0505), // Deep threat red
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.redAccent.withOpacity(0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.emergency_rounded, color: Colors.redAccent, size: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_bloodGroupController.text.isEmpty ? "---" : _bloodGroupController.text.toUpperCase(), 
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                  const Text("BLOOD TYPE", style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),
          Text(_nameController.text.isEmpty ? "UNIDENTIFIED SUBJECT" : _nameController.text.toUpperCase(), 
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          Text("PRIMARY SUBJECT IDENTIFIER", style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 48),
          _buildPreviewField("ALLERGIC RISKS", _allergiesController.text),
          const SizedBox(height: 24),
          _buildPreviewField("CHRONIC CONDITIONS", _conditionsController.text),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Divider(color: Colors.white10, height: 1),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), shape: BoxShape.circle),
                child: const Icon(Icons.phone_rounded, color: AppTheme.accentColor, size: 16),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_contactNameController.text.isEmpty ? "GUARDIAN_PENDING" : _contactNameController.text.toUpperCase(), 
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(_contactPhoneController.text.isEmpty ? "COMMS_UNAVAILABLE" : _contactPhoneController.text, 
                      style: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Text(value.isEmpty ? "NO RECORDED DATA" : value.toUpperCase(), 
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5), maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildSlabInput(String label, TextEditingController ctrl, IconData icon, {String? hint, TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.01), 
            borderRadius: BorderRadius.circular(16), 
            border: Border.all(color: Colors.white.withOpacity(0.03))
          ),
          child: TextField(
            controller: ctrl,
            onChanged: (v) => setState(() {}),
            keyboardType: type,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.accentColor.withOpacity(0.2), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              hintText: hint?.toUpperCase(),
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.05), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
        ),
      ],
    );
  }
}
