import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class AddCreditCardScreen extends StatefulWidget {
  final int userId;
  final int folderId;

  const AddCreditCardScreen({
    super.key, 
    required this.userId, 
    required this.folderId
  });

  @override
  _AddCreditCardScreenState createState() => _AddCreditCardScreenState();
}

class _AddCreditCardScreenState extends State<AddCreditCardScreen> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _holderNameController = TextEditingController();
  
  bool _isScanning = false;
  bool _isSaving = false;

  Future<void> _scanCard() async {
    setState(() => _isScanning = true);
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) {
      setState(() => _isScanning = false);
      return;
    }

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      String cardNumber = "";
      String expiryDate = "";

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String text = line.text.replaceAll(" ", "");
          if (RegExp(r'^\d{13,19}$').hasMatch(text)) {
            cardNumber = line.text;
          }
          if (RegExp(r'^(0[1-9]|1[0-2])\/\d{2,4}$').hasMatch(line.text)) {
            expiryDate = line.text;
          }
        }
      }

      setState(() {
        if (cardNumber.isNotEmpty) _cardNumberController.text = cardNumber;
        if (expiryDate.isNotEmpty) _expiryController.text = expiryDate;
      });

      textRecognizer.close();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Scan Failed: $e")));
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _saveCard() async {
    if (_cardNumberController.text.isEmpty || _expiryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Required metrics missing.")));
      return;
    }

    setState(() => _isSaving = true);
    try {
      String cardData = '{"holder": "${_holderNameController.text}", "number": "${_cardNumberController.text}", "expiry": "${_expiryController.text}", "cvv": "${_cvvController.text}"}';
      await ApiService().createVaultItem(
        userId: widget.userId,
        folderId: widget.folderId,
        itemType: 'credit_card',
        title: "CARD ENDING IN ${_cardNumberController.text.length > 4 ? _cardNumberController.text.substring(_cardNumberController.text.length - 4) : 'XXXX'}",
        encryptedData: cardData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Asset secured in vault."), backgroundColor: AppTheme.accentColor));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Security sync error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Financial Ingestion", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.qr_code_scanner_rounded : Icons.camera_alt_rounded, color: AppTheme.accentColor),
            onPressed: _scanCard,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardPreview(),
            const SizedBox(height: 48),
            const Text("ASSET IDENTIFIERS", style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.slabDecoration,
              child: Column(
                children: [
                  _buildSentinelField("LEGAL HOLDER", _holderNameController, Icons.person_outline_rounded),
                  const SizedBox(height: 24),
                  _buildSentinelField("INSTRUMENT NUMBER", _cardNumberController, Icons.credit_card_rounded, type: TextInputType.number),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildSentinelField("EXPIRY", _expiryController, Icons.calendar_today_rounded)),
                      const SizedBox(width: 24),
                      Expanded(child: _buildSentinelField("SECRET", _cvvController, Icons.lock_outline_rounded, obscure: true)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 72,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveCard,
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("COMMIT TO VAULT"),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: _scanCard,
                icon: const Icon(Icons.document_scanner_rounded, color: AppTheme.accentColor, size: 16),
                label: const Text("OPTICAL SCAN", style: TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardPreview() {
    return ListenableBuilder(
      listenable: Listenable.merge([_cardNumberController, _holderNameController, _expiryController]),
      builder: (context, _) {
        return Container(
          height: 220,
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: const Color(0xFF161618),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("SENTINEL CORE", style: TextStyle(color: AppTheme.accentColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  Icon(Icons.wifi_rounded, color: Colors.white.withOpacity(0.1), size: 18),
                ],
              ),
              Text(
                _cardNumberController.text.isEmpty ? "•••• •••• •••• ••••" : _cardNumberController.text,
                style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 3, fontWeight: FontWeight.w600),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("SUBJECT", style: TextStyle(color: Colors.white12, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      Text(
                        _holderNameController.text.isEmpty ? "UNDEFINED" : _holderNameController.text.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("VALIDITY", style: TextStyle(color: Colors.white12, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      Text(
                        _expiryController.text.isEmpty ? "••/••" : _expiryController.text,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSentinelField(String label, TextEditingController ctrl, IconData icon, {TextInputType type = TextInputType.text, bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: type,
            obscureText: obscure,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.accentColor.withOpacity(0.5), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }
}
