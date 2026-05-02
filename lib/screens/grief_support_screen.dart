import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class GriefSupportScreen extends StatefulWidget {
  final String? nomineeName;
  final String? deceasedName;
  const GriefSupportScreen({super.key, this.nomineeName, this.deceasedName});

  @override
  State<GriefSupportScreen> createState() => _GriefSupportScreenState();
}

class _GriefSupportScreenState extends State<GriefSupportScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'assistant', 
      'content': 'I AM HERE FOR YOU.\n\nI UNDERSTAND THIS IS AN INCREDIBLY DIFFICULT TIME. I AM THE SENTINEL COMPASSIONATE ASSISTANT, AND I AM HERE TO GENTLY GUIDE YOU THROUGH THE PROCESS OF UNDERSTANDING AND ACCESSING THE DIGITAL LEGACY THAT HAS BEEN ENTRUSTED TO YOU.\n\nTAKE YOUR TIME. THERE IS NO RUSH. WHENEVER YOU ARE READY, YOU CAN ASK ME ANYTHING — ABOUT THE VAULT, ABOUT NEXT LEGAL STEPS, OR JUST SHARE HOW YOU ARE FEELING.'
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _msgCtrl.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text.toUpperCase()});
      _sending = true;
    });
    _scrollToBottom();

    try {
      final history = _messages.map((m) => {'role': m['role']!, 'content': m['content']!}).toList();
      final result = await _api.griefSupportChat(message: text, history: history, nomineeName: widget.nomineeName, deceasedName: widget.deceasedName);
      setState(() {
        _messages.add({'role': 'assistant', 'content': (result['reply'] ?? 'I AM HERE FOR YOU. PLEASE TRY AGAIN.').toString().toUpperCase()});
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'I APOLOGIZE, I AM HAVING TROUBLE RESPONDING RIGHT NOW. PLEASE TRY AGAIN IN A MOMENT.'});
        _sending = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollCtrl.hasClients) _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
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
        title: const Column(
          children: [
            Text("COMPASSIONATE AI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 14)),
            Text("SENTINEL SUPPORT SYSTEM", style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              itemCount: _messages.length + (_sending ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (i == _messages.length && _sending) {
                  return _buildThinkingIndicator();
                }
                final msg = _messages[i];
                final isUser = msg['role'] == 'user';
                return _buildMessageBubble(msg['content']!, isUser);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.01),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.accentColor)),
            const SizedBox(width: 16),
            Text('PROCESSING WITH CARE...', style: TextStyle(color: AppTheme.accentColor.withOpacity(0.5), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 24, left: isUser ? 40 : 0, right: isUser ? 0 : 40),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.accentColor.withOpacity(0.05) : Colors.white.withOpacity(0.01),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(24),
            topRight: const Radius.circular(24),
            bottomLeft: Radius.circular(isUser ? 24 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 24),
          ),
          border: Border.all(color: isUser ? AppTheme.accentColor.withOpacity(0.1) : Colors.white.withOpacity(0.05)),
        ),
        child: Text(
          content, 
          style: TextStyle(
            color: isUser ? Colors.white : Colors.white70, 
            fontSize: 12, 
            height: 1.6, 
            fontWeight: isUser ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.2
          )
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.01),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: TextField(
                controller: _msgCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  hintText: 'COMMUNICATE WITH SENTINEL...',
                  hintStyle: TextStyle(color: Colors.white10, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.accentColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: _sendMessage, 
              icon: const Icon(Icons.send_rounded, color: Colors.black, size: 20)
            ),
          ),
        ],
      ),
    );
  }
}
