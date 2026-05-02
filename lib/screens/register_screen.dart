import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'main_navigation_shell.dart';
import 'legal_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  
  bool otpSent = false;
  bool otpVerified = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  void sendOTP() async {
    if (phoneController.text.length < 10) return;
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().sendOtp(phoneController.text, 'register');
      if (res['success'] == true) {
        setState(() {
          otpSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> verifyOTP() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().verifyOtp(phoneController.text, otpController.text, 'register');
      if (res['success'] == true) {
         setState(() {
           otpVerified = true;
           _isLoading = false;
         });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> completeRegistration() async {
    setState(() => _isLoading = true);
    try {
        String publicKey = "sentinel_pk_${DateTime.now().millisecondsSinceEpoch}";
        String encryptedPrivateKey = "sentinel_epk_SECURE";

        final registeredUser = await ApiService().registerUser(
          phoneController.text,
          publicKey, 
          encryptedPrivateKey,
          nameController.text,
          emailController.text
        );
        
        final prefs = await SharedPreferences.getInstance();
        if (registeredUser['user'] != null) {
          await prefs.setString('userProfile', jsonEncode(registeredUser['user']));
          if (registeredUser['token'] != null) await prefs.setString('authToken', registeredUser['token']);
          
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainNavigationShell(userId: registeredUser['user']['id'])),
          );
        }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.accentColor.withOpacity(0.1)),
                ),
                child: const Icon(Icons.shield_moon_rounded, size: 48, color: AppTheme.accentColor),
              ),
              const SizedBox(height: 48),
              const Text("VAULT INITIATION", style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 12),
              const Text("ESTABLISH SANCTUARY", style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1)),
              const SizedBox(height: 64),
              
              if (!otpVerified) ...[
                _buildInputLabel("SECURE MOBILE IDENTIFIER"),
                _buildSlabInput(
                  controller: phoneController,
                  hint: "000 000 0000",
                  enabled: !otpSent,
                  icon: Icons.phone_android_rounded,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                ),
                if (otpSent) ...[
                  const SizedBox(height: 32),
                  _buildInputLabel("AUTHORIZATION CODE"),
                  _buildSlabInput(
                    controller: otpController,
                    hint: "000 000",
                    icon: Icons.lock_open_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  ),
                ],
              ] else ...[
                _buildInputLabel("FULL LEGAL IDENTITY"),
                _buildSlabInput(
                  controller: nameController, 
                  hint: "AS PER IDENTIFICATION", 
                  icon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name
                ),
                const SizedBox(height: 32),
                _buildInputLabel("ENCRYPTED RECOVERY EMAIL"),
                _buildSlabInput(
                  controller: emailController, 
                  hint: "EMERGENCY@RECOVERY.COM", 
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress
                ),
              ],
              
              const SizedBox(height: 48),
              _buildTermsSlab(),
              const SizedBox(height: 64),
              SizedBox(
                width: double.infinity,
                height: 72,
                child: ElevatedButton(
                  onPressed: _isLoading || !_agreeToTerms ? null : () {
                    if (otpVerified) completeRegistration();
                    else if (otpSent) verifyOTP();
                    else sendOTP();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : Text(
                        otpVerified ? "INITIALIZE SANCTUARY" : (otpSent ? "VERIFY IDENTITY" : "BEGIN INITIATION"),
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    text: const TextSpan(
                      text: "ALREADY SECURED? ",
                      style: TextStyle(color: Colors.white10, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                      children: [
                        TextSpan(
                          text: "ACCESS VAULT",
                          style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSlab() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24, height: 24,
            child: Checkbox(
              value: _agreeToTerms,
              onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
              activeColor: AppTheme.accentColor,
              checkColor: Colors.black,
              side: const BorderSide(color: Colors.white10, width: 2),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LegalScreen())),
              child: const Text(
                "I VERIFY MY IDENTITY AND AGREE TO THE DIGITAL LEGACY SOVEREIGNTY DECLARATION.",
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w800, height: 1.6, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }

  Widget _buildSlabInput({required TextEditingController controller, required String hint, required IconData icon, bool enabled = true, TextInputType keyboardType = TextInputType.text, List<TextInputFormatter>? inputFormatters}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppTheme.accentColor.withOpacity(0.4), size: 18),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white10, fontSize: 16, fontWeight: FontWeight.w800),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        ),
      ),
    );
  }
}
