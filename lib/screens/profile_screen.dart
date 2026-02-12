import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../theme/glassmorphism.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userProfile;
  const ProfileScreen({super.key, this.userProfile});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.userProfile != null) {
      nameController.text = widget.userProfile!['name'] ?? "";
      emailController.text = widget.userProfile!['email'] ?? "";
      phoneController.text = widget.userProfile!['mobile_number'] ?? widget.userProfile!['phone_number'] ?? "";
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    if (widget.userProfile != null) {
      try {
        await ApiService().updateUserProfile(widget.userProfile!['id'].toString(), {
          'name': nameController.text,
          'email': emailController.text,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully!")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to update profile: $e")),
          );
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text("Profile", style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF2F2F7), // System Gray 6
              Color(0xFFE5E5EA), // System Gray 5
              Color(0xFFF2F2F7),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SingleChildScrollView( // Added scroll view
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Profile Avatar
                 GlassCard(
                  opacity: 0.6,
                  blur: 20,
                  color: Colors.white,
                  borderColor: Colors.white.withOpacity(0.9),
                  padding: const EdgeInsets.all(16), // Fixed padding directly on card
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 3),
                        ),
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.backgroundColor,
                          child: Icon(Icons.person, size: 60, color: AppTheme.primaryColor),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        nameController.text.isNotEmpty ? nameController.text : "User Name", 
                        style: TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary
                        )
                      ),
                      Text(
                        phoneController.text, 
                        style: TextStyle(color: AppTheme.textSecondary)
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
          
                GlassCard(
                  opacity: 0.6,
                  blur: 20,
                  color: Colors.white,
                  borderColor: Colors.white.withOpacity(0.9),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildTextField(controller: nameController, label: "Full Name", icon: Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextField(controller: emailController, label: "Email Address", icon: Icons.email_outlined),
                      const SizedBox(height: 16),
                      _buildTextField(controller: phoneController, label: "Phone Number", icon: Icons.phone_android, enabled: false),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Update Profile", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(color: enabled ? AppTheme.textPrimary : AppTheme.textSecondary),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: enabled ? AppTheme.primaryColor : Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

