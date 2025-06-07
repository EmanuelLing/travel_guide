import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';

class ImageStorageService {
  static final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  static Future<File?> pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Take photo with camera
  static Future<File?> takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  // Save image to local storage
  static Future<String?> saveImageLocally(File imageFile, String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final profileImagesDir = Directory('${directory.path}/profile_images');

      // Create the directory if it doesn't exist
      if (!await profileImagesDir.exists()) {
        await profileImagesDir.create(recursive: true);
      }

      // Generate unique filename using userId
      final filename = 'profile_$userId${path.extension(imageFile.path)}';
      final localPath = path.join(profileImagesDir.path, filename);

      // Copy the image to local storage
      await imageFile.copy(localPath);
      return localPath;
    } catch (e) {
      print('Error saving image: $e');
      return null;
    }
  }

  // Delete image from local storage
  static Future<void> deleteImageLocally(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  // Get image from local storage
  static Future<File?> getImageFromPath(String? imagePath) async {
    if (imagePath == null) return null;

    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      print('Error getting image: $e');
      return null;
    }
  }
}
