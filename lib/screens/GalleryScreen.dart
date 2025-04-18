import 'package:flutter/material.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('คลังรูปภาพ'),
      ),
      body: const Center(
        child: Text('นี่คือหน้าคลังรูปภาพ'),
      ),
    );
  }
}
