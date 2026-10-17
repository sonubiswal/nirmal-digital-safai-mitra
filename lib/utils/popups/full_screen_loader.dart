import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nirmal/common/widgets/animation_loader.dart';
import 'package:nirmal/utils/constants/colors.dart';
import 'package:nirmal/utils/helpers/helper_functions.dart';
// Import your animation loader widget (adjust path if needed)


class TFullScreenLoader {
  /// Opens a full‑screen loading dialog with a custom animation.
  static void openLoadingDialog(String text, String animation) {
    Get.dialog(
      PopScope(
        canPop: false, // Prevent closing with back button
        child: Container(
          color: THelperFunction.isDarkMode(Get.context!)
              ? TColors.dark
              : TColors.white,
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              const SizedBox(height: 250), // Adjust spacing as needed
              TAnimationLoaderWidget(
                text: text,
                animation: animation,
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false, // Prevent closing by tapping outside
    );
  }

  /// Closes the currently open loading dialog.
  static void stopLoading() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
}