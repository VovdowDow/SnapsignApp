import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../components/Navbar.dart';
import 'TranslateScreen.dart';
import 'WordScreen.dart';

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

  Future<void> _speak() async {
    await flutterTts.setLanguage("th-TH");
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(1.0);
    await flutterTts.speak(
      'วิธีการใช้งานแอปพลิเคชัน\n'
      '1. ไปที่หน้า"กล้อง"\n'
      '2. ยกมือทำท่าทางภาษามือต่อหน้ากล้อง\n'
      '3. ระบบจะตรวจจับท่าทางแล้วแสดงข้อความแปลด้านล่าง\n'
      '4. กดไอคอนลำโพงเพื่อให้ระบบอ่านข้อความให้ฟัง\n',
    );
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

      // AppBar ด้านบน
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
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
                color: Colors.purple,
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
                    fontSize: 14,
                    color: Color.fromARGB(255, 122, 122, 122),
                  ),
                  children: [
                    TextSpan(
                      text:
                          'ยินดีต้อนรับเข้าสู่ แอปพลิเคชันแปลภาษามือสำหรับผู้พิการ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color.fromARGB(255, 48, 48, 48),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),

              SizedBox(
                height: 180,
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
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.pink
                          : Colors.grey[300],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 1),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'วิธีการใช้งาน',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _speak,
                    icon: const Icon(Icons.volume_up, color: Colors.black),
                    label: const Text(
                      'ฟังเสียง',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),

              const Text(
                '1. ไปที่หน้า"กล้อง"\n'
                '2. ยกมือทำท่าทางภาษามือต่อหน้ากล้อง\n'
                '3. ระบบตรวจจับท่าทางแล้วขึ้นข้อความแปลด้านล่าง\n'
                '4. กดไอคอนลำโพง🔊เพื่อให้ระบบอ่านข้อความให้ฟัง\n',
                style: TextStyle(fontSize: 14),
                
              ),
              const Text(
                    'คำแนะนำ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Text(
                '• ยกมือในตำแหน่งที่กล้องมองเห็นชัด (กลางหน้าจอ)\n'
                '• อยู่ที่แสงสว่างพอ เพื่อให้ระบบตรวจจับได้แม่นยำ\n'
                '• หลีกเลี่ยงฉากหลังที่วุ่นวายเกินไป\n',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),

      // ✅ ปุ่มลอยตรงกลาง
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pinkAccent,
        child: const Icon(Icons.camera_alt, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TranslateScreen()),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ✅ Navbar ด้านล่าง
      bottomNavigationBar: Navbar(
        selectedIndex: _selectedIndex,
        onItemTapped: (index) {
          if (index == 0) {
            setState(() {
              _selectedIndex = index;
            });
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WordScreen()),
            );
          }
        },
      ),
    );
  }
}
