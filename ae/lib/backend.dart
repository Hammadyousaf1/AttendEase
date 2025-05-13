import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FaceRecognitionBackend {
  static const String modelPath = 'assets/mobilefacenet.tflite';
  late Interpreter interpreter;
  final SupabaseClient supabaseClient = Supabase.instance.client;

  // Add class fields for storing embeddings and related data
  List<List<double>> storedEmbeddings = [];
  List<String> ids = [];
  List<String> names = [];

  FaceRecognitionBackend() {
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    interpreter = await Interpreter.fromAsset(modelPath);
    print("MobileFaceNet model loaded successfully");
  }

  Future<List<double>?> getEmbedding(File imageFile) async {
    try {
      // Load and preprocess image
      final imageBytes = await imageFile.readAsBytes();
      final image = decodeImage(imageBytes)!;
      final resizedImage = copyResize(image, width: 112, height: 112);

      // Convert to float32 array and normalize
      final input = List.generate(112 * 112 * 3, (index) {
        final pixel = resizedImage.getPixel(index % 112, index ~/ 112);
        return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
      }).expand((e) => e).toList();

      // Run inference
      final output = List.filled(192, 0.0).reshape([1, 192]);
      interpreter.run([input], output);

      // Normalize embedding
      final embedding = output[0];
      final norm = embedding.map((e) => e * e).reduce((a, b) => a + b).sqrt();
      if (norm == 0) {
        print("No face detected or invalid embedding!");
        return null;
      }
      return embedding.map((e) => e / norm).toList();
    } catch (e) {
      print("Error getting embedding: $e");
      return null;
    }
  }

  Future<void> loadEmbeddings() async {
    try {
      final response =
          await supabaseClient.from('users').select('id, name, embedding');

      final data = await response;

      if (data.isEmpty) {
        print("No embeddings found in the database.");
        // Reset if empty
        return;
      }

      List<String> ids = [];
      List<String> names = [];
      List<List<double>> storedEmbeddings = [];

      for (var user in data) {
        try {
          final embedding = List<double>.from(user['embedding']);
          if (embedding.length != 192) {
            // Ensure correct embedding size
            print("Skipping invalid embedding for ${user['name']}");
            continue;
          }
          ids.add(user['id']);
          names.add(user['name']);
          storedEmbeddings.add(embedding);
        } catch (e) {
          print("Error loading embedding for ${user['name']}: $e");
        }
      }

      // Store embeddings in memory
      if (storedEmbeddings.isNotEmpty) {
        // Convert to 2D array
      } else {
        // Set empty array
      }
    } catch (e) {
      print("Error loading embeddings: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> recognizeFace(
      File imageFile, String timestamp, String adminId) async {
    try {
      // Check if embeddings are loaded
      if (storedEmbeddings.isEmpty) {
        print("Debug: Reloading embeddings...");
        await loadEmbeddings();
      }

      if (storedEmbeddings.isEmpty) {
        print("Debug: No stored embeddings available.");
        throw Exception("No stored embeddings available.");
      }

      // Get embedding from image
      final embedding = await getEmbedding(imageFile);
      if (embedding == null) {
        print("Debug: No face detected in the image.");
        throw Exception("No face detected!");
      }

      // Calculate similarities
      double maxSimilarity = 0.0;
      int recognizedIndex = 0;
      for (int i = 0; i < storedEmbeddings.length; i++) {
        double similarity = 0.0;
        for (int j = 0; j < embedding.length; j++) {
          similarity += storedEmbeddings[i][j] * embedding[j];
        }
        if (similarity > maxSimilarity) {
          maxSimilarity = similarity;
          recognizedIndex = i;
        }
      }

      final recognizedName = names[recognizedIndex];
      print(
          "Debug: Recognized name: $recognizedName, Similarity: $maxSimilarity");

      // Dynamic Threshold Calculation
      double threshold = math.max(0.4, math.min(0.7, (maxSimilarity + 0.1)));
      print("Debug: Calculated threshold: $threshold");

      if (maxSimilarity < threshold) {
        print("Debug: Similarity below threshold, returning 'Unknown'.");
        return {
          "recognized_name": "Unknown",
          "similarity": maxSimilarity,
          "status": 200
        };
      }

      final recognizedUserId = ids[recognizedIndex];

      // Mark attendance
      final attendanceResponse = await markAttendance(
          recognizedUserId, recognizedName, timestamp, adminId);
      attendanceResponse["recognized_name"] = recognizedName;
      attendanceResponse["similarity"] = maxSimilarity;

      return attendanceResponse;
    } catch (e) {
      print("Debug: Exception occurred: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> trainUser(
      {required String name,
      required String userId,
      required String email,
      required String phone,
      required List<File> images,
      required String adminId}) async {
    try {
      List<List<double>> embeddings = [];
      print("Training user: $name with ID: $userId");

      for (int idx = 0; idx < images.length; idx++) {
        final image = images[idx];
        final tempPath = '${image.path}.temp';
        await image.copy(tempPath);
        print("Image saved to temporary path: $tempPath");

        final embedding = await getEmbedding(File(tempPath));

        // Upload 3rd image to Supabase bucket
        if (idx == 2) {
          // Third image (0-based index)
          // Convert to PNG format
          final pngPath = '${image.path}.png';
          await File(pngPath).writeAsBytes(await image.readAsBytes());

          // Upload to Supabase bucket
          await Supabase.instance.client.storage.from('profile').upload(
              '$userId.png', File(pngPath),
              fileOptions: FileOptions(contentType: 'image/png'));
          print("Profile image uploaded to Supabase bucket for user $userId");
          await File(pngPath).delete();
        }

        await File(tempPath).delete();

        if (embedding != null) {
          embeddings.add(embedding);
          print(
              "Valid embedding added. Total embeddings: ${embeddings.length}");
        } else {
          print("No embedding found for image: $tempPath");
        }
      }

      if (embeddings.isEmpty) {
        print("No valid embeddings generated.");
        return {'error': 'No valid embeddings generated.', 'status': 400};
      }

      // Calculate average embedding
      final avgEmbedding = List<double>.filled(192, 0.0);
      for (var embedding in embeddings) {
        for (int i = 0; i < 192; i++) {
          avgEmbedding[i] += embedding[i];
        }
      }
      for (int i = 0; i < 192; i++) {
        avgEmbedding[i] /= embeddings.length;
      }

      // Normalize embedding
      double norm = 0.0;
      for (var value in avgEmbedding) {
        norm += value * value;
      }
      norm = math.sqrt(norm);
      for (int i = 0; i < avgEmbedding.length; i++) {
        avgEmbedding[i] /= norm;
      }

      // Save to Supabase
      final data = {
        'id': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'embedding': avgEmbedding,
        'admin_id': adminId
      };
      await Supabase.instance.client.from('users').upsert(data);
      print("User data upserted to Supabase for ID: $userId");

      print("User trained successfully!");
      return {'message': 'User trained successfully!', 'status': 200};
    } catch (e) {
      print("Error during training: $e");
      return {'error': e.toString(), 'status': 500};
    }
  }

  Future<Map<String, dynamic>> markAttendance(
      String userId, String userName, String timestamp, String adminId) async {
    try {
      // Initialize response flags
      bool freezeStatus = false;
      bool timeInMarked = false;
      bool timeOutMarked = false;
      bool attendanceMarked = false;

      // Parse the provided timestamp
      String timestampStr = timestamp.replaceAll("Z", "");
      DateTime attendanceTime = DateTime.parse(timestampStr);

      // Get today's date in YYYY-MM-DD format
      String todayDate =
          "${attendanceTime.year}-${attendanceTime.month.toString().padLeft(2, '0')}-${attendanceTime.day.toString().padLeft(2, '0')}";

      // Fetch user info
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('phone, freeze_start, freeze_end')
          .eq('admin_id', adminId)
          .eq('id', userId)
          .single();

      if (userResponse == null) {
        throw Exception('User with ID $userId not found');
      }

      String phone = userResponse['phone'];
      String? freezeStart = userResponse['freeze_start'];
      String? freezeEnd = userResponse['freeze_end'];

      // Check freeze period
      if (freezeStart != null && freezeEnd != null) {
        DateTime freezeStartDt =
            DateTime.parse(freezeStart.replaceAll("Z", ""));
        DateTime freezeEndDt = DateTime.parse(freezeEnd.replaceAll("Z", ""));
        if (freezeStartDt.isBefore(attendanceTime) &&
            freezeEndDt.isAfter(attendanceTime)) {
          freezeStatus = true;
          print(
              'Attendance frozen for user $userName (ID: $userId) from $freezeStart to $freezeEnd');
          return {
            'freeze': freezeStatus,
            'time_in': timeInMarked,
            'time_out': timeOutMarked,
            'attendance_marked': attendanceMarked,
            'status': 200
          };
        }
      }

      // Check existing attendance for today
      final response = await Supabase.instance.client
          .from('attendance2')
          .select('id, time_in, time_out')
          .eq('admin_id', adminId)
          .eq('user_id', userId)
          .gte('time_in', '${todayDate}T00:00:00.000Z')
          .lte('time_in', '${todayDate}T23:59:59.999Z')
          .order('time_in', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final attendanceRecord = response[0];
        String attendanceId = attendanceRecord['id'];

        if (attendanceRecord['time_out'] == null) {
          // Update time_out
          await Supabase.instance.client.from('attendance2').update({
            'time_out': attendanceTime.toUtc().toIso8601String(),
            'admin_id': adminId
          }).eq('id', attendanceId);
          timeOutMarked = true;
          attendanceMarked = true;
        }
      } else {
        // Insert time_in
        await Supabase.instance.client.from('attendance2').insert({
          'user_id': userId,
          'user_name': userName,
          'Phone': phone,
          'time_in': attendanceTime.toUtc().toIso8601String(),
          'time_out': null,
          'admin_id': adminId
        });
        timeInMarked = true;
        attendanceMarked = true;
      }

      return {
        'freeze': freezeStatus,
        'time_in': timeInMarked,
        'time_out': timeOutMarked,
        'attendance_marked': attendanceMarked,
        'status': 200
      };
    } catch (e) {
      print('Error marking attendance: $e');
      rethrow;
    }
  }
}
