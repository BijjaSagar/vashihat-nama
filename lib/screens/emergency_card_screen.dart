import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EmergencyCardScreen extends StatefulWidget {
  final int userId;
  const EmergencyCardScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<EmergencyCardScreen> createState() => _EmergencyCardScreenState();
}

class _EmergencyCardScreenState extends State<EmergencyCardScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _saving = false;

  final _nameCtrl = TextEditingController();
  final _bloodGroupCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  final _medicationsCtrl = TextEditingController();
  final _doctorNameCtrl = TextEditingController();
  final _doctorPhoneCtrl = TextEditingController();
  final _emergencyContact1Ctrl = TextEditingController();
  final _emergencyContact2Ctrl = TextEditingController();
  final _insuranceInfoCtrl = TextEditingController();
  final _organDonorCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final result = await _api.getEmergencyCard(widget.userId);
      final data = result['emergency_data'] ?? {};
      final user = result['user'] ?? {};
      _nameCtrl.text = data['full_name'] ?? user['name'] ?? '';
      _bloodGroupCtrl.text = data['blood_group'] ?? '';
      _allergiesCtrl.text = data['allergies'] ?? '';
      _conditionsCtrl.text = data['conditions'] ?? '';
      _medicationsCtrl.text = data['medications'] ?? '';
      _doctorNameCtrl.text = data['doctor_name'] ?? '';
      _doctorPhoneCtrl.text = data['doctor_phone'] ?? '';
      _emergencyContact1Ctrl.text = data['emergency_contact_1'] ?? '';
      _emergencyContact2Ctrl.text = data['emergency_contact_2'] ?? '';
      _insuranceInfoCtrl.text = data['insurance_info'] ?? '';
      _organDonorCtrl.text = data['organ_donor'] ?? '';
      _notesCtrl.text = data['notes'] ?? '';
      setState(() => _loading = false);
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.updateEmergencyCard(widget.userId, {
        'full_name': _nameCtrl.text,
        'blood_group': _bloodGroupCtrl.text,
        'allergies': _allergiesCtrl.text,
        'conditions': _conditionsCtrl.text,
        'medications': _medicationsCtrl.text,
        'doctor_name': _doctorNameCtrl.text,
        'doctor_phone': _doctorPhoneCtrl.text,
        'emergency_contact_1': _emergencyContact1Ctrl.text,
        'emergency_contact_2': _emergencyContact2Ctrl.text,
        'insurance_info': _insuranceInfoCtrl.text,
        'organ_donor': _organDonorCtrl.text,
        'notes': _notesCtrl.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Emergency card saved!'), backgroundColor: Color(0xFF4CAF50)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save'), backgroundColor: Colors.red));
    }
    setState(() => _saving = false);
  }

  Widget _buildField(String label, String emoji, TextEditingController ctrl, {int maxLines = 1, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: '$emoji $label',
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Emergency Card', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFFD84315),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildPreviewCard(),
                const SizedBox(height: 24),
                const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _buildField('Full Name', '👤', _nameCtrl),
                _buildField('Blood Group', '🩸', _bloodGroupCtrl, hint: 'e.g. O+, A-'),
                _buildField('Allergies', '⚠️', _allergiesCtrl, hint: 'e.g. Penicillin, Peanuts', maxLines: 2),
                _buildField('Medical Conditions', '🏥', _conditionsCtrl, hint: 'e.g. Diabetes, Asthma', maxLines: 2),
                _buildField('Current Medications', '💊', _medicationsCtrl, hint: 'e.g. Metformin 500mg', maxLines: 2),
                const SizedBox(height: 16),
                const Text('Emergency Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _buildField('Doctor Name', '👨‍⚕️', _doctorNameCtrl),
                _buildField('Doctor Phone', '📞', _doctorPhoneCtrl),
                _buildField('Emergency Contact 1', '📱', _emergencyContact1Ctrl, hint: 'Name - Phone'),
                _buildField('Emergency Contact 2', '📱', _emergencyContact2Ctrl, hint: 'Name - Phone'),
                const SizedBox(height: 16),
                const Text('Additional Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _buildField('Insurance Info', '📋', _insuranceInfoCtrl, hint: 'Policy number / company'),
                _buildField('Organ Donor', '❤️', _organDonorCtrl, hint: 'Yes / No'),
                _buildField('Additional Notes', '📝', _notesCtrl, maxLines: 3),
                const SizedBox(height: 32),
                SizedBox(height: 54, child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD84315), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: const Text('Save Emergency Card', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                )),
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFD84315), Color(0xFFE64A19)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFFD84315).withOpacity(0.3), blurRadius: 20)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.emergency, color: Colors.white, size: 28),
          SizedBox(width: 10),
          Text('EMERGENCY', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ]),
        const Divider(color: Colors.white30, height: 24),
        _previewRow('Name', _nameCtrl.text),
        _previewRow('Blood', _bloodGroupCtrl.text),
        _previewRow('Allergies', _allergiesCtrl.text),
        _previewRow('Contact', _emergencyContact1Ctrl.text),
        const SizedBox(height: 8),
        const Text('Show this card in an emergency', style: TextStyle(color: Colors.white54, fontSize: 11, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _previewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 70, child: Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13))),
        Expanded(child: Text(value.isEmpty ? '—' : value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))),
      ]),
    );
  }
}
