import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'main_navigation_shell.dart';
import 'register_screen.dart';
import '../services/api_service.dart';
import 'package:local_auth/local_auth.dart';

class SecureLoginScreen extends StatefulWidget {
  const SecureLoginScreen({super.key});

  @override
  _SecureLoginScreenState createState() => _SecureLoginScreenState();
}

class _SecureLoginScreenState extends State<SecureLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  bool _otpSent = false;
  bool _isLoading = false;
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userProfileStr = prefs.getString('userProfile');

    if (userProfileStr != null) {
      bool authenticated = false;
      try {
        final bool canAuthenticate = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
        if (canAuthenticate) {
          authenticated = await _auth.authenticate(
            localizedReason: 'SCAN BIOMETRICS TO UNLOCK SENTINEL VAULT',
          );
        } else {
          authenticated = true; 
        }
      } catch (e) {
        authenticated = false; 
      }

      if (authenticated && mounted) {
        final userProfile = jsonDecode(userProfileStr);
        
        // Log biometric login
        try {
          ApiService().logActivity(
            userId: userProfile['id'],
            action: 'BIOMETRIC_ACCESS',
            details: {'method': 'biometric_unlock', 'timestamp': DateTime.now().toIso8601String()}
          );
        } catch (e) {
          debugPrint("Logging failed: $e");
        }

        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => MainNavigationShell(
            userId: userProfile['id']
          ))
        );
      }
    }
  }

  void _sendOTP() async {
    if (_phoneController.text.length < 10) return;
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().sendOtp(_phoneController.text, 'login');
      if (res['success'] == true) {
        setState(() {
          _otpSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _verifyOTP() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().verifyOtp(_phoneController.text, _otpController.text, 'login');
      if (res['success'] == true && res['user'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userProfile', jsonEncode(res['user']));
        if (res['token'] != null) await prefs.setString('authToken', res['token']);

        // Log successful login
        try {
          await ApiService().logActivity(
            userId: res['user']['id'],
            action: 'VAULT_ACCESS',
            details: {'method': 'otp_verification', 'timestamp': DateTime.now().toIso8601String()}
          );
        } catch (e) {
          debugPrint("Logging failed: $e");
        }

        if (mounted) {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => MainNavigationShell(userId: res['user']['id']))
          );
        }
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
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.accentColor.withOpacity(0.1)),
                  ),
                  child: const Icon(Icons.shield_rounded, size: 48, color: AppTheme.accentColor),
                ),
                const SizedBox(height: 48),
                const Text("ACCESS GATEWAY", style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 12),
                const Text("SENTINEL", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1)),
                const SizedBox(height: 64),
                _buildInputLabel("SECURE MOBILE IDENTIFIER"),
                _buildSlabTextField(
                  controller: _phoneController,
                  hint: "000 000 0000",
                  enabled: !_otpSent,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  icon: Icons.phone_android_rounded,
                ),
                if (_otpSent) ...[
                  const SizedBox(height: 32),
                  _buildInputLabel("AUTHORIZATION CODE"),
                  _buildSlabTextField(
                    controller: _otpController,
                    hint: "000 000",
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                    icon: Icons.lock_open_rounded,
                  ),
                ],
                const SizedBox(height: 64),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : (_otpSent ? _verifyOTP : _sendOTP),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(_otpSent ? "UNLOCK VAULT" : "REQUEST ACCESS CODE", style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                    child: RichText(
                      text: const TextSpan(
                        text: "NEW USER? ",
                        style: TextStyle(color: Colors.white10, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                        children: [
                          TextSpan(
                            text: "INITIALIZE SANCTUARY",
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
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
    );
  }

  Widget _buildSlabTextField({
    required TextEditingController controller, 
    required String hint, 
    bool enabled = true, 
    TextInputType keyboardType = TextInputType.text, 
    List<TextInputFormatter>? inputFormatters,
    required IconData icon,
  }) {
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
