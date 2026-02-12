import 'package:flutter/material.dart';
import '../theme/glassmorphism.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'register_screen.dart';
import '../services/api_service.dart';

class SecureLoginScreen extends StatefulWidget {
  const SecureLoginScreen({Key? key}) : super(key: key);

  @override
  _SecureLoginScreenState createState() => _SecureLoginScreenState();
}

class _SecureLoginScreenState extends State<SecureLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  bool _otpSent = false;
  bool _isLoading = false;

  void _sendOTP() async {
     if (_phoneController.text.length < 10) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter valid mobile number")));
       return;
     }

    setState(() => _isLoading = true);
    try {
      final res = await ApiService().sendOtp(_phoneController.text, 'login');
      if (res['success'] == true) {
        setState(() {
          _otpSent = true;
          _isLoading = false;
        });
        if (res['debug_otp'] != null) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("DEV OTP: ${res['debug_otp']}")));
        } else {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("OTP Sent Successfully")));
        }
      } else {
        throw Exception(res['message']);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _verifyOTP() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().verifyOtp(_phoneController.text, _otpController.text, 'login');
      
      if (res['success'] == true) {
         if (res['user'] != null) {
            if (!mounted) return;
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => SecureDashboardScreen(
                userProfile: res['user']
              ))
            );
         } else if (res['next_step'] == 'register') {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account not found. Please create simple vault first.")));
         }
      } else {
        throw Exception(res['message']);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          // Subtle Apple-like Mesh Gradient
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF2F2F7), 
                Color(0xFFE5E5EA),
                Color(0xFFF2F2F7),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                const Icon(Icons.shield_rounded, size: 80, color: AppTheme.primaryColor),
                const SizedBox(height: 20),
                Text(
                  "Vasihat Nama",
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  "Zero-Knowledge Secure Vault",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 50),

                // Glassmorphism Login Card
                GlassCard(
                  opacity: 0.65,
                  blur: 30,
                  color: Colors.white,
                  borderColor: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _phoneController,
                        icon: Icons.phone_android_rounded,
                        hint: "Mobile Number",
                        enabled: !_otpSent,
                        keyboardType: TextInputType.phone
                      ),
                      if (_otpSent) ...[
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _otpController,
                          icon: Icons.lock_outline,
                          hint: "Enter OTP",
                          obscure: false,
                          keyboardType: TextInputType.number
                        ),
                      ],
                      const SizedBox(height: 30),
                      
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : (_otpSent ? _verifyOTP : _sendOTP),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading 
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : Text(
                                _otpSent ? "Verify & Unlock" : "Get OTP",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const RegisterScreen())
                    );
                  },
                  child: const Text(
                    "Create New Secure Vault",
                    style: TextStyle(color: AppTheme.primaryColor),
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
    required IconData icon, 
    required String hint, 
    bool obscure = false,
    bool enabled = true,
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1), // Light gray background for inputs
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        enabled: enabled,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
