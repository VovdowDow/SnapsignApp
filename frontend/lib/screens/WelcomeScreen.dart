import 'package:flutter/material.dart';
import 'HomeScreen.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // หน่วงเวลา 3 วินาที แล้วเปลี่ยนหน้าอัตโนมัติ
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // รูปพื้นหลังเต็มจอ
          Positioned.fill(
            child: Image.asset(
              'assets/images/background1.png',
              fit: BoxFit.cover,
            ),
          ),
          // เพิ่ม Logo หรือข้อความต้อนรับได้ที่นี่ (ถ้าต้องการ)
          Center(
            child: SizedBox(),
          ),
        ],
      ),
    );
  }
}