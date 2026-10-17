import 'package:flutter/material.dart';
import 'package:nirmal/utils/constants/size.dart';
import 'package:nirmal/utils/helpers/helper_functions.dart';

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