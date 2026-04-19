import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../theme/glassmorphism.dart';
import 'dart:ui';

class PremiumDetailSheet extends StatelessWidget {
  final Map<String, dynamic> item;
  final Widget content;
  final VoidCallback onAssignNominee;
  final VoidCallback onDelete;

  const PremiumDetailSheet({
    Key? key,
    required this.item,
    required this.content,
    required this.onAssignNominee,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400]?.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              
              // Header with Glass Effect
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 16, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getTypeColor(item['item_type']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getTypeIcon(item['item_type']),
                        color: _getTypeColor(item['item_type']),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'],
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            _getTypeLabel(item['item_type']),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 20, color: Colors.grey),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      GlassCard(
                        opacity: 0.5,
                        color: Colors.white,
                        padding: const EdgeInsets.all(20),
                        child: content,
                      ),
                      
                      if (item['nominees'] != null && (item['nominees'] as List).isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader("Assigned Nominees"),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (item['nominees'] as List).map((n) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.person_pin, size: 14, color: AppTheme.primaryColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      n['name'],
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
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
                padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 20),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: onAssignNominee,
                        icon: const Icon(Icons.person_add_rounded, size: 20),
                        label: const Text('Assign Nominee'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        onPressed: onDelete,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade300),
                          foregroundColor: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Icon(Icons.delete_outline_rounded),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary.withOpacity(0.6),
          letterSpacing: 1.2,
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
      default: return Icons.help_outline_rounded;
    }
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'note': return Colors.blue;
      case 'password': return Colors.purple;
      case 'credit_card': return Colors.orange;
      case 'file': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'note': return 'Secure Document';
      case 'password': return 'Sensitive Password';
      case 'credit_card': return 'Payment Card';
      case 'file': return 'Personal File';
      default: return 'Vault Item';
    }
  }
}
