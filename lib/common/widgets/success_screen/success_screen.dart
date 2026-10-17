import 'package:flutter/material.dart';
import 'package:nirmal/utils/constants/size.dart';
import 'package:nirmal/utils/constants/text_strings.dart';
import 'package:nirmal/utils/helpers/helper_functions.dart';


class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, this.image, this.title, this.subtitle, required this.onPressed});

  final image,title,subtitle;
  final VoidCallback onPressed;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(Tsizes.defaultSpace),
          child: Column(
            children: [
              Image(

                image: AssetImage(image),
                width: THelperFunction.getScreenWidth(context) * 0.6,
              ),
              const SizedBox(height: Tsizes.spaceBtwSections),

              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall ,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Tsizes.spaceBtwItems),
              
              
              Text(
                subtitle,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Tsizes.spaceBtwSections),

              ///button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onPressed,
                  child: Text(TTests.continueText), 
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}