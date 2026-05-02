import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class LegalAssistantScreen extends StatefulWidget {
  final int userId;
  const LegalAssistantScreen({super.key, required this.userId});

  @override
  _LegalAssistantScreenState createState() => _LegalAssistantScreenState();
}

class _LegalAssistantScreenState extends State<LegalAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {"role": "assistant", "content": "I AM THE SENTINEL INTELLIGENCE. QUERY ME REGARDING YOUR ASSETS, LEGACY PROTOCOLS, OR SECURE DATA MANAGEMENT."}
  ];
  final List<dynamic> _history = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    String msg = _messageController.text.trim();
    if (msg.isEmpty) return;

    if (mounted) {
      setState(() {
        _messages.add({"role": "user", "content": msg});
        _messageController.clear();
        _isLoading = true;
      });
    }
    
    _scrollToBottom();

    try {
      final reply = await ApiService().getAIChatResponse(msg, _history);
      
      if (mounted) {
        setState(() {
          _messages.add({"role": "assistant", "content": reply});
          _history.add({"role": "user", "parts": [{"text": msg}]});
          _history.add({"role": "model", "parts": [{"text": reply}]});
          _isLoading = false;
        });
      }
      
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("TRANSMISSION FAILURE: $e"), backgroundColor: Colors.redAccent));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
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
        title: const Text("SENTINEL INTELLIGENCE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg["role"] == "user";
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 40),
                      padding: const EdgeInsets.all(32),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                      decoration: isUser 
                        ? AppTheme.slabDecoration.copyWith(
                            color: AppTheme.accentColor.withOpacity(0.02),
                            border: Border.all(color: AppTheme.accentColor.withOpacity(0.1)),
                          )
                        : AppTheme.slabDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(isUser ? Icons.fingerprint_rounded : Icons.auto_awesome_rounded, 
                                color: isUser ? Colors.white.withOpacity(0.1) : AppTheme.accentColor, size: 14),
                              const SizedBox(width: 12),
                              Text(isUser ? "ORIGINATOR" : "SENTINEL CORE", 
                                style: TextStyle(color: isUser ? Colors.white.withOpacity(0.1) : AppTheme.accentColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            msg["content"]!.toUpperCase(),
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              height: 1.8,
                              fontWeight: isUser ? FontWeight.w900 : FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator(color: AppTheme.accentColor, strokeWidth: 1.5)),
              ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.02))),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: AppTheme.slabDecoration,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                decoration: InputDecoration(
                  hintText: "INPUT QUERY FOR ANALYSIS...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.05), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: AppTheme.accentColor, size: 20),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
