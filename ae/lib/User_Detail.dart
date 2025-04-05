import 'package:ae/User_Input_Screen.dart';
import 'package:ae/User_Management.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? profileImageUrl;

  const UserDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.profileImageUrl,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool isLoading = false;
  String? profileImageUrl;
  final supabase = Supabase.instance.client;

  int attendanceStreak = 0;
  int workingHours = 0;

  @override
  void initState() {
    super.initState();
    profileImageUrl = widget.profileImageUrl;
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      // Get current week's Monday
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final sunday = monday.add(const Duration(days: 6));
      final mondayStart = DateTime(monday.year, monday.month, monday.day);
      final sundayEnd =
          DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);

      // Get working hours from 'attendance2' table
      final response = await supabase
          .from('attendance2')
          .select()
          .eq('Phone', widget.userId)
          .gte('timestamp', mondayStart.toIso8601String())
          .lte('timestamp', sundayEnd.toIso8601String());

      Duration totalDuration = Duration.zero;

      for (var record in response) {
        if (record['working_hours'] != null) {
          final durationStr = record['working_hours'] as String;
          final parts = durationStr.split(':');
          if (parts.length >= 3) {
            final hours = int.tryParse(parts[0]) ?? 0;
            final minutes = int.tryParse(parts[1]) ?? 0;
            final seconds = int.tryParse(parts[2].split('.')[0]) ?? 0;
            totalDuration +=
                Duration(hours: hours, minutes: minutes, seconds: seconds);
          }
        }
      }

      setState(() {
        workingHours = totalDuration.inHours; // only hours
      });
    } catch (e) {
      print('Error fetching working hours: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: profileImageUrl != null
                            ? Image.network(
                                profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.person, size: 50),
                              )
                            : const Icon(Icons.person, size: 50),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: isLoading ? null : _showImageOptions,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 16,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${widget.userId}',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Yellow container and streak/working hours section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: workingHours < 40
                    ? Colors.yellow.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    workingHours < 40 ? Icons.warning : Icons.check_circle,
                    color: workingHours < 40 ? Colors.orange : Colors.green,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    workingHours < 40
                        ? " Hours Below Required!"
                        : " Attendance Full!",
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                    child: _buildStatCard(
                        "Attendance Streak", "$attendanceStreak 🔥")),
                SizedBox(width: 10.w),
                Expanded(
                    child: _buildStatCard("Working Hours", "$workingHours ⏳")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue)),
          SizedBox(height: 4.h),
          Text(value,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _showImageOptions() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Picture'),
        content: const Text('What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'upload'),
            child: const Text('Upload New'),
          ),
          if (profileImageUrl != null)
            TextButton(
              onPressed: () => Navigator.pop(context, 'delete'),
              child: const Text('Delete Current',
                  style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result == 'upload') {
      await updateProfilePicture();
    } else if (result == 'delete') {
      await deleteProfilePicture();
    }
  }

  Future<void> updateProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        setState(() => isLoading = true);
        final imageBytes = await File(pickedFile.path).readAsBytes();
        final image = img.decodeImage(imageBytes);
        final pngBytes = img.encodePng(image!);
        final tempFile = File('${pickedFile.path}.png');
        await tempFile.writeAsBytes(pngBytes);

        final fileName = '${widget.userId}.png';

        await supabase.storage.from('profile_pictures').upload(
              fileName,
              tempFile,
              fileOptions: FileOptions(contentType: 'image/png', upsert: true),
            );

        final newImageUrl = await supabase.storage
            .from('profile_pictures')
            .createSignedUrl(fileName, 3600);

        await tempFile.delete();

        setState(() {
          profileImageUrl = newImageUrl;
          isLoading = false;
        });
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e')),
        );
      }
    }
  }

  Future<void> deleteProfilePicture() async {
    try {
      setState(() => isLoading = true);
      final fileName = '${widget.userId}.png';

      await supabase.storage.from('profile_pictures').remove([fileName]);

      setState(() {
        profileImageUrl = null;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture deleted successfully')),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete profile picture: $e')),
      );
    }
  }
}
