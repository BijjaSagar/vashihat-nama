import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/glassmorphism.dart';

class SmartScanScreen extends StatefulWidget {
  final int userId;
  const SmartScanScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _SmartScanScreenState createState() => _SmartScanScreenState();
}

class _SmartScanScreenState extends State<SmartScanScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // File & OCR
  File? _imageFile;
  final _textRecognizer = TextRecognizer();
  bool _isScanning = false;
  
  // Form Fields
  final TextEditingController _docTypeController = TextEditingController();
  final TextEditingController _docNumberController = TextEditingController();
  final TextEditingController _authorityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  DateTime? _expiryDate;
  DateTime? _renewalDate;

  // Recognized Data
  String _recognizedText = "";

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  // 1. Pick Image
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

  // 2. Process Image with ML Kit
  Future<void> _processImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    
    _recognizedText = recognizedText.text;
    _analyzeText(_recognizedText);

    if (mounted) {
      setState(() {
        _isScanning = false;
      });
    }
  }

  // 3. Analyze Text (Regex for Dates & Keywords)
  void _analyzeText(String text) {
    // A. Detect Document Type (Simple Keyword Matching)
    String lowerText = text.toLowerCase();
    if (lowerText.contains("insurance")) {
      _docTypeController.text = "Insurance Policy";
    } else if (lowerText.contains("license") || lowerText.contains("licence")) {
      _docTypeController.text = "Driving License";
    } else if (lowerText.contains("passport")) {
      _docTypeController.text = "Passport";
    } else if (lowerText.contains("warranty")) {
      _docTypeController.text = "Warranty Card";
    } else if (lowerText.contains("pan card") || lowerText.contains("permanent account")) {
      _docTypeController.text = "PAN Card";
    } else if (lowerText.contains("aadhaar")) {
      _docTypeController.text = "Aadhaar Card";
    } else {
      _docTypeController.text = "Document";
    }

    // B. Detect Dates (DD/MM/YYYY or DD-MM-YYYY)
    // Regex allows / . - separators
    RegExp dateRegExp = RegExp(r"(\d{2})[\/.-](\d{2})[\/.-](\d{4})");
    Iterable<RegExpMatch> matches = dateRegExp.allMatches(text);
    
    List<DateTime> foundDates = [];
    for (var m in matches) {
      try {
        // Normalize separators
        String dStr = m.group(0)!.replaceAll('-', '/').replaceAll('.', '/');
        foundDates.add(DateFormat('dd/MM/yyyy').parse(dStr));
      } catch (e) {
        // ignore invalid dates
      }
    }

    // Logic: Usually Expiry Date is in the future
    DateTime now = DateTime.now();
    foundDates.sort((a, b) => a.compareTo(b)); // Sort ascending
    
    DateTime? probableExpiry;
    for (var d in foundDates) {
      if (d.isAfter(now)) {
        probableExpiry = d;
        break; // First future date is likely expiry
      }
    }

    if (probableExpiry != null) {
      setState(() {
        _expiryDate = probableExpiry;
        // Renewal is usually same as expiry or 1 day before
        _renewalDate = probableExpiry!.subtract(const Duration(days: 1));
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("AI Detected Expiry: ${DateFormat('dd/MM/yyyy').format(probableExpiry)}"))
      );
    }

    // C. Detect Authority (Simple)
    if (lowerText.contains("transport")) _authorityController.text = "Transport Dept";
    if (lowerText.contains("govt of india") || lowerText.contains("government")) _authorityController.text = "Government of India";
  }

  // 4. Save Intelligent Alert
  Future<void> _saveSmartDoc() async {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select an expiry date")));
      return;
    }

    try {
      await ApiService().createSmartAlert(
        userId: widget.userId,
        docType: _docTypeController.text,
        docNumber: _docNumberController.text,
        expiryDate: _expiryDate,
        renewalDate: _renewalDate,
        issuingAuthority: _authorityController.text,
        notes: _notesController.text,
        // Optional: File Upload logic can be added here (uploading _imageFile)
        // For now, we just save the intelligence data.
      );

      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Smart Alert Saved!")));
         Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _selectDate(bool isExpiry) async {
    DateTime initial = isExpiry ? (_expiryDate ?? DateTime.now()) : (_renewalDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isExpiry) {
          _expiryDate = picked;
          if (_renewalDate == null) _renewalDate = picked.subtract(const Duration(days: 1));
        } else {
          _renewalDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Smart Scan 🧠", style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
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
            colors: [
              Color(0xFFF2F2F7), 
              Color(0xFFE5E5EA),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Image Preview / Scanner
                   GestureDetector(
                     onTap: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Camera'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.camera);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Search Gallery'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.gallery);
                                },
                              ),
                            ],
                          )
                        );
                     },
                     child: Container(
                       height: 200,
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(16),
                         border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                         boxShadow: [
                           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                         ]
                       ),
                       child: _imageFile != null
                         ? ClipRRect(
                             borderRadius: BorderRadius.circular(16),
                             child: Image.file(_imageFile!, fit: BoxFit.cover),
                           )
                         : Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Icon(Icons.document_scanner, size: 48, color: AppTheme.primaryColor),
                               const SizedBox(height: 8),
                               const Text("Tap to Scan Document", style: TextStyle(color: AppTheme.textSecondary)),
                             ],
                           ),
                     ),
                   ),
                   const SizedBox(height: 10),
                   if (_isScanning) const LinearProgressIndicator(),

                   const SizedBox(height: 20),
                   GlassCard(
                     child: Padding(
                       padding: const EdgeInsets.all(16),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text("Detected Intelligence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                           const SizedBox(height: 16),
                           
                           // Doc Type
                           TextFormField(
                             controller: _docTypeController,
                             decoration: const InputDecoration(labelText: "Document Type", border: OutlineInputBorder()),
                             validator: (v) => v!.isEmpty ? "Required" : null,
                           ),
                           const SizedBox(height: 12),
                           
                           // Doc Number
                           TextFormField(
                             controller: _docNumberController,
                             decoration: const InputDecoration(labelText: "Policy / ID Number", border: OutlineInputBorder()),
                           ),
                           const SizedBox(height: 12),
                           
                           // Dates Row
                           Row(
                             children: [
                               Expanded(
                                 child: InkWell(
                                   onTap: () => _selectDate(true),
                                   child: InputDecorator(
                                     decoration: const InputDecoration(labelText: "Expiry Date", border: OutlineInputBorder()),
                                     child: Text(
                                       _expiryDate == null ? "Select" : DateFormat('dd/MM/yyyy').format(_expiryDate!),
                                       style: TextStyle(color: _expiryDate == null ? Colors.grey : Colors.black),
                                     ),
                                   ),
                                 ),
                               ),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: InkWell(
                                   onTap: () => _selectDate(false),
                                   child: InputDecorator(
                                     decoration: const InputDecoration(labelText: "Renewal Reminder", border: OutlineInputBorder()),
                                     child: Text(
                                       _renewalDate == null ? "Select" : DateFormat('dd/MM/yyyy').format(_renewalDate!),
                                       style: TextStyle(color: _renewalDate == null ? Colors.grey : Colors.black),
                                     ),
                                   ),
                                 ),
                               ),
                             ],
                           ),
                           const SizedBox(height: 12),
                           
                           // Authority
                           TextFormField(
                             controller: _authorityController,
                             decoration: const InputDecoration(labelText: "Issuing Authority", border: OutlineInputBorder()),
                           ),
                           const SizedBox(height: 12),

                           // Notes
                           TextFormField(
                             controller: _notesController,
                             decoration: const InputDecoration(labelText: "Notes", border: OutlineInputBorder()),
                             maxLines: 2,
                           ),
                         ],
                       ),
                     ),
                   ),
                   const SizedBox(height: 24),
                   SizedBox(
                     height: 50,
                     child: ElevatedButton(
                       onPressed: _saveSmartDoc,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: AppTheme.primaryColor,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       ),
                       child: const Text("Save Alert & Reminder", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                     ),
                   ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
