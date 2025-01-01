import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class MessageInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(String, String)? onSendImage;
  final Function(String, String)? onSendFile;

  const MessageInput({
    super.key,
    required this.onSendMessage,
    this.onSendImage,
    this.onSendFile,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _textController = TextEditingController();
  final _picker = ImagePicker();

  Future<void> _showAttachmentOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.deepPurple),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Colors.deepPurple),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: Colors.deepPurple),
              title: const Text('Attach File'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      print('Starting image picker from $source...');
      final XFile? image = await _picker.pickImage(
        source: source,
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
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final destination = 'assets/chat_images/image_$timestamp.jpg';
        final storageRef = FirebaseStorage.instance.ref().child(destination);
        final file = File(image.path);

        if (!await file.exists()) {
          throw Exception('File does not exist at path: ${image.path}');
        }

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

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result == null) {
        print('No file selected');
        return;
      }

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
        final file = File(result.files.single.path!);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = result.files.single.name;
        final destination = 'assets/chat_files/$timestamp-$fileName';

        final storageRef = FirebaseStorage.instance.ref().child(destination);

        final metadata = SettableMetadata(
          contentType: 'application/${fileName.split('.').last}',
          customMetadata: {
            'timestamp': timestamp.toString(),
            'type': 'chat_file',
            'originalName': fileName,
          },
        );

        await storageRef.putFile(file, metadata);
        final fileUrl = await storageRef.getDownloadURL();

        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();

        widget.onSendFile?.call(
          fileUrl,
          fileName,
        );
      } catch (e) {
        print('Error uploading file: $e');
        if (!context.mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload file: $e')),
        );
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _showAttachmentOptions,
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
