import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/screens/auth_widgets.dart';
import 'package:my_first_app/screens/onboarding_screen.dart';
import 'package:my_first_app/screens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool useEmailPassword = false;

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String _internationalPhoneNumber() {
    final digits = phoneController.text.replaceAll(RegExp(r'\D'), '');
    return digits.startsWith('244') ? '+$digits' : '+244$digits';
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return AuthPageBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 6, 26, 24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Close',
                onPressed: () {
                  auth.cancelPendingSignup();
                  Get.offAll(() => const OnboardingScreen());
                },
                icon: const Icon(Icons.close, size: 22),
              ),
            ),
            const SizedBox(height: 8),
            const LuxeLoftWordmark(),
            const SizedBox(height: 68),
            const Text(
              'Welcome Back!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              useEmailPassword ? 'Login with your email' : 'Login to continue',
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 34),
            if (useEmailPassword) ...[
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
                hintText: 'Password',
                obscureText: true,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: Color(0xFFD5D5D5),
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => AuthPrimaryButton(
                  label: 'LOGIN',
                  isLoading: auth.isLoading.value,
                  onPressed: () =>
                      auth.login(emailController.text, passwordController.text),
                ),
              ),
            ] else ...[
              AuthTextField(
                controller: phoneController,
                hintText: 'Phone Number',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(
                  Icons.phone_iphone,
                  size: 18,
                  color: Color(0xFFD5D5D5),
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
              const SizedBox(height: 20),
              Obx(
                () => AuthPrimaryButton(
                  label: auth.isOtpSent.value ? 'VERIFY OTP' : 'GET OTP',
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
                      final digits = phoneController.text.replaceAll(
                        RegExp(r'\D'),
                        '',
                      );
                      if (digits.length < 8) {
                        Get.snackbar(
                          'Phone number required',
                          'Enter a valid phone number to receive an OTP.',
                        );
                        return;
                      }
                      auth.requestPhoneOtp(_internationalPhoneNumber());
                    }
                  },
                ),
              ),
            ],
            const SizedBox(height: 82),
            const Text(
              'Or Continue With',
              style: TextStyle(fontSize: 12, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 40),
            Obx(
              () => GoogleSignInButton(
                isLoading: auth.isLoading.value,
                onPressed: auth.signInWithGoogle,
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: () {
                setState(() {
                  useEmailPassword = !useEmailPassword;
                });
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                useEmailPassword
                    ? 'Sign in with phone number instead'
                    : 'Use email and password instead',
                style: const TextStyle(color: authTeal, fontSize: 13),
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
                TextButton(
                  onPressed: () {
                    auth.cancelPendingSignup();
                    Get.to(() => const SignupScreen());
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'SIGN UP',
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
