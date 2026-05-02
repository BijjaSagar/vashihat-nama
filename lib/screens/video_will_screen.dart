import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/encryption/security_service.dart';
import '../theme/app_theme.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class VideoWillScreen extends StatefulWidget {
  final int userId;
  const VideoWillScreen({super.key, required this.userId});

  @override
  State<VideoWillScreen> createState() => _VideoWillScreenState();
}

class _VideoWillScreenState extends State<VideoWillScreen> {
  final ApiService _api = ApiService();
  final SecurityService _security = SecurityService();
  final ImagePicker _picker = ImagePicker();
  
  List<dynamic> _videoWills = [];
  List<dynamic> _nominees = [];
  bool _loading = true;
  bool _isUploading = false;
  bool _isRecordingAudio = false;
  final _audioRecorder = AudioRecorder();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final wills = await _api.getVideoWills(widget.userId);
      final noms = await _api.getNominees(widget.userId);
      if (mounted) {
        setState(() {
          _videoWills = wills['video_wills'] ?? [];
          _nominees = noms is List ? noms : [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Memory Vault", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      ),
      body: Stack(
        children: [
          _loading 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
            : _buildGallery(),
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.accentColor),
                    SizedBox(height: 16),
                    Text("ENCRYPTING & UPLOADING...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : () => _showRecordingSheet(),
        backgroundColor: AppTheme.accentColor,
        label: const Text("DEPOSIT MESSAGE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.videocam_outlined, color: Colors.black),
      ),
    );
  }

  Widget _buildGallery() {
    if (_videoWills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_motion_outlined, color: AppTheme.surfaceColor, size: 80),
            const SizedBox(height: 16),
            const Text("Your sanctuary is empty.", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text("Preserve your voice for the next generation.", style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _videoWills.length,
      itemBuilder: (context, index) => _buildMessageSlab(_videoWills[index]),
    );
  }

  Widget _buildMessageSlab(dynamic vw) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: AppTheme.slabDecoration,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), shape: BoxShape.circle),
                  child: Icon(_getIcon(vw['message_type']), color: AppTheme.accentColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vw['title'] ?? "Untitled Message", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text("PROTECTED MESSAGE", style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white24),
                  onPressed: () {},
                ),
              ],
            ),
            if (vw['transcript'] != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  vw['transcript'],
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'video': return Icons.videocam_outlined;
      case 'audio': return Icons.mic_none_outlined;
      case 'text': return Icons.notes_outlined;
      default: return Icons.auto_awesome_outlined;
    }
  }

  Future<void> _recordVideo() async {
    Navigator.pop(context); // Close sheet
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (video != null) {
        _showTitleDialog(File(video.path), 'video');
      }
    } catch (e) {
      _showError("Camera access failed: $e");
    }
  }

  void _showTitleDialog(File file, String type) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161922),
        title: Text("NAME YOUR ${type.toUpperCase()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: titleCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Enter a memorable title",
            hintStyle: const TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _processAndUpload(file, titleCtrl.text.isEmpty ? "Untitiled $type" : titleCtrl.text, type);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, foregroundColor: Colors.black),
            child: const Text("SAVE TO VAULT"),
          ),
        ],
      ),
    );
  }

  Future<void> _processAndUpload(File file, String title, String type) async {
    setState(() => _isUploading = true);
    try {
      // 1. Read Bytes
      final bytes = await file.readAsBytes();
      
      // 2. Encrypt
      final encryptionKey = _security.generateFileKey();
      final encryptedBytes = _security.encryptFile(Uint8List.fromList(bytes), encryptionKey);
      
      // 3. Create a temp file for encrypted data
      final tempDir = await Directory.systemTemp.createTemp();
      final encryptedFile = File('${tempDir.path}/enc_${DateTime.now().millisecondsSinceEpoch}.bin');
      await encryptedFile.writeAsBytes(encryptedBytes);

      // 4. Upload to S3 (using folder_id 0 as placeholder for video wills)
      // Note: Backend get-presigned-url works regardless of folder_id
      final uploadResult = await _api.uploadFileToS3(encryptedFile);
      
      // 5. Save to Database
      await _api.createVideoWill(
        userId: widget.userId,
        title: title,
        messageType: type,
        storagePath: uploadResult['key'],
        transcript: type == 'text' ? null : "Protected encrypted content.", // Placeholder transcript
      );

      _showSuccess("Memory deposited securely.");
      _loadData();
    } catch (e) {
      _showError("Vault deposit failed: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _writeMessage() {
    Navigator.pop(context);
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: AppTheme.slabDecoration.copyWith(borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Write Message", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 24),
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  labelText: "TITLE",
                  labelStyle: TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.w900),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: msgCtrl,
                maxLines: 5,
                style: const TextStyle(color: Colors.white70),
                decoration: const InputDecoration(
                  labelText: "MESSAGE CONTENT",
                  labelStyle: TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.w900),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (msgCtrl.text.isEmpty) return;
                    Navigator.pop(ctx);
                    
                    // For text messages, we create a temp file and upload it encrypted
                    final tempDir = await Directory.systemTemp.createTemp();
                    final file = File('${tempDir.path}/msg_${DateTime.now().millisecondsSinceEpoch}.txt');
                    await file.writeAsString(msgCtrl.text);
                    
                    _processAndUpload(file, titleCtrl.text.isEmpty ? "Written Message" : titleCtrl.text, 'text');
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text("DEPOSIT TO VAULT", style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  Future<void> _startAudioRecording() async {
    Navigator.pop(context); // Close sheet
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecordingAudio = true);
        
        _showRecordingDialog(path);
      } else {
        _showError("Microphone permission denied.");
      }
    } catch (e) {
      _showError("Audio recording failed: $e");
    }
  }

  void _showRecordingDialog(String path) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF161922),
          title: const Text("RECORDING AUDIO", style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w900)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic_rounded, color: Colors.redAccent, size: 48),
              SizedBox(height: 16),
              Text("Capturing your voice...", style: TextStyle(color: Colors.white70)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _audioRecorder.stop();
                setState(() => _isRecordingAudio = false);
                Navigator.pop(ctx);
              },
              child: const Text("CANCEL", style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () async {
                final finalPath = await _audioRecorder.stop();
                setState(() => _isRecordingAudio = false);
                Navigator.pop(ctx);
                if (finalPath != null) {
                  _showTitleDialog(File(finalPath), 'audio');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor, foregroundColor: Colors.black),
              child: const Text("FINISH"),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: AppTheme.slabDecoration.copyWith(borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Deposit New Memory", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 48),
            _buildActionTile("RECORD VIDEO", Icons.videocam_rounded, onTap: _recordVideo),
            const SizedBox(height: 16),
            _buildActionTile("RECORD AUDIO", Icons.mic_rounded, onTap: _startAudioRecording),
            const SizedBox(height: 16),
            _buildActionTile("WRITE MESSAGE", Icons.edit_note_rounded, onTap: _writeMessage),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.accentColor, size: 24),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 16),
          ],
        ),
      ),
    );
  }
}
