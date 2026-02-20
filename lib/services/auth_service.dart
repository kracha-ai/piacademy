import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. Send OTP to the mobile number
  Future<void> sendOtp(String mobile, Function(String, int?) codeSent) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: '+91$mobile',
      verificationCompleted: (PhoneAuthCredential credential) async {
        // This happens automatically on some Android phones
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseException e) {
        print("Verification Failed: ${e.message}");
      },
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // 2. Verify the OTP entered by the student
  Future<UserCredential?> verifyOtp(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Error verifying OTP: $e");
      return null;
    }
  }

  // 3. Email/Password Login
  Future<UserCredential?> loginWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print("Login failed: $e");
      return null;
    }
  }
}