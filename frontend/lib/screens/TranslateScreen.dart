import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'SpeechPopup.dart';

import 'dart:async';
import 'package:flutter/services.dart';

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
  String translatedText = ''; // ✅ ข้อความแปลที่จะแสดง/พูด

  // 🔌 ช่องสื่อสารกับ Native
  static const MethodChannel _method = MethodChannel('snapsign/native');
  static const EventChannel _events = EventChannel('snapsign/native/events');

  StreamSubscription? _gestureSub;
  bool _isProcessing = false;
  int _lastSentMs = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _listenGestureStream(); // 📡 รอรับผลจาก Native
  }

  void _listenGestureStream() {
    _gestureSub = _events.receiveBroadcastStream().listen(
      (dynamic label) {
        if (!mounted) return;
        setState(() => translatedText = (label ?? '').toString());
      },
      onError: (e) => debugPrint('EventChannel error: $e'),
    );
  }

  Future<void> _initCamera([int cameraIndex = 0]) async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    _cameraController = CameraController(
      _cameras![cameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    // ▶️ เริ่มดึงภาพเป็นสตรีมแล้วส่งไป Native เป็นระยะ
    await _cameraController!.startImageStream(_onImage);

    if (!mounted) return;
    setState(() {
      _isCameraInitialized = true;
      _selectedCameraIndex = cameraIndex;
    });
  }

  Future<void> _onImage(CameraImage image) async {
    if (_isProcessing) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSentMs < 250) return; // ⏱️ throttle ~4 fps เพื่อไม่หนักเครื่อง
    _isProcessing = true;
    _lastSentMs = now;

    try {
      // ส่งข้อมูลที่จำเป็นไป Native (รองรับ Android: YUV_420_888)
      await _method.invokeMethod('analyze', {
        'width': image.width,
        'height': image.height,
        'format': image.format.raw, // ส่วนใหญ่จะเป็น 35 บน Android
        'planes': image.planes
            .map((p) => {
                  'bytes': p.bytes, // Uint8List -> จะถูกส่งเป็น byte array
                  'bytesPerRow': p.bytesPerRow,
                  'bytesPerPixel': p.bytesPerPixel ?? 0,
                })
            .toList(),
      });
    } catch (e) {
      debugPrint('analyze error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _disposeCamera() async {
    if (_cameraController != null) {
      if (_cameraController!.value.isStreamingImages) {
        try {
          await _cameraController!.stopImageStream();
        } catch (_) {}
      }
      await _cameraController!.dispose();
      _cameraController = null;
    }
    if (mounted) {
      setState(() => _isCameraInitialized = false);
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    final newIndex = (_selectedCameraIndex + 1) % _cameras!.length;

    // หยุดสตรีมเดิมก่อนสลับ
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      try {
        await _cameraController!.stopImageStream();
      } catch (_) {}
    }
    await _cameraController?.dispose();
    await _initCamera(newIndex); // จะ startImageStream ใหม่ให้แล้ว
  }

  @override
  void dispose() {
    _gestureSub?.cancel();
    _flutterTts.stop();
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
            onPressed: () async => _switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SpeechPopup(
                    onCancel: () => Navigator.of(context).pop(),
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
                Expanded(
                  child: Text(
                    translatedText.isEmpty ? '—' : translatedText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => translatedText = ''),
                  child: const Icon(Icons.clear),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
