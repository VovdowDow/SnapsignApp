import 'package:flutter/material.dart';

class SpeechPopup extends StatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final String? transcribedText;

  const SpeechPopup({
    Key? key, 
    required this.onCancel,
    this.onStartRecording,
    this.onStopRecording,
    this.transcribedText,
  }) : super(key: key);

  @override
  State<SpeechPopup> createState() => _SpeechPopupState();
}

class _SpeechPopupState extends State<SpeechPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
    });
    _controller.repeat(reverse: true);
    if (widget.onStartRecording != null) {
      widget.onStartRecording!();
    }
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
    _controller.stop();
    _controller.reset();
    if (widget.onStopRecording != null) {
      widget.onStopRecording!();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ไอคอนไมค์
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRecording ? _scaleAnimation.value : 1.0,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red.shade400 : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 20),
            
            // ข้อความ
            Text(
              _isRecording ? 'กำลังฟัง...' : 'พร้อมอัดเสียง',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            
            SizedBox(height: 10),
            
            Text(
              _isRecording ? 'พูดเข้าไมโครโฟน' : 'กดปุ่มเริ่มอัดเสียง',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            
            SizedBox(height: 30),
            
            // ช่องแสดงข้อความที่แปลงแล้ว
            Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: 80),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ข้อความที่แปลงได้:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.transcribedText ?? 'ยังไม่มีข้อความ',
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.transcribedText != null 
                          ? Colors.grey.shade800 
                          : Colors.grey.shade500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // ปุ่มต่างๆ
            if (!_isRecording) ...[
              // ปุ่มเริ่มอัดเสียง
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mic, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'เริ่มอัดเสียง',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 12),
              
              // ปุ่มยกเลิก
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'ยกเลิก',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // ปุ่มหยุดอัด
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _stopRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stop, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'หยุดอัด',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 12),
              
              // ปุ่มยกเลิก
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                  child: Text(
                    'ยกเลิก',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}