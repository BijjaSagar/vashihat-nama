import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; 
import '../theme/glassmorphism.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'upload_document_screen.dart';

class FilesScreen extends StatefulWidget {
  final String folderName;
  final int folderId;
  const FilesScreen({Key? key, required this.folderName, required this.folderId}) : super(key: key);

  @override
  _FilesScreenState createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  List<dynamic> files = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final fetchedFiles = await ApiService().getFiles(widget.folderId);
      if (mounted) {
        setState(() {
          files = fetchedFiles;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading files: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "Unknown Date";
    try {
      // Assuming date string is ISO or similar. Just returning simplified version for now.
      return dateStr.split('T')[0];
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.folderName, 
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold
          )
        ),
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
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : files.isEmpty
                  ? Center(child: Text("No files uploaded yet", style: TextStyle(color: AppTheme.textSecondary)))
                  : Column(
                      children: [
                        // List of Files
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: files.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final file = files[index];
                              // Determine icon/color based on mime type or extension (mock logic for now)
                              final isPdf = file['file_name'].toString().toLowerCase().endsWith('.pdf');
                              
                              return GlassCard(
                                opacity: 0.6,
                                blur: 20,
                                color: Colors.white,
                                borderColor: Colors.white.withOpacity(0.9),
                                padding: const EdgeInsets.all(12),
                                borderRadius: BorderRadius.circular(16),
                                child: Row(
                                  children: [
                                    // File Icon
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isPdf 
                                            ? Colors.red.withOpacity(0.1) 
                                            : Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        isPdf ? Icons.picture_as_pdf : Icons.image,
                                        color: isPdf ? Colors.redAccent : Colors.blueAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    
                                    // File Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            file['file_name'] ?? "Unknown File",
                                            style: TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                "${(double.parse((file['file_size'] ?? 0).toString()) / 1024).toStringAsFixed(1)} KB",
                                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(Icons.circle, size: 4, color: AppTheme.textSecondary.withOpacity(0.5)),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatDate(file['uploaded_at'] ?? file['created_at']),
                                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    
                                    // Actions
                                    IconButton(
                                      icon: Icon(Icons.more_vert, color: AppTheme.textSecondary),
                                      onPressed: () {},
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UploadDocumentScreen(folderId: widget.folderId)),
          );
          // Refresh list on return
          _loadFiles();
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text("Upload File"),
      ),
    );
  }
}


