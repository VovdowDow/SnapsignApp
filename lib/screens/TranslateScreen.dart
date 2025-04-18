import 'package:flutter/material.dart';
import 'GalleryScreen.dart';

class TranslateScreen extends StatelessWidget {
  const TranslateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('แปลภาษามือ'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GalleryScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔴 กล้องที่จะแสดงภาพมือแบบเรียลไทม์
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.grey[300],
              child: const Center(child: Text('Live Camera Feed')),
            ),
          ),

          // 🔵 ภาษาที่เลือก
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('ภาษามือ'),
                    Icon(Icons.swap_horiz, color: Colors.pink),
                    Text('ภาษาไทย'),
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: () {
                        // TODO: พูดข้อความที่แปลได้
                      },
                    ),
                  ],
                ),
              ),

          // 🟣 ข้อความผลลัพธ์
          Container(
            margin: const EdgeInsets.all(30),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: const [
                Expanded(child: Text('สวัสดี')),
                Icon(Icons.clear),
              ],
            ),
          ),
        ],
      ),
    );
  }
}