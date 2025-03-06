import 'dart:io';
import 'package:ae/InputUserDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:async'; // For Future.delayed if needed to manage delays between captures

class ImageCaptureScreen extends StatefulWidget {
  const ImageCaptureScreen({super.key});

  @override
  State<ImageCaptureScreen> createState() => _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends State<ImageCaptureScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFaceDetected = false;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
    ),
  );
  List<String> capturedImages = [];
  int _currentCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Initialize the camera based on the current camera index
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Determine the camera to use (front or back)
    final camera = cameras[_currentCameraIndex];

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    setState(() {
      _isCameraInitialized = true;
    });
  }

  // Switch between front and back camera
  Future<void> _switchCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Toggle the camera index (0 for front, 1 for back)
    setState(() {
      _currentCameraIndex = (_currentCameraIndex + 1) % cameras.length;
      _isCameraInitialized = false; // Reset camera initialization
    });

    // Re-initialize the camera with the new camera
    await _initializeCamera();
  }

  // Capture images 5 times
  Future<void> _captureAndProcessImages() async {
    if (!_isCameraInitialized) return;

    try {
      // Capture 5 images quickly first
      List<XFile> imageFiles = [];
      for (int i = 0; i < 5; i++) {
        final XFile imageFile = await _cameraController!.takePicture();
        imageFiles.add(imageFile);
      }

      // Then process them afterwards
      for (XFile imageFile in imageFiles) {
        final File file = File(imageFile.path);
        final img.Image? capturedImage =
            img.decodeImage(await file.readAsBytes());

        if (capturedImage != null) {
          await _processAndSaveImage(capturedImage, file);
        }
      }

      if (!mounted) return;
      _showCapturedImagesDialog();
    } catch (e) {
      debugPrint('Error capturing images: $e');
    }
  }

  // Process image (face detection, cropping, and resizing)
  Future<void> _processAndSaveImage(img.Image capturedImage, File file) async {
    final inputImage = InputImage.fromFile(file);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isNotEmpty) {
      final face = faces[0];

      // Draw rectangle around detected face
      final img.Image markedImage = img.copyResize(
        capturedImage,
        width: capturedImage.width,
        height: capturedImage.height,
      );

      // Draw green rectangle around face
      img.drawRect(
        markedImage,
        x1: face.boundingBox.left.toInt(),
        y1: face.boundingBox.top.toInt(),
        x2: face.boundingBox.right.toInt(),
        y2: face.boundingBox.bottom.toInt(),
        color: img.ColorRgb8(0, 255, 0), // color
        thickness: 10,
      );

      // Save the image with rectangle to temporary path
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      File(tempPath).writeAsBytesSync(img.encodeJpg(markedImage, quality: 100));

      setState(() {
        capturedImages.add(tempPath);
      });
    }
  }

  void _clearImages() {
    setState(() {
      capturedImages.clear();
    });
  }

  void _showCapturedImagesDialog() {
    // Only show dialog if all 5 images are captured
    if (capturedImages.length != 5) return;

    int currentIndex = 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Review Images"),
        content: SizedBox(
          height: 400,
          width: 300,
          child: PageView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: capturedImages.length,
            onPageChanged: (index) {
              currentIndex = index;
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.file(
                  File(capturedImages[index]),
                  height: 230,
                  width: 150,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                capturedImages.clear();
              });
              Navigator.of(context).pop();
              _captureAndProcessImages(); // Allow the user to take new images
            },
            child: const Text("Take New"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(capturedImages: capturedImages),
                ),
              );
            },
            child: const Text("Continue..."),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        children: [
          // Full screen camera preview
          SizedBox.expand(
            child: CameraPreview(_cameraController!),
          ),

          // Bottom floating buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Switch camera button
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: FloatingActionButton(
                      onPressed: _switchCamera,
                      backgroundColor: Colors.white,
                      heroTag: "switchCameraButton",
                      child: const Icon(Icons.switch_camera, color: Colors.black),
                    ),
                  ),

                  // Camera capture button
                  FloatingActionButton.large(
                    onPressed: _captureAndProcessImages,
                    backgroundColor: Colors.blue,
                    heroTag: "camera",
                    child: const Icon(Icons.camera_alt, color: Colors.white),
                  ),

                  // Refresh button
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: FloatingActionButton(
                      onPressed: _clearImages,
                      backgroundColor: Colors.white,
                      heroTag: "refresh",
                      child: const Icon(Icons.refresh, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Image counter
          Positioned(
            bottom: 130,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                '${capturedImages.length}/5',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
