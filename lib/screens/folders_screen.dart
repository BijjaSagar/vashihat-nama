import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'vault_items_screen.dart';

class FoldersScreen extends StatefulWidget {
  final int userId;
  const FoldersScreen({super.key, required this.userId});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<dynamic> _allFolders = [];
  List<dynamic> _displayed = [];
  bool _isLoading = true;
  String _selectedCategory = "ALL";
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _categories = ["ALL", "IDENTITY", "FINANCIAL", "LEGAL", "DIGITAL"];

  @override
  void initState() {
    super.initState();
    _loadFolders();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFolders() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final fetched = await ApiService().getFolders(widget.userId);
      if (mounted) {
        setState(() {
          _allFolders = fetched;
          _displayed = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _displayed = _allFolders
          .where((f) => f['name'].toString().toLowerCase().contains(q))
          .toList();
    });
  }

  // ── Show bottom sheet to CREATE a new folder
  void _showCreateFolderSheet() {
    final nameCtrl = TextEditingController();
    String selectedIcon = 'folder';
    bool isSaving = false;

    final iconOptions = [
      {'key': 'folder',          'icon': Icons.folder_rounded,             'label': 'GENERAL'},
      {'key': 'account_balance', 'icon': Icons.account_balance_wallet_rounded, 'label': 'FINANCIAL'},
      {'key': 'folder_shared',   'icon': Icons.folder_shared_rounded,      'label': 'IDENTITY'},
      {'key': 'lock',            'icon': Icons.lock_rounded,               'label': 'LEGAL'},
      {'key': 'devices',         'icon': Icons.devices_rounded,            'label': 'DIGITAL'},
      {'key': 'photo',           'icon': Icons.photo_library_rounded,      'label': 'MEDIA'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 32,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          decoration: BoxDecoration(
            color: AppTheme.slabColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text("CREATE NEW FOLDER",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              const Text("SECURE VAULT DIRECTORY",
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2)),
              const SizedBox(height: 28),

              // Folder name input
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.folder_rounded, color: AppTheme.accentColor, size: 20),
                    hintText: "FOLDER NAME",
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Icon picker
              const Text("FOLDER TYPE",
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 12),
              SizedBox(
                height: 72,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: iconOptions.length,
                  itemBuilder: (_, i) {
                    final opt = iconOptions[i];
                    final isSelected = selectedIcon == opt['key'];
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedIcon = opt['key'] as String),
                      child: Container(
                        width: 72,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.accentColor.withValues(alpha: 0.12) : AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppTheme.accentColor : Colors.white.withValues(alpha: 0.06),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(opt['icon'] as IconData,
                              color: isSelected ? AppTheme.accentColor : Colors.white38, size: 22),
                          const SizedBox(height: 4),
                          Text(opt['label'] as String,
                              style: TextStyle(
                                  color: isSelected ? AppTheme.accentColor : Colors.white38,
                                  fontSize: 6, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),

              // Create button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          setSheetState(() => isSaving = true);
                          try {
                            await ApiService().createFolder(
                              widget.userId,
                              name.toUpperCase(),
                              selectedIcon,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadFolders();
                          } catch (e) {
                            setSheetState(() => isSaving = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text("ERROR: $e"),
                                    backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text("CREATE FOLDER",
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildCategoryChips(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
                  : _displayed.isEmpty
                      ? _buildEmptyState()
                      : _buildFolderList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "folder_action_btn",
        onPressed: _showCreateFolderSheet,
        backgroundColor: AppTheme.accentColor,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.create_new_folder_rounded, color: Colors.black, size: 20),
        label: const Text("NEW FOLDER",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("VAULT DIRECTORY",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppTheme.accentColor, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.slabColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: TextField(
          controller: _searchCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded, color: Colors.white38, size: 18),
            hintText: "SEARCH SECURE ARCHIVES",
            hintStyle: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: _categories.length,
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final active = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppTheme.accentColor.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? AppTheme.accentColor.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.06),
                ),
              ),
              child: Text(cat,
                  style: TextStyle(
                      color: active ? AppTheme.accentColor : Colors.white38,
                      fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFolderList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
      itemCount: _displayed.length,
      itemBuilder: (_, i) => _folderTile(_displayed[i]),
    );
  }

  Widget _folderTile(dynamic folder) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VaultItemsScreen(
          userId: widget.userId,
          folderId: folder['id'] ?? 0,
          folderName: folder['name'],
        )),
      ).then((_) => _loadFolders()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: AppTheme.slabDecoration,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.15)),
              ),
              child: Icon(_iconFor(folder['icon']), color: AppTheme.accentColor, size: 20),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(folder['name'].toString().toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text("${folder['item_count'] ?? 0} ITEMS · SENTINEL PROTECTED",
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 7,
                        fontWeight: FontWeight.w800, letterSpacing: 1)),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.slabColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: const Icon(Icons.create_new_folder_outlined, color: AppTheme.accentColor, size: 40),
        ),
        const SizedBox(height: 20),
        const Text("NO FOLDERS YET",
            style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        const Text("TAP 'NEW FOLDER' TO CREATE YOUR FIRST ARCHIVE",
            style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ]),
    );
  }

  IconData _iconFor(String? key) {
    switch (key) {
      case 'account_balance': return Icons.account_balance_wallet_rounded;
      case 'folder_shared':   return Icons.folder_shared_rounded;
      case 'lock':            return Icons.lock_rounded;
      case 'devices':         return Icons.devices_rounded;
      case 'photo':           return Icons.photo_library_rounded;
      default:                return Icons.folder_rounded;
    }
  }
}
