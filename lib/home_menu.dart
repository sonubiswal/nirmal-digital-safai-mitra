import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:nirmal/features/shop/screens/complain/complaint_screen.dart';
import 'package:nirmal/features/shop/screens/home/home.dart';
import 'package:nirmal/features/shop/screens/profile/profile.dart';
import 'package:nirmal/features/shop/screens/settings/settings.dart';
import 'package:nirmal/utils/constants/colors.dart';
import 'package:nirmal/utils/helpers/helper_functions.dart';


class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController(), permanent: true);
    final darkMode = THelperFunction.isDarkMode(context);

    return Scaffold(
      bottomNavigationBar: Obx(
        () => NavigationBar(
          height: 80,
          elevation: 0,
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: (index) => controller.selectedIndex.value = index,
          backgroundColor: darkMode ? TColors.black : Colors.white,
          indicatorColor: darkMode 
              ? TColors.white.withOpacity(0.1) 
              : TColors.black.withOpacity(0.1),
          destinations: const [
            NavigationDestination(
              icon: Icon(Iconsax.home),               // outline
              selectedIcon: Icon(Iconsax.home_15),     // bold/filled
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.note),
              selectedIcon: Icon(Iconsax.note_1),
              label: 'Complaint',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.profile_circle),
              selectedIcon: Icon(Iconsax.profile_circle5),
              label: 'Profile',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.setting),
              selectedIcon: Icon(Iconsax.setting5),
              label: 'Settings',
            ),
          ],
        ),
      ),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  // Replace these with your actual screen widgets
  final screens = [
    const HomeScreen(),
    const ComplaintScreen(),   // TODO: Replace with SearchScreen()
    const ProfileScreen(),  // TODO: Replace with ProfileScreen()
    const SettingsScreen(),    // TODO: Replace with SettingsScreen()
  ];
}