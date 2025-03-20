import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:ae/InputUserDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class Registrationscreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<Registrationscreen> {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  List<Face> _faces = [];
  Size? _imageSize;
  bool _isFrontCamera = true;
  bool _isCapturing = false;
  List<String> capturedImages = [];
  static const int requiredImages = 5;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _startCamera(_isFrontCamera ? _cameras[1] : _cameras[0]);
  }

  Future<void> _startCamera(CameraDescription camera) async {
    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    setState(() {
      _imageSize = _cameraController!.value.previewSize;
      _isFrontCamera = _cameraController!.description.lensDirection ==
          CameraLensDirection.front;
    });

    _startFaceDetection();
  }

  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableClassification: false,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast,
      ),
    );
  }

  Future<void> _captureImages() async {
    if (_isCapturing) return;
    _isCapturing = true;

    try {
      for (int i = capturedImages.length; i < requiredImages; i++) {
        if (_cameraController?.value.isInitialized ?? false) {
          try {
            // Wait for a face to be detected before capturing an image

            // Capture the image
            final XFile image = await _cameraController!.takePicture();
            setState(() {
              capturedImages.add(image.path);
            });

            if (i < requiredImages - 1) {
              await Future.delayed(Duration(
                  milliseconds: 100)); // Add a small delay between captures
            }
          } catch (e) {
            print("Error capturing image: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text("Failed to capture image. Please try again.")),
            );
            break;
          }
        }
      }

      if (!mounted) return;
      await _showCapturedImagesDialog();
    } catch (e) {
      print("Error capturing images: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred. Please try again.")),
      );
    } finally {
      _isCapturing = false;
      if (_cameraController != null &&
          _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
    }
  }

  Future<void> _showCapturedImagesDialog() async {
    int currentImageIndex = 0;
    PageController _pageController = PageController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
              'Review Images (${currentImageIndex + 1}/${capturedImages.length})',
              style: TextStyle(fontSize: 16)),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentImageIndex = index;
                });
              },
              itemCount: capturedImages.length,
              itemBuilder: (context, index) {
                return Image.file(
                  File(capturedImages[index]),
                  height: 280,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Clear captured images
                setState(() {
                  capturedImages.clear();
                  _isCapturing = false;
                });

                // Close the dialog
                Navigator.pop(context);

                // Restart the camera and face detection
                await _initializeCamera();
                _startFaceDetection();
              },
              child: Text('Retry'),
            ),
            TextButton(
              onPressed: () async {
                await _stopCameraAndDispose();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfileScreen(capturedImages: capturedImages),
                  ),
                );
              },
              child: Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  void _startFaceDetection() {
    if (_cameraController == null) return;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isDetecting) return; // Skip if already detecting
      _isDetecting = true;

      _frameCount++;
      if (_frameCount % 3 != 0) {
        // Process every 3rd frame
        _isDetecting = false;
        return;
      }

      try {
        final List<Uint8List> planeData = [];
        for (Plane plane in image.planes) {
          final bytes = Uint8List.fromList(plane.bytes);
          planeData.add(bytes);
        }

        final inputImage = await _processImageData(
          planeData,
          image.width,
          image.height,
          image.planes[0].bytesPerRow,
        );

        if (inputImage == null) {
          _isDetecting = false;
          return;
        }

        final faces = await _faceDetector.processImage(inputImage);
        if (!mounted) return;

        setState(() {
          final imageWidth = image.width;
          _faces = faces.map((face) {
            Rect boundingBox = _isFrontCamera
                ? Rect.fromLTRB(
                    imageWidth - face.boundingBox.right,
                    face.boundingBox.top,
                    imageWidth - face.boundingBox.left,
                    face.boundingBox.bottom,
                  )
                : face.boundingBox;

            return Face(
              boundingBox: boundingBox,
              landmarks: face.landmarks,
              contours: face.contours,
              trackingId: face.trackingId,
              leftEyeOpenProbability: face.leftEyeOpenProbability,
              rightEyeOpenProbability: face.rightEyeOpenProbability,
              smilingProbability: face.smilingProbability,
              headEulerAngleX: face.headEulerAngleX,
              headEulerAngleY: face.headEulerAngleY,
              headEulerAngleZ: face.headEulerAngleZ,
            );
          }).toList();
        });

        // Start capturing images if a face is detected and not already capturing
        if (_faces.isNotEmpty &&
            !_isCapturing &&
            capturedImages.length < requiredImages) {
          _captureImages(); // Call the _captureImages method
        }
      } catch (e) {
        print("Error in face detection: $e");
      } finally {
        _isDetecting = false;
      }
    });
  }

  Future<InputImage?> _processImageData(
    List<Uint8List> planeData,
    int width,
    int height,
    int bytesPerRow,
  ) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (Uint8List bytes in planeData) {
        allBytes.putUint8List(bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final inputImageFormat = Platform.isAndroid
          ? InputImageFormat.nv21
          : InputImageFormat.bgra8888;

      final inputImageData = InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: _isFrontCamera
            ? InputImageRotation.rotation270deg
            : InputImageRotation.rotation90deg,
        format: inputImageFormat,
        bytesPerRow: bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );
    } catch (e) {
      print("Error processing image data: $e");
      return null;
    }
  }

  Future<void> _stopCameraAndDispose() async {
    try {
      if (_cameraController != null &&
          _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      await _cameraController?.dispose();
      _cameraController = null;
      await _faceDetector.close();
    } catch (e) {
      print("Error disposing resources: $e");
    }
  }

  Future<void> _toggleCamera() async {
    await _stopCameraAndDispose();
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    await _startCamera(_isFrontCamera ? _cameras[1] : _cameras[0]);
  }

  @override
  void dispose() {
    _stopCameraAndDispose();
    super.dispose();
  }

  Rect _transformRect(Rect rect, Size imageSize, Size screenSize) {
    double scaleX = screenSize.width / imageSize.width;
    double scaleY = screenSize.height / imageSize.height;

    double left, right;
    double offsetX = 300.0;

    if (_isFrontCamera) {
      left = rect.left * scaleX - offsetX;
      right = left + rect.width * scaleX;
    } else {
      left = rect.left * scaleX;
      right = left + rect.width * scaleX;
    }

    return Rect.fromLTRB(
      left,
      rect.top * scaleY,
      right,
      rect.bottom * scaleY,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    double captureProgress = capturedImages.length / requiredImages;

    return WillPopScope(
      onWillPop: () async {
        if (_isCapturing) {
          await _stopCameraAndDispose();
          capturedImages.clear();
          Navigator.pop(context);
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(
                  _cameraController!), // Improved camera preview aspect ratio
            ),
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  SizedBox(
                    height: 16, // Set the desired height
                    child: LinearProgressIndicator(
                      value: captureProgress,
                      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Capturing...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ..._faces.map((face) {
              final Rect faceRect = _transformRect(
                face.boundingBox,
                Size(_imageSize!.height, _imageSize!.width),
                MediaQuery.of(context).size,
              );

              return Positioned(
                left: faceRect.left,
                top: faceRect.top,
                width: faceRect.width,
                height: faceRect.height,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }).toList(),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: _toggleCamera,
                child: Icon(Icons.switch_camera,
                    color: Colors.white), // Changed icon color to white
                backgroundColor: Color(0xFF1E4FFE), // Added background color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
