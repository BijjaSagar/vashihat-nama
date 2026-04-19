import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GriefSupportScreen extends StatefulWidget {
  final String? nomineeName;
  final String? deceasedName;
  const GriefSupportScreen({Key? key, this.nomineeName, this.deceasedName}) : super(key: key);

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
    _messages.add({'role': 'assistant', 'content': 'I\'m here for you. 💙\n\nI understand this is an incredibly difficult time. I\'m the Eversafe support assistant, and I\'m here to gently guide you through the process of understanding and accessing the digital legacy that has been entrusted to you.\n\nTake your time. There\'s no rush. Whenever you\'re ready, you can ask me anything — about the vault, about next legal steps, or just share how you\'re feeling.'});
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _msgCtrl.clear();
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _sending = true;
    });
    _scrollToBottom();

    try {
      final history = _messages.map((m) => {'role': m['role']!, 'content': m['content']!}).toList();
      final result = await _api.griefSupportChat(message: text, history: history, nomineeName: widget.nomineeName, deceasedName: widget.deceasedName);
      setState(() {
        _messages.add({'role': 'assistant', 'content': result['reply'] ?? 'I\'m here for you. Please try again.'});
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'I apologize, I\'m having trouble responding right now. Please try again in a moment.'});
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
      backgroundColor: const Color(0xFFF5F0F7),
      appBar: AppBar(
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Grief Support', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          Text('Compassionate AI Assistant', style: TextStyle(fontSize: 12, color: Colors.white70)),
        ]),
        backgroundColor: const Color(0xFF5C6BC0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(16),
          itemCount: _messages.length + (_sending ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i == _messages.length && _sending) {
              return Align(alignment: Alignment.centerLeft,
                child: Container(margin: const EdgeInsets.only(bottom: 8, right: 60), padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[400])),
                    const SizedBox(width: 10),
                    Text('Thinking with care...', style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic)),
                  ])));
            }
            final msg = _messages[i];
            final isUser = msg['role'] == 'user';
            return Align(
              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.only(bottom: 10, left: isUser ? 50 : 0, right: isUser ? 0 : 50),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isUser ? const Color(0xFF5C6BC0) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4), bottomRight: Radius.circular(isUser ? 4 : 18)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                ),
                child: Text(msg['content']!, style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 15, height: 1.5)),
              ),
            );
          },
        )),
        Container(
          padding: EdgeInsets.only(left: 16, right: 8, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2))]),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _msgCtrl,
              decoration: InputDecoration(
                hintText: 'Type your message...', hintStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true, fillColor: const Color(0xFFF5F0F7), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
              maxLines: 3, minLines: 1, textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            )),
            const SizedBox(width: 8),
            Container(decoration: BoxDecoration(color: const Color(0xFF5C6BC0), borderRadius: BorderRadius.circular(24)),
              child: IconButton(onPressed: _sendMessage, icon: const Icon(Icons.send_rounded, color: Colors.white))),
          ]),
        ),
      ]),
    );
  }
}
