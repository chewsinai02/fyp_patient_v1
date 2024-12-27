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
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Set the destination path in Firebase Storage
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final destination = 'assets/chat_images/image_$timestamp.jpg';

        final storageRef = FirebaseStorage.instance.ref().child(destination);

        final file = File(image.path);
        if (!await file.exists()) {
          throw Exception('File does not exist at path: ${image.path}');
        }

        // Upload with metadata
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'timestamp': timestamp.toString(),
            'type': 'chat_image'
          },
        );

        await storageRef.putFile(file, metadata);
        final imageUrl = await storageRef.getDownloadURL();

        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();

        // Send message with image
        widget.onSendImage?.call(
          imageUrl,
          _textController.text.trim(),
        );
        _textController.clear();
      } catch (e) {
        print('Error uploading image: $e');
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
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
