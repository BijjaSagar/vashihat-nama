import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../theme/glassmorphism.dart';
import '../services/api_service.dart';
import '../widgets/credit_card_widget.dart';

class AddCreditCardScreen extends StatefulWidget {
  final int userId;
  final int folderId;

  const AddCreditCardScreen({
    Key? key, 
    required this.userId, 
    required this.folderId
  }) : super(key: key);

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
          
          // Simple Regex for Visa/Mastercard (13-19 digits)
          if (RegExp(r'^\d{13,19}$').hasMatch(text)) {
            cardNumber = line.text;
          }
          
          // Regex for Expiry Date (MM/YY or MM/YYYY)
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in required fields")));
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Create a JSON object for the card data
      String cardData = '''
      {
        "holder": "${_holderNameController.text}",
        "number": "${_cardNumberController.text}",
        "expiry": "${_expiryController.text}",
        "cvv": "${_cvvController.text}"
      }
      ''';

      // Use the generic createVaultItem API
      await ApiService().createVaultItem(
        userId: widget.userId,
        folderId: widget.folderId,
        itemType: 'credit_card',
        title: "Card ending in ${_cardNumberController.text.length > 4 ? _cardNumberController.text.substring(_cardNumberController.text.length - 4) : 'XXXX'}",
        encryptedData: cardData, // In a real app, encrypt this first!
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Card Saved Successfully")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Add Card", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.camera_front : Icons.camera_alt, color: AppTheme.primaryColor),
            onPressed: _scanCard,
            tooltip: "Scan Card",
          )
        ],
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Camera Preview Area (Mock/Placeholder for now, or actual if available)
                if (_isScanning)
                  Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.primaryColor, width: 2),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            "Scanning Card...",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Hold steady",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Visual Card Preview
                  Container(
                    margin: const EdgeInsets.only(bottom: 30),
                    child: ListenableBuilder(
                      listenable: Listenable.merge([_cardNumberController, _holderNameController, _expiryController]),
                      builder: (context, _) {
                        // Very simple card visual
                        return Container(
                          height: 200,
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E1E1E), Color(0xFF2C2C2E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Debit / Credit", style: TextStyle(color: Colors.white54, fontSize: 12)),
                                  Icon(Icons.contactless, color: Colors.white.withOpacity(0.7), size: 20),
                                ],
                              ),
                              Text(
                                _cardNumberController.text.isEmpty ? "0000 0000 0000 0000" : _cardNumberController.text,
                                style: const TextStyle(color: Colors.white, fontSize: 22, letterSpacing: 2, fontFamily: 'Courier'),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("CARD HOLDER", style: TextStyle(color: Colors.white30, fontSize: 8)),
                                      Text(
                                        _holderNameController.text.isEmpty ? "YOUR NAME" : _holderNameController.text.toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text("EXPIRES", style: TextStyle(color: Colors.white30, fontSize: 8)),
                                      Text(
                                        _expiryController.text.isEmpty ? "MM/YY" : _expiryController.text,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                GlassCard(
                  opacity: 0.7,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _holderNameController,
                        label: "Cardholder Name",
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _cardNumberController,
                        label: "Card Number",
                        icon: Icons.credit_card,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _expiryController,
                              label: "Expiry (MM/YY)",
                              icon: Icons.calendar_today,
                              keyboardType: TextInputType.datetime,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _cvvController,
                              label: "CVV",
                              icon: Icons.lock_outline,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, // Apple style black button
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 5,
                      shadowColor: Colors.black26,
                    ),
                    child: _isSaving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Save to Vault", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: _scanCard,
                    icon: const Icon(Icons.camera_alt_outlined, color: AppTheme.primaryColor),
                    label: const Text("Scan Card with Camera", style: TextStyle(color: AppTheme.primaryColor)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    List<TextInputFormatter> formatters = [];
    if (label.contains("Card Number")) {
       formatters.add(FilteringTextInputFormatter.digitsOnly);
       formatters.add(LengthLimitingTextInputFormatter(19));
       // Add space every 4 digits logic could be here, or use a package
    } else if (label.contains("Expiry")) {
       formatters.add(LengthLimitingTextInputFormatter(5)); // MM/YY
    } else if (label.contains("CVV")) {
      formatters.add(FilteringTextInputFormatter.digitsOnly);
      formatters.add(LengthLimitingTextInputFormatter(4));
    }

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: formatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: const UnderlineInputBorder(), // Simpler look
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primaryColor, width: 2)),
      ),
    );
  }
}
