import 'dart:async';
import 'dart:io';
import 'package:ae/old/user_details_screen.dart';
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
  int _frameCount = 0; // Counter to track frames
  String recognizedPersonName = ""; // Variable to hold recognized person's name

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector(); // Initialize face detector only once
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras[1], // Use front camera
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

  void _startFaceDetection() {
    if (_cameraController == null) return;

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;

      // Increment frame count
      _frameCount++;

      // Process every 5th frame
      if (_frameCount % 5 != 0) {
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

  Future<void> _captureAndSendImage(CameraImage image) async {
    try {
      // Capture the image
      final XFile capturedImage = await _cameraController!.takePicture();
      final File imageFile = File(capturedImage.path);

      // Rotate the image to match camera orientation
      final rotatedImage = await _rotateImage(imageFile);

      // Send the image to the server
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
          'POST', Uri.parse('http://192.168.100.5:5000/recognize'));
      request.files.add(await http.MultipartFile.fromPath(
          'image', imageFile.path,
          contentType: MediaType('image', 'jpeg')));
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        setState(() {
          recognizedPersonName =
              responseData; // Assuming the response contains the name directly
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
      if (_cameraController != null &&
          _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      await _cameraController!.dispose();
      _cameraController = null;
      await _faceDetector.close();
    } catch (e) {
      print("Error disposing resources: $e");
    }
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
      left = screenSize.width -
          (rect.left * scaleX) -
          rect.width * scaleX -
          offsetX;
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

    //final size = MediaQuery.of(context).size;
    //final deviceRatio = size.width / size.height;
    //final previewRatio = _cameraController!.value.aspectRatio;

    String statusText = "Face the camera";
    Color statusColor = Colors.red;

    if (_faces.isNotEmpty) {
      statusText = recognizedPersonName.isNotEmpty
          ? "Recognized: $recognizedPersonName"
          : "Face Detected";
      statusColor = Colors.green;
    } else if (_isDetecting) {
      statusText = "Detecting...";
      statusColor = Colors.yellow;
    }

    return Scaffold(
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
                  border: Border.all(color: Colors.green, width: 8),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
