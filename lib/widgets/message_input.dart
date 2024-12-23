import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(String, String)? onSendImage;

  const MessageInput({
    super.key,
    required this.onSendMessage,
    this.onSendImage,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();

  Future<void> _pickAndUploadImage() async {
    try {
      print('Starting image picker...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image == null) {
        print('No image selected');
        return;
      }
      print('Image selected: ${image.path}');

      // Show loading indicator
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Uploading image...',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      );

      try {
        print('Preparing Firebase Storage reference...');
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('chat_images')
            .child('image_${DateTime.now().millisecondsSinceEpoch}.jpg');

        print('Creating file object...');
        final file = File(image.path);
        if (!await file.exists()) {
          throw Exception('File does not exist at path: ${image.path}');
        }

        print('Starting file upload...');
        final uploadTask = storageRef.putFile(
          file,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        // Monitor upload progress
        uploadTask.snapshotEvents.listen(
          (TaskSnapshot snapshot) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
          },
          onError: (e) {
            print('Upload stream error: $e');
          },
        );

        print('Waiting for upload to complete...');
        await uploadTask;

        print('Getting download URL...');
        final imageUrl = await storageRef.getDownloadURL();
        print('Download URL obtained: $imageUrl');

        // Hide loading indicator and send message
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();

        // Send message with image
        widget.onSendImage?.call(
          imageUrl,
          _textController.text.trim(),
        );
        _textController.clear();
      } catch (e, stackTrace) {
        print('Error during upload process:');
        print('Error: $e');
        print('Stack trace: $stackTrace');

        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error in image picker:');
      print('Error: $e');
      print('Stack trace: $stackTrace');

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickAndUploadImage,
            color: Colors.deepPurple,
          ),
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              if (_textController.text.trim().isNotEmpty) {
                widget.onSendMessage(_textController.text);
                _textController.clear();
              }
            },
            color: Colors.deepPurple,
          ),
        ],
      ),
    );
  }
}
