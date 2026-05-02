import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class AssetDiscoveryScreen extends StatefulWidget {
  final int userId;
  const AssetDiscoveryScreen({super.key, required this.userId});

  @override
  _AssetDiscoveryScreenState createState() => _AssetDiscoveryScreenState();
}

class _AssetDiscoveryScreenState extends State<AssetDiscoveryScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _items = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  
  final TextEditingController _countryController = TextEditingController(text: "INDIA");
  final TextEditingController _occupationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final itemsData = await _apiService.getAssetDiscoveryItems(widget.userId);
      if (mounted) {
        setState(() {
          _items = itemsData['items'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateChecklist() async {
    if (mounted) setState(() => _isGenerating = true);
    try {
      await _apiService.generateAssetDiscoveryAI(
        userId: widget.userId, 
        country: _countryController.text, 
        occupation: _occupationController.text
      );
      await _fetchItems();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI GENERATION FAILED")));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _toggleItem(int itemId) async {
    try {
      await _apiService.toggleAssetDiscovery(widget.userId, itemId);
      setState(() {
        final index = _items.indexWhere((i) => i['id'] == itemId);
        if (index != -1) {
          _items[index]['is_completed'] = !(_items[index]['is_completed'] ?? false);
        }
      });
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    int completed = _items.where((i) => i['is_completed'] == true).length;
    double progress = _items.isEmpty ? 0 : completed / _items.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("ASSET INTELLIGENCE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildGenerateSlab(),
            const SizedBox(height: 32),
            if (_items.isNotEmpty) _buildProgressSlab(completed, _items.length, progress),
            const SizedBox(height: 32),
            _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
                : _buildAssetList(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateSlab() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.slabDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CHECKLIST GENERATOR", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 24),
          _buildSlabInput("JURISDICTION", _countryController, Icons.public_rounded),
          const SizedBox(height: 24),
          _buildSlabInput("OCCUPATION", _occupationController, Icons.work_outline_rounded, hint: "DOCTOR, MERCHANT, ETC."),
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateChecklist,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.black,
              ),
              child: _isGenerating 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 16),
                        SizedBox(width: 12),
                        Text("INITIATE AI SCAN", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlabInput(String label, TextEditingController ctrl, IconData icon, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.w900),
              prefixIcon: Icon(icon, color: AppTheme.accentColor.withOpacity(0.4), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSlab(int completed, int total, double progress) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.slabDecoration,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("INTELLIGENCE COVERAGE", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
              Text("${(progress * 100).toInt()}%", style: const TextStyle(color: AppTheme.accentColor, fontSize: 12, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.02),
              color: AppTheme.accentColor,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 12),
          Text("$completed / $total ASSETS INDEXED", style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildAssetList() {
    if (_items.isEmpty) return const SizedBox();

    Map<String, List<dynamic>> grouped = {};
    for (var item in _items) {
      String cat = item['category'] ?? "GENERAL";
      grouped.putIfAbsent(cat.toUpperCase(), () => []).add(item);
    }

    return Column(
      children: grouped.entries.map((entry) => _buildCategoryGroup(entry.key, entry.value)).toList(),
    );
  }

  Widget _buildCategoryGroup(String category, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16, top: 32),
          child: Text(category, style: const TextStyle(color: AppTheme.accentColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ),
        ...items.map((item) => _buildAssetItem(item)).toList(),
      ],
    );
  }

  Widget _buildAssetItem(dynamic item) {
    bool isDone = item['is_completed'] == true;
    return GestureDetector(
      onTap: () => _toggleItem(item['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.slabDecoration.copyWith(
          border: Border.all(color: isDone ? Colors.greenAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(
              isDone ? Icons.verified_rounded : Icons.radio_button_off_rounded,
              color: isDone ? Colors.greenAccent : Colors.white12,
              size: 20,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                item['asset_name'].toString().toUpperCase(),
                style: TextStyle(
                  color: isDone ? Colors.white24 : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (item['priority'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(item['priority']).withOpacity(0.05),
                  border: Border.all(color: _getPriorityColor(item['priority']).withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['priority'].toString().toUpperCase(),
                  style: TextStyle(color: _getPriorityColor(item['priority']), fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return Colors.redAccent;
      case 'medium': return Colors.amberAccent;
      default: return AppTheme.accentColor;
    }
  }
}
