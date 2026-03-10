import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LegalDocumentScreen extends StatefulWidget {
  final int userId;
  const LegalDocumentScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _documents = [];
  bool _loading = true;
  bool _generating = false;

  final List<Map<String, String>> _docTypes = [
    {'key': 'power_of_attorney', 'title': 'Power of Attorney', 'icon': '⚖️', 'desc': 'Authorize someone to act on your behalf'},
    {'key': 'gift_deed', 'title': 'Gift Deed', 'icon': '🎁', 'desc': 'Transfer property as a gift'},
    {'key': 'succession_certificate', 'title': 'Succession Certificate', 'icon': '📜', 'desc': 'Apply for succession rights'},
    {'key': 'nominee_claim_letter', 'title': 'Nominee Claim Letter', 'icon': '✉️', 'desc': 'Claim letter for bank accounts'},
    {'key': 'insurance_claim', 'title': 'Insurance Claim', 'icon': '🏥', 'desc': 'Apply for insurance claim'},
    {'key': 'will', 'title': 'Last Will & Testament', 'icon': '📋', 'desc': 'Draft your last will'},
    {'key': 'property_transfer', 'title': 'Property Transfer', 'icon': '🏠', 'desc': 'Transfer property ownership'},
    {'key': 'bank_closure', 'title': 'Bank Closure Application', 'icon': '🏦', 'desc': 'Close a bank account'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final result = await _api.getLegalDocuments(widget.userId);
      setState(() { _documents = result['documents'] ?? []; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showGenerateSheet() {
    String selectedLang = 'en';
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 20),
          const Text('📜 Generate Legal Document', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('AI will generate a professional draft', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          SizedBox(height: 400,
            child: GridView.count(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
              children: _docTypes.map((doc) => InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  setState(() => _generating = true);
                  try {
                    await _api.generateLegalDocument(userId: widget.userId, docType: doc['key']!, language: selectedLang);
                    _loadDocuments();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate')));
                  }
                  setState(() => _generating = false);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.2))),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(doc['icon']!, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 6),
                    Text(doc['title']!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ]),
                ),
              )).toList(),
            ),
          ),
        ]),
      ),
    );
  }

  void _viewDocument(dynamic doc) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(doc['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          ]),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFF00695C).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(doc['status'] ?? 'draft', style: const TextStyle(color: Color(0xFF00695C), fontWeight: FontWeight.w600, fontSize: 12))),
          const SizedBox(height: 16),
          Expanded(child: SingleChildScrollView(child: SelectableText(doc['content'] ?? '', style: const TextStyle(fontSize: 14, height: 1.8)))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Legal Documents', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generating ? null : _showGenerateSheet,
        backgroundColor: const Color(0xFF00695C),
        icon: _generating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add, color: Colors.white),
        label: Text(_generating ? 'Generating...' : 'Generate', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _documents.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.description, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No Documents Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Generate legal documents\nusing AI', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _documents.length,
                  itemBuilder: (ctx, i) {
                    final doc = _documents[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF00695C).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.description, color: Color(0xFF00695C))),
                        title: Text(doc['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Type: ${doc['doc_type'] ?? ''}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(_formatDate(doc['created_at']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ]),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.visibility, color: Color(0xFF00695C)), onPressed: () => _viewDocument(doc)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () async {
                            await _api.deleteLegalDocument(doc['id'], widget.userId);
                            _loadDocuments();
                          }),
                        ]),
                        onTap: () => _viewDocument(doc),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    try { final d = DateTime.parse(date); return '${d.day}/${d.month}/${d.year}'; } catch (e) { return date; }
  }
}
