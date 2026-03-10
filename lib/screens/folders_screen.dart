import 'package:flutter/material.dart';
import '../theme/glassmorphism.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'vault_items_screen.dart';

class FoldersScreen extends StatefulWidget {
  final int userId;
  const FoldersScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<dynamic> folders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      final fetchedFolders = await ApiService().getFolders(widget.userId.toString());
      
      // Auto-create "Bank Accounts" if missing
      bool hasBankDetails = fetchedFolders.any((f) => f['name'] == 'Bank Accounts');
      if (!hasBankDetails) {
        await ApiService().createFolder(widget.userId.toString(), 'Bank Accounts', 'account_balance');
        // Reload to get the ID of the new folder
        final updatedFolders = await ApiService().getFolders(widget.userId.toString());
         if (mounted) {
          setState(() {
            folders = updatedFolders;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            folders = fetchedFolders;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error loading folders: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _createFolder(String name) async {
    try {
      await ApiService().createFolder(widget.userId.toString(), name, "folder_shared"); // Default icon
      _loadFolders(); // Refresh list
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Folder Created")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _renameFolder(int folderId, String currentName) async {
    final TextEditingController renameController = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Rename Folder", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: renameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Enter new name",
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (renameController.text.isNotEmpty) {
                Navigator.pop(context, renameController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Rename", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      try {
        await ApiService().renameFolder(folderId, newName, widget.userId.toString());
        _loadFolders();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Folder Renamed")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Future<void> _confirmDeleteFolder(int folderId, String folderName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Folder", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to delete \"$folderName\"? All items inside this folder will also be removed.",
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService().deleteFolder(folderId, widget.userId.toString());
        _loadFolders();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Folder Deleted")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Secure Vault", 
          style: TextStyle(
            color: AppTheme.textPrimary, 
            fontWeight: FontWeight.bold
          )
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.primaryColor),
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
            : folders.isEmpty 
              ? Center(child: Text("No folders found", style: TextStyle(color: AppTheme.textSecondary)))
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.builder(
                    padding: const EdgeInsets.only(top: 20, bottom: 80),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final folder = folders[index];
                      // Fallback dummy styling if API doesn't provide color/icon
                      Color folderColor = Colors.blue; 
                      IconData folderIcon = Icons.folder;
                      
                      return GestureDetector(
                        onTap: () {
                           Navigator.push(context, MaterialPageRoute(builder: (context) => VaultItemsScreen(
                             userId: widget.userId,
                             folderId: folder['id'],
                             folderName: folder['name'],
                           )));
                        },
                        child: GlassCard(
                          opacity: 0.6,
                          blur: 20,
                          color: Colors.white,
                          borderColor: Colors.white.withOpacity(0.9),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: folderColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(folderIcon, size: 28, color: folderColor),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_horiz, color: AppTheme.textSecondary, size: 20),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 8,
                                    onSelected: (value) {
                                      if (value == 'rename') {
                                        _renameFolder(folder['id'], folder['name']);
                                      } else if (value == 'delete') {
                                        _confirmDeleteFolder(folder['id'], folder['name']);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem<String>(
                                        value: 'rename',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_rounded, size: 20, color: AppTheme.primaryColor),
                                            const SizedBox(width: 12),
                                            const Text("Rename", style: TextStyle(fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red),
                                            const SizedBox(width: 12),
                                            const Text("Delete", style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    folder['name'],
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Encrypted", // We can add file count from API later
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final TextEditingController folderNameController = TextEditingController();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("New Folder", style: TextStyle(fontWeight: FontWeight.bold)),
              content: TextField(
                controller: folderNameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "Folder Name",
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    if (folderNameController.text.isNotEmpty) {
                      Navigator.pop(context);
                      _createFolder(folderNameController.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Create", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
