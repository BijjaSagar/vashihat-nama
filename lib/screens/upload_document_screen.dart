import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../theme/glassmorphism.dart';
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
    setState(() => _isUploading = true);

    try {
      await ApiService().uploadFile(widget.folderId, selectedFile!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File uploaded successfully!")));
      Navigator.pop(context); // Go back after upload
    } catch (e) {
      print("Error uploading file: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error uploading file: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Upload Document", style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
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
            colors: [
              Color(0xFFF2F2F7), // System Gray 6
              Color(0xFFE5E5EA), // System Gray 5
              Color(0xFFF2F2F7),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassCard(
                opacity: 0.6,
                blur: 20,
                color: Colors.white,
                borderColor: Colors.white.withOpacity(0.9),
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      selectedFile != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
                      size: 64,
                      color: selectedFile != null ? Colors.green : AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      selectedFile != null ? "File Selected" : "Select a file to upload",
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        color: AppTheme.textPrimary
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedFile != null ? selectedFile!.path.split('/').last : "Tap below to browse",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    
                    if (selectedFile == null)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: pickFile,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppTheme.primaryColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Choose File"),
                        ),
                      ),
                      
                    if (selectedFile != null) ...[
                       const SizedBox(height: 16),
                       SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : uploadFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isUploading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Upload Now", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: pickFile,
                        child: const Text("Change File"),
                      )
                    ]
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

