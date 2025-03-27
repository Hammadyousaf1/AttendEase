import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
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
  bool _isLive = false; // Added for liveness check
  int _blinkCount = 0; // Added for blink detection
  DateTime? _lastBlinkTime; // Added for blink timing

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector(); // Initialize face detector only once
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras[_isFrontCamera ? 1 : 0], // Use front or back camera based on _isFrontCamera
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
        performanceMode:
            FaceDetectorMode.fast, // Use fast mode for real-time performance
      ),
    );
  }

  bool _checkLiveness(Face face) {
    // Check for blinking
    if (face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
      if (face.leftEyeOpenProbability! < 0.3 && face.rightEyeOpenProbability! < 0.3) {
        if (_lastBlinkTime == null || DateTime.now().difference(_lastBlinkTime!) > Duration(seconds: 1)) {
          _blinkCount++;
          _lastBlinkTime = DateTime.now();
        }
      }
    }

    // Check head movement
    if (face.headEulerAngleX != null && face.headEulerAngleY != null) {
      if (face.headEulerAngleX!.abs() > 15 || face.headEulerAngleY!.abs() > 15) {
        return true;
      }
    }

    // Check for smile
    if (face.smilingProbability != null && face.smilingProbability! > 0.8) {
      return true;
    }

    // Require at least 2 blinks for liveness
    return _blinkCount >= 2;
  }

  void _startFaceDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isDetecting) return; // Check if the previous frame is still being processed
      _isDetecting = true;

      // Increment frame count
      _frameCount++;

      // Process every 5th frame
      if (_frameCount % 3 != 0) {
        _isDetecting = false;
        return;
      }

      // Add a small delay before processing the image buffer
      await Future.delayed(Duration(milliseconds: 50));

      try {
        // Check if the image buffer is accessible
        if (image.planes.isEmpty) {
          print("Image buffer inaccessible, restarting camera...");
          await _restartCamera(); // Restart camera if buffer is inaccessible
          _isDetecting = false;
          return;
        }

        // Create a copy of the image data immediately to avoid buffer access issues
        final List<Uint8List> planeData = [];
        for (Plane plane in image.planes) {
          try {
            // Use a copy of the bytes to avoid buffer access issues
            final bytes = Uint8List.fromList(plane.bytes);
            planeData.add(bytes);
          } catch (e) {
            print("Error accessing plane data: $e");
            _isDetecting = false;
            return;
          }
        }

        // Ensure the image is not closed before processing
        if (_cameraController == null || !_cameraController!.value.isInitialized) {
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
            _isLive = _checkLiveness(_faces.first);
            if (_isLive) {
              _captureAndSendImage(image);
            }
          }
        });
      } catch (e) {
        print("Error in face detection: $e");
      } finally {
        _isDetecting = false; // Mark detection as complete
      }
    });
  }

  Future<void> _restartCamera() async {
    await _stopCameraAndDispose();
    await _initializeCamera(); // Reinitialize the camera
  }

  Future<void> _captureAndSendImage(CameraImage image) async {
    try {
      // Capture the image
      final XFile capturedImage = await _cameraController!.takePicture();
      final File imageFile = File(capturedImage.path);

      // Rotate the image to match camera orientation
      final rotatedImage = await _rotateImage(imageFile);

      // Send the image to the server along with the current time
      await _sendImageToServer(rotatedImage);
    } catch (e) {
      print("Error capturing and sending image: $e");
    }
  }

  Future<File> _rotateImage(File imageFile) async {
    // Implement rotation logic based on camera orientation
    // This is a placeholder for the actual rotation logic
    return imageFile; // Return the original file for now
  }

  Future<void> _sendImageToServer(File imageFile) async {
    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse('http://192.168.163.219:8000/recognize'));
      request.files.add(await http.MultipartFile.fromPath(
          'image', imageFile.path,
          contentType: MediaType('image', 'jpeg')));

      // Get the current device time
      final currentTime = DateTime.now().toIso8601String();
      // Debug: Print the timestamp being sent
      print("Sending timestamp: $currentTime");

      request.fields['timestamp'] = currentTime; // Add timestamp to the request

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);
        setState(() {
          recognizedPersonName = data['recognized_name']; // Extracting recognized name
          attendanceMarked = data['attendance_marked']; // Extract attendance status
        });
        print("Image sent successfully");
      } else {
        print("Failed to send image: ${response.statusCode}");
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
        _isDetecting = false; // Ensure face detection is stopped
      }
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
        await Future.delayed(Duration(milliseconds: 100)); // Delay before disposing
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
      _isFrontCamera = !_isFrontCamera; // Toggle camera
    });
    _restartCamera(); // Restart camera with the new setting
  }

  @override
  void dispose() {
    super.dispose(); // Call super.dispose() first
    _stopCameraAndDispose();
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

    if (attendanceMarked) {
      statusText = "Attendance marked for $recognizedPersonName";
      statusColor = Colors.green;
      Future.delayed(Duration(seconds: 3), () {
        setState(() {
          attendanceMarked = false; // Reset attendance status after 3 seconds
        });
      });
    } else if (_faces.isNotEmpty) {
      if (!_isLive) {
        statusText = "Checking Liveness";
        statusColor = Colors.orange;
      } else {
        statusText = "Recognizing...";
        statusColor = const Color(0xFF1E4FFE);
      }
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
              child: CameraPreview(_cameraController!), // Improved camera preview aspect ratio
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () async {
                await _stopCameraAndDispose(); // Ensure proper cleanup
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/'); // Navigate to main screen
                }
              },
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.switch_camera, color: Color(0xFF1E4FFE)),
              onPressed: _switchCamera,
            ),
          ),
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.5),
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
                      border: Border.all(color: isRecognized ? Colors.green : Colors.white, width: 6),
                      borderRadius: BorderRadius.circular(12), // Added radius
                    ),
                  ),
                  Positioned(
                    top: 10, // Adjust as needed to position the text above the rectangle
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        isRecognized ? recognizedPersonName : "",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isRecognized ? const Color.fromARGB(255, 255, 255, 255) : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
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
