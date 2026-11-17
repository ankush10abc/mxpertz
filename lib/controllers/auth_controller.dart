import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:my_first_app/screens/home_screen.dart';
import 'package:my_first_app/screens/login_screen.dart';
import 'package:my_first_app/screens/otp_verification_screen.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  final isLoading = false.obs;
  final isOtpSent = false.obs;
  final storage = GetStorage();

  String? _verificationId;
  String? _phoneNumber;
  String? _pendingSignupEmail;
  String? _pendingSignupPassword;
  bool _googleInitialized = false;

  User? get currentUser => _auth.currentUser;

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = result.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Firebase did not return a signed-in user.',
        );
      }
      await _saveUserProfile(user);
      Get.offAll(() => const HomeScreen());
      Get.snackbar('Signed in', 'Your Google profile was saved successfully.');
    } on FirebaseAuthException catch (error) {
      _showError('Login Failed', error.message ?? 'Please try again.');
    } on FirebaseException catch (error) {
      _showError(
        'Profile Load Failed',
        error.message ?? 'Could not load your profile.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signup(
    String email,
    String password, {
    required String phoneNumber,
  }) async {
    _pendingSignupEmail = email.trim();
    _pendingSignupPassword = password;
    await requestPhoneOtp(phoneNumber);
  }

  void cancelPendingSignup() {
    _pendingSignupEmail = null;
    _pendingSignupPassword = null;
    _verificationId = null;
    _phoneNumber = null;
    isOtpSent.value = false;
  }

  Future<void> requestPhoneOtp(String phoneNumber) async {
    _phoneNumber = phoneNumber;
    _verificationId = null;
    isOtpSent.value = false;

    try {
      isLoading.value = true;
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) {
          _finishPhoneSignIn(credential, phoneNumber);
        },
        verificationFailed: (error) {
          isLoading.value = false;
          _showError(
            'Phone Verification Failed',
            error.message ?? 'Try again.',
          );
        },
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          isOtpSent.value = true;
          isLoading.value = false;
          Get.to(() => const OtpVerificationScreen());
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
          isLoading.value = false;
        },
      );
    } on FirebaseAuthException catch (error) {
      _showError('Phone Verification Failed', error.message ?? 'Try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyPhoneOtp(String smsCode) async {
    final verificationId = _verificationId;
    if (verificationId == null) {
      _showError('Verification Required', 'Request a new code and try again.');
      return;
    }

    try {
      isLoading.value = true;
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      await _finishPhoneSignIn(credential, _phoneNumber);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _finishPhoneSignIn(
    PhoneAuthCredential credential,
    String? phoneNumber,
  ) async {
    try {
      isLoading.value = true;
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'phone-sign-in-failed',
          message: 'Firebase did not return a signed-in user.',
        );
      }

      final signupEmail = _pendingSignupEmail;
      final signupPassword = _pendingSignupPassword;
      if (signupEmail != null && signupPassword != null) {
        final linkedResult = await user.linkWithCredential(
          EmailAuthProvider.credential(
            email: signupEmail,
            password: signupPassword,
          ),
        );
        final linkedUser = linkedResult.user;
        if (linkedUser == null) {
          throw FirebaseAuthException(
            code: 'signup-link-failed',
            message: 'Firebase did not return the linked account.',
          );
        }
        await _saveUserProfile(linkedUser, phoneNumber: phoneNumber);
        cancelPendingSignup();
        Get.offAll(() => const HomeScreen());
        Get.snackbar(
          'Account created',
          'Your profile details were saved successfully.',
        );
        return;
      }

      await _saveUserProfile(user, phoneNumber: phoneNumber);
      isOtpSent.value = false;
      Get.offAll(() => const HomeScreen());
    } on FirebaseAuthException catch (error) {
      _showError('Phone Sign-In Failed', error.message ?? 'Please try again.');
    } on FirebaseException catch (error) {
      _showError(
        'Profile Load Failed',
        error.message ?? 'Could not load your profile.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      if (!_googleInitialized) {
        await _googleSignIn.initialize();
        _googleInitialized = true;
      }

      final googleUser = await _googleSignIn.authenticate();
      final idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message:
              'Google sign-in did not return an ID token. Check your Firebase '
              'Google provider and Android OAuth client configuration.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-failed',
          message: 'Firebase did not return a signed-in user.',
        );
      }
      await _saveUserProfile(user);
      Get.offAll(() => const HomeScreen());
    } on GoogleSignInException catch (error) {
      if (error.code != GoogleSignInExceptionCode.canceled) {
        _showError(
          'Google Sign-In Failed',
          error.description ?? 'Please check your Google sign-in setup.',
        );
      }
    } on FirebaseAuthException catch (error) {
      _showError('Google Sign-In Failed', error.message ?? 'Please try again.');
    } on FirebaseException catch (error) {
      _showError(
        'Profile Save Failed',
        error.message ?? 'Could not save your profile.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveUserProfile(User user, {String? phoneNumber}) async {
    final profileReference = _firestore.collection('users').doc(user.uid);
    final currentProfile = await profileReference.get();
    final resolvedPhoneNumber = user.phoneNumber ?? phoneNumber;

    await profileReference.set({
      if (!currentProfile.exists) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (user.email != null) 'email': user.email,
      if (user.displayName != null) 'displayName': user.displayName,
      if (resolvedPhoneNumber != null) 'phoneNumber': resolvedPhoneNumber,
    }, SetOptions(merge: true));
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      try {
        await _googleSignIn.signOut();
      } on GoogleSignInException catch (error) {
        _showError(
          'Google Sign-Out Failed',
          error.description ?? 'Your Firebase session was signed out.',
        );
      }
      Get.offAll(() => const LoginScreen());
    } on FirebaseAuthException catch (error) {
      _showError('Sign-Out Failed', error.message ?? 'Please try again.');
    }
  }

  void _showError(String title, String message) {
    Get.snackbar(title, message);
  }
}
