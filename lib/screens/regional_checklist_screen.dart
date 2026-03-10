import 'package:flutter/material.dart';
import '../theme/glassmorphism.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class RegionalChecklistScreen extends StatefulWidget {
  final int userId;
  const RegionalChecklistScreen({Key? key, required this.userId}) : super(key: key);

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
    "AF": "Afghanistan", "AL": "Albania", "DZ": "Algeria", "AD": "Andorra", "AO": "Angola", "AG": "Antigua and Barbuda",
    "AR": "Argentina", "AM": "Armenia", "AU": "Australia", "AT": "Austria", "AZ": "Azerbaijan", "BS": "Bahamas",
    "BH": "Bahrain", "BD": "Bangladesh", "BB": "Barbados", "BY": "Belarus", "BE": "Belgium", "BZ": "Belize",
    "BJ": "Benin", "BT": "Bhutan", "BO": "Bolivia", "BA": "Bosnia and Herzegovina", "BW": "Botswana", "BR": "Brazil",
    "BN": "Brunei", "BG": "Bulgaria", "BF": "Burkina Faso", "BI": "Burundi", "KH": "Cambodia", "CM": "Cameroon",
    "CA": "Canada", "CV": "Cape Verde", "CF": "Central African Republic", "TD": "Chad", "CL": "Chile", "CN": "China",
    "CO": "Colombia", "KM": "Comoros", "CG": "Congo", "CR": "Costa Rica", "HR": "Croatia", "CU": "Cuba", "CY": "Cyprus",
    "CZ": "Czech Republic", "DK": "Denmark", "DJ": "Djibouti", "DM": "Dominica", "DO": "Dominican Republic", "EC": "Ecuador",
    "EG": "Egypt", "SV": "El Salvador", "GQ": "Equatorial Guinea", "ER": "Eritrea", "EE": "Estonia", "ET": "Ethiopia",
    "FJ": "Fiji", "FI": "Finland", "FR": "France", "GA": "Gabon", "GM": "Gambia", "GE": "Georgia", "DE": "Germany",
    "GH": "Ghana", "GR": "Greece", "GD": "Grenada", "GT": "Guatemala", "GN": "Guinea", "GW": "Guinea-Bissau", "GY": "Guyana",
    "HT": "Haiti", "HN": "Honduras", "HU": "Hungary", "IS": "Iceland", "IN": "India", "ID": "Indonesia", "IR": "Iran",
    "IQ": "Iraq", "IE": "Ireland", "IL": "Israel", "IT": "Italy", "JM": "Jamaica", "JP": "Japan", "JO": "Jordan",
    "KZ": "Kazakhstan", "KE": "Kenya", "KI": "Kiribati", "KP": "Korea, North", "KR": "Korea, South", "KW": "Kuwait",
    "KG": "Kyrgyzstan", "LA": "Laos", "LV": "Latvia", "LB": "Lebanon", "LS": "Lesotho", "LR": "Liberia", "LY": "Libya",
    "LI": "Liechtenstein", "LT": "Lithuania", "LU": "Luxembourg", "MK": "Macedonia", "MG": "Madagascar", "MW": "Malawi",
    "MY": "Malaysia", "MV": "Maldives", "ML": "Mali", "MT": "Malta", "MH": "Marshall Islands", "MR": "Mauritania",
    "MU": "Mauritius", "MX": "Mexico", "FM": "Micronesia", "MD": "Moldova", "MC": "Monaco", "MN": "Mongolia", "ME": "Montenegro",
    "MA": "Morocco", "MZ": "Mozambique", "MM": "Myanmar", "NA": "Namibia", "NR": "Nauru", "NP": "Nepal", "NL": "Netherlands",
    "NZ": "New Zealand", "NI": "Nicaragua", "NE": "Niger", "NG": "Nigeria", "NO": "Norway", "OM": "Oman", "PK": "Pakistan",
    "PW": "Palau", "PA": "Panama", "PG": "Papua New Guinea", "PY": "Paraguay", "PE": "Peru", "PH": "Philippines",
    "PL": "Poland", "PT": "Portugal", "QA": "Qatar", "RO": "Romania", "RU": "Russian Federation", "RW": "Rwanda",
    "KN": "Saint Kitts and Nevis", "LC": "Saint Lucia", "VC": "Saint Vincent and the Grenadines", "WS": "Samoa",
    "SM": "San Marino", "ST": "Sao Tome and Principe", "SA": "Saudi Arabia", "SN": "Senegal", "RS": "Serbia",
    "SC": "Seychelles", "SL": "Sierra Leone", "SG": "Singapore", "SK": "Slovakia", "SI": "Slovenia", "SB": "Solomon Islands",
    "SO": "Somalia", "ZA": "South Africa", "SS": "South Sudan", "ES": "Spain", "LK": "Sri Lanka", "SD": "Sudan",
    "SR": "Suriname", "SZ": "Swaziland", "SE": "Sweden", "CH": "Switzerland", "SY": "Syrian Arab Republic", "TW": "Taiwan",
    "TJ": "Tajikistan", "TZ": "Tanzania", "TH": "Thailand", "TL": "Timor-Leste", "TG": "Togo", "TO": "Tonga",
    "TT": "Trinidad and Tobago", "TN": "Tunisia", "TR": "Turkey", "TM": "Turkmenistan", "TV": "Tuvalu", "UG": "Uganda",
    "UA": "Ukraine", "AE": "United Arab Emirates", "GB": "United Kingdom", "US": "United States", "UY": "Uruguay",
    "UZ": "Uzbekistan", "VU": "Vanuatu", "VA": "Vatican City", "VE": "Venezuela", "VN": "Vietnam", "YE": "Yemen",
    "ZM": "Zambia", "ZW": "Zimbabwe",
    "OTHER": "Other (Enter Manually...)",
  };

  final TextEditingController _customCountryController = TextEditingController();
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
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
    setState(() => isAiGenerating = true);
    try {
      String countryName = _showCustomInput ? _customCountryController.text : (countries[selectedCountry] ?? selectedCountry);
      if (countryName.isEmpty) {
        throw Exception("Please enter a country name");
      }
      await ApiService().generateRegionalChecklistAI(selectedCountry, countryName);
      await _loadData();
      if (mounted) {
        setState(() => isAiGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("AI Checklist Generated & Saved!")));
      }
    } catch (e) {
      if (mounted) {
        setState(() => isAiGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("AI Error: $e")));
      }
    }
  }

  Future<void> _toggleDocument(int checklistId, bool isSelected) async {
    if (isSelected) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Document already selected")));
       return;
    }

    try {
      await ApiService().saveRegionalDoc(
        userId: widget.userId,
        checklistId: checklistId,
        details: {'selected_at': DateTime.now().toIso8601String()},
      );
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Added to your vault checklist")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter selected docs for 'My Checklist' tab
    final myChecklistItems = checklists.where((item) => userDocs.any((d) => d['checklist_id'] == item['id'])).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text("Regional Compliance", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.primaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(text: "Explore"),
              Tab(text: "My Checklist"),
            ],
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
            child: TabBarView(
              children: [
                // Tab 1: Explore (Original View)
                Column(
                  children: [
                    // Country Picker
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          GlassCard(
                            opacity: 0.7,
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedCountry,
                                isExpanded: true,
                                items: countries.entries.map((e) {
                                  return DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                          ),
                          if (_showCustomInput) ...[
                            const SizedBox(height: 12),
                            GlassCard(
                              opacity: 0.7,
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: TextField(
                                controller: _customCountryController,
                                decoration: const InputDecoration(
                                  hintText: "Enter Country Name (e.g. Canada, Germany)",
                                  border: InputBorder.none,
                                  icon: Icon(Icons.public, color: AppTheme.primaryColor),
                                ),
                                onChanged: (v) {
                                   if (checklists.isNotEmpty) setState(() => checklists = []);
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // AI Generate Button Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GlassCard(
                        opacity: 0.8,
                        color: Colors.indigo.withOpacity(0.05),
                        borderColor: Colors.indigo.withOpacity(0.2),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Text(
                              "Don't see what you need? Use our Legal AI to generate a custom regional compliance checklist.",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isAiGenerating ? null : _generateWithAI,
                                icon: isAiGenerating 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.auto_awesome),
                                label: Text(isAiGenerating ? "AI is Thinking..." : "Generate/Refresh AI Checklist"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Full Checklist
                    Expanded(
                      child: isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : checklists.isEmpty 
                          ? const Center(child: Text("No documents found for this region"))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: checklists.length,
                              itemBuilder: (context, index) {
                                final item = checklists[index];
                                final isSelected = userDocs.any((d) => d['checklist_id'] == item['id']);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: GlassCard(
                                    opacity: 0.6,
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Icon(
                                          item['is_mandatory'] ? Icons.warning_amber_rounded : Icons.description_outlined,
                                          color: item['is_mandatory'] ? Colors.orange : AppTheme.primaryColor,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item['document_name'],
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                item['description'] ?? "Mandatory legal document",
                                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Checkbox(
                                          value: isSelected,
                                          activeColor: AppTheme.primaryColor,
                                          onChanged: (val) => _toggleDocument(item['id'], isSelected),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),

                // Tab 2: My Checklist (Selected Only)
                isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : myChecklistItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.playlist_add_check, size: 60, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              "You haven't selected any documents yet.",
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                            TextButton(
                              onPressed: () => DefaultTabController.of(context).animateTo(0),
                              child: const Text("Go to Explore to add items"),
                            )
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: myChecklistItems.length,
                        itemBuilder: (context, index) {
                          final item = myChecklistItems[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: GlassCard(
                              opacity: 0.8,
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['document_name'],
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Added to your compliance list",
                                          style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Could add an 'Upload' button here in future
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
