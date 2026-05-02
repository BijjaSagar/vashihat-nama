import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:ui';

class PremiumDetailSheet extends StatelessWidget {
  final Map<String, dynamic> item;
  final Widget content;
  final VoidCallback onAssignNominee;
  final VoidCallback onDelete;

  const PremiumDetailSheet({
    super.key,
    required this.item,
    required this.content,
    required this.onAssignNominee,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pull Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 16, 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getTypeIcon(item['item_type']),
                    color: AppTheme.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'].toString().toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getTypeLabel(item['item_type']).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 8,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white24),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Colors.white10),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.slabDecoration,
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        textTheme: Theme.of(context).textTheme.apply(bodyColor: Colors.white70),
                      ),
                      child: content,
                    ),
                  ),
                  
                  if (item['nominees'] != null && (item['nominees'] as List).isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildSectionHeader("AUTHORIZED NODES"),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: (item['nominees'] as List).map((n) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.accentColor.withOpacity(0.1)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.verified_user_rounded, size: 12, color: AppTheme.accentColor),
                                const SizedBox(width: 8),
                                Text(
                                  n['name'].toString().toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.accentColor,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Bottom Actions
          Padding(
            padding: EdgeInsets.fromLTRB(32, 0, 32, MediaQuery.of(context).padding.bottom + 32),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 64,
                    child: ElevatedButton(
                      onPressed: onAssignNominee,
                      child: const Text("ASSIGN NODE"),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 64,
                    child: OutlinedButton(
                      onPressed: onDelete,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: AppTheme.textSecondary,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'note': return Icons.description_rounded;
      case 'password': return Icons.password_rounded;
      case 'credit_card': return Icons.credit_card_rounded;
      case 'file': return Icons.attach_file_rounded;
      default: return Icons.shield_rounded;
    }
  }

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'note': return 'SECURE ARTIFACT';
      case 'password': return 'AUTH CREDENTIAL';
      case 'credit_card': return 'FINANCIAL INSTRUMENT';
      case 'file': return 'ENCRYPTED DATA';
      default: return 'VAULT ITEM';
    }
  }
}
