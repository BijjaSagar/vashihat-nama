import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../widgets/credit_card_widget.dart';

class AddVaultItemScreen extends StatefulWidget {
  final int userId;
  final int folderId;
  final String folderName;

  const AddVaultItemScreen({
    super.key,
    required this.userId,
    required this.folderId,
    required this.folderName,
  });

  @override
  _AddVaultItemScreenState createState() => _AddVaultItemScreenState();
}

class _AddVaultItemScreenState extends State<AddVaultItemScreen> {
  String selectedType = 'note';
  bool isSaving = false;
  File? _selectedFile;
  List<dynamic> _nominees = [];
  List<int> _selectedNomineeIds = [];
  bool _isLoadingNominees = true;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteContentController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardholderNameController = TextEditingController();
  final TextEditingController _expiryMonthController = TextEditingController();
  final TextEditingController _expiryYearController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cryptoCoinController = TextEditingController();
  final TextEditingController _cryptoWalletAddressController = TextEditingController();
  final TextEditingController _cryptoSeedPhraseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNominees();
  }

  Future<void> _loadNominees() async {
    try {
      final data = await ApiService().getNominees(widget.userId);
      if (mounted) {
        setState(() {
          _nominees = data;
          _isLoadingNominees = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingNominees = false);
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        if (_titleController.text.isEmpty) {
          _titleController.text = result.files.single.name.toUpperCase();
        }
      });
    }
  }

  Future<void> _saveItem() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('REFERENCE DESIGNATION REQUIRED'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => isSaving = true);

    try {
      Map<String, dynamic> data = {};
      switch (selectedType) {
        case 'note': data = {'content': _noteContentController.text}; break;
        case 'password': data = {'username': _usernameController.text, 'password': _passwordController.text, 'url': _urlController.text}; break;
        case 'credit_card': data = {'card_number': _cardNumberController.text, 'cardholder_name': _cardholderNameController.text, 'expiry_month': _expiryMonthController.text, 'expiry_year': _expiryYearController.text, 'cvv': _cvvController.text}; break;
        case 'file': if (_selectedFile != null) { final bytes = await _selectedFile!.readAsBytes(); data = {'file_name': _selectedFile!.path.split('/').last, 'file_content': base64Encode(bytes), 'file_size': bytes.length}; } break;
        case 'crypto': data = {'coin': _cryptoCoinController.text, 'wallet_address': _cryptoWalletAddressController.text, 'seed_phrase': _cryptoSeedPhraseController.text}; break;
      }

      await ApiService().createVaultItem(
        userId: widget.userId,
        folderId: widget.folderId,
        itemType: selectedType,
        title: _titleController.text.toUpperCase(),
        encryptedData: jsonEncode(data),
        nomineeIds: _selectedNomineeIds,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('SECURITY ERROR: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => isSaving = false);
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
        title: const Text("ASSET INDUCTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildTypeSelector(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildSectionHeader("VAULT PROTOCOL"),
                  const SizedBox(height: 20),
                  Container(
                    decoration: AppTheme.slabDecoration,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        _buildSlabField(_titleController, "ARTIFACT DESIGNATION", Icons.fingerprint_rounded),
                        const SizedBox(height: 48),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text("ACCESS DELEGATION", style: TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        ),
                        const SizedBox(height: 24),
                        _isLoadingNominees ? const LinearProgressIndicator(color: AppTheme.accentColor, minHeight: 1) : _buildNomineeGrid(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildSectionHeader("ENCRYPTED DATA STREAM"),
                  const SizedBox(height: 20),
                  Container(
                    decoration: AppTheme.slabDecoration,
                    padding: const EdgeInsets.all(32),
                    child: Column(children: _buildTypeFields()),
                  ),
                  const SizedBox(height: 140),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.03))),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: isSaving ? null : _saveItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: isSaving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Text("COMMIT TO VAULT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2));
  }

  Widget _buildTypeSelector() {
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildTypeModule('note', Icons.description_rounded, "NOTE"),
          _buildTypeModule('password', Icons.vpn_key_rounded, "AUTH"),
          _buildTypeModule('credit_card', Icons.credit_card_rounded, "CARD"),
          _buildTypeModule('crypto', Icons.currency_bitcoin_rounded, "CRYPTO"),
          _buildTypeModule('file', Icons.insert_drive_file_rounded, "FILE"),
        ],
      ),
    );
  }

  Widget _buildTypeModule(String type, IconData icon, String label) {
    bool isSelected = selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 16),
        width: 100,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor.withOpacity(0.05) : Colors.white.withOpacity(0.01),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? AppTheme.accentColor : Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppTheme.accentColor : Colors.white12, size: 28),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: isSelected ? AppTheme.accentColor : Colors.white12, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildNomineeGrid() {
    if (_nominees.isEmpty) {
      return const Text("NO NOMINEES REGISTERED. PROTOCOL: OWNER-ONLY ACCESS.", style: TextStyle(color: Colors.white10, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1));
    }
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _nominees.map((n) {
        bool isSelected = _selectedNomineeIds.contains(n['id']);
        return InkWell(
          onTap: () {
            setState(() {
              if (isSelected) _selectedNomineeIds.remove(n['id']);
              else _selectedNomineeIds.add(n['id']);
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.accentColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppTheme.accentColor : Colors.white.withOpacity(0.03)),
            ),
            child: Text(n['name'].toString().toUpperCase(), style: TextStyle(color: isSelected ? AppTheme.accentColor : Colors.white10, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSlabField(TextEditingController controller, String label, IconData icon, {bool obscure = false, int maxLines = 1, TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            maxLines: obscure ? 1 : maxLines,
            keyboardType: type,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.accentColor.withOpacity(0.4), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTypeFields() {
    switch (selectedType) {
      case 'note': return [_buildSlabField(_noteContentController, "NOTE CONTENT STREAM", Icons.notes_rounded, maxLines: 10)];
      case 'password': return [
        _buildSlabField(_usernameController, "IDENTITY IDENTIFIER", Icons.person_rounded),
        const SizedBox(height: 32),
        _buildSlabField(_passwordController, "ACCESS CREDENTIAL", Icons.key_rounded, obscure: true),
        const SizedBox(height: 32),
        _buildSlabField(_urlController, "NETWORK ENDPOINT", Icons.public_rounded, type: TextInputType.url),
      ];
      case 'credit_card': return [
        CreditCardWidget(
          cardNumber: _cardNumberController.text.isEmpty ? "XXXX XXXX XXXX XXXX" : _cardNumberController.text,
          cardHolder: _cardholderNameController.text.isEmpty ? "HOLDER DESIGNATION" : _cardholderNameController.text.toUpperCase(),
          expiryDate: "${_expiryMonthController.text}/${_expiryYearController.text}",
          baseColor: Colors.black,
        ),
        const SizedBox(height: 48),
        _buildSlabField(_cardNumberController, "INSTRUMENT NUMBER", Icons.credit_card_rounded, type: TextInputType.number),
        const SizedBox(height: 32),
        _buildSlabField(_cardholderNameController, "HOLDER DESIGNATION", Icons.person_rounded),
        const SizedBox(height: 32),
        Row(children: [
          Expanded(child: _buildSlabField(_expiryMonthController, "MM", Icons.calendar_today_rounded, type: TextInputType.number)),
          const SizedBox(width: 16),
          Expanded(child: _buildSlabField(_expiryYearController, "YY", Icons.calendar_today_rounded, type: TextInputType.number)),
          const SizedBox(width: 16),
          Expanded(child: _buildSlabField(_cvvController, "CVV", Icons.security_rounded, obscure: true, type: TextInputType.number)),
        ]),
      ];
      case 'crypto': return [
        _buildSlabField(_cryptoCoinController, "ASSET DESIGNATION", Icons.token_rounded),
        const SizedBox(height: 32),
        _buildSlabField(_cryptoWalletAddressController, "WALLET ADDRESS", Icons.account_balance_wallet_rounded),
        const SizedBox(height: 32),
        _buildSlabField(_cryptoSeedPhraseController, "RECOVERY MNEMONIC", Icons.vpn_key_rounded, obscure: true),
      ];
      case 'file': return [
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 64),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.01),
              border: Border.all(color: AppTheme.accentColor.withOpacity(0.1), width: 1.5),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Icon(_selectedFile == null ? Icons.cloud_upload_rounded : Icons.verified_user_rounded, color: AppTheme.accentColor, size: 56),
                const SizedBox(height: 32),
                Text(_selectedFile == null ? "INJECT SOURCE ARTIFACT" : _selectedFile!.path.split('/').last.toUpperCase(), 
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
              ],
            ),
          ),
        ),
      ];
      default: return [];
    }
  }
}
