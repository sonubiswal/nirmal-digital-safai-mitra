import 'package:flutter/material.dart';
import 'package:nirmal/features/authentication/controllers.onboarding/onboarding_conroller.dart';
import 'package:nirmal/utils/constants/size.dart';
import 'package:nirmal/utils/device/device_utility.dart';


class onBoardingSkip extends StatelessWidget {
  const onBoardingSkip({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: TDeviceUtils.getAppBarHeight(), 
      right: Tsizes.defaultSpace,
      child:TextButton(onPressed: ()=> OnboardingController.instance.skipPage(), child: const Text('Skip'),
     ),
    );
  }
}