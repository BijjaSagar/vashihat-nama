import 'package:flutter/material.dart';
import 'package:vasihat_nama/screens/dashboard_screen.dart';
import '../theme/glassmorphism.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

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

  void sendOTP() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().sendOtp(phoneController.text, 'register');
      if (res['success'] == true) {
        setState(() {
          otpSent = true;
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
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error sending OTP: $e")));
    }
  }

  Future<void> verifyOTP() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().verifyOtp(phoneController.text, otpController.text, 'register');
      
      if (res['success'] == true) {
         setState(() {
           otpVerified = true; // Show profile fields
           _isLoading = false;
         });
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mobile Verified. Please details.")));
      } else {
        throw Exception(res['message']);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Verification Failed: $e")));
    }
  }

  Future<void> completeRegistration() async {
    if (nameController.text.isEmpty || emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all details")));
      return;
    }

    setState(() => _isLoading = true);
    try {
        // Generate Keys (Mocked for now - in real app use encryption lib)
        // In reality, we should generate these on the device securely
        String publicKey = "mock_public_key_${DateTime.now().millisecondsSinceEpoch}";
        String encryptedPrivateKey = "mock_encrypted_private_key_SECRET";

        // Call Backend to Register User
        final registeredUser = await ApiService().registerUser(
          phoneController.text,
          publicKey, 
          encryptedPrivateKey,
          nameController.text,
          emailController.text
        );
        
        if (!mounted) return;
        navigateToDashboard(registeredUser['id']);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Registration Failed: $e")));
    }
  }

  void navigateToDashboard(dynamic userId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => SecureDashboardScreen(
        userProfile: {
          'id': userId, // CRITICAL: Pass the ID
          'name': nameController.text,
          'email': emailController.text,
          'mobile_number': phoneController.text, // CORRECT KEY
        }
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: const BoxDecoration(
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
                const Icon(Icons.person_add_alt_1_rounded, size: 80, color: AppTheme.primaryColor),
                const SizedBox(height: 20),
                Text(
                    "Create Account",
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    ),
                ),
                Text(
                    "Secure your legacy today",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    ),
                ),
                const SizedBox(height: 40),

                // Glass Card for Input
                GlassCard(
                    opacity: 0.65,
                    blur: 30,
                    color: Colors.white,
                    borderColor: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(24),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                    children: [
                        if (!otpVerified) ...[
                          _buildTextField(
                          controller: phoneController,
                          icon: Icons.phone_android_rounded,
                          hint: "Phone Number (10 digits)",
                          enabled: !otpSent,
                          keyboardType: TextInputType.phone,
                          ),
                          if (otpSent) ...[
                            const SizedBox(height: 20),
                            _buildTextField(
                                controller: otpController,
                                icon: Icons.lock_clock_rounded,
                                hint: "Enter OTP",
                                keyboardType: TextInputType.number,
                            ),
                          ],
                        ] else ...[
                           // Profile Fields
                           _buildTextField(
                             controller: nameController, 
                             icon: Icons.person, 
                             hint: "Full Name",
                             keyboardType: TextInputType.name
                           ),
                           const SizedBox(height: 20),
                           _buildTextField(
                             controller: emailController, 
                             icon: Icons.email, 
                             hint: "Email Address",
                             keyboardType: TextInputType.emailAddress
                           ),
                        ],
                        const SizedBox(height: 30),

                        // Action Button
                        SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                            onPressed: _isLoading ? null : () {
                              if (otpVerified) {
                                completeRegistration();
                              } else if (otpSent) {
                                verifyOTP();
                              } else {
                                sendOTP();
                              }
                            },
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
                                otpVerified ? "Complete Registration" : (otpSent ? "Verify OTP" : "Send OTP"),
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
                
                const SizedBox(height: 20),
                TextButton(
                    onPressed: () {
                        // Navigate to Login if account exists
                        Navigator.pop(context);
                    },
                    child: const Text(
                    "Already have an account? Login",
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
    required TextEditingController controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: TextField(
        controller: controller,
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
