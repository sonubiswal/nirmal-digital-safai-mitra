import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nirmal/utils/constants/size.dart';
import 'package:nirmal/utils/constants/text_strings.dart';
import 'package:nirmal/utils/constants/image_strings.dart';
import 'package:nirmal/utils/helpers/helper_functions.dart';
import 'package:flutter/cupertino.dart';

class ResetPassword extends StatelessWidget {
  const ResetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(CupertinoIcons.clear),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(Tsizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Changed to center
          children: [
            // Image
            Image(
              image: AssetImage(TImages.passwardConfig),
              width: THelperFunction.getScreenWidth(context) * 0.6,
            ),
            const SizedBox(height: Tsizes.spaceBtwSections),

            // Title
            Text(
              TTests.changePasswordTitle,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Tsizes.spaceBtwItems),

            // Subtitle
            Text(
              TTests.changePasswordSubtitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Tsizes.spaceBtwSections),

            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Add functionality
                },
                child: Text(TTests.done),
              ),
            ),
            const SizedBox(height: Tsizes.spaceBtwItems),

            // Resend email button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  // Add functionality
                },
                child: Text(TTests.resendEmail),
              ),
            ),
          ],
        ),
      ),
    );
  }
}