import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'SpeechPopup.dart';

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';           // ✅ สำหรับ Uint8List
import 'package:flutter/services.dart'; // ✅ สำหรับ MethodChannel

class NativeBridge {
    static const platform = MethodChannel('mediapipe_channel');

    static Future<List<dynamic>> getLiveLandmarks(Uint8List imageBytes) async {
      try {
        final result = await platform.invokeMethod('getLandmarks', imageBytes);
        return result as List<dynamic>; // คุณอาจแปลงเป็น List<List<double>> ได้
      } catch (e) {
        print("Platform error: $e");
        return [];
      }
    }
  }

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}


class _TranslateScreenState extends State<TranslateScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraEnabled = true; // 👈 เพิ่มตัวแปร toggle กล้อง

  List<Map<String, dynamic>> _gestureDB = [];
  Future<void> loadGesturesFromJson() async {
    final data = await rootBundle.loadString('assets/gestures/gestures.json');
    final List<dynamic> decoded = json.decode(data);
    setState(() {
      _gestureDB = decoded.cast<Map<String, dynamic>>();
    });
}

  

  @override
  void initState() {
    super.initState();
    _initCamera();
    loadGesturesFromJson(); // โหลด JSON เพิ่มเข้าไป
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
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

  @override
  void dispose() {
    _disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('แปลภาษามือ'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isCameraEnabled ? Icons.videocam : Icons.videocam_off),
            tooltip: _isCameraEnabled ? 'ปิดกล้อง' : 'เปิดกล้อง',
            onPressed: () async {
              if (_isCameraEnabled) {
                await _disposeCamera();
              } else {
                await _initCamera();
              }
              setState(() {
                _isCameraEnabled = !_isCameraEnabled;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.mic),
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
            child: _isCameraEnabled && _isCameraInitialized && _cameraController != null
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
                    height: 250,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: const Text(
                      'กล้องถูกปิด',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  ),
          ),

          // 🔵 ภาษา
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Text('ภาษามือ'),
                const Icon(Icons.swap_horiz, color: Colors.pink),
                const Text('ภาษาไทย'),
                IconButton(
                  icon: const Icon(Icons.volume_up),
                  onPressed: () {
                    // TODO: พูดข้อความที่แปลได้
                  },
                ),
              ],
            ),
          ),

          // 🟣 ผลลัพธ์
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
