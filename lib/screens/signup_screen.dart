import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/screens/auth_widgets.dart';
import 'package:my_first_app/screens/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  bool showPassword = false;
  bool showConfirmPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    otpController.dispose();
    Get.find<AuthController>().cancelPendingSignup();
    super.dispose();
  }

  void _submit(AuthController auth) {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final phoneDigits = phoneController.text.replaceAll(RegExp(r'\D'), '');

    if (email.isEmpty || !email.contains('@')) {
      Get.snackbar('Email required', 'Enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      Get.snackbar(
        'Password too short',
        'Use at least 6 characters for your password.',
      );
      return;
    }
    if (password != confirmPasswordController.text) {
      Get.snackbar('Passwords do not match', 'Check both password fields.');
      return;
    }
    if (phoneDigits.length < 8) {
      Get.snackbar(
        'Phone number required',  
        'Enter a valid mobile number with country code +244.',
      );
      return;
    }

    final phoneNumber = phoneDigits.startsWith('244')
        ? '+$phoneDigits'
        : '+244$phoneDigits';
    auth.signup(email, password, phoneNumber: phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return AuthPageBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 88, 26, 28),
        child: Column(
          children: [
            const Text(
              'Create Account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sign Up',
              style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 70),
            AuthTextField(
              controller: emailController,
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(
                Icons.email_outlined,
                size: 18,
                color: Color(0xFFD5D5D5),
              ),
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: passwordController,
              hintText: 'Special Characters',
              obscureText: !showPassword,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(
                Icons.lock_outline,
                size: 18,
                color: Color(0xFFD5D5D5),
              ),
              suffixIcon: IconButton(
                onPressed: () => setState(() {
                  showPassword = !showPassword;
                }),
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: const Color(0xFFBBBBBB),
                ),
              ),
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: confirmPasswordController,
              hintText: 'Repeat Password',
              obscureText: !showConfirmPassword,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(
                Icons.lock_outline,
                size: 18,
                color: Color(0xFFD5D5D5),
              ),
              suffixIcon: IconButton(
                onPressed: () => setState(() {
                  showConfirmPassword = !showConfirmPassword;
                }),
                icon: Icon(
                  showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  size: 18,
                  color: const Color(0xFFBBBBBB),
                ),
              ),
            ),
            const SizedBox(height: 14),
            AuthTextField(
              controller: phoneController,
              hintText: 'Mobile Number',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              prefix: const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🇦🇴', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    Text(
                      '+244',
                      style: TextStyle(color: Color(0xFF999999), fontSize: 14),
                    ),
                    SizedBox(width: 3),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: authOrange,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            Obx(
              () => auth.isOtpSent.value
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: AuthTextField(
                        controller: otpController,
                        hintText: 'Verification Code',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        prefixIcon: const Icon(
                          Icons.verified_user_outlined,
                          size: 18,
                          color: Color(0xFFD5D5D5),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 52),
            Obx(
              () => AuthPrimaryButton(
                label: auth.isOtpSent.value ? 'VERIFY OTP' : 'NEXT',
                isLoading: auth.isLoading.value,
                onPressed: () {
                  if (auth.isOtpSent.value) {
                    if (otpController.text.trim().isEmpty) {
                      Get.snackbar(
                        'Verification code required',
                        'Enter the code sent to your phone.',
                      );
                    } else {
                      auth.verifyPhoneOtp(otpController.text);
                    }
                  } else {
                    _submit(auth);
                  }
                },
              ),
            ),
            Obx(
              () => auth.isOtpSent.value
                  ? TextButton(
                      onPressed: auth.isLoading.value
                          ? null
                          : () => _submit(auth),
                      child: const Text(
                        'RESEND CODE',
                        style: TextStyle(color: authTeal, fontSize: 12),
                      ),
                    )
                  : Column(
                      children: [
                        const SizedBox(height: 32),
                        const Text(
                          'Or Continue With',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 20),
                        GoogleSignInButton(
                          isLoading: auth.isLoading.value,
                          onPressed: auth.signInWithGoogle,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
                TextButton(
                  onPressed: () => Get.off(() => const LoginScreen()),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'LOGIN',
                    style: TextStyle(
                      color: authTeal,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
