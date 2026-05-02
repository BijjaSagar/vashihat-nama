import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'upload_document_screen.dart';

class FilesScreen extends StatefulWidget {
  final String folderName;
  final int folderId;
  const FilesScreen({super.key, required this.folderName, required this.folderId});

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
    if (mounted) setState(() => isLoading = true);
    try {
      final fetchedFiles = await ApiService().getFiles(widget.folderId);
      if (mounted) {
        setState(() {
          files = fetchedFiles;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "Unknown Date";
    try {
      return dateStr.split('T')[0];
    } catch (e) {
      return dateStr;
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
        title: Text(widget.folderName.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.white.withOpacity(0.05)),
                      const SizedBox(height: 24),
                      const Text("NO ARTIFACTS FOUND", style: TextStyle(color: Colors.white12, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final isPdf = file['file_name'].toString().toLowerCase().endsWith('.pdf');
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: AppTheme.slabDecoration,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (isPdf ? Colors.redAccent : AppTheme.accentColor).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPdf ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                              color: isPdf ? Colors.redAccent : AppTheme.accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file['file_name']?.toString().toUpperCase() ?? "UNKNOWN_ARTIFACT",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      "${(double.parse((file['file_size'] ?? 0).toString()) / 1024).toStringAsFixed(1)} KB",
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text("|", style: TextStyle(color: Colors.white10, fontSize: 10)),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDate(file['uploaded_at'] ?? file['created_at']).toUpperCase(),
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_horiz_rounded, color: Colors.white24),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UploadDocumentScreen(folderId: widget.folderId)),
          );
          _loadFiles();
        },
        backgroundColor: AppTheme.accentColor,
        icon: const Icon(Icons.add_rounded, color: Colors.black),
        label: const Text("INGEST ARTIFACT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
      ),
    );
  }
}
