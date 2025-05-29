import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  File? _selectedImage;

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('คลังรูปภาพ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _pickImageFromGallery,
          )
        ],
      ),
      body: Center(
        child: _selectedImage == null
            ? const Text('ยังไม่ได้เลือกรูปภาพ')
            : Image.file(
                _selectedImage!,
                width: 300,
                height: 300,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}