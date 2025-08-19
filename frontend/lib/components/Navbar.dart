import 'package:flutter/material.dart';

class Navbar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const Navbar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ค่าคงที่
    const double barHeight = 65.0;
    const double fabDiameter = 60.0;

    // bottom safe area (เช่น iPhone home indicator)
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    // ให้ SizedBox มีความสูงพอสำหรับแถบ + ครึ่งหนึ่งของปุ่มกล้อง + safe area
    final double totalHeight = barHeight + (fabDiameter / 2) + bottomPadding;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // แถบพื้นหลัง วางติดด้านล่างของ SizedBox (คำนึงถึง safe area)
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding,
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 165, 28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      _buildNavItem(Icons.home_outlined, Icons.home, "หน้าแรก", 0),
                      const SizedBox(width: 60), // เว้นที่ให้ปุ่มกล้อง
                      _buildNavItem(Icons.image_outlined, Icons.image, "แปลจากภาพ", 1),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ปุ่มกล้อง: วางโดยอาศัย bottom padding และตำแหน่งกึ่งกลางด้านบนของแถบ
          Positioned(
            bottom: bottomPadding + (barHeight / 2) - (fabDiameter / 2) + 20,
            child: GestureDetector(
              onTap: () => onItemTapped(2),
              child: Container(
                width: fabDiameter,
                height: fabDiameter,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 10, 44, 145),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData outlinedIcon, IconData filledIcon, String label, int index) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? filledIcon : outlinedIcon,
            color: isSelected ? const Color(0xFF0D33AA) : Colors.white,
            size: 25,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF0D33AA) : Colors.white,
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}