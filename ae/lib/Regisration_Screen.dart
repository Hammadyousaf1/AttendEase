import 'dart:async';
import 'dart:io';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:typed_data';
import 'package:ae/User_Input_Screen.dart';
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
  bool _faceDetectedOnce = false;

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
      for (int i = 0; i < requiredImages; i++) {
        if (_cameraController?.value.isInitialized ?? false) {
          try {
            final XFile image = await _cameraController!.takePicture();
            setState(() {
              capturedImages.add(image.path);
            });
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
      await _stopFaceDetection(); // Stop face detection before showing dialog
      await _showCapturedImagesDialog();
    } catch (e) {
      print("Error capturing images: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred. Please try again.")),
      );
    } finally {
      _isCapturing = false;
      _faceDetectedOnce = false;
      if (_cameraController != null &&
          _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
    }
  }

  Future<void> _stopFaceDetection() async {
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
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
          backgroundColor: Colors.white,
          title: Text(
              'Review Images (${currentImageIndex + 1}/${capturedImages.length})',
              style: TextStyle(fontSize: 16.sp)),
          content: Container(
            width: double.maxFinite,
            height: 300.h,
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
                  height: 280.h,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () async {
                await _stopCameraAndDispose();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Registrationscreen(),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.3),
                    width: 1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          const Color.fromARGB(255, 0, 0, 0).withOpacity(0.4),
                      blurRadius: 4.r,
                      offset: Offset(0, 3.h),
                    ),
                    BoxShadow(
                      color: const Color.fromARGB(255, 0, 0, 0),
                      offset: Offset(3.w, 4.h),
                    ),
                  ],
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
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
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.3),
                    width: 1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          const Color.fromARGB(255, 0, 0, 0).withOpacity(0.4),
                      blurRadius: 4.r,
                      offset: Offset(0, 3.h),
                    ),
                    BoxShadow(
                      color: Color.fromARGB(255, 8, 84, 146),
                      offset: Offset(3.w, 4.h),
                    ),
                  ],
                ),
                child: Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                ),
              ),
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

      _frameCount++;
      if (_frameCount % 3 != 0) {
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

        if (_faces.isNotEmpty && !_isCapturing && !_faceDetectedOnce) {
          _faceDetectedOnce = true;
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
    double offsetX = 300.w; // Use responsive width unit

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
              top: 50.h, // Use .h for responsive height
              left: 0,
              right: 0,
              child: Column(
                children: [
                  SizedBox(
                    height: 16.h, // Responsive height
                    child: LinearProgressIndicator(
                      value: captureProgress,
                      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                  SizedBox(height: 8.h), // Responsive spacing
                  Text(
                    "Capturing...",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp, // Responsive font size
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
                    border: Border.all(
                      color: Colors.green, 
                      width: 6.w // Responsive border width
                    ),
                    borderRadius: BorderRadius.circular(12.r), // Responsive border radius
                  ),
                ),
              );
            }).toList(),
            Positioned(
              bottom: 48.h,
              right: 36.w,
              child: FloatingActionButton(
                onPressed: _toggleCamera,
                child: Icon(Icons.switch_camera, color: Colors.white, size: 24.w),
                backgroundColor: Colors.black26,
                mini: true,
              ),
            ),
            Positioned(
              bottom: 48.h,
              left: 36.w,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Icon(Icons.arrow_back, color: Colors.white, size: 24.w),
                backgroundColor: Colors.black26,
                mini: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
