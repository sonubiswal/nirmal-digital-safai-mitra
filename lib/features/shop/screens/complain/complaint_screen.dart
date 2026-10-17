import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nirmal/home_menu.dart'; // import NavigationMenu & NavigationController
import 'complaint_controller.dart';

// Design tokens – reuse from profile.dart or define your own
class _T {
  static const primaryBlue = Color(0xFF2563EB);
}

class ComplaintScreen extends StatelessWidget {
  const ComplaintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Get.put(ComplaintController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Complaint'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () {
            // Get the existing navigation controller (from main menu)
            final navController = Get.find<NavigationController>();
            // Switch to Home tab (index 0)
            navController.selectedIndex.value = 0;
            // Replace the navigation stack with the main menu
            Get.offAll(() => const NavigationMenu());
          },
        ),
        automaticallyImplyLeading: false, // remove default back arrow
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Obx(() => Text(
                      'Uploading ${(controller.uploadProgress.value * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 14),
                    )),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title field
                _buildLabel('Title'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.titleController,
                  decoration: InputDecoration(
                    hintText: 'Brief summary of the issue',
                    prefixIcon: const Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Category field
                _buildLabel('Location'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.categoryController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Area, Landmark, Locality, etc.',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Priority selection
                _buildLabel('Priority'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Obx(
                    () => Row(
                      children: [
                        _PriorityOption(
                          label: 'Low',
                          value: ComplaintPriority.low,
                          groupValue: controller.priority.value,
                          color: Colors.green,
                          onChanged: (val) =>
                              controller.priority.value = val!,
                        ),
                        _PriorityOption(
                          label: 'Medium',
                          value: ComplaintPriority.medium,
                          groupValue: controller.priority.value,
                          color: Colors.orange,
                          onChanged: (val) =>
                              controller.priority.value = val!,
                        ),
                        _PriorityOption(
                          label: 'High',
                          value: ComplaintPriority.high,
                          groupValue: controller.priority.value,
                          color: Colors.red,
                          onChanged: (val) =>
                              controller.priority.value = val!,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Description field
                _buildLabel('Description'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Provide detailed information...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please describe the issue';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Image picker area
                _buildLabel('Attachments (optional)'),
                const SizedBox(height: 8),
                _ImagePickerWidget(controller: controller),
                const SizedBox(height: 30),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: controller.submitComplaint,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit Complaint',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _PriorityOption extends StatelessWidget {
  final String label;
  final ComplaintPriority value;
  final ComplaintPriority groupValue;
  final Color color;
  final ValueChanged<ComplaintPriority?> onChanged;

  const _PriorityOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: isSelected ? color : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePickerWidget extends StatelessWidget {
  final ComplaintController controller;

  const _ImagePickerWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Obx(() {
          final images = controller.selectedImages;
          if (images.isEmpty) {
            return GestureDetector(
              onTap: controller.showImageSourceDialog,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to add images',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            );
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: images.length + 1,
            itemBuilder: (context, index) {
              if (index == images.length) {
                return GestureDetector(
                  onTap: controller.showImageSourceDialog,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.grey.shade500),
                        const SizedBox(height: 4),
                        Text(
                          'Add',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      images[index],
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => controller.removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }),
      ],
    );
  }
}