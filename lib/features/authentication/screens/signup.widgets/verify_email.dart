import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nirmal/common/widgets/success_screen/success_screen.dart';
import 'package:nirmal/features/authentication/screens/login/login.dart';
import 'package:nirmal/utils/constants/image_strings.dart';
import 'package:nirmal/utils/constants/size.dart';
import 'package:nirmal/utils/constants/text_strings.dart';
import 'package:nirmal/utils/helpers/helper_functions.dart';

class VerifyEmailScreen extends StatelessWidget {
  final String? email; // Added email parameter
  const VerifyEmailScreen({super.key, this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Get.offAll(() => const LoginScreen()),
            icon: const Icon(CupertinoIcons.clear),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(Tsizes.defaultSpace),
          child: Column(
            children: [
              // Image
              Image(
                image: AssetImage(TImages.verificarionScreen1),
                width: THelperFunction.getScreenWidth(context) * 0.6,
              ),
              const SizedBox(height: Tsizes.spaceBtwSections),

              // Title and subtitle
              Text(
                TTests.confirmemail,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Tsizes.spaceBtwItems),
              Text(
                email ?? 'your email', // Display the passed email or fallback
                style: Theme.of(context).textTheme.labelLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Tsizes.spaceBtwItems),
              Text(
                TTests.confirmEmailSubtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Tsizes.spaceBtwSections),

              // Continue button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.to(() => SuccessScreen(
                    image: TImages.verificarionScreen2,
                    title: TTests.accountCreateTitle,
                    subtitle: TTests.accountCreateSubtitle,
                    onPressed: () => Get.to(() => const LoginScreen()),
                  )),
                  child: Text(TTests.continueText),
                ),
              ),
              const SizedBox(height: Tsizes.spaceBtwItems),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {},
                  child: Text(TTests.resendEmail),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}