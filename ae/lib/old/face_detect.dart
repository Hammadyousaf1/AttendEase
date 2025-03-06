import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionScreen extends StatefulWidget {
  @override
  _FaceDetectionScreenState createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  CameraController? _cameraController;
  late List<CameraDescription> _cameras;
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  List<Face> _faces = [];
  Size? _imageSize;
  bool _isFrontCamera = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeFaceDetector();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras[1], // Use front camera
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    setState(() {});
    _imageSize = _cameraController!.value.previewSize;
    _isFrontCamera = _cameraController!.description.lensDirection == CameraLensDirection.front;
    _startFaceDetection();
  }

  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableClassification: false,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  void _startFaceDetection() {
    _cameraController!.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;

      // First flip the image horizontally if using front camera
      final inputImage = await _processAndFlipCameraImage(image);
      if (inputImage == null) {
        _isDetecting = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);
      if (mounted) {
        setState(() {
          // Flip face coordinates horizontally if using front camera
          if (_isFrontCamera) {
            _faces = faces.map((face) {
              final flippedBoundingBox = Rect.fromLTRB(
                image.width - face.boundingBox.right,
                face.boundingBox.top,
                image.width - face.boundingBox.left,
                face.boundingBox.bottom
              );
              // Since Face class doesn't have copyWith, create a new Face instance
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
                headEulerAngleZ: face.headEulerAngleZ
              );
            }).toList();
          } else {
            _faces = faces;
          }
        });
      }

      _isDetecting = false;
    });
  }

  Future<InputImage?> _processAndFlipCameraImage(CameraImage image) async {
    try {
      // Create a buffer for the image data
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      // For front camera, we need to flip the image horizontally
      final inputImageData = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _isFrontCamera ? InputImageRotation.rotation270deg : InputImageRotation.rotation90deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: inputImageData,
      );
    } catch (e) {
      print("Error processing image: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Rect _transformRect(Rect rect, Size imageSize, Size screenSize) {
  double scaleX = screenSize.width / imageSize.width;
  double scaleY = screenSize.height / imageSize.height;

  double left, right;
  double offsetX = 300.0;

  if (_isFrontCamera) {
    // Flip the bounding box in the opposite direction
    left = rect.left * scaleX - offsetX;
    right = left + rect.width * scaleX;
  } else {
    // Standard transformation for the back camera
    left = screenSize.width - (rect.left * scaleX) - rect.width * scaleX - offsetX;
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

    final size = MediaQuery.of(context).size;
    final deviceRatio = size.width / size.height;
    final previewRatio = _cameraController!.value.aspectRatio;

    // Determine the text and color based on detection state
    String statusText = "Face the camera";
    Color statusColor = Colors.red;

    if (_faces.isNotEmpty) {
      statusText = "Face Detected";
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
              Size(_imageSize!.height, _imageSize!.width), // Swap width and height
              MediaQuery.of(context).size,
            );

            return Positioned(
              left: faceRect.left,
              top: faceRect.top,
              width: faceRect.width,
              height: faceRect.height,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 8),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

}
