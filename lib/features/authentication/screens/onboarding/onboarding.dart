import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nirmal/features/authentication/controllers.onboarding/onboarding_conroller.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:iconsax/iconsax.dart';

// Constants and utilities (make sure these paths are correct in your project)
import 'package:nirmal/utils/constants/image_strings.dart';
import 'package:nirmal/utils/constants/size.dart';
import 'package:nirmal/utils/constants/text_strings.dart';
import 'package:nirmal/utils/constants/colors.dart';
import 'package:nirmal/utils/device/device_utility.dart';
import 'package:nirmal/utils/helpers/helper_functions.dart';

// -------------------- Main Onboarding Screen --------------------
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller
    final controller = Get.put(OnboardingController());

    return Scaffold(
      body: Stack(
        children: [
          // PageView
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.updatePageIndicator,
            children: const [
              OnBoardingPage(
                image: TImages.OnboardingImages1,
                title: TTests.onBordingTitle1,    // Note: 'TTests' might be a typo, check your constants
                subTitle: TTests.onBordingSubTitle1,
              ),
              OnBoardingPage(
                image: TImages.OnboardingImages2,
                title: TTests.onBordingTitle2,
                subTitle: TTests.onBordingSubTitle2,
              ),
              OnBoardingPage(
                image: TImages.OnboardingImages3,
                title: TTests.onBordingTitle3,
                subTitle: TTests.onBordingSubTitle3,
              ),
            ],
          ),

          // Skip button
          const OnBoardingSkip(),

          // Dot navigation
          const OnBoardingDotNavigation(),

          // Circular next button
          const OnBoardingNextButton(),
        ],
      ),
    );
  }
}

// -------------------- Skip Button --------------------
class OnBoardingSkip extends StatelessWidget {
  const OnBoardingSkip({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OnboardingController.instance;

    return Positioned(
      top: TDeviceUtils.getAppBarHeight(),
      right: Tsizes.defaultSpace,
      child: TextButton(
        onPressed: controller.skipPage,
        child: const Text('Skip'),
      ),
    );
  }
}

// -------------------- Dot Navigation --------------------
class OnBoardingDotNavigation extends StatelessWidget {
  const OnBoardingDotNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OnboardingController.instance;
    final dark = THelperFunction.isDarkMode(context);

    return Positioned(
      bottom: TDeviceUtils.getBottomNavigationBarHeight() + 25,
      left: Tsizes.defaultSpace,
      child: SmoothPageIndicator(
        controller: controller.pageController,
        count: 3,
        onDotClicked: controller.dotNavigationClick,
        effect: ExpandingDotsEffect(
          activeDotColor: dark ? TColors.light : TColors.dark,
          dotHeight: 6,
          dotWidth: 6,
          expansionFactor: 3,
        ),
      ),
    );
  }
}

// -------------------- Next Button --------------------
class OnBoardingNextButton extends StatelessWidget {
  const OnBoardingNextButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OnboardingController.instance;
    final dark = THelperFunction.isDarkMode(context);

    return Positioned(
      right: Tsizes.defaultSpace,
      bottom: TDeviceUtils.getBottomNavigationBarHeight(),
      child: ElevatedButton(
        onPressed: controller.nextPage,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
          backgroundColor: dark ? TColors.light : TColors.dark,
          foregroundColor: dark ? TColors.dark : TColors.light,
        ),
        // ✅ No side effects here – only UI logic
        child: Obx(() {
          return Icon(controller.currentPageIndex.value == 2
              ? Iconsax.tick_circle
              : Iconsax.arrow_right_3);
        }),
      ),
    );
  }
}

// -------------------- Page Content --------------------
class OnBoardingPage extends StatelessWidget {
  final String image;
  final String title;
  final String subTitle;

  const OnBoardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.subTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Tsizes.defaultSpace),
      child: Column(
        children: [
          Image(
            width: THelperFunction.getScreenWidth(context) * 0.8,
            height: THelperFunction.getScreenHeight(context) * 0.6,
            image: AssetImage(image),
            fit: BoxFit.contain,
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Tsizes.spaceBtwItems),
          Text(
            subTitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}