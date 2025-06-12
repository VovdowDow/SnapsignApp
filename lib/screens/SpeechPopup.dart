import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechPopup extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(String)? onTextTranscribed; // เพิ่ม callback สำหรับส่งข้อความกลับ

  const SpeechPopup({
    Key? key, 
    required this.onCancel,
    this.onTextTranscribed,
  }) : super(key: key);

  @override
  State<SpeechPopup> createState() => _SpeechPopupState();
}

class _SpeechPopupState extends State<SpeechPopup>
    with SingleTickerProviderStateMixin {
  
  // Animation controllers
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  // Speech to text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isAvailable = false;
  String _transcribedText = '';
  String _currentWords = '';
  double _confidence = 1.0;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation
    _controller = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    // Initialize speech to text
    _speech = stt.SpeechToText();
    _initializeSpeech();
  }

  void _initializeSpeech() async {
    // ขอสิทธิ์เข้าถึงไมโครโฟน
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _showPermissionDialog();
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (val) {
        print('Speech status: $val');
        if (val == 'notListening') {
          setState(() {
            _isListening = false;
            _controller.stop();
            _controller.reset();
          });
        } else if (val == 'listening') {
          print('Speech recognition is listening...');
        }
      },
      onError: (val) {
        print('Speech error: ${val.errorMsg}');
        setState(() {
          _isListening = false;
          _controller.stop();
          _controller.reset();
        });
        
        // แสดงข้อความ error ที่เข้าใจง่ายขึ้น
        String errorMessage = '';
        switch (val.errorMsg) {
          case 'error_speech_timeout':
            errorMessage = 'หมดเวลารอ กรุณาลองใหม่และพูดให้ชัดเจน';
            break;
          case 'error_no_match':
            errorMessage = 'ไม่สามารถแปลงเสียงได้ กรุณาลองใหม่';
            break;
          case 'error_audio':
            errorMessage = 'ปัญหาเสียง ตรวจสอบไมโครโฟน';
            break;
          case 'error_permission':
            errorMessage = 'ไม่ได้รับอนุญาตใช้ไมโครโฟน';
            break;
          default:
            errorMessage = 'เกิดข้อผิดพลาด: ${val.errorMsg}';
        }
        _showErrorDialog(errorMessage);
      },
      debugLogging: true, // เปิด debug log
    );
    
    if (available) {
      setState(() => _isAvailable = true);
      
      // ดึงรายการภาษาที่รองรับ
      var locales = await _speech.locales();
      print('Available locales: $locales');
      
      // ตรวจสอบว่ามีภาษาไทย
      bool hasThaiLocale = locales.any((locale) => 
        locale.localeId.contains('en_US') || locale.localeId.contains('en_US'));
      print('Thai locale available: $hasThaiLocale');
      
    } else {
      setState(() => _isAvailable = false);
      _showErrorDialog('Speech recognition ไม่พร้อมใช้งานบนอุปกรณ์นี้');
    }
  }

  void _startListening() async {
    if (!_isAvailable) {
      _showErrorDialog('Speech recognition ไม่พร้อมใช้งาน');
      return;
    }

    // ตรวจสอบสิทธิ์อีกครั้ง
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      var result = await Permission.microphone.request();
      if (!result.isGranted) {
        _showPermissionDialog();
        return;
      }
    }

    setState(() {
      _isListening = true;
      _currentWords = '';
    });
    
    _controller.repeat(reverse: true);
    
    try {
      await _speech.listen(
        onResult: (val) {
          setState(() {
            _currentWords = val.recognizedWords;
            _confidence = val.confidence;
            
            // ถ้าการฟังเสร็จสิ้น ให้อัพเดทข้อความที่แปลงแล้ว
            if (val.finalResult) {
              _transcribedText = val.recognizedWords;
            }
          });
        },
        listenFor: Duration(seconds: 60),     // เพิ่มเวลาฟังเป็น 60 วินาที
        pauseFor: Duration(seconds: 5),      // เพิ่มเวลาหยุดเป็น 5 วินาที
        partialResults: true,                // แสดงผลระหว่างฟัง
        localeId: 'th_TH',                  // ใช้ภาษาไทย
        cancelOnError: false,                // ไม่ยกเลิกเมื่อเกิด error
        listenMode: stt.ListenMode.confirmation,
        onSoundLevelChange: (level) {
          // แสดงระดับเสียงที่รับได้
          print('Sound level: $level');
        },
      );
    } catch (e) {
      print('Error starting speech recognition: $e');
      setState(() {
        _isListening = false;
      });
      _controller.stop();
      _controller.reset();
      _showErrorDialog('ไม่สามารถเริ่มการฟังได้: ${e.toString()}');
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      if (_currentWords.isNotEmpty) {
        _transcribedText = _currentWords;
      }
    });
    _controller.stop();
    _controller.reset();
  }

  void _confirmText() {
    if (_transcribedText.isNotEmpty && widget.onTextTranscribed != null) {
      widget.onTextTranscribed!(_transcribedText);
    }
    widget.onCancel();
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ต้องการสิทธิ์เข้าถึงไมโครโฟน'),
        content: Text('แอปต้องการสิทธิ์เข้าถึงไมโครโฟนเพื่อทำการอัดเสียง'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onCancel();
            },
            child: Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('ตั้งค่า'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('เกิดข้อผิดพลาด'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.stop();
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
                  scale: _isListening ? _scaleAnimation.value : 1.0,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _isListening 
                          ? Colors.red.shade400 
                          : (_isAvailable ? Colors.blue.shade400 : Colors.grey.shade400),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: 20),
            
            // ข้อความสถานะ
            Text(
              _isListening 
                  ? 'กำลังฟัง...' 
                  : (_isAvailable ? 'พร้อมอัดเสียง' : 'ไม่พร้อมใช้งาน'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            
            SizedBox(height: 10),
            
            Text(
              _isListening 
                  ? 'พูดเข้าไมโครโฟน' 
                  : (_isAvailable ? 'กดปุ่มเริ่มอัดเสียง' : 'ตรวจสอบสิทธิ์การเข้าถึง'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            
            // แสดง confidence level ถ้ากำลังฟัง
            if (_isListening && _confidence > 0) ...[
              SizedBox(height: 10),
              Text(
                'ความแม่นยำ: ${(_confidence * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            
            SizedBox(height: 30),
            
            // ช่องแสดงข้อความที่แปลงแล้ว
            Container(
              width: double.infinity,
              constraints: BoxConstraints(minHeight: 80, maxHeight: 150),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
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
                      _isListening && _currentWords.isNotEmpty
                          ? _currentWords
                          : (_transcribedText.isNotEmpty ? _transcribedText : 'ยังไม่มีข้อความ'),
                      style: TextStyle(
                        fontSize: 16,
                        color: (_isListening && _currentWords.isNotEmpty) || _transcribedText.isNotEmpty
                            ? Colors.grey.shade800 
                            : Colors.grey.shade500,
                        height: 1.4,
                        fontStyle: _isListening && _currentWords.isNotEmpty
                            ? FontStyle.italic 
                            : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // ปุ่มต่างๆ
            if (!_isListening) ...[
              // ปุ่มเริ่มอัดเสียง
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isAvailable ? _startListening : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAvailable ? Colors.red.shade500 : Colors.grey.shade400,
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
              
              // ปุ่มยืนยันข้อความ (ถ้ามีข้อความแล้ว)
              if (_transcribedText.isNotEmpty) ...[
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmText,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ใช้ข้อความนี้',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
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
                  onPressed: _stopListening,
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