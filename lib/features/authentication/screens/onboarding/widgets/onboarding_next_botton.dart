
import 'package:flutter/material.dart';

import 'package:iconsax/iconsax.dart';

import 'package:nirmal/utils/constants/size.dart';

import 'package:nirmal/utils/device/device_utility.dart';



class OnBoardingNextButton extends StatelessWidget {
  const OnBoardingNextButton({
    super.key,
    required PageController pageController,
  }) : _pageController = pageController;

  final PageController _pageController;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: Tsizes.defaultSpace,
      bottom: TDeviceUtils.getBottomNavigationBarHeight(),
      child: ElevatedButton(
        onPressed: () {
          // Go to next page, or if last page, navigate to home screen
          
          if (_pageController.page == 2) {
            // TODO: Navigate to home screen
          } else {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.ease,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
          backgroundColor: Colors.black, // Button background color
          foregroundColor: Colors.white, // Icon color
        ),
        child: const Icon(Iconsax.arrow_right_3),
      ),
    );
  }
}