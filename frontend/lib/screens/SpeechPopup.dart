import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class SpeechPopup extends StatefulWidget {
  final VoidCallback onCancel;
  final Function(String)? onTextTranscribed;

  const SpeechPopup({
    Key? key,
    required this.onCancel,
    this.onTextTranscribed,
  }) : super(key: key);

  @override
  State<SpeechPopup> createState() => _SpeechPopupState();
}

class _SpeechPopupState extends State<SpeechPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isAvailable = false;
  String _transcribedText = '';
  String _currentWords = '';
  double _confidence = 1.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _speech = stt.SpeechToText();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSpeech();
    });
  }

  void _initializeSpeech() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showPermissionDialog();
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'notListening') {
          setState(() {
            _isListening = false;
            _controller.stop();
            _controller.reset();
          });
        }
      },
      onError: (val) {
        setState(() {
          _isListening = false;
          _controller.stop();
          _controller.reset();
        });

        String errorMessage;
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
      debugLogging: true,
    );

    if (available) {
      setState(() => _isAvailable = true);
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
            if (val.finalResult) {
              _transcribedText = val.recognizedWords;
            }
          });
        },
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: 'th_TH',
        cancelOnError: false,
        listenMode: stt.ListenMode.confirmation,
      );
    } catch (e) {
      setState(() => _isListening = false);
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

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ต้องการสิทธิ์เข้าถึงไมโครโฟน'),
        content: const Text('แอปต้องการสิทธิ์เข้าถึงไมโครโฟนเพื่อทำการอัดเสียง'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onCancel();
            },
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('ตั้งค่า'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เกิดข้อผิดพลาด'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_isListening) _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: widget.onCancel,
                  child: const Icon(Icons.close, size: 24, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 10),

              // 🎤 ไอคอนไมค์ใหญ่
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

              const SizedBox(height: 20),

              const Text(
                'กดปุ่มเริ่มอัดเสียง',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ข้อความที่แปลงได้ :',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _transcribedText.isNotEmpty ? _transcribedText : 'ยังไม่มีข้อความ',
                      style: TextStyle(
                        fontSize: 16,
                        color: _transcribedText.isNotEmpty ? Colors.black : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isListening ? _stopListening : _startListening,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _isListening ? 'หยุดอัดเสียง' : 'เริ่มอัดเสียง',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
