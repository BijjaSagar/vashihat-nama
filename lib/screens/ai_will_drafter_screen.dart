import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AIWillDrafterScreen extends StatefulWidget {
  final int userId;
  const AIWillDrafterScreen({super.key, required this.userId});

  @override
  _AIWillDrafterScreenState createState() => _AIWillDrafterScreenState();
}

class _AIWillDrafterScreenState extends State<AIWillDrafterScreen> {
  final TextEditingController _promptController = TextEditingController();
  String _generatedWill = "";
  bool _isGenerating = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) => setState(() => _promptController.text = val.recognizedWords));
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _generateWill() async {
    if (_promptController.text.isEmpty) return;
    setState(() => _isGenerating = true);
    try {
      String prompt = "Generate a formal and legally-structured Last Will and Testament based on: ${_promptController.text}. Ensure it includes standard legal clauses for revocation of prior wills, appointment of executors, and clear distribution of assets.";
      final response = await ApiService().getAIChatResponse(prompt, []);
      if (mounted) {
        setState(() {
          _generatedWill = response;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _checkTone() async {
    if (_promptController.text.isEmpty) return;
    setState(() => _isGenerating = true);
    try {
      final res = await ApiService().analyzeTone(_promptController.text);
      if (mounted) {
        _showResultDialog("TONE EQUILIBRIUM", "ANALYSIS: ${res['tone']?.toString().toUpperCase()}\n\n${res['suggestion']?.toString().toUpperCase() ?? ''}");
      }
    } catch (e) {
      debugPrint("TONE CHECK FAILED: $e");
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _checkConflicts() async {
    if (_generatedWill.isEmpty) return;
    setState(() => _isGenerating = true);
    try {
      final res = await ApiService().checkWillConflicts(_generatedWill);
      if (mounted) {
        String issues = (res['issues'] as List?)?.map((i) => i.toString().toUpperCase()).join("\n• ") ?? "NO ISSUES FOUND.";
        _showResultDialog("CLAUSE VERIFICATION", res['has_conflict'] == true ? "POTENTIAL CONFLICTS:\n\n• $issues" : "NO CONFLICTS DETECTED. PROTOCOL APPEARS COHERENT.");
      }
    } catch (e) {
      debugPrint("CONFLICT CHECK FAILED: $e");
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showResultDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32), 
          side: const BorderSide(color: Colors.white10)
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1)),
        content: Text(content, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.8, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("DISMISS", style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5))),
        ],
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
        title: const Text("PROTOCOL SYNTHESIS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInputSlab(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 72,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateWill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isGenerating 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                  : const Text("SYNTHESIZE LEGAL PROTOCOL", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
            ),
            if (_generatedWill.isNotEmpty) ...[
              const SizedBox(height: 48),
              _buildOutputSlab(),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSlab() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: AppTheme.slabDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("INTENT DECLARATION", style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2)),
              GestureDetector(
                onTap: _listen,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.redAccent.withOpacity(0.05) : Colors.white.withOpacity(0.01),
                    shape: BoxShape.circle,
                    border: Border.all(color: _isListening ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05)),
                  ),
                  child: Icon(_isListening ? Icons.mic_rounded : Icons.mic_none_rounded, 
                    color: _isListening ? Colors.redAccent : AppTheme.accentColor, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _promptController,
            maxLines: 10,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.8, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            decoration: InputDecoration(
              hintText: "DESCRIBE YOUR WISHES IN NATURAL LANGUAGE...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.05), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: _buildMiniAction(
                  "TONE CHECK", 
                  Icons.psychology_outlined, 
                  Colors.purpleAccent, 
                  _checkTone
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMiniAction(
                  "LEGAL AUDIT", 
                  Icons.gavel_rounded, 
                  Colors.orangeAccent, 
                  _checkConflicts,
                  disabled: _generatedWill.isEmpty
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAction(String label, IconData icon, Color color, VoidCallback onTap, {bool disabled = false}) {
    return InkWell(
      onTap: (disabled || _isGenerating) ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(disabled ? 0.01 : 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(disabled ? 0.05 : 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color.withOpacity(disabled ? 0.1 : 1), size: 18),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(color: color.withOpacity(disabled ? 0.1 : 1), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildOutputSlab() {
    return Container(
      width: double.infinity,
      decoration: AppTheme.slabDecoration.copyWith(
        color: Colors.white.withOpacity(0.01),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: AppTheme.accentColor.withOpacity(0.1))),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_outlined, color: AppTheme.accentColor, size: 16),
                const SizedBox(width: 16),
                const Text("GENETIC PROTOCOL DRAFT", style: TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(40),
            child: Text(
              _generatedWill.toUpperCase(),
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 2.0, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {}, 
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withOpacity(0.05)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white24),
                label: const Text("DOWNLOAD PDF", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
