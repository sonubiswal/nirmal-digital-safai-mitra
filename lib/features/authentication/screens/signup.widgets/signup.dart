import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:nirmal/features/authentication/screens/signup.widgets/signup_controller.dart';
import 'package:nirmal/utils/constants/colors.dart';
import 'package:nirmal/utils/constants/size.dart';
import 'package:nirmal/utils/constants/text_strings.dart';
import 'package:nirmal/utils/helpers/helper_functions.dart';


class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunction.isDarkMode(context);
    final controller = Get.put(SignupController());

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(Tsizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(TTests.signupTitle, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: Tsizes.spaceBtwSections),
              Form(
                key: controller.signupFormKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller.firstName,
                            decoration: const InputDecoration(labelText: TTests.firstName, prefixIcon: Icon(Iconsax.user)),
                            validator: (v) => v == null || v.isEmpty ? 'First name required' : null,
                          ),
                        ),
                        const SizedBox(width: Tsizes.spaceBtwInputFields),
                        Expanded(
                          child: TextFormField(
                            controller: controller.lastName,
                            decoration: const InputDecoration(labelText: TTests.lastName, prefixIcon: Icon(Iconsax.user)),
                            validator: (v) => v == null || v.isEmpty ? 'Last name required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Tsizes.spaceBtwInputFields),
                    TextFormField(
                      controller: controller.username,
                      decoration: const InputDecoration(labelText: TTests.username, prefixIcon: Icon(Iconsax.user_edit)),
                      validator: (v) => v == null || v.isEmpty ? 'Username required' : null,
                    ),
                    const SizedBox(height: Tsizes.spaceBtwInputFields),
                    TextFormField(
                      controller: controller.email,
                      decoration: const InputDecoration(labelText: TTests.email, prefixIcon: Icon(Iconsax.direct)),
                      validator: (v) => v == null || v.isEmpty ? 'Email required' : null,
                    ),
                    const SizedBox(height: Tsizes.spaceBtwInputFields),
                    TextFormField(
                      controller: controller.phoneNumber,
                      decoration: const InputDecoration(labelText: TTests.phoneNumber, prefixIcon: Icon(Iconsax.call)),
                      validator: (v) => v == null || v.isEmpty ? 'Phone required' : null,
                    ),
                    const SizedBox(height: Tsizes.spaceBtwInputFields),
                    Obx(
                      () => TextFormField(
                        controller: controller.password,
                        obscureText: controller.obscurePassword.value,
                        decoration: InputDecoration(
                          labelText: TTests.password,
                          prefixIcon: const Icon(Iconsax.password_check),
                          suffixIcon: IconButton(
                            icon: Icon(controller.obscurePassword.value ? Iconsax.eye_slash : Iconsax.eye),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Password required' : null,
                      ),
                    ),
                    const SizedBox(height: Tsizes.spaceBtwSections),
                    Row(
                      children: [
                        Obx(() => Checkbox(
                          value: controller.isPrivacyAccepted.value,
                          onChanged: (v) => controller.isPrivacyAccepted.value = v ?? false,
                        )),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: '${TTests.agreeTo} ', style: Theme.of(context).textTheme.bodySmall),
                                TextSpan(text: TTests.privacyPolicy, style: Theme.of(context).textTheme.bodyMedium!.apply(color: dark ? TColors.light : TColors.primary, decoration: TextDecoration.underline)),
                                const TextSpan(text: ' and '),
                                TextSpan(text: TTests.termsOfService, style: Theme.of(context).textTheme.bodyMedium!.apply(color: dark ? TColors.light : TColors.primary, decoration: TextDecoration.underline)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Tsizes.spaceBtwSections),
                    SizedBox(
                      width: double.infinity,
                      child: Obx(() => ElevatedButton(
                        onPressed: controller.isLoading.value ? null : controller.signup,
                        child: controller.isLoading.value ? const CircularProgressIndicator(color: Colors.white) : const Text(TTests.signup),
                      )),
                    ),
                  ],
                ),
              ),
              // ... social buttons (same as login screen)
            ],
          ),
        ),
      ),
    );
  }
}