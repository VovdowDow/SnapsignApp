import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../components/Navbar.dart';
import 'TranslateScreen.dart';
import 'GalleryScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterTts flutterTts = FlutterTts();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _selectedIndex = 0;

  List<String> imagePaths = [
    'assets/images/photo1.png',
    'assets/images/photo2.png',
    'assets/images/photo3.png',
  ];

  File? _selectedImage;

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('รูปที่เลือก'),
          content: Image.file(
            _selectedImage!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GalleryScreen(
                      selectedImage: _selectedImage!,
                      translatedText: 'เหนื่อย',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 252, 192, 102),
              ),
              child: const Text('ดูคำแปล'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FD),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 10, 44, 145),
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 50,
            ),
            const SizedBox(width: 8),
            const Text(
              'SnapSign',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.shade300,
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  text: 'สวัสดี,\n',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color.fromARGB(255, 122, 122, 122),
                  ),
                  children: [
                    TextSpan(
                      text: 'ยินดีต้อนรับเข้าสู่ แอปพลิเคชันแปลภาษามือสำหรับผู้พิการ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color.fromARGB(255, 48, 48, 48),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: imagePaths.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        imagePaths[index],
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(imagePaths.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.pink
                          : Colors.grey[300],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 5),
              const Text(
                'วิธีการใช้งาน',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                '1. ไปที่หน้า"กล้อง"\n'
                '2. ยกมือทำท่าทางภาษามือต่อหน้ากล้อง\n'
                '3. ระบบตรวจจับท่าทางแล้วขึ้นข้อความแปลด้านล่าง\n',
                style: TextStyle(fontSize: 18),
              ),
              const Text(
                'คำแนะนำ',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Text(
                '• ยกมือในตำแหน่งที่กล้องมองเห็นชัด (กลางหน้าจอ)\n'
                '• อยู่ที่แสงสว่างพอ เพื่อให้ระบบตรวจจับได้แม่นยำ\n'
                '• หลีกเลี่ยงฉากหลังที่วุ่นวายเกินไป\n',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
      
      bottomNavigationBar: Navbar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          if (index == 0) {
            setState(() {
              _selectedIndex = index;
            });
          } else if (index == 1) {
            _pickImageFromGallery();
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TranslateScreen()),
            );
          }
        },
      ),
    );
  }
}