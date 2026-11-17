import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/screens/auth_widgets.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final otpController = TextEditingController();

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  void _verify(AuthController auth) {
    final code = otpController.text.trim();
    if (code.length != 6) {
      Get.snackbar(
        'Verification code required',
        'Enter the 6-digit code sent to your phone.',
      );
      return;
    }

    auth.verifyPhoneOtp(code);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: IconButton(
                          tooltip: 'Back',
                          onPressed: Get.back,
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFE8F6F7),
                            foregroundColor: authTeal,
                          ),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 23),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'OTP Verification',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF20252B),
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Enter the 6-digit verification code we just sent to your phone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF8A939E),
                        fontSize: 17,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _OtpCodeInput(controller: otpController),
                    const SizedBox(height: 44),
                    Obx(
                      () => SizedBox(
                        height: 58,
                        child: FilledButton(
                          onPressed: auth.isLoading.value
                              ? null
                              : () => _verify(auth),
                          style: FilledButton.styleFrom(
                            backgroundColor: authTeal,
                            disabledBackgroundColor: authTeal.withValues(
                              alpha: 0.55,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          child: auth.isLoading.value
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'VERIFY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpCodeInput extends StatefulWidget {
  const _OtpCodeInput({required this.controller});

  final TextEditingController controller;

  @override
  State<_OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<_OtpCodeInput> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleCodeChanged);
  }

  @override
  void didUpdateWidget(covariant _OtpCodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleCodeChanged);
      widget.controller.addListener(_handleCodeChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleCodeChanged);
    super.dispose();
  }

  void _handleCodeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;

    return SizedBox(
      height: 62,
      child: Stack(
        children: [
          Row(
            children: List.generate(6, (index) {
              final digit = index < code.length ? code[index] : '';
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 5 ? 0 : 9),
                  child: Container(
                    height: 62,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      digit,
                      style: const TextStyle(
                        color: Color(0xFF20252B),
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          Semantics(
            label: '6-digit verification code',
            textField: true,
            child: TextField(
              controller: widget.controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              style: const TextStyle(color: Colors.transparent, fontSize: 1),
              cursorColor: Colors.transparent,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
