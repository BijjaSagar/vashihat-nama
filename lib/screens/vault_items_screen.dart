import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../theme/glassmorphism.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/credit_card_widget.dart';
import '../widgets/premium_detail_sheet.dart';
import '../widgets/crypto_wallet_widget.dart';
import 'add_vault_item_screen.dart';
import 'smart_scan_screen.dart';

class VaultItemsScreen extends StatefulWidget {
  final int userId;
  final int folderId;
  final String folderName;

  const VaultItemsScreen({
    Key? key,
    required this.userId,
    required this.folderId,
    required this.folderName,
  }) : super(key: key);

  @override
  _VaultItemsScreenState createState() => _VaultItemsScreenState();
}

class _VaultItemsScreenState extends State<VaultItemsScreen> {
  List<dynamic> vaultItems = [];
  bool isLoading = true;
  String filterType = 'all'; // 'all', 'note', 'password', 'credit_card', 'crypto', 'file'

  @override
  void initState() {
    super.initState();
    _loadVaultItems();
  }

  Future<void> _loadVaultItems() async {
    setState(() => isLoading = true);
    try {
      final items = await ApiService().getVaultItems(
        userId: widget.userId,
        folderId: widget.folderId,
        itemType: filterType == 'all' ? null : filterType,
      );
      if (mounted) {
        setState(() {
          vaultItems = items;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading vault items: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _assignNominee(int itemId) async {
    try {
      final nominees = await ApiService().getNominees(widget.userId.toString());
      if (!mounted) return;

      if (nominees.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No nominees found. Please add a nominee first.')),
        );
        return;
      }

      int? selectedNomineeId;
      final result = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Assign to Nominee'),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select a nominee who will receive this document:'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedNomineeId,
                    decoration: const InputDecoration(labelText: "Select Nominee"),
                    items: nominees.map<DropdownMenuItem<int>>((n) {
                      return DropdownMenuItem<int>(
                        value: n['id'],
                        child: Text(n['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedNomineeId = val);
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedNomineeId),
              child: const Text('Assign'),
            ),
          ],
        ),
      );

      if (result != null) {
        await ApiService().assignNomineeToVaultItem(
          itemId: itemId,
          userId: widget.userId,
          nomineeId: result,
        );
        _loadVaultItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Document assigned successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteItem(int itemId) async {
    try {
      await ApiService().deleteVaultItem(itemId: itemId, userId: widget.userId);
      _loadVaultItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showItemDetails(Map<String, dynamic> item) {
    final itemType = item['item_type'];
    final encryptedData = item['encrypted_data'];
    
    // Decrypt data logic here
    Map<String, dynamic> data = {};
    try {
      data = jsonDecode(encryptedData);
    } catch (e) {
      data = {'error': 'Failed to decrypt'};
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PremiumDetailSheet(
        item: item,
        content: _buildItemContent(itemType, data),
        onAssignNominee: () {
          Navigator.pop(context);
          _assignNominee(item['id']);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(item['id']);
        },
      ),
    );
  }

  Widget _buildItemContent(String itemType, Map<String, dynamic> data) {
    switch (itemType) {
      case 'note':
        return _buildNoteContent(data);
      case 'password':
        return _buildPasswordContent(data);
      case 'credit_card':
        return _buildCreditCardContent(data);
      case 'crypto':
        return _buildCryptoContent(data);
      case 'file':
        return _buildFileContent(data);
      default:
        return const Text('Unknown item type');
    }
  }

  Widget _buildNoteContent(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Content:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(data['content'] ?? ''),
      ],
    );
  }

  Widget _buildPasswordContent(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Username', data['username'] ?? '', Icons.person),
        _buildDetailRow('Password', data['password'] ?? '', Icons.lock, isPassword: true),
        _buildDetailRow('URL', data['url'] ?? '', Icons.link),
        if (data['notes'] != null && data['notes'].isNotEmpty)
          _buildDetailRow('Notes', data['notes'], Icons.note),
      ],
    );
  }

  Widget _buildCreditCardContent(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CreditCardWidget(
          cardNumber: data['number'] ?? data['card_number'] ?? '',
          cardHolder: data['holder'] ?? data['cardholder_name'] ?? '',
          expiryDate: data['expiry'] ?? '${data['expiry_month']}/${data['expiry_year']}',
        ),
        const SizedBox(height: 24),
        _buildDetailRow('Card Number', data['number'] ?? data['card_number'] ?? '', Icons.credit_card, isPassword: true),
        _buildDetailRow('Cardholder', data['holder'] ?? data['cardholder_name'] ?? '', Icons.person),
        _buildDetailRow('Expiry', data['expiry'] ?? '${data['expiry_month']}/${data['expiry_year']}', Icons.calendar_today),
        _buildDetailRow('CVV', data['cvv'] ?? '', Icons.security, isPassword: true),
        if (data['notes'] != null && data['notes'].isNotEmpty)
          _buildDetailRow('Notes', data['notes'], Icons.note),
      ],
    );
  }

  Widget _buildCryptoContent(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Coin/Token', data['coin'] ?? '', Icons.currency_bitcoin),
        _buildDetailRow('Network', data['network'] ?? '', Icons.lan),
        _buildDetailRow('Wallet Address', data['wallet_address'] ?? '', Icons.account_balance_wallet),
        _buildDetailRow('Seed Phrase / Private Key', data['seed_phrase'] ?? '', Icons.key, isPassword: true),
        if (data['notes'] != null && data['notes'].isNotEmpty)
          _buildDetailRow('Notes', data['notes'], Icons.note),
      ],
    );
  }

  Widget _buildFileContent(Map<String, dynamic> data) {
    String? base64Content = data['file_content'];
    String fileName = data['file_name'] ?? 'Unknown File';
    
    // Check if it's an image
    bool isImage = fileName.toLowerCase().endsWith('.jpg') || 
                   fileName.toLowerCase().endsWith('.jpeg') || 
                   fileName.toLowerCase().endsWith('.png');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('File Name', fileName, Icons.file_present),
        _buildDetailRow('Size', '${data['file_size'] ?? 0} bytes', Icons.storage),
        
        const SizedBox(height: 16),
        if (base64Content != null && isImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              base64Decode(base64Content),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Text("Error loading image"),
            ),
          )
        else if (base64Content != null)
           ElevatedButton.icon(
             onPressed: () {
               // TODO: Save to file and open (requires open_file package)
               // For now, copy base64 to clipboard as fallback
               Clipboard.setData(ClipboardData(text: base64Content));
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('File content copied to clipboard (Base64)')),
               );
             },
             icon: const Icon(Icons.download),
             label: const Text("Copy File Content"),
             style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
           ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  isPassword ? '••••••••' : value,
                  style: const TextStyle(fontSize: 16, color: AppTheme.textPrimary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$label copied')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(itemId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.folderName,
          style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
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
            colors: [Color(0xFFF2F2F7), Color(0xFFE5E5EA), Color(0xFFF2F2F7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all', Icons.all_inclusive),
                    _buildFilterChip('Notes', 'note', Icons.note_alt),
                    _buildFilterChip('Passwords', 'password', Icons.lock),
                    _buildFilterChip('Cards', 'credit_card', Icons.credit_card),
                    _buildFilterChip('Crypto', 'crypto', Icons.currency_bitcoin),
                    _buildFilterChip('Files', 'file', Icons.file_present),
                  ],
                ),
              ),

              // Items list
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
                    : vaultItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.folder_open, size: 80, color: AppTheme.textSecondary.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  'No items yet',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: vaultItems.length,
                            itemBuilder: (context, index) {
                              final item = vaultItems[index];
                              return _buildVaultItemCard(item);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "scan",
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SmartScanScreen(userId: widget.userId)),
              );
            },
            icon: const Icon(Icons.document_scanner),
            label: const Text('Smart Scan'),
            backgroundColor: Colors.indigo,
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: "add",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddVaultItemScreen(
                    userId: widget.userId,
                    folderId: widget.folderId,
                    folderName: widget.folderName,
                  ),
                ),
              );
              if (result == true) {
                _loadVaultItems();
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
            backgroundColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String type, IconData icon) {
    final isSelected = filterType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          filterType = type;
          _loadVaultItems();
        });
      },
      child: GlassCard(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        borderRadius: BorderRadius.circular(24),
        color: isSelected ? AppTheme.primaryColor : Colors.white,
        opacity: isSelected ? 0.9 : 0.6,
        blur: 10,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultItemCard(Map<String, dynamic> item) {
    final itemType = item['item_type'];
    IconData icon;
    Color color;

    switch (itemType) {
      case 'note':
        icon = Icons.note_alt;
        color = Colors.blue;
        break;
      case 'password':
        icon = Icons.lock;
        color = Colors.purple;
        break;
      case 'credit_card':
        icon = Icons.credit_card;
        color = Colors.orange;
        break;
      case 'crypto':
        icon = Icons.currency_bitcoin;
        color = Colors.amber;
        break;
      case 'file':
        icon = Icons.file_present;
        color = Colors.green;
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
    }

    if (itemType == 'credit_card') {
      return GestureDetector(
        onTap: () => _showItemDetails(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Stack(
            children: [
              CreditCardWidget(
                cardNumber: "XXXX XXXX XXXX " + (item['title'].split(' ').last),
                cardHolder: "TOUCH TO VIEW",
                expiryDate: "XX/XX",
                baseColor: Colors.indigo.shade900,
              ),
              // Overlay to make it feel like a list item
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.2), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (itemType == 'crypto') {
      return GestureDetector(
        onTap: () => _showItemDetails(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Stack(
            children: [
              CryptoWalletWidget(
                coinName: item['title'].split(' ').first,
                network: "SECURE",
                walletAddress: "••••••••••••••••••••",
                baseColor: Colors.orange.shade700,
              ),
              // Overlay to make it feel like a list item
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.2), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showItemDetails(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: GlassCard(
          opacity: 0.8,
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getItemTypeLabel(itemType),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item['nominees'] != null && (item['nominees'] as List).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: (item['nominees'] as List).map<Widget>((n) {
                          final int nomineeId = n['id'] is int ? n['id'] : int.tryParse(n['id'].toString()) ?? 0;
                          final String nomineeName = n['name'] ?? '';
                          return GestureDetector(
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: const Text('Remove Nominee?', style: TextStyle(fontWeight: FontWeight.bold)),
                                  content: Text('Remove "$nomineeName" from "${item['title']}"?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                      child: const Text('Remove', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                try {
                                  await ApiService().unassignNomineeFromVaultItem(
                                    itemId: item['id'],
                                    userId: widget.userId,
                                    nomineeId: nomineeId,
                                  );
                                  _loadVaultItems();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('$nomineeName removed'),
                                        backgroundColor: Colors.green[700],
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Failed to remove nominee'), backgroundColor: Colors.redAccent),
                                    );
                                  }
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_pin_rounded, size: 12, color: AppTheme.primaryColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    nomineeName,
                                    style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.close, size: 11, color: AppTheme.primaryColor.withOpacity(0.7)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  String _getItemTypeLabel(String type) {
    switch (type) {
      case 'note':
        return 'Secure Note';
      case 'password':
        return 'Password';
      case 'credit_card':
        return 'Credit Card';
      case 'crypto':
        return 'Crypto Wallet';
      case 'file':
        return 'File';
      default:
        return 'Unknown';
    }
  }
}
