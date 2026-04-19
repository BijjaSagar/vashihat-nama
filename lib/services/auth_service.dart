import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> sendOTP(String phoneNumber) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print("OTP Verification Failed: ${e.message}");
      },
      codeSent: (String verificationId, int? resendToken) async {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString("verificationId", verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<bool> verifyOTP(String smsCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? verificationId = prefs.getString("verificationId");

    if (verificationId == null) return false;

    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    try {
      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      print("OTP Verification Failed: $e");
      return false;
    }
  }
}
