import 'package:flutter/material.dart';
import '../theme/glassmorphism.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'dart:convert';

class AddVaultItemScreen extends StatefulWidget {
  final int userId;
  final int folderId;
  final String folderName;

  const AddVaultItemScreen({
    Key? key,
    required this.userId,
    required this.folderId,
    required this.folderName,
  }) : super(key: key);

  @override
  _AddVaultItemScreenState createState() => _AddVaultItemScreenState();
}

class _AddVaultItemScreenState extends State<AddVaultItemScreen> {
  String selectedType = 'note';
  bool isSaving = false;

  // Common fields
  final TextEditingController _titleController = TextEditingController();

  // Note fields
  final TextEditingController _noteContentController = TextEditingController();

  // Password fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _passwordNotesController = TextEditingController();

  // Credit Card fields
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardholderNameController = TextEditingController();
  final TextEditingController _expiryMonthController = TextEditingController();
  final TextEditingController _expiryYearController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardNotesController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _noteContentController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _urlController.dispose();
    _passwordNotesController.dispose();
    _cardNumberController.dispose();
    _cardholderNameController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    _cardNotesController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      // Create encrypted data based on type
      Map<String, dynamic> data = {};

      switch (selectedType) {
        case 'note':
          data = {'content': _noteContentController.text};
          break;
        case 'password':
          data = {
            'username': _usernameController.text,
            'password': _passwordController.text,
            'url': _urlController.text,
            'notes': _passwordNotesController.text,
          };
          break;
        case 'credit_card':
          data = {
            'card_number': _cardNumberController.text,
            'cardholder_name': _cardholderNameController.text,
            'expiry_month': _expiryMonthController.text,
            'expiry_year': _expiryYearController.text,
            'cvv': _cvvController.text,
            'notes': _cardNotesController.text,
          };
          break;
      }

      // TODO: Encrypt the data here before sending
      // For now, we'll send as JSON string
      final encryptedData = jsonEncode(data);

      await ApiService().createVaultItem(
        userId: widget.userId,
        folderId: widget.folderId,
        itemType: selectedType,
        title: _titleController.text,
        encryptedData: encryptedData,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Add to ${widget.folderName}',
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
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
            colors: [Color(0xFFF2F2F7), Color(0xFFE5E5EA), Color(0xFFF2F2F7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Type Selector
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassCard(
                  opacity: 0.7,
                  color: Colors.white,
                  child: Row(
                    children: [
                      _buildTypeButton('note', Icons.note_alt, 'Note'),
                      _buildTypeButton('password', Icons.lock, 'Password'),
                      _buildTypeButton('credit_card', Icons.credit_card, 'Card'),
                    ],
                  ),
                ),
              ),

              // Form Fields
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: GlassCard(
                    opacity: 0.7,
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title (common for all types)
                        _buildTextField(
                          controller: _titleController,
                          label: 'Title',
                          icon: Icons.title,
                        ),
                        const SizedBox(height: 16),

                        // Type-specific fields
                        if (selectedType == 'note') ..._buildNoteFields(),
                        if (selectedType == 'password') ..._buildPasswordFields(),
                        if (selectedType == 'credit_card') ..._buildCreditCardFields(),
                      ],
                    ),
                  ),
                ),
              ),

              // Save Button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSaving ? null : _saveItem,
                    icon: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save),
                    label: Text(isSaving ? 'Saving...' : 'Save Securely'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, IconData icon, String label) {
    final isSelected = selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppTheme.textSecondary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
      ),
    );
  }

  List<Widget> _buildNoteFields() {
    return [
      _buildTextField(
        controller: _noteContentController,
        label: 'Note Content',
        icon: Icons.notes,
        maxLines: 10,
      ),
    ];
  }

  List<Widget> _buildPasswordFields() {
    return [
      _buildTextField(
        controller: _usernameController,
        label: 'Username/Email',
        icon: Icons.person,
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _passwordController,
        label: 'Password',
        icon: Icons.lock,
        obscureText: true,
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _urlController,
        label: 'Website URL',
        icon: Icons.link,
        keyboardType: TextInputType.url,
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _passwordNotesController,
        label: 'Notes (Optional)',
        icon: Icons.note,
        maxLines: 3,
      ),
    ];
  }

  List<Widget> _buildCreditCardFields() {
    return [
      _buildTextField(
        controller: _cardNumberController,
        label: 'Card Number',
        icon: Icons.credit_card,
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _cardholderNameController,
        label: 'Cardholder Name',
        icon: Icons.person,
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _buildTextField(
              controller: _expiryMonthController,
              label: 'MM',
              icon: Icons.calendar_today,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTextField(
              controller: _expiryYearController,
              label: 'YYYY',
              icon: Icons.calendar_today,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildTextField(
              controller: _cvvController,
              label: 'CVV',
              icon: Icons.security,
              keyboardType: TextInputType.number,
              obscureText: true,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _cardNotesController,
        label: 'Notes (Optional)',
        icon: Icons.note,
        maxLines: 3,
      ),
    ];
  }
}
