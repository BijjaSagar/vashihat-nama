import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class RegionalChecklistScreen extends StatefulWidget {
  final int userId;
  const RegionalChecklistScreen({super.key, required this.userId});

  @override
  _RegionalChecklistScreenState createState() => _RegionalChecklistScreenState();
}

class _RegionalChecklistScreenState extends State<RegionalChecklistScreen> {
  String selectedCountry = "IN";
  List<dynamic> checklists = [];
  List<dynamic> userDocs = [];
  bool isLoading = true;
  bool isAiGenerating = false;

  final Map<String, String> countries = {
    "IN": "India", "US": "United States", "GB": "United Kingdom", "AE": "United Arab Emirates", 
    "SG": "Singapore", "AU": "Australia", "CA": "Canada", "DE": "Germany", "FR": "France", "JP": "Japan",
    "OTHER": "Other Region..."
  };

  final TextEditingController _customCountryController = TextEditingController();
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => isLoading = true);
    try {
      final docs = await ApiService().getUserRegionalDocs(widget.userId);
      final list = await ApiService().getRegionalChecklists(selectedCountry);
      if (mounted) {
        setState(() {
          userDocs = docs;
          checklists = list;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _generateWithAI() async {
    if (mounted) setState(() => isAiGenerating = true);
    try {
      String countryName = _showCustomInput ? _customCountryController.text : (countries[selectedCountry] ?? selectedCountry);
      await ApiService().generateRegionalChecklistAI(selectedCountry, countryName);
      await _loadData();
      if (mounted) {
        setState(() => isAiGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("SYNTHESIS COMPLETE. REGIONAL PROTOCOLS UPDATED."),
          backgroundColor: AppTheme.accentColor,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => isAiGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("SYNTHESIS FAILURE: $e"), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _toggleDocument(int checklistId, bool isSelected) async {
    if (isSelected) return;
    try {
      await ApiService().saveRegionalDoc(
        userId: widget.userId,
        checklistId: checklistId,
        details: {'selected_at': DateTime.now().toIso8601String()},
      );
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("SYNC ERROR: $e"), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.accentColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text("REGIONAL COMPLIANCE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: AppTheme.accentColor,
            indicatorWeight: 3,
            labelColor: AppTheme.accentColor,
            unselectedLabelColor: Colors.white10,
            labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
            tabs: const [
              Tab(text: "EXPLORE"),
              Tab(text: "VAULT CHECKLIST"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildExploreTab(),
            _buildMyChecklistTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("GEOGRAPHIC TARGET", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 20),
          _buildCountryPicker(),
          if (_showCustomInput) ...[
            const SizedBox(height: 16),
            _buildCustomInput(),
          ],
          const SizedBox(height: 48),
          _buildAiActionSlab(),
          const SizedBox(height: 56),
          const Text("REGIONAL PROTOCOLS", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 24),
          isLoading 
            ? const Center(child: Padding(padding: EdgeInsets.all(80), child: CircularProgressIndicator(color: AppTheme.accentColor)))
            : checklists.isEmpty 
              ? const Center(child: Padding(padding: EdgeInsets.all(80), child: Text("NO REGIONAL DATA FOUND", style: TextStyle(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))))
              : Column(
                  children: checklists.map((item) {
                    final isSelected = userDocs.any((d) => d['checklist_id'] == item['id']);
                    return _buildChecklistItem(item, isSelected);
                  }).toList(),
                ),
          const SizedBox(height: 64),
        ],
      ),
    );
  }

  Widget _buildCountryPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      decoration: AppTheme.slabDecoration,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCountry,
          dropdownColor: AppTheme.slabColor,
          icon: const Icon(Icons.expand_more_rounded, color: AppTheme.accentColor),
          isExpanded: true,
          items: countries.entries.map((e) {
            return DropdownMenuItem(
              value: e.key,
              child: Text(e.value.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                selectedCountry = val;
                _showCustomInput = (val == "OTHER");
              });
              if (!_showCustomInput) _loadData();
            }
          },
        ),
      ),
    );
  }

  Widget _buildCustomInput() {
    return Container(
      decoration: AppTheme.slabDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: TextField(
        controller: _customCountryController,
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
        decoration: const InputDecoration(
          hintText: "ENTER CUSTOM JURISDICTION...",
          hintStyle: TextStyle(color: Colors.white10, fontSize: 12, fontWeight: FontWeight.w900),
          border: InputBorder.none,
          icon: Icon(Icons.public_rounded, color: AppTheme.accentColor, size: 18),
        ),
      ),
    );
  }

  Widget _buildAiActionSlab() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.slabDecoration.copyWith(
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentColor, size: 16),
              const SizedBox(width: 12),
              const Text("INTELLIGENCE SYNTHESIS", style: TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            "GENERATE A CUSTOM COMPLIANCE FRAMEWORK FOR THIS SPECIFIC REGION USING SENTINEL AI ENGINE.", 
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, height: 1.6)
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 64,
            child: ElevatedButton(
              onPressed: isAiGenerating ? null : _generateWithAI,
              child: isAiGenerating 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : const Text("SYNTHESIZE PROTOCOL"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(dynamic item, bool isSelected) {
    bool isMandatory = item['is_mandatory'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.slabDecoration.copyWith(
        border: Border.all(color: isMandatory ? Colors.orangeAccent.withOpacity(0.05) : Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMandatory ? Colors.orangeAccent.withOpacity(0.05) : AppTheme.accentColor.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMandatory ? Icons.priority_high_rounded : Icons.description_outlined,
              color: isMandatory ? Colors.orangeAccent : AppTheme.accentColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['document_name'].toString().toUpperCase(), 
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)
                ),
                const SizedBox(height: 4),
                Text(
                  item['description']?.toString().toUpperCase() ?? "MANDATORY REGIONAL PROTOCOL", 
                  style: const TextStyle(color: Colors.white10, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)
                ),
              ],
            ),
          ),
          Checkbox(
            value: isSelected,
            activeColor: AppTheme.accentColor,
            checkColor: Colors.black,
            side: BorderSide(color: Colors.white.withOpacity(0.05), width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (val) => _toggleDocument(item['id'], isSelected),
          ),
        ],
      ),
    );
  }

  Widget _buildMyChecklistTab() {
    final myChecklistItems = checklists.where((item) => userDocs.any((d) => d['checklist_id'] == item['id'])).toList();
    
    return isLoading 
      ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
      : myChecklistItems.isEmpty
        ? Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, color: Colors.white.withOpacity(0.01), size: 64),
              const SizedBox(height: 24),
              const Text("VAULT EMPTY", style: TextStyle(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ],
          ))
        : ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            itemCount: myChecklistItems.length,
            itemBuilder: (context, index) {
              final item = myChecklistItems[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(32),
                decoration: AppTheme.slabDecoration,
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: AppTheme.accentColor, size: 24),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['document_name'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          const Text("SECURED IN VAULT", style: TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
  }
}
