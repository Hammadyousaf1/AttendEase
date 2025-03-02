import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:ae/old/user_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionScreen extends StatefulWidget {
  @override
  _FaceDetectioncaptureScreenState createState() => _FaceDetectioncaptureScreenState();
}

class _FaceDetectioncaptureScreenState extends State<FaceDetectionScreen> {
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
  int _frameCount = 0; // Counter to track frames

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector(); // Initialize face detector only once
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _startCamera(_isFrontCamera ? _cameras[1] : _cameras[0]); // Start with front or back camera
  }

  Future<void> _startCamera(CameraDescription camera) async {
    if (_cameraController != null) {
      await _cameraController!.dispose(); // Dispose of the previous camera controller
    }

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    setState(() {
      _imageSize = _cameraController!.value.previewSize;
      _isFrontCamera = _cameraController!.description.lensDirection == CameraLensDirection.front;
    });

    _startFaceDetection();
  }

  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableClassification: false,
        enableTracking: true,
        performanceMode: FaceDetectorMode.fast, // Use fast mode for real-time performance
      ),
    );
  }

  Future<void> _captureImages() async {
    if (_isCapturing) return;
    _isCapturing = true;

    try {
      // Capture 5 images with 100ms delay while keeping face detection active
      for (int i = capturedImages.length; i < requiredImages; i++) {
        if (_cameraController?.value.isInitialized ?? false) {
          try {
            final XFile image = await _cameraController!.takePicture();
            setState(() {
              capturedImages.add(image.path);
            });

            if (i < requiredImages - 1) {
              await Future.delayed(Duration(milliseconds: 100));
            }
          } catch (e) {
            print("Error capturing image: $e");
            break; // Exit the loop if an error occurs
          }
        }
      }

      if (!mounted) return;
      await _showCapturedImagesDialog();
    } catch (e) {
      print("Error capturing images: $e");
    } finally {
      _isCapturing = false;
      // Stop the camera stream after capturing images
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
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
          title: Text('Review Images (${currentImageIndex + 1}/${capturedImages.length})'),
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
              onPressed: () {
                this.setState(() {
                  capturedImages.clear();
                  _isCapturing = false;
                });
                Navigator.pop(context);
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
                    builder: (context) => ProfileScreen(capturedImages: capturedImages),
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
      if (_isDetecting) return;
      _isDetecting = true;

      // Increment frame count
      _frameCount++;

      // Process every 3rd frame
      if (_frameCount % 3 != 0) {
        _isDetecting = false;
        return;
      }

      try {
        // Create a copy of the image data immediately to avoid buffer access issues
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
            // Use bounding box for both front and back cameras
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

        if (_faces.isNotEmpty && !_isCapturing && capturedImages.length < requiredImages) {
          _captureImages();
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

      final inputImageFormat = Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888;

      final inputImageData = InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: _isFrontCamera ? InputImageRotation.rotation270deg : InputImageRotation.rotation90deg,
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
      // Stop face detection before stopping the camera stream
      if (_isDetecting) {
        _isDetecting = false; // Ensure face detection is stopped
      }
      
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
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
    await _stopCameraAndDispose(); // Stop the camera and face detection first
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    await _startCamera(_isFrontCamera ? _cameras[1] : _cameras[0]); // Then start the new camera
  }

  @override
  void dispose() {
    _stopCameraAndDispose(); // Ensure resources are released before leaving the screen
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
      // Adjusting for back camera
      left = rect.left * scaleX; // Adjusting left position for back camera
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

    String statusText = "Face the camera";
    Color statusColor = Colors.red;

    if (_faces.isNotEmpty) {
      statusText = _isCapturing
          ? "Capturing images... (${capturedImages.length}/$requiredImages)"
          : "Face Detected";
      statusColor = Colors.green;
    } else if (_isDetecting) {
      statusText = "Detecting...";
      statusColor = Colors.yellow;
    }

    return WillPopScope(
      onWillPop: () async {
        if (_isCapturing) {
          await _stopCameraAndDispose();
          capturedImages.clear(); // Clear captured images
          Navigator.pop(context); // Go back to the main screen
          return false; // Prevent default back action
        }
        return true; // Allow default back action
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.black,
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1 / _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                ),
              );
            }).toList(),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                onPressed: _toggleCamera,
                child: Icon(Icons.switch_camera),
              ),
            ),
          ],
        ),
      ),
    );
  }
}