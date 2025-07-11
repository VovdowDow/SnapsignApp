import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'SpeechPopup.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  List<CameraDescription>? _cameras;
  int _selectedCameraIndex = 0;

  final FlutterTts _flutterTts = FlutterTts();
  String translatedText = 'สวัสดี'; // ✅ ตัวแปรเก็บคำแปล

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera([int cameraIndex = 0]) async {
    _cameras = await availableCameras();

    if (_cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _selectedCameraIndex = cameraIndex;
        });
      }
    }
  }

  Future<void> _disposeCamera() async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    final newIndex = (_selectedCameraIndex + 1) % _cameras!.length;

    await _cameraController?.dispose();
    await _initCamera(newIndex);
  }

  @override
  void dispose() {
    _flutterTts.stop(); // ✅ หยุดเสียงเมื่อปิดหน้า
    _disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 165, 28),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 10, 44, 145),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'แปลภาษามือ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            tooltip: 'สลับกล้อง',
            onPressed: () async {
              await _switchCamera();
            },
          ),
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SpeechPopup(
                    onCancel: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔴 Live Camera Feed
          Expanded(
            flex: 3,
            child: _isCameraInitialized && _cameraController != null
                ? Container(
                    width: double.infinity,
                    color: Colors.black,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.width *
                                _cameraController!.value.aspectRatio,
                            child: CameraPreview(_cameraController!),
                          ),
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: const Text(
                      'กล้องไม่พร้อมใช้งาน',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  ),
          ),

          // 🔵 แถบภาษา + ปุ่มลำโพง
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text('ภาษามือ'),
                const Icon(Icons.east, color: Color.fromARGB(255, 10, 44, 145)),
                const Text('ภาษาไทย'),
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.black),
                  onPressed: () async {
                    await _flutterTts.setLanguage("th-TH");
                    await _flutterTts.setPitch(1.0);
                    await _flutterTts.speak(translatedText);
                  },
                ),
              ],
            ),
          ),

          // 🟣 กล่องผลลัพธ์
          Container(
            margin: const EdgeInsets.all(30),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(child: Text(translatedText)),
                const Icon(Icons.clear),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
