import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/glassmorphism.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'add_vault_item_screen.dart';
import 'dart:convert';

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
  String filterType = 'all'; // 'all', 'note', 'password', 'credit_card', 'file'

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
    
    // TODO: Decrypt data here
    // For now, parse JSON directly
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
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item['title'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildItemContent(itemType, data),
              ),
            ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(item['id']);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('Delete', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        _buildDetailRow('Card Number', data['card_number'] ?? '', Icons.credit_card, isPassword: true),
        _buildDetailRow('Cardholder', data['cardholder_name'] ?? '', Icons.person),
        _buildDetailRow('Expiry', '${data['expiry_month']}/${data['expiry_year']}', Icons.calendar_today),
        _buildDetailRow('CVV', data['cvv'] ?? '', Icons.security, isPassword: true),
        if (data['notes'] != null && data['notes'].isNotEmpty)
          _buildDetailRow('Notes', data['notes'], Icons.note),
      ],
    );
  }

  Widget _buildFileContent(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('File Name', data['file_name'] ?? '', Icons.file_present),
        _buildDetailRow('Size', '${data['file_size'] ?? 0} bytes', Icons.storage),
        _buildDetailRow('Type', data['mime_type'] ?? '', Icons.category),
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
      floatingActionButton: FloatingActionButton.extended(
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
    );
  }

  Widget _buildFilterChip(String label, String type, IconData icon) {
    final isSelected = filterType == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : AppTheme.primaryColor),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            filterType = type;
            _loadVaultItems();
          });
        },
        selectedColor: AppTheme.primaryColor,
        labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary),
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
      case 'file':
        icon = Icons.file_present;
        color = Colors.green;
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
    }

    return GestureDetector(
      onTap: () => _showItemDetails(item),
      child: GlassCard(
        opacity: 0.7,
        color: Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getItemTypeLabel(itemType),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
          ],
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
      case 'file':
        return 'File';
      default:
        return 'Unknown';
    }
  }
}
