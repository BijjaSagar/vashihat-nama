import 'package:flutter/material.dart';
import '../theme/glassmorphism.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AIWillDrafterScreen extends StatefulWidget {
  final int userId;
  const AIWillDrafterScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _AIWillDrafterScreenState createState() => _AIWillDrafterScreenState();
}

class _AIWillDrafterScreenState extends State<AIWillDrafterScreen> {
  final TextEditingController _promptController = TextEditingController();
  String _generatedWill = "";
  bool _isGenerating = false;

  // Speech to Text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  double _confidence = 1.0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _promptController.text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
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
      String prompt = "Generate a formal and legally-structured Last Will and Testament based on the following wishes: ${_promptController.text}. Ensure it includes standard legal clauses for revocation of prior wills, appointment of executors, and clear distribution of assets.";
      final response = await ApiService().getAIChatResponse(prompt, []); // Use Chat API for generation
      
      setState(() {
        _generatedWill = response;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("AI Error: $e")));
      }
    }
  }

  Future<void> _checkConflicts() async {
    if (_generatedWill.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generate a will draft first to check for conflicts.")));
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final result = await ApiService().checkWillConflicts(_generatedWill);
      setState(() => _isGenerating = false);

      bool hasConflict = result['has_conflict'] ?? false;
      List issues = result['issues'] ?? [];

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(hasConflict ? "⚠️ Conflicts Detected" : "✅ No Conflicts Found"),
            content: SingleChildScrollView(
              child: hasConflict
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: issues.map<Widget>((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text("• $e", style: const TextStyle(color: Colors.redAccent)),
                      )).toList(),
                    )
                  : const Text("The legal clauses appear consistent. No obvious contradictions found."),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _analyzeTone() async {
    if (_promptController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your personal wishes/message first.")));
      return;
    }
    setState(() => _isGenerating = true);
    try {
      final result = await ApiService().analyzeTone(_promptController.text);
      setState(() => _isGenerating = false);

      String tone = result['tone'] ?? "Neutral";
      bool isHarsh = result['is_harsh'] ?? false;
      String? suggestion = result['suggestion'];

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text("❤️ Emotional Tone Check"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Detected Tone: $tone", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (isHarsh) ...[
                    const Text("⚠️ Warning: The tone seems harsh or potentially confusing.", style: TextStyle(color: Colors.orange)),
                    const SizedBox(height: 10),
                    const Text("Suggestion:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(suggestion ?? "Consider rewriting to be more clear and calm."),
                  ] else
                    const Text("The tone is appropriate for a legal/personal sentiment.", style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK"))],
          ),
        );
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("AI Will Drafter", style: TextStyle(color: Colors.black)),
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
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      GlassCard(
                        opacity: 0.7,
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Describe your wishes:", style: TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: Icon(
                                    _isListening ? Icons.mic : Icons.mic_none,
                                    color: _isListening ? Colors.red : AppTheme.primaryColor,
                                  ),
                                  onPressed: _listen,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _promptController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: "E.g., I want to leave my house to my wife and my savings to my two children equally...",
                                border: InputBorder.none,
                              ),
                            ),
                            if (_isListening)
                              const Padding(
                                padding: EdgeInsets.only(top: 8.0),
                                child: Text("Listening...", style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _generateWill,
                          icon: _isGenerating 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                              : const Icon(Icons.psychology),
                          label: Text(_isGenerating ? "Drafting..." : "Generate Will"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isGenerating ? null : _analyzeTone,
                              icon: const Icon(Icons.favorite_outline, color: Colors.pinkAccent),
                              label: const Text("Tone Check", style: TextStyle(color: Colors.black)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Colors.pinkAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isGenerating ? null : _checkConflicts,
                              icon: const Icon(Icons.gavel, color: Colors.orange),
                              label: const Text("Conflict Check", style: TextStyle(color: Colors.black)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Colors.orange),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_generatedWill.isNotEmpty)
                        Expanded(
                          child: GlassCard(
                            opacity: 0.8,
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            padding: const EdgeInsets.all(16),
                            child: SingleChildScrollView(
                              child: Text(_generatedWill, style: const TextStyle(fontSize: 14, height: 1.5)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
