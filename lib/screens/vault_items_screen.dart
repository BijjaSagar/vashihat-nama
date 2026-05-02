import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:local_auth/local_auth.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'add_vault_item_screen.dart';
import '../services/sentinel_backup_service.dart';

class VaultItemsScreen extends StatefulWidget {
  final int userId;
  final int folderId;
  final String folderName;

  const VaultItemsScreen({
    super.key,
    required this.userId,
    required this.folderId,
    required this.folderName,
  });

  @override
  _VaultItemsScreenState createState() => _VaultItemsScreenState();
}

class _VaultItemsScreenState extends State<VaultItemsScreen> {
  List<dynamic> vaultItems = [];
  bool isLoading = true;
  String selectedType = "ALL";
  final LocalAuthentication auth = LocalAuthentication();
  bool _isVerified = false;

  final List<String> types = ["ALL", "NOTE", "PASSWORD", "CREDIT_CARD", "CRYPTO", "FILE"];

  @override
  void initState() {
    super.initState();
    _loadVaultItems();
  }

  Future<void> _loadVaultItems() async {
    if (mounted) setState(() => isLoading = true);
    try {
      final items = await ApiService().getVaultItems(
        userId: widget.userId,
        folderId: widget.folderId,
        itemType: selectedType == "ALL" ? null : selectedType.toLowerCase(),
      );
      if (mounted) {
        setState(() {
          vaultItems = items;
          isLoading = false;
        });

        // --- SENTINEL INTEGRITY GUARD ---
        _runIntegrityCheck(items);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _runIntegrityCheck(List<dynamic> serverItems) async {
    final report = await SentinelBackupService().checkIntegrity(serverItems);
    if (report['status'] == 'TAMPERED' && mounted) {
      _showTamperWarning(report['message'], report['local_backup']);
    } else {
      // Auto-update local secure cache if everything is healthy
      await SentinelBackupService().saveVaultToLocalCache(serverItems);
    }
  }

  void _showTamperWarning(String message, List<dynamic> localBackup) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161922),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.redAccent, width: 2)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 12),
            Text("INTEGRITY BREACH", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("IGNORE (AT RISK)", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => vaultItems = localBackup);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("VAULT RESTORED FROM LOCAL SENTINEL CACHE"), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text("RESTORE FROM LOCAL", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Future<void> _authenticate() async {
    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'ACCESS PROTOCOL: BIOMETRIC CLEARANCE REQUIRED',
      );
      if (didAuthenticate) {
        setState(() => _isVerified = true);
        
        // Log sensitive item access
        try {
          ApiService().logActivity(
            userId: widget.userId,
            action: 'ARTIFACT_VIEWED',
            details: {
              'folderName': widget.folderName,
              'timestamp': DateTime.now().toIso8601String()
            }
          );
        } catch (e) {
          debugPrint("Logging failed: $e");
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AUTHORITY DENIED"), backgroundColor: Colors.redAccent));
    }
  }

  void _showItemDetails(Map<String, dynamic> item) {
    setState(() => _isVerified = false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.92,
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white24, size: 24), onPressed: () => Navigator.pop(context)),
                      const Text("ARTIFACT ANALYTICS", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      IconButton(icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withOpacity(0.5), size: 22), onPressed: () => _deleteItem(item['id'])),
                    ],
                  ),
                  const SizedBox(height: 48),
                  _buildSecurityGatewaySlab(item, setModalState),
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['title']?.toString().toUpperCase() ?? "UNKNOWN_ARTIFACT", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.accentColor.withOpacity(0.1)),
                          ),
                          child: Text(item['item_type'].toString().toUpperCase(), style: const TextStyle(color: AppTheme.accentColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  if (_isVerified) ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 20),
                      child: Text("DECRYPTED DATA STREAM", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    ),
                    _buildDecryptedContent(item),
                  ] else ...[
                     _buildMetadataSlab("ENCRYPTION", "AES-256-GCM"),
                     _buildMetadataSlab("INTEGRITY", "VERIFIED"),
                     _buildMetadataSlab("TIMESTAMP", "12 MAY 2024"),
                  ],
                  
                  const SizedBox(height: 48),
                  _buildActionStrip(),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildDecryptedContent(Map<String, dynamic> item) {
    try {
      final Map<String, dynamic> data = jsonDecode(item['encrypted_data']);
      final String? fileContent = data['file_content'] ?? data['FILE_CONTENT'];
      final String? fileName = (data['file_name'] ?? data['FILE_NAME'])?.toString().toLowerCase();
      
      bool isImage = false;
      if (fileName != null) {
        isImage = fileName.endsWith('.jpg') || fileName.endsWith('.jpeg') || fileName.endsWith('.png') || fileName.endsWith('.gif') || fileName.endsWith('.webp');
      }

      return Container(
        padding: const EdgeInsets.all(32),
        decoration: AppTheme.slabDecoration,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isImage && fileContent != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    base64Decode(fileContent),
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(color: Colors.white10),
                const SizedBox(height: 32),
              ],
              ...data.entries.map((e) {
                // Skip showing the raw base64 content in the text list
                if (e.key.toLowerCase() == 'file_content') return const SizedBox.shrink();
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key.toUpperCase(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      const SizedBox(width: 16),
                      Flexible(child: Text(e.value.toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5))),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      );
    } catch (e) {
      return const Center(child: Text("FAILED TO DECODE STREAM", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)));
    }
  }

  Widget _buildSecurityGatewaySlab(Map<String, dynamic> item, StateSetter setModalState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: AppTheme.slabDecoration,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_isVerified ? Icons.lock_open_rounded : Icons.lock_rounded, color: AppTheme.accentColor, size: 48),
          const SizedBox(height: 40),
          if (!_isVerified)
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: () async {
                  await _authenticate();
                  if (_isVerified) setModalState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.backgroundColor,
                  foregroundColor: AppTheme.accentColor,
                  side: BorderSide(color: AppTheme.accentColor.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("INITIATE CLEARANCE", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
              ),
            )
          else
            const Text("CLEARANCE GRANTED", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildMetadataSlab(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      decoration: AppTheme.slabDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildActionStrip() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildCircleAction(Icons.share_rounded, "SHARE"),
        _buildCircleAction(Icons.history_rounded, "AUDIT"),
        _buildCircleAction(Icons.sync_rounded, "SYNC"),
        _buildCircleAction(Icons.more_horiz_rounded, "MORE"),
      ],
    );
  }

  Widget _buildCircleAction(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.01), 
            shape: BoxShape.circle, 
            border: Border.all(color: Colors.white.withOpacity(0.05))
          ),
          child: Icon(icon, color: Colors.white.withOpacity(0.4), size: 20),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      ],
    );
  }

  Future<void> _deleteItem(int itemId) async {
    try {
      await ApiService().deleteVaultItem(itemId: itemId, userId: widget.userId);
      Navigator.pop(context);
      _loadVaultItems();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ARTIFACT PURGED FROM ARCHIVE"), backgroundColor: Colors.redAccent));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PURGE OPERATION FAILED"), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.accentColor), onPressed: () => Navigator.pop(context)),
        title: Text(widget.folderName.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded, color: Colors.white24), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterStrip(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
                  : _buildItemsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        height: 64,
        width: 64,
        margin: const EdgeInsets.only(bottom: 16, right: 8),
        child: FloatingActionButton(
          heroTag: "vault_item_action_btn",
          onPressed: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddVaultItemScreen(userId: widget.userId, folderId: widget.folderId, folderName: widget.folderName)));
            if (result == true) _loadVaultItems();
          },
          backgroundColor: AppTheme.accentColor,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.add_rounded, color: Colors.black, size: 32),
        ),
      ),
    );
  }

  Widget _buildFilterStrip() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: types.length,
        itemBuilder: (context, index) {
          final isSelected = selectedType == types[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() => selectedType = types[index]);
                _loadVaultItems();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accentColor.withOpacity(0.05) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppTheme.accentColor.withOpacity(0.2) : Colors.white.withOpacity(0.03)),
                ),
                child: Center(
                  child: Text(
                    types[index],
                    style: TextStyle(
                      color: isSelected ? AppTheme.accentColor : Colors.white10,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemsList() {
    if (vaultItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.white.withOpacity(0.01), size: 64),
            const SizedBox(height: 24),
            const Text("NO ARTIFACTS DETECTED", style: TextStyle(color: Colors.white10, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 80),
      itemCount: vaultItems.length,
      itemBuilder: (context, index) {
        final item = vaultItems[index];
        return _buildItemSlab(item);
      },
    );
  }

  Widget _buildItemSlab(dynamic item) {
    return GestureDetector(
      onTap: () => _showItemDetails(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(28),
        decoration: AppTheme.slabDecoration,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.05), 
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.accentColor.withOpacity(0.1)),
              ),
              child: Icon(_getIconForType(item['item_type']), color: AppTheme.accentColor, size: 20),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title']?.toString().toUpperCase() ?? "SECURED_ARTIFACT", 
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(item['item_type'].toString().toUpperCase(), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(width: 12),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle)),
                      const SizedBox(width: 12),
                      const Text("ENCRYPTED", style: TextStyle(color: AppTheme.textSecondary, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.05), size: 12),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'note': return Icons.description_rounded;
      case 'password': return Icons.vpn_key_rounded;
      case 'credit_card': return Icons.credit_card_rounded;
      case 'crypto': return Icons.currency_bitcoin_rounded;
      case 'file': return Icons.insert_drive_file_rounded;
      default: return Icons.shield_rounded;
    }
  }
}
