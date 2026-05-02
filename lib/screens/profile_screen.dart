import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'sentinel_protocol_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  final Map<String, dynamic>? userProfile;
  const ProfileScreen({super.key, required this.userId, this.userProfile});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isFetching = false;
  Map<String, dynamic>? _currentProfile;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.userProfile;
    if (_currentProfile != null) {
      _populateControllers(_currentProfile!);
    } else {
      _fetchProfile();
    }
  }

  void _populateControllers(Map<String, dynamic> profile) {
    nameController.text = (profile['name'] ?? "").toString().toUpperCase();
    emailController.text = (profile['email'] ?? "").toString().toUpperCase();
    phoneController.text = (profile['mobile_number'] ?? profile['phone_number'] ?? "").toString();
  }

  Future<void> _fetchProfile() async {
    if (mounted) setState(() => _isFetching = true);
    try {
      final profile = await ApiService().getUserProfile(userId: widget.userId);
      // Save to SharedPreferences so dashboard can update
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userProfile', jsonEncode(profile));
      
      if (mounted) {
        setState(() {
          _currentProfile = profile;
          _populateControllers(profile);
        });
      }
    } catch (e) {
      debugPrint("ERROR FETCHING PROFILE: $e");
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _updateProfile() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      await ApiService().updateUserProfile(
        userId: widget.userId,
        name: nameController.text,
        email: emailController.text,
      );
      
      // Refresh local profile
      await _fetchProfile();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PROFILE METRICS SYNCHRONIZED"), backgroundColor: AppTheme.accentColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("METRIC SYNC FAILED: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("SUBJECT CONFIGURATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 16)),
        centerTitle: true,
      ),
      body: _isFetching 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileIdentity(),
                const SizedBox(height: 56),
                _buildSectionHeader("DATA FIELDSET"),
                const SizedBox(height: 24),
                Container(
                  decoration: AppTheme.slabDecoration,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      _buildSlabInput("FULL IDENTITY", nameController, Icons.badge_rounded),
                      const SizedBox(height: 32),
                      _buildSlabInput("COMMUNICATION CHANNEL", emailController, Icons.alternate_email_rounded, type: TextInputType.emailAddress),
                      const SizedBox(height: 32),
                      _buildSlabInput("PRIMARY TERMINAL", phoneController, Icons.smartphone_rounded, enabled: false),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 72,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Text("SYNC DATA METRICS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 56),
                _buildSectionHeader("SYSTEM PROTOCOLS"),
                const SizedBox(height: 24),
                _buildProtocolSlab(),
                const SizedBox(height: 80),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2));
  }

  Widget _buildProfileIdentity() {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.accentColor.withOpacity(0.1), width: 1),
                ),
                child: CircleAvatar(
                  radius: 64,
                  backgroundColor: Colors.white.withOpacity(0.01),
                  child: const Icon(Icons.shield_rounded, size: 48, color: AppTheme.accentColor),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: AppTheme.accentColor, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            nameController.text.isNotEmpty ? nameController.text.toUpperCase() : "IDENTIFYING...", 
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.accentColor.withOpacity(0.1)),
            ),
            child: const Text(
              "LEVEL 4 SENTINEL", 
              style: TextStyle(color: AppTheme.accentColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlabInput(String label, TextEditingController ctrl, IconData icon, {bool enabled = true, TextInputType type = TextInputType.emailAddress}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(enabled ? 0.01 : 0.005), 
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(enabled ? 0.03 : 0.01)),
          ),
          child: TextField(
            controller: ctrl,
            enabled: enabled,
            keyboardType: type,
            style: TextStyle(color: enabled ? Colors.white : AppTheme.textSecondary, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.accentColor.withOpacity(enabled ? 0.2 : 0.05), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProtocolSlab() {
    return Container(
      decoration: AppTheme.slabDecoration,
      child: Column(
        children: [
          _buildProtocolTile("SECURITY SCORE", "98/100", Icons.verified_user_rounded, Colors.greenAccent),
          _buildDivider(),
          _buildProtocolTile("SENTINEL PROTOCOL", "TUTORIAL", Icons.history_edu_rounded, AppTheme.accentColor, onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SentinelProtocolScreen()));
          }),
          _buildDivider(),
          _buildProtocolTile("VAULT AUDIT", "7 DAYS AGO", Icons.history_rounded, Colors.white10),
          _buildDivider(),
          _buildProtocolTile("TERMINATE SESSION", "LOGOUT", Icons.logout_rounded, Colors.redAccent, isDestructive: true, onTap: _handleLogout),
        ],
      ),
    );
  }

  Widget _buildDivider() => Divider(color: Colors.white.withOpacity(0.01), height: 1, indent: 32, endIndent: 32);

  Widget _buildProtocolTile(String title, String value, IconData icon, Color color, {bool isDestructive = false, VoidCallback? onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      leading: Icon(icon, color: color.withOpacity(0.4), size: 18),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.redAccent : Colors.white70, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      trailing: Text(value, style: TextStyle(color: color.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32), 
          side: BorderSide(color: Colors.white.withOpacity(0.05))
        ),
        title: const Text("TERMINATE CONNECTION?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
        content: const Text("ARE YOU SURE YOU WANT TO DISCONNECT FROM THE SENTINEL BACKBONE?", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, height: 1.8, letterSpacing: 0.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("DISCONNECT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService().logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SecureLoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
