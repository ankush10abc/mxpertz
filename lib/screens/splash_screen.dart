import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/screens/home_screen.dart';
import 'package:my_first_app/screens/login_screen.dart';
import 'package:my_first_app/screens/onboarding_screen.dart' show OnboardingScreen;

class SplashScreen extends StatefulWidget {
   SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    navigateUser();
  }

  Future<void> navigateUser() async {
    await Future.delayed(const Duration(seconds: 2));

    final auth = Get.find<AuthController>();
    final onboardingDone =
        auth.storage.read('onboarding_done') ?? false;

    if (auth.currentUser != null) {
      Get.offAll(() => const HomeScreen());
    } else if (onboardingDone) {
      Get.offAll(() => const LoginScreen());
    } else {
      Get.offAll(() => const OnboardingScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,  
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
                        Image.asset(
                'assets/splash.png',
                fit: BoxFit.contain,
                width: 200,
                height: 200,
              ),
            SizedBox(height: 15),
            
          ],
        ),
      ),
    );
  }
}