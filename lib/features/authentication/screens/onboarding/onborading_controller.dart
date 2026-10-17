import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingController extends GetxController {
  static OnboardingController get instance => Get.find();

  // Observables
  final currentPageIndex = 0.obs;
  final pageController = PageController();

  // Update current index when page changes
  void updatePageIndicator(int index) => currentPageIndex.value = index;

  // Jump to a specific page when dot is clicked
  void dotNavigationClick(int index) {
    currentPageIndex.value = index;
    pageController.jumpToPage(index);
  }

  // Go to next page, or finish onboarding if on last page
  void nextPage() {
    if (currentPageIndex.value == 2) {
      // Last page – mark onboarding complete and navigate to next screen
      _markOnboardingComplete();
      // TODO: Replace with your actual next screen (e.g., LoginScreen)
      Get.offAllNamed('/login'); // or Get.offAll(() => LoginScreen());
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  // Skip onboarding – mark complete and go to next screen
  void skipPage() {
    _markOnboardingComplete();
    // TODO: Replace with your actual next screen
    Get.offAllNamed('/login');
  }

  // Mark that user has seen onboarding (never show again)
  Future<void> _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('IsFirstTime', false);
  }
}