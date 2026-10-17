import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

enum ComplaintPriority { low, medium, high }

class ComplaintController extends GetxController {
  // Form fields
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final categoryController = TextEditingController();
  final priority = ComplaintPriority.medium.obs;
  final selectedImages = <File>[].obs;

  // Form key
  final formKey = GlobalKey<FormState>();

  // Loading state
  final isLoading = false.obs;
  final uploadProgress = 0.0.obs;

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Image picker
  final ImagePicker _picker = ImagePicker();

  // -------------------------------------------------------------------------
  // Image picking methods
  // -------------------------------------------------------------------------
  Future<void> pickImages() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (images != null) {
        selectedImages.addAll(images.map((x) => File(x.path)));
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick images: $e');
    }
  }

  Future<void> takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
      );
      if (image != null) {
        selectedImages.add(File(image.path));
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to take photo: $e');
    }
  }

  void removeImage(int index) {
    selectedImages.removeAt(index);
  }

  void showImageSourceDialog() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Get.context?.isDarkMode == true
              ? const Color(0xFF1C1C1E)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Get.back();
                pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Get.back();
                takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Submit complaint to Firebase (no authentication)
  // -------------------------------------------------------------------------
  Future<void> submitComplaint() async {
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;
    uploadProgress.value = 0.0;

    try {
      // 1. Upload images to Firebase Storage (use a generic folder, e.g., 'complaints/anonymous/')
      List<String> imageUrls = [];
      if (selectedImages.isNotEmpty) {
        for (int i = 0; i < selectedImages.length; i++) {
          final file = selectedImages[i];
          final fileName =
              '${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          // Store in an anonymous folder (no user ID)
          final ref = _storage.ref().child(
                'complaints/anonymous/$fileName',
              );
          final uploadTask = ref.putFile(file);
          uploadTask.snapshotEvents.listen((snapshot) {
            uploadProgress.value =
                snapshot.bytesTransferred / snapshot.totalBytes;
          });
          final snapshot = await uploadTask;
          final url = await snapshot.ref.getDownloadURL();
          imageUrls.add(url);
        }
      }

      // 2. Create complaint document in Firestore (no user fields)
      await _firestore.collection('complaints').add({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'category': categoryController.text.trim(),
        'priority': priority.value.toString().split('.').last,
        'imageUrls': imageUrls,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Success feedback
      Get.snackbar(
        'Success',
        'Your complaint has been submitted.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Clear form
      titleController.clear();
      descriptionController.clear();
      categoryController.clear();
      selectedImages.clear();
      priority.value = ComplaintPriority.medium;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to submit complaint: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
      uploadProgress.value = 0.0;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    super.onClose();
  }
}