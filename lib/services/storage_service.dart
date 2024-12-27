import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Initialize Firebase App Check
  Future<void> initializeAppCheck() async {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
      );
      print("Firebase App Check activated successfully.");
    } catch (e) {
      print("Error initializing Firebase App Check: $e");
    }
  }

  // Upload file to Firebase Storage
  Future<String?> uploadFile(String filePath, String destination) async {
    try {
      final ref = _storage.ref().child(destination);
      final uploadTask = await ref.putFile(File(filePath));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading file: $e");
      return null;
    }
  }

  // Delete file from Firebase Storage
  Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print("Error deleting file: $e");
      return false;
    }
  }

  // Upload profile image
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      // Set the destination path in Firebase Storage
      final destination = 'assets/images/$userId.jpg';
      final ref = _storage.ref().child(destination);

      // Create file metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId},
      );

      // Upload the file with metadata
      await ref.putFile(imageFile, metadata);

      // Get and return the download URL
      final downloadUrl = await ref.getDownloadURL();
      print('Image uploaded to Firebase Storage: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print("Error uploading profile image: $e");
      return null;
    }
  }

  // Get profile image URL
  Future<String?> getProfileImageUrl(String? imagePath) async {
    if (imagePath == null) return null;
    try {
      // If the path starts with 'images/', assume it's from the assets
      if (imagePath.startsWith('images/')) {
        return null; // Return null to use the default asset image
      }

      // If the path is already a full Firebase Storage URL, extract the path
      if (imagePath.startsWith('https://firebasestorage.googleapis.com')) {
        // Extract the path from the URL
        final uri = Uri.parse(imagePath);
        final pathSegments = uri.pathSegments;
        // The path will be after 'o/' in the URL
        final index = pathSegments.indexOf('o');
        if (index != -1 && index + 1 < pathSegments.length) {
          final storagePath = Uri.decodeComponent(pathSegments[index + 1]);
          final ref = _storage.ref().child(storagePath);
          return await ref.getDownloadURL();
        }
        return imagePath; // Return the original URL if we can't parse it
      }

      // Otherwise, get the download URL from Firebase Storage
      final ref = _storage.ref().child(imagePath);
      return await ref.getDownloadURL();
    } catch (e) {
      print("Error getting profile image URL: $e");
      return null;
    }
  }

  // Delete profile image
  Future<bool> deleteProfileImage(String userId) async {
    try {
      final ref = _storage.ref().child('assets/images/$userId.jpg');
      await ref.delete();
      return true;
    } catch (e) {
      print("Error deleting profile image: $e");
      return false;
    }
  }
}
