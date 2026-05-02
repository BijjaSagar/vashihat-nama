import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SmartScanScreen extends StatefulWidget {
  final int userId;
  final String mode; 
  const SmartScanScreen({super.key, required this.userId, this.mode = 'document'});

  @override
  _SmartScanScreenState createState() => _SmartScanScreenState();
}

class _SmartScanScreenState extends State<SmartScanScreen> {
  File? _imageFile;
  final _textRecognizer = TextRecognizer();
  bool _isScanning = false;
  
  final TextEditingController _docTypeController = TextEditingController();
  final TextEditingController _docNumberController = TextEditingController();
  final TextEditingController _authorityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _textRecognizer.close();
    _docTypeController.dispose();
    _docNumberController.dispose();
    _authorityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _isScanning = true;
      });
      _processImage(_imageFile!);
    }
  }

  Future<void> _processImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    await _classifyWithAI(recognizedText.text);
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _classifyWithAI(String text) async {
    try {
      final result = await ApiService().classifyDocument(text);
      if (mounted) {
        setState(() {
          _docTypeController.text = (result['category'] ?? "DOCUMENT").toString().toUpperCase();
          _notesController.text = (result['title'] ?? "").toString().toUpperCase();
        });
      }
    } catch (e) {
      // Manual entry fallback
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
        title: const Text("OPTICAL INTELLIGENCE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            _buildScannerSlab(),
            const SizedBox(height: 40),
            _buildDataSlab(),
            const SizedBox(height: 56),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: _imageFile == null || _isScanning ? null : () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.black,
                ),
                child: const Text("ENSHRINE IN VAULT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerSlab() {
    return GestureDetector(
      onTap: () => _pickImage(ImageSource.camera),
      child: Container(
        height: 280,
        width: double.infinity,
        decoration: AppTheme.slabDecoration.copyWith(
          border: Border.all(color: _imageFile != null ? AppTheme.accentColor.withOpacity(0.2) : Colors.white.withOpacity(0.05)),
        ),
        child: Stack(
          children: [
            if (_imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(24), 
                child: Opacity(
                  opacity: _isScanning ? 0.3 : 1.0,
                  child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                )
              ),
            Center(
              child: _isScanning 
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.accentColor, strokeWidth: 2),
                      const SizedBox(height: 24),
                      Text("EXTRACTING METADATA...", style: TextStyle(color: AppTheme.accentColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ],
                  )
                : _imageFile == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_rounded, color: AppTheme.accentColor, size: 48),
                        const SizedBox(height: 24),
                        Text("INITIATE SCAN", style: TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        const SizedBox(height: 8),
                        Text("POSITION DOCUMENT WITHIN FRAME", style: TextStyle(color: Colors.white10, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSlab() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.slabDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("DERIVED METADATA", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 32),
          _buildSlabInput("CATEGORY", _docTypeController, Icons.grid_view_rounded),
          const SizedBox(height: 24),
          _buildSlabInput("IDENTIFIER", _docNumberController, Icons.pin_rounded, hint: "EXTRACTING..."),
          const SizedBox(height: 24),
          _buildSlabInput("ISSUING AUTHORITY", _authorityController, Icons.account_balance_rounded),
          const SizedBox(height: 24),
          _buildSlabInput("REMARKS", _notesController, Icons.notes_rounded),
        ],
      ),
    );
  }

  Widget _buildSlabInput(String label, TextEditingController ctrl, IconData icon, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.01), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white10, fontSize: 11, fontWeight: FontWeight.w800),
              prefixIcon: Icon(icon, color: AppTheme.accentColor.withOpacity(0.4), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
