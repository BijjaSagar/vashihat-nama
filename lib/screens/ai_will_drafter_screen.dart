import 'package:flutter/material.dart';
import '../theme/glassmorphism.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

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

  void _generateWill() async {
    if (_promptController.text.isEmpty) return;

    setState(() => _isGenerating = true);

    // TODO: Connect to actual AI Backend Endpoint
    // For now, we simulate a response
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _generatedWill = """
LAST WILL AND TESTAMENT

I, [Name], residing at [Address], being of sound mind, do hereby declare this to be my Last Will and Testament.

1. I revoke all prior Wills and Codicils.
2. I appoint my nominee(s) as the Executor(s) of this Will.
3. I give, devise, and bequeath my assets as follows:
   - To my spouse/children: All my digital assets and secure vault contents.
   
(Generated based on prompt: "${_promptController.text}")
      """;
      _isGenerating = false;
    });
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
                            const Text("Describe your wishes:", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _promptController,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                hintText: "E.g., I want to leave my house to my wife and my savings to my two children equally...",
                                border: InputBorder.none,
                              ),
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
