import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController pageController = PageController();
  final currentPage = 0.obs;

  final List<Map<String, String>> pages = [
    {
      'image': 'assets/one.png',
      'title': 'ONLINE PAYMENT',
      'description':
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
          'Pharetra elementum elementum massa, viverra. Ut turpis '
          'consectetur.',
    },
    {
      'image': 'assets/two.png',
      'title': 'Work From Anywhere',
      'description': 'Access your SaaS platform anytime and anywhere.',
    },
    {
      'image': 'assets/three.png',
      'title': 'Grow Your Business',
      'description': 'Track performance and make smarter business decisions.',
    },
  ];

  void finishOnboarding() {
    Get.find<AuthController>().storage.write('onboarding_done', true);
    Get.offAll(() => const LoginScreen());
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF1B9EAF);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: backgroundColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final panelTop = constraints.maxHeight * 0.58;

              return Stack(
                children: [
                  SizedBox(
                    height: panelTop,
                    width: double.infinity,
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: pages.length,
                      onPageChanged: (index) => currentPage.value = index,
                      itemBuilder: (context, index) {
                        return Align(
                          alignment: const Alignment(0, 0.2),
                          child: Image.asset(
                            pages[index]['image']!,
                            width: constraints.maxWidth * 0.80,
                            fit: BoxFit.contain,
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: panelTop,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipPath(
                      clipper: _OnboardingPanelClipper(),
                      child: Container(
                        color: Colors.white,
                        padding: EdgeInsets.fromLTRB(
                          20,
                          58,
                          20,
                          MediaQuery.viewPaddingOf(context).bottom + 20,
                        ),
                        child: Obx(() {
                          final page = pages[currentPage.value];

                          return Column(
                            children: [
                              Text(
                                page['title']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFFF4A900),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 34),
                              Text(
                                page['description']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF929292),
                                  fontSize: 12,
                                  height: 1.45,
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                height: 54,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    TextButton(
                                      onPressed: finishOnboarding,
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFFF4A900,
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      child: const Text('Skip>>'),
                                    ),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Semantics(
                                        label:
                                            currentPage.value ==
                                                pages.length - 1
                                            ? 'Get started'
                                            : 'Next page',
                                        button: true,
                                        child: InkWell(
                                          onTap: () {
                                            if (currentPage.value ==
                                                pages.length - 1) {
                                              finishOnboarding();
                                            } else {
                                              pageController.nextPage(
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          },
                                          customBorder: const CircleBorder(),
                                          child: Container(
                                            width: 52,
                                            height: 52,
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(
                                                  0xFFF4A900,
                                                ).withValues(alpha: 0.45),
                                              ),
                                            ),
                                            child: DecoratedBox(
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFF4A900),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.arrow_forward,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OnboardingPanelClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const cornerHeight = 38.0;
    const cornerWidth = 42.0;
    return Path()
      ..moveTo(0, cornerHeight)
      ..cubicTo(0, 17, 18, 0, cornerWidth, 0)
      ..lineTo(size.width - cornerWidth, 0)
      ..cubicTo(size.width - 18, 0, size.width, 17, size.width, cornerHeight)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant _OnboardingPanelClipper oldClipper) => false;
}
