import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'GalleryScreen.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras[0], // กล้องหน้า (หรือใช้ cameras[0] ถ้าต้องการกล้องหลัง)
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

  double _getScaleFactor() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return 1.0;
    }
    
    // This ensures the camera preview fills the container width
    return 1 / _cameraController!.value.aspectRatio;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
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
            icon: const Icon(Icons.image),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GalleryScreen()),
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
                : const Center(child: CircularProgressIndicator()),
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
