import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:nirmal/common/styles/spacing_style.dart';
import 'package:nirmal/features/authentication/screens/login/login_controller.dart';
import 'package:nirmal/features/authentication/screens/signup.widgets/signup.dart';
import 'package:nirmal/utils/constants/colors.dart';
import 'package:nirmal/utils/constants/image_strings.dart';
import 'package:nirmal/utils/constants/size.dart';
import 'package:nirmal/utils/constants/text_strings.dart';
import 'package:nirmal/utils/helpers/helper_functions.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller is already registered as permanent in main.dart
    final controller = Get.find<LoginController>();
    final dark = THelperFunction.isDarkMode(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: TSpacingStyle.paddingWithAppBarHeight,
          child: Form(
            key: controller.loginFormKey,
            child: Column(
              children: [

                // ── Header ──────────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image(
                      height: 150,
                      image: AssetImage(dark ? TImages.darkAppLogo : TImages.lightAppLogo),
                    ),
                    Text(TTests.loginTitle,
                        style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: Tsizes.sm),
                    Text(TTests.loginSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),

                // ── Form ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: Tsizes.spaceBtwSections),
                  child: Column(
                    children: [

                      // Email
                      TextFormField(
                        controller: controller.email,
                        validator: controller.validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Iconsax.direct_right),
                          labelText: TTests.email,
                        ),
                      ),
                      const SizedBox(height: Tsizes.spaceBtwInputFields),

                      // Password
                      Obx(() => TextFormField(
                        controller: controller.password,
                        validator: controller.validatePassword,
                        obscureText: controller.obscurePassword.value,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Iconsax.password_check),
                          labelText: TTests.password,
                          suffixIcon: IconButton(
                            icon: Icon(controller.obscurePassword.value
                                ? Iconsax.eye_slash
                                : Iconsax.eye),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                        ),
                      )),
                      const SizedBox(height: Tsizes.spaceBtwInputFields / 2),

                      // Remember me & Forgot password
                      Obx(() => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: controller.rememberMe.value,
                                onChanged: (val) =>
                                    controller.rememberMe.value = val ?? false,
                              ),
                              const Text(TTests.rememberMe),
                            ],
                          ),
                          TextButton(
                            onPressed: () => _showForgotPasswordDialog(context, controller),
                            child: const Text(TTests.forgotPassword),
                          ),
                        ],
                      )),
                      const SizedBox(height: Tsizes.spaceBtwSections),

                      // Sign in button – calls controller.login()
                      Obx(() => SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : controller.login,
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(TTests.login),
                        ),
                      )),
                      const SizedBox(height: Tsizes.spaceBtwSections),

                      // Create account
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Get.to(() => const SignupScreen()),
                          child: Text(TTests.signup),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Divider ─────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                        child: Divider(
                            color: dark ? TColors.darkGrey : TColors.grey,
                            thickness: 0.5,
                            indent: 60,
                            endIndent: 5)),
                    Text("  ${TTests.orSignInWith}  ",
                        style: Theme.of(context).textTheme.labelMedium),
                    Flexible(
                        child: Divider(
                            color: dark ? TColors.darkGrey : TColors.grey,
                            thickness: 0.5,
                            indent: 5,
                            endIndent: 60)),
                  ],
                ),
                const SizedBox(height: Tsizes.spaceBtwSections),

                // ── Social buttons (UI only) ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialButton(
                        imagePath: TImages.google,
                        onPressed: () => Get.snackbar(
                            'Info', 'Social login not available')),
                    const SizedBox(width: Tsizes.spaceBtwItems),
                    _SocialButton(
                        imagePath: TImages.facebook,
                        onPressed: () => Get.snackbar(
                            'Info', 'Social login not available')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog(
      BuildContext context, LoginController controller) {
    final resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: resetEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Enter your email',
            prefixIcon: Icon(Iconsax.direct_right),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.sendPasswordResetEmail(resetEmailController.text);
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String imagePath;
  final VoidCallback onPressed;
  const _SocialButton({required this.imagePath, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: TColors.grey),
          borderRadius: BorderRadius.circular(100)),
      child: IconButton(
        onPressed: onPressed,
        icon: Image(
            width: Tsizes.iconMd,
            height: Tsizes.iconMd,
            image: AssetImage(imagePath)),
      ),
    );
  }
}