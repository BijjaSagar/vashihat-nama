import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class LegalDocumentScreen extends StatefulWidget {
  final int userId;
  const LegalDocumentScreen({super.key, required this.userId});

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _documents = [];
  bool _loading = true;
  bool _generating = false;

  final List<Map<String, String>> _docTypes = [
    {'key': 'power_of_attorney', 'title': 'POWER OF ATTORNEY', 'icon': '⚖️', 'desc': 'AUTHORIZE LEGAL REPRESENTATION'},
    {'key': 'gift_deed', 'title': 'GIFT DEED', 'icon': '🎁', 'desc': 'TRANSFER ASSETS AS GRATUITY'},
    {'key': 'succession_certificate', 'title': 'SUCCESSION CERTIFICATE', 'icon': '📜', 'desc': 'VALIDATE INHERITANCE RIGHTS'},
    {'key': 'nominee_claim_letter', 'title': 'NOMINEE CLAIM LETTER', 'icon': '✉️', 'desc': 'FORMAL ASSET REQUISITION'},
    {'key': 'insurance_claim', 'title': 'INSURANCE CLAIM', 'icon': '🏥', 'desc': 'POLICY BENEFIT ACTIVATION'},
    {'key': 'will', 'title': 'LAST WILL & TESTAMENT', 'icon': '📋', 'desc': 'FINAL ASSET DISPOSITION'},
    {'key': 'property_transfer', 'title': 'PROPERTY TRANSFER', 'icon': '🏠', 'desc': 'REAL ESTATE OWNERSHIP SHIFT'},
    {'key': 'bank_closure', 'title': 'BANK CLOSURE', 'icon': '🏦', 'desc': 'ACCOUNT TERMINATION PROTOCOL'},
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    if (mounted) setState(() => _loading = true);
    try {
      final result = await _api.getLegalDocuments(widget.userId);
      if (mounted) {
        setState(() { 
          _documents = result['documents'] ?? []; 
          _loading = false; 
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showGenerateSheet() {
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.8,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: AppTheme.slabDecoration.copyWith(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          color: AppTheme.backgroundColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)))),
            const SizedBox(height: 40),
            const Text('DRAFT LEGAL INSTRUMENT', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            const Text('AI INTELLIGENCE WILL GENERATE A PRECISE LEGAL DRAFT.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            const SizedBox(height: 40),
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, 
                  crossAxisSpacing: 16, 
                  mainAxisSpacing: 16, 
                  childAspectRatio: 1.1,
                ),
                itemCount: _docTypes.length,
                itemBuilder: (context, i) {
                  final doc = _docTypes[i];
                  return InkWell(
                    onTap: () async {
                      Navigator.pop(ctx);
                      setState(() => _generating = true);
                      try {
                        await _api.generateLegalDocument(userId: widget.userId, docType: doc['key']!, language: 'en');
                        _loadDocuments();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GENERATION FAILED')));
                      }
                      if (mounted) setState(() => _generating = false);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.01), 
                        borderRadius: BorderRadius.circular(20), 
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                          Text(doc['icon']!, style: const TextStyle(fontSize: 24)),
                          const SizedBox(height: 16),
                          Text(doc['title']!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _viewDocument(dynamic doc) {
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.9,
        padding: const EdgeInsets.all(32),
        decoration: AppTheme.slabDecoration.copyWith(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          color: AppTheme.backgroundColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                Expanded(child: Text(doc['title'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
                IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white24, size: 24), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
              decoration: BoxDecoration(color: AppTheme.accentColor.withOpacity(0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.accentColor.withOpacity(0.1))),
              child: Text(doc['status']?.toString().toUpperCase() ?? 'DRAFT', style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1)),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.01), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: SelectableText(
                    doc['content'] ?? '', 
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.8, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, foregroundColor: Colors.black),
                child: const Text("EXPORT AS SECURE PDF", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("LEGAL PROTOCOLS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generating ? null : _showGenerateSheet,
        backgroundColor: AppTheme.accentColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: _generating 
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) 
          : const Icon(Icons.add_rounded, color: Colors.black, size: 24),
        label: Text(_generating ? 'DRAFTING...' : 'NEW PROTOCOL', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : _documents.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                  itemCount: _documents.length,
                  itemBuilder: (ctx, i) {
                    final doc = _documents[i];
                    return _buildDocCard(doc);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          Icon(Icons.gavel_rounded, size: 64, color: Colors.white.withOpacity(0.02)),
          const SizedBox(height: 32),
          const Text('NO PROTOCOLS FOUND', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 12),
          const Text('INITIATE AI DRAFTING TO SECURE\nYOUR LEGAL POSTURE.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildDocCard(dynamic doc) {
    return GestureDetector(
      onTap: () => _viewDocument(doc),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: AppTheme.slabDecoration,
        child: ListTile(
          contentPadding: const EdgeInsets.all(24),
          leading: Container(
            padding: const EdgeInsets.all(12), 
            decoration: BoxDecoration(color: AppTheme.accentColor.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.description_rounded, color: AppTheme.accentColor, size: 20),
          ),
          title: Text(doc['title']?.toString().toUpperCase() ?? 'LEGAL INSTRUMENT', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Text(doc['doc_type']?.toString().replaceAll('_', ' ').toUpperCase() ?? '', style: const TextStyle(fontSize: 8, color: AppTheme.textSecondary, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                const SizedBox(width: 8),
                const Text("•", style: TextStyle(color: Colors.white10)),
                const SizedBox(width: 8),
                Text(_formatDate(doc['created_at']), style: const TextStyle(fontSize: 8, color: Colors.white24, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), 
            onPressed: () async {
              await _api.deleteLegalDocument(doc['id'], widget.userId);
              _loadDocuments();
            },
          ),
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    try { 
      final d = DateTime.parse(date); 
      return '${d.day} ${_getMonth(d.month)} ${d.year}'; 
    } catch (e) { 
      return date.toUpperCase(); 
    }
  }

  String _getMonth(int m) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[m - 1];
  }
}
