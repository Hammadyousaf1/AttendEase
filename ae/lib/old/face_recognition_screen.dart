import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FaceRecognitionScreen extends StatefulWidget {
  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  String _recognizedUserName = "Waiting...";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      // Request camera permission
      if (await Permission.camera.request().isGranted) {
        _cameras = await availableCameras();
        
        CameraDescription? frontCamera = _cameras?.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first, // Fallback to first camera
        );

        if (frontCamera == null) {
          print("❌ No front camera found");
          return;
        }

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
        );

        await _cameraController!.initialize();
        if (!mounted) return;

        setState(() {
          _isCameraInitialized = true;
        });
      } else {
        print("❌ Camera permission denied");
      }
    } catch (e) {
      print("❌ Error initializing camera: $e");
    }
  }

  Future<void> _captureAndSendImage() async {
    if (!(_cameraController?.value.isInitialized ?? false)) {
      print("❌ Camera is not initialized");
      return;
    }

    try {
      XFile imageFile = await _cameraController!.takePicture();
      // Rotate the image if necessary
      final rotatedImage = await _rotateImageIfNeeded(imageFile);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.100.5:5000/recognize'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', rotatedImage.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        var jsonResponse = jsonDecode(responseData);

        if (jsonResponse.containsKey('name')) {
          setState(() {
            _recognizedUserName = jsonResponse['name'];
          });
          print("✅ Recognized User: ${jsonResponse['name']}");
        } else {
          print("⚠️ No name in response");
          setState(() {
            _recognizedUserName = "Unknown";
          });
        }
      } else {
        print("❌ Recognition failed: ${response.statusCode}");
        setState(() {
          _recognizedUserName = "Recognition failed!";
        });
      }
    } catch (e) {
      print("❌ Error capturing/sending image: $e");
      setState(() {
        _recognizedUserName = "Error recognizing face!";
      });
    }
  }

  Future<XFile> _rotateImageIfNeeded(XFile imageFile) async {
    // Determine if rotation is needed based on camera orientation
    int rotationAngle = 0;

    // Get the current camera description
    CameraDescription? camera = _cameraController?.description;

    if (camera != null) {
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationAngle = 0; // Rotate for front camera
      }
    }

    // Load the image as a file
    final imageBytes = await imageFile.readAsBytes();
    final originalImage = decodeImage(imageBytes); // Decode the image using the image package
    final rotatedImage = copyRotate(originalImage!, angle: rotationAngle); // Use named parameter

    // Save the rotated image to a temporary file
    final tempDir = await getTemporaryDirectory();
    final rotatedImageFile = XFile('${tempDir.path}/rotated_image.jpg');
    await File(rotatedImageFile.path).writeAsBytes(encodeJpg(rotatedImage)); // Use the image package to encode

    return rotatedImageFile; // Return the rotated image file
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Face Recognition"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isCameraInitialized
                ? CameraPreview(_cameraController!)
                : Center(child: CircularProgressIndicator()),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "Recognized User: $_recognizedUserName",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _captureAndSendImage,
                  child: Text("Capture & Recognize"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
