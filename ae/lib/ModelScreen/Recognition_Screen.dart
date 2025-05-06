import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ae/LandingScreen/AdminScreen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class FaceRectScreen extends StatefulWidget {
  @override
  _FaceRectScreenState createState() => _FaceRectScreenState();
}

class _FaceRectScreenState extends State<FaceRectScreen> {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  List<Face> _faces = [];
  Size? _imageSize;
  bool _isFrontCamera = true;
  int _frameCount = 0;
  String recognizedPersonName = "";
  bool attendanceMarked = false;
  bool freezeStatus = false;
  bool timeInMarked = false;
  bool timeOutMarked = false;
  DateTime? _lastRequestTime;

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras[_isFrontCamera ? 1 : 0],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    setState(() {});
    _imageSize = _cameraController!.value.previewSize;
    _isFrontCamera = _cameraController!.description.lensDirection ==
        CameraLensDirection.front;
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

  void _startFaceDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;

      _frameCount++;

      if (_frameCount % 3 != 0) {
        _isDetecting = false;
        return;
      }

      await Future.delayed(Duration(milliseconds: 50));

      try {
        if (image.planes.isEmpty) {
          print("Image buffer inaccessible, restarting camera...");
          await _restartCamera();
          _isDetecting = false;
          return;
        }

        final List<Uint8List> planeData = [];
        for (Plane plane in image.planes) {
          try {
            final bytes = Uint8List.fromList(plane.bytes);
            planeData.add(bytes);
          } catch (e) {
            print("Error accessing plane data: $e");
            _isDetecting = false;
            return;
          }
        }

        if (_cameraController == null ||
            !_cameraController!.value.isInitialized) {
          _isDetecting = false;
          return;
        }

        final inputImage = await _processImageData(
            planeData, image.width, image.height, image.planes[0].bytesPerRow);

        if (inputImage == null) {
          _isDetecting = false;
          return;
        }

        final faces = await _faceDetector.processImage(inputImage);
        if (!mounted) return;

        final imageWidth = image.width;
        setState(() {
          if (_isFrontCamera) {
            _faces = faces.map((face) {
              final flippedBoundingBox = Rect.fromLTRB(
                  imageWidth - face.boundingBox.right,
                  face.boundingBox.top,
                  imageWidth - face.boundingBox.left,
                  face.boundingBox.bottom);
              return Face(
                  boundingBox: flippedBoundingBox,
                  landmarks: face.landmarks,
                  contours: face.contours,
                  trackingId: face.trackingId,
                  leftEyeOpenProbability: face.leftEyeOpenProbability,
                  rightEyeOpenProbability: face.rightEyeOpenProbability,
                  smilingProbability: face.smilingProbability,
                  headEulerAngleX: face.headEulerAngleX,
                  headEulerAngleY: face.headEulerAngleY,
                  headEulerAngleZ: face.headEulerAngleZ);
            }).toList();
          } else {
            _faces = faces;
          }

          if (_faces.isNotEmpty) {
            _captureAndSendImage(image);
          }
        });
      } catch (e) {
        print("Error in face detection: $e");
      } finally {
        _isDetecting = false;
      }
    });
  }

  Future<void> _restartCamera() async {
    await _stopCameraAndDispose();
    await _initializeCamera();
  }

  Future<void> _captureAndSendImage(CameraImage image) async {
    try {
      final XFile capturedImage = await _cameraController!.takePicture();
      final File imageFile = File(capturedImage.path);
      final rotatedImage = await _rotateImage(imageFile);
      await _sendImageToServer(rotatedImage);
    } catch (e) {
      print("Error capturing and sending image: $e");
    }
  }

  Future<File> _rotateImage(File imageFile) async {
    return imageFile;
  }

  Future<void> _sendImageToServer(File imageFile) async {
    try {
      // Check if 90 seconds have passed since last request
      if (_lastRequestTime != null &&
          DateTime.now().difference(_lastRequestTime!) <
              Duration(seconds: 10)) {
        print("Waiting for 90 seconds between requests");
        return;
      }

      final request = http.MultipartRequest(
          'POST',
          Uri.parse(
              'http://192.168.100.3:5000/recognize'));
      request.files.add(await http.MultipartFile.fromPath(
          'image', imageFile.path,
          contentType: MediaType('image', 'jpeg')));

      final currentTime = DateTime.now().toIso8601String();
      print("Sending timestamp: $currentTime");

      request.fields['timestamp'] = currentTime;

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);

        setState(() {
          recognizedPersonName = data['recognized_name'];
          Future.delayed(Duration(seconds: 10), () {
            if (mounted) {
              setState(() {
                recognizedPersonName = "";
              });
            }
          });
          attendanceMarked = data['attendance_marked'];
          freezeStatus = data['freeze'];
          timeInMarked = data['time_in'];
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                timeInMarked = false;
              });
            }
          });
          timeOutMarked = data['time_out'];
          Future.delayed(Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                timeOutMarked = false;
              });
            }
          });
        });

        print("Image sent successfully");
        _lastRequestTime = DateTime.now(); // Update last request time
      } else {
        print("Failed to send image. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending image to server: $e");
    }
  }

  Future<InputImage?> _processImageData(
      List<Uint8List> planeData, int width, int height, int bytesPerRow) async {
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
      if (_isDetecting) {
        _isDetecting = false;
      }
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        await Future.delayed(Duration(milliseconds: 100));
        await _cameraController!.dispose();
        _cameraController = null;
      }
      await _faceDetector.close();
    } catch (e) {
      print("Error disposing resources: $e");
    }
  }

  void _switchCamera() {
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
    _restartCamera();
  }

  @override
  void dispose() {
    super.dispose();
    _stopCameraAndDispose();
  }

  Rect _transformRect(Rect rect, Size imageSize, Size screenSize) {
    double scaleX = screenSize.width / imageSize.width;
    double scaleY = screenSize.height / imageSize.height;

    double left, right;
    double offsetX = 300.w;

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

    if (freezeStatus) {
      statusText = "Attendance Freezed";
      statusColor = const Color.fromARGB(255, 111, 80, 251);
      Future.delayed(Duration(seconds: 3), () {
        setState(() {
          freezeStatus = false; // Reset attendance status after 3 seconds
        });
      });
    } else if (attendanceMarked) {
      statusText = "Marked $recognizedPersonName";
      statusColor = Colors.green;
      Future.delayed(Duration(seconds: 3), () {
        setState(() {
          attendanceMarked = false; // Reset attendance status after 3 seconds
        });
      });
    } else if (_faces.isNotEmpty) {
      statusText = "Recognizing...";
      statusColor = Colors.blue;
    } else if (_isDetecting) {
      statusText = "Recognizing...";
      statusColor = Colors.yellow;
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: Colors.black,
            child: AspectRatio(
              aspectRatio: _cameraController!.value.aspectRatio,
              child: CameraPreview(
                  _cameraController!), // Improved camera preview aspect ratio
            ),
          ),
          Positioned(
            bottom: 48,
            left: 36,
            child: GestureDetector(
              onTap: () async {
                await _stopCameraAndDispose(); // Ensure proper cleanup
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                }
              },
              child: Container(
                width: 40,
                height: 40,
                child: Center(
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            right: 36,
            child: GestureDetector(
              onTap: _switchCamera,
              child: Container(
                width: 40,
                height: 40,
                child: Center(
                  child: Icon(Icons.switch_camera, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
          Positioned(
            top: 120.h, // Use .h for responsive height
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                    vertical: 8.h,
                    horizontal: 16.w), // Use .h and .w for responsive padding
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(
                      8.r), // Use .r for responsive border radius
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp, // Use .sp for responsive font size
                  ),
                ),
              ),
            ),
          ),
          if (timeInMarked)
            Positioned(
              bottom: 70,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    "Time In",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
            ),
          if (timeOutMarked)
            Positioned(
              bottom: 70,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    "Time Out",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
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

            bool isRecognized = recognizedPersonName.isNotEmpty;

            return Positioned(
              left: faceRect.left,
              top: faceRect.top,
              width: faceRect.width,
              height: faceRect.height,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: isRecognized ? Colors.green : Colors.white,
                          width: 6.w),
                      borderRadius: BorderRadius.circular(12), // Added radius
                    ),
                  ),
                  Positioned(
                    top: 10
                        .h, // Adjust as needed to position the text above the rectangle
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        isRecognized ? recognizedPersonName : "",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isRecognized
                              ? const Color.fromARGB(255, 255, 255, 255)
                              : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
