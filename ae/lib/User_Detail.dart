import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
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
  final supabase = Supabase.instance.client;
  int workingHours = 0;
  int attendanceStreak = 0;
  bool isLoading = false;
  String? profileImageUrl;
  String? phoneNumber; // Added phone number variable

  @override
  void initState() {
    super.initState();
    profileImageUrl = widget.profileImageUrl;
    fetchAttendanceData();
    fetchUserPhoneNumber(); // Fetch phone number on initialization
  }

  Future<void> fetchAttendanceData() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([
        fetchWorkingHours(),
        fetchAttendanceStreak(),
      ]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchUserPhoneNumber() async {
    // New function to fetch phone number
    try {
      final response = await supabase
          .from('attendance2')
          .select('Phone')
          .eq('user_name', widget.userName)
          .limit(1);

      setState(() {
        phoneNumber = response[0]['Phone'];
      });
    } catch (e) {
      print('Error fetching phone number: $e');
    }
  }

  Future<void> fetchWorkingHours() async {
    try {
      final response = await supabase
          .from('attendance2')
          .select('time_in, time_out')
          .eq('user_name', widget.userName);

      double totalHours = 0;
      for (final record in response) {
        if (record['time_in'] != null && record['time_out'] != null) {
          final timeIn = DateTime.parse(record['time_in'].toString());
          final timeOut = DateTime.parse(record['time_out'].toString());
          totalHours += timeOut.difference(timeIn).inHours.toDouble();
        }
      }
      setState(() => workingHours = totalHours.round());
    } catch (e) {
      print('Error fetching working hours: $e');
      rethrow;
    }
  }

  Future<void> fetchAttendanceStreak() async {
    try {
      final response = await supabase
          .from('attendance2')
          .select('time_in')
          .eq('user_name', widget.userName)
          .order('time_in', ascending: false);

      int streak = 0;
      DateTime? prevDate;

      for (final record in response) {
        if (record['time_in'] == null) continue;

        final parsedDate = DateTime.parse(record['time_in'].toString()).toUtc();
        final currentDate =
            DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

        if (prevDate == null) {
          streak = 1;
          prevDate = currentDate;
        } else if (prevDate.difference(currentDate).inDays == 1) {
          streak++;
          prevDate = currentDate;
        } else if (prevDate.isAfter(currentDate)) {
          continue;
        } else {
          break;
        }
      }
      setState(() => attendanceStreak = streak);
    } catch (e) {
      print('Error fetching attendance streak: $e');
      rethrow;
    }
  }

  // New function for showing image options (upload or delete)
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

  // Function to upload a new profile picture
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile UI with edit functionality
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
                        onTap: isLoading
                            ? null
                            : _showImageOptions, // Open image options dialog
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
                      const SizedBox(height: 8),
                      Text(
                        'Phone: ${phoneNumber ?? "kalia"}', // Added phone number display
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(onPressed: () {}, icon: Icon(Icons.edit)),
                    IconButton(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Confirm Deletion'),
                                content: Text(
                                    'Are you sure you want to delete this user?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmed == true) {
                            // Call the delete function here
                            await supabase
                                .from('users')
                                .delete()
                                .eq('id', widget.userId);
                            Navigator.pop(
                                context); // Move back to the previous screen
                          }
                        },
                        icon: Icon(Icons.delete))
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),

            const SizedBox(width: 8),
            Image.asset(
              workingHours < 20
                  ? 'assets/indicator3.png'
                  : (workingHours < 35
                      ? 'assetsindicator2.png'
                      : 'assets/indicator1.png'),
              height: 60.h,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                      "Attendance\n    Streak", "$attendanceStreak 🔥"),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard("Working Hours", "$workingHours ⏳"),
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRewards(
                      Image.asset(
                        'assets/level1.gif',
                        height: 80, // Increased height from 30 to 50
                      ),
                      'Level 1',
                      "20 Working\nHours"),
                  SizedBox(
                    width: 10,
                  ),
                  _buildRewards(
                      Image.asset(
                        'assets/level2.gif',
                        height: 80, // Increased height from 30 to 50
                      ),
                      'Level 2',
                      "30 Working\nHours"),
                  SizedBox(
                    width: 10,
                  ),
                  _buildRewards(
                      Image.asset(
                        'assets/level3.gif',
                        height: 80, // Increased height from 30 to 50
                      ),
                      'Level 3',
                      "40 Working\nHours"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      child: Container(
        height: 100.h,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue)),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

Widget _buildRewards(Image image, String title, String desc) {
  return Container(
    width: 130.w,
    padding: EdgeInsets.all(6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.blue),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        image,
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          desc,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    ),
  );
}
