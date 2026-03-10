import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/glassmorphism.dart';

class VideoWillScreen extends StatefulWidget {
  final int userId;
  const VideoWillScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<VideoWillScreen> createState() => _VideoWillScreenState();
}

class _VideoWillScreenState extends State<VideoWillScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _videoWills = [];
  List<dynamic> _nominees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final wills = await _api.getVideoWills(widget.userId);
      final noms = await _api.getNominees(widget.userId.toString());
      setState(() {
        _videoWills = wills['video_wills'] ?? [];
        _nominees = noms is List ? noms : [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    int? selectedNomineeId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Container(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 20),
              const Text('📹 New Message for Nominee', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Leave a personal message for your loved ones', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              TextField(controller: titleCtrl, decoration: InputDecoration(labelText: 'Title', hintText: 'e.g. "Message for my family"', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: const Color(0xFFF5F7FA))),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedNomineeId,
                decoration: InputDecoration(labelText: 'For Nominee (optional)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: const Color(0xFFF5F7FA)),
                items: _nominees.map<DropdownMenuItem<int>>((n) => DropdownMenuItem(value: n['id'] as int, child: Text(n['name'] ?? 'Unknown'))).toList(),
                onChanged: (val) => setInner(() => selectedNomineeId = val),
              ),
              const SizedBox(height: 16),
              TextField(controller: messageCtrl, maxLines: 6, decoration: InputDecoration(labelText: 'Your Message', hintText: 'Write your personal message here...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: const Color(0xFFF5F7FA))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleCtrl.text.isEmpty || messageCtrl.text.isEmpty) return;
                    Navigator.pop(ctx);
                    setState(() => _loading = true);
                    await _api.createVideoWill(userId: widget.userId, title: titleCtrl.text, nomineeId: selectedNomineeId, messageType: 'text', transcript: messageCtrl.text);
                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text('💾 Save Message', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Video Will & Messages', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF880E4F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: const Color(0xFF880E4F),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _videoWills.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.videocam_off, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No Messages Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text('Leave a personal message\nfor your loved ones', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ]))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _videoWills.length,
                  itemBuilder: (ctx, i) {
                    final vw = _videoWills[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF880E4F).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: Icon(vw['message_type'] == 'video' ? Icons.videocam : vw['message_type'] == 'audio' ? Icons.mic : Icons.note, color: const Color(0xFF880E4F))),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(vw['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              if (vw['nominee_name'] != null) Text('For: ${vw['nominee_name']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            ])),
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () async {
                              await _api.deleteVideoWill(vw['id'], widget.userId);
                              _loadData();
                            }),
                          ]),
                          if (vw['transcript'] != null && vw['transcript'].toString().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12)),
                              child: Text(vw['transcript'], style: const TextStyle(fontSize: 14, height: 1.5), maxLines: 4, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(_formatDate(vw['created_at']), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '';
    try {
      final d = DateTime.parse(date);
      return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (e) { return date; }
  }
}
