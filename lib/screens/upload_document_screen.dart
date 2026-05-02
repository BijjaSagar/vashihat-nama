import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class UploadDocumentScreen extends StatefulWidget {
  final int folderId;

  const UploadDocumentScreen({super.key, required this.folderId});

  @override
  _UploadDocumentScreenState createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  File? selectedFile;
  bool _isUploading = false;

  Future<void> pickFile() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedFile = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadFile() async {
    if (selectedFile == null) return;
    if (mounted) setState(() => _isUploading = true);

    try {
      await ApiService().uploadFile(widget.folderId, selectedFile!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("DOCUMENT SECURED IN VAULT"), backgroundColor: Colors.greenAccent));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ENCRYPTION ERROR: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
        title: const Text("SECURE INGESTION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                decoration: AppTheme.slabDecoration,
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.02),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.accentColor.withOpacity(0.1)),
                      ),
                      child: Icon(
                        selectedFile != null ? Icons.verified_rounded : Icons.cloud_upload_rounded,
                        size: 64,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      selectedFile != null ? "READY FOR ENCRYPTION" : "SELECT SOURCE ASSET",
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      selectedFile != null 
                          ? selectedFile!.path.split('/').last.toUpperCase() 
                          : "INJECT A DIGITAL ARTIFACT TO BE SEALED WITHIN THE SENTINEL VAULT.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 56),
                    if (selectedFile == null)
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: OutlinedButton(
                          onPressed: pickFile,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text("BROWSE DIRECTORY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
                        ),
                      )
                    else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 64,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : uploadFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            foregroundColor: Colors.black,
                          ),
                          child: _isUploading 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                            : const Text("INITIATE UPLOAD & ENCRYPT", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: pickFile,
                        child: const Text("REPLACE ARTIFACT", style: TextStyle(color: Colors.white10, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      )
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
