import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AssetDiscoveryScreen extends StatefulWidget {
  final int userId;
  const AssetDiscoveryScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<AssetDiscoveryScreen> createState() => _AssetDiscoveryScreenState();
}

class _AssetDiscoveryScreenState extends State<AssetDiscoveryScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _assets = [];
  bool _loading = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    try {
      final result = await _api.getAssetDiscovery(widget.userId);
      setState(() { _assets = result['assets'] ?? []; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _generateChecklist() async {
    setState(() => _generating = true);
    try {
      final result = await _api.generateAssetDiscovery(userId: widget.userId, country: 'India');
      setState(() {
        _assets = result['assets'] ?? [];
        _generating = false;
      });
      _loadAssets(); // Refresh from DB
    } catch (e) {
      setState(() => _generating = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate checklist')));
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'financial': return const Color(0xFF4CAF50);
      case 'property': return const Color(0xFF2196F3);
      case 'insurance': return const Color(0xFFFF9800);
      case 'digital': return const Color(0xFF9C27B0);
      case 'personal': return const Color(0xFFE91E63);
      case 'legal': return const Color(0xFF795548);
      default: return const Color(0xFF607D8B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'financial': return Icons.account_balance;
      case 'property': return Icons.home;
      case 'insurance': return Icons.health_and_safety;
      case 'digital': return Icons.computer;
      case 'personal': return Icons.person;
      case 'legal': return Icons.gavel;
      default: return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String>{};
    for (var a in _assets) { categories.add(a['category'] ?? 'Other'); }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Smart Asset Discovery', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assets.isEmpty
              ? _buildEmptyState()
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildProgressCard(),
                    const SizedBox(height: 20),
                    ...categories.map((cat) => _buildCategorySection(cat)).toList(),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 20),
        const Text('Discover Your Assets', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('AI will analyze your profile and suggest\nassets you should add to your vault.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 15)),
        const SizedBox(height: 30),
        SizedBox(width: double.infinity, height: 54,
          child: ElevatedButton.icon(
            onPressed: _generating ? null : _generateChecklist,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00695C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            icon: _generating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome, color: Colors.white),
            label: Text(_generating ? 'AI is thinking...' : '🧠 Generate My Checklist', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    ));
  }

  Widget _buildProgressCard() {
    final total = _assets.length;
    final added = _assets.where((a) => a['is_added'] == true).length;
    final progress = total > 0 ? added / total : 0.0;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00695C), Color(0xFF00897B)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Your Progress', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          Text('$added/$total', style: const TextStyle(color: Colors.white70, fontSize: 16)),
        ]),
        const SizedBox(height: 14),
        ClipRRect(borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Colors.white))),
        const SizedBox(height: 12),
        Text('${(progress * 100).toInt()}% of recommended assets added', style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _generating ? null : _generateChecklist,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
          label: const Text('Refresh Suggestions', style: TextStyle(color: Colors.white)),
        ),
      ]),
    );
  }

  Widget _buildCategorySection(String category) {
    final items = _assets.where((a) => a['category'] == category).toList();
    final color = _getCategoryColor(category);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Icon(_getCategoryIcon(category), color: color, size: 22),
          const SizedBox(width: 8),
          Text(category, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Text('${items.length}', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12))),
        ]),
      ),
      ...items.map((asset) {
        final isAdded = asset['is_added'] == true;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isAdded ? color.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: isAdded ? Border.all(color: color.withOpacity(0.3)) : null,
            boxShadow: [if (!isAdded) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          child: ListTile(
            onTap: () async {
              await _api.toggleAssetDiscovery(asset['id']);
              _loadAssets();
            },
            leading: Icon(isAdded ? Icons.check_circle : Icons.circle_outlined, color: isAdded ? color : Colors.grey),
            title: Text(asset['asset_name'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, decoration: isAdded ? TextDecoration.lineThrough : null)),
            subtitle: Text(asset['ai_suggestion'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: asset['priority'] == 'high' ? Colors.red.withOpacity(0.1) : asset['priority'] == 'medium' ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text((asset['priority'] ?? '').toString().toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                color: asset['priority'] == 'high' ? Colors.red : asset['priority'] == 'medium' ? Colors.orange : Colors.blue)),
            ),
          ),
        );
      }).toList(),
    ]);
  }
}
