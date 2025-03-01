import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

class FaceRecognitionScreen extends StatefulWidget {
  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isDetecting = false;
  final MethodChannel _channel = MethodChannel('opencv_face_recognition');
  String _recognizedName = "Unknown";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras!.isEmpty) return;

    _cameraController = CameraController(
      _cameras![1],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() {});

    _startFaceRecognition();
  }

  void _startFaceRecognition() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    _cameraController!.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;

      try {
        final result = await _channel.invokeMethod('detectFace', {
          'bytes': image.planes[0].bytes,
          'width': image.width,
          'height': image.height,
          'bytesPerRow': image.planes[0].bytesPerRow,
        });

        setState(() {
          _recognizedName = result ?? "Unknown";
        });

        if (_recognizedName != "Unknown") {
          _showRecognitionPopup(_recognizedName);
        }
      } catch (e) {
        print("Error in face recognition: $e");
      }

      _isDetecting = false;
    });
  }

  void _showRecognitionPopup(String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Recognized Person"),
          content: Text("Name: $name"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_cameraController!)),
        ],
      ),
    );
  }
}
