
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart'; // ✅ Added import
import 'package:nirmal/utils/constants/size.dart';
import 'package:nirmal/utils/constants/colors.dart'; // ✅ Added import for TColors
import 'package:nirmal/utils/device/device_utility.dart';


class OnBoardingDotNavigation extends StatelessWidget {
  const OnBoardingDotNavigation({
    super.key,
    required PageController pageController,
  }) : _pageController = pageController;

  final PageController _pageController;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: TDeviceUtils.getBottomNavigationBarHeight() + 25,
      left: Tsizes.defaultSpace,
      child: SmoothPageIndicator(
        controller: _pageController, // ✅ Use the same controller
        count: 3,
        effect: const ExpandingDotsEffect(
          activeDotColor: TColors.dark, // ✅ Fixed color reference
          dotHeight: 6, // ✅ Fixed parameter name
        ),
      ),
    );
  }
}