import 'dart:io';

import 'package:ae/LandingScreen/UserLand.dart';
import 'package:ae/UserManagement/Dashboard.dart';
import 'package:ae/LandingScreen/AdminScreen.dart';
import 'package:ae/ModelScreen/Recognition_Screen.dart';
import 'package:ae/UserManagement/User_Management.dart';
import 'package:ae/auth/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserlandingScreen extends StatefulWidget {
  final String? email;
  const UserlandingScreen({super.key, this.email});

  @override
  State<UserlandingScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserlandingScreen> {
  final supabase = Supabase.instance.client;
  bool isAttendanceFrozen = false;
  int _selectedIndex = 2;
  int workingHours = 0;
  int totalworkinghours = 0;
  int attendanceStreak = 0;
  bool isLoading = false;
  String? profileImageUrl;
  String userName = '';
  String? phoneNumber;
  String? userId = '';

  @override
  void initState() {
    super.initState();
    fetchUserId().then((_) {
      profileImageUrl =
          'https://arlexrfzqvahegtolcjp.supabase.co/storage/v1/object/public/profile/${userId}.png';
      fetchAttendanceData();
      checkFreezeStatus();
      fetchUserPhoneNumber(); // Fetch phone number on initialization
      fetchWorkingHours();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> fetchUserId() async {
    try {
      final email = widget.email ??
          (ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?)?['email'] ??
          Supabase.instance.client.auth.currentUser?.email ??
          '';

      if (email.isNotEmpty) {
        final response = await supabase
            .from('users')
            .select('id')
            .eq('email', email)
            .single();

        setState(() {
          userId = response['id'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user ID: $e')),
      );
    }
  }

  Future<void> checkFreezeStatus() async {
    final response = await supabase
        .from('users')
        .select('freeze_start, freeze_end')
        .eq('id', userId ?? '')
        .single();

    setState(() {
      isAttendanceFrozen =
          response['freeze_start'] != null && response['freeze_end'] != null;
      isLoading = false;
    });
  }

  Future<void> fetchAttendanceData() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([
        fetchWorkingHours(),
        fetchAttendanceStreak(),
        calculateTotalWorkingHours(),
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
    // Fetch phone number and name using user ID
    try {
      final response = await supabase
          .from('users')
          .select('phone, name')
          .eq('id', userId ?? '')
          .limit(1);

      if (response.isNotEmpty) {
        setState(() {
          phoneNumber = response[0]['phone'];
          userName = response[0]['name'] ?? userName;
        });
      }
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  Future<void> fetchWorkingHours() async {
    try {
      // Get current date and calculate start of week (Monday)
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      // Fetch attendance records for the current week
      final response = await supabase
          .from('attendance2')
          .select('time_in, time_out')
          .eq('user_id', userId ?? '')
          .gte('time_in', startOfWeek.toIso8601String())
          .lte('time_in', endOfWeek.toIso8601String());

      double totalHours = 0;
      for (final record in response) {
        if (record['time_in'] != null && record['time_out'] != null) {
          final timeIn = DateTime.parse(record['time_in'].toString());
          final timeOut = DateTime.parse(record['time_out'].toString());

          // Only count hours for weekdays (Monday to Friday)
          if (timeIn.weekday >= DateTime.monday &&
              timeIn.weekday <= DateTime.friday) {
            totalHours += timeOut.difference(timeIn).inHours.toDouble();
          }
        }
      }
      setState(() => workingHours = totalHours.round());
    } catch (e) {
      print('Error fetching working hours: $e');
      rethrow;
    }
  }

  Future<void> calculateTotalWorkingHours() async {
    try {
      // Fetch all attendance records for the user
      final response = await supabase
          .from('attendance2')
          .select('time_in, time_out')
          .eq('user_id', userId ?? '');

      double totalHours = 0;
      for (final record in response) {
        if (record['time_in'] != null && record['time_out'] != null) {
          final timeIn = DateTime.parse(record['time_in'].toString());
          final timeOut = DateTime.parse(record['time_out'].toString());

          // Calculate hours for each record and add to total
          totalHours += timeOut.difference(timeIn).inHours.toDouble();
        }
      }
      setState(() => totalworkinghours = totalHours.round());
    } catch (e) {
      print('Error calculating total working hours: $e');
      rethrow;
    }
  }

  Future<void> fetchAttendanceStreak() async {
    try {
      final response = await supabase
          .from('attendance2')
          .select('time_in')
          .eq('user_id', userId ?? '')
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
        backgroundColor: Colors.white,
        title: Center(
            child: Text('Profile Picture', style: TextStyle(fontSize: 20.sp))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
                child: Text('What would you like to do?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: const Color.fromARGB(255, 75, 75, 75)))),
            SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pop(context, 'upload'),
              child: Container(
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
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: const Center(
                    child: Text('Upload New',
                        style: TextStyle(color: Colors.white))),
              ),
            ),
            SizedBox(
              height: 10.h,
            ),
            if (profileImageUrl != null)
              GestureDetector(
                onTap: () => Navigator.pop(context, 'delete'),
                child: Container(
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
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  child: const Center(
                    child: Text('Delete Current',
                        style: TextStyle(color: Colors.black)),
                  ),
                ),
              ),
          ],
        ),
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

        final fileName = '${userId}.png';

        await supabase.storage.from('profile').upload(
              fileName,
              tempFile,
              fileOptions: FileOptions(contentType: 'image/png', upsert: true),
            );

        final newImageUrl = await supabase.storage
            .from('profile')
            .createSignedUrl(fileName, 3600);

        await tempFile.delete();

        setState(() {
          profileImageUrl = newImageUrl;
          isLoading = false;
        });
      } catch (e) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> deleteProfilePicture() async {
    try {
      setState(() => isLoading = true);
      final fileName = '${userId}.png';

      await supabase.storage.from('profile').remove([fileName]);

      setState(() {
        profileImageUrl = null;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Widget _buildWeeklyTracker() {
    final now = DateTime.now();
    final dayOfWeek = now.weekday;

    if (dayOfWeek >= 3) {
      return Image.asset(
        workingHours < 20
            ? 'assets/indicator3.png'
            : (workingHours < 40
                ? 'assets/indicator2.png'
                : 'assets/indicator1.png'),
        height: 64.h,
      );
    }
    return SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                'assets/logo5.png',
                height: 28.h,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(Icons.logout, color: Colors.black, size: 28.w),
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh all data
          await Future.wait([
            fetchAttendanceData(),
            checkFreezeStatus(),
            fetchUserPhoneNumber(),
            fetchWorkingHours(),
            fetchUserId(),
          ]);
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 100.w,
                        height: 100.h,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: profileImageUrl != null
                              ? Image.network(
                                  profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.person, size: 50.w),
                                )
                              : Icon(Icons.person, size: 50.w),
                        ),
                      ),
                      Positioned(
                        bottom: 4.h,
                        right: 4.w,
                        child: GestureDetector(
                          onTap: isLoading
                              ? null
                              : _showImageOptions, // Open image options dialog
                          child: Container(
                            padding: EdgeInsets.all(4.0.w),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: isLoading
                                ? SizedBox(
                                    width: 16.w,
                                    height: 16.h,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    Icons.edit,
                                    color: Colors.black,
                                    size: 16.w,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${userName ?? "Null"}',
                          style: TextStyle(
                            fontSize: 16.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'ID: ${userId ?? "N/A"}',
                          style:
                              TextStyle(fontSize: 12.sp, color: Colors.black87),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Phone: ${phoneNumber ?? "Not Found"}',
                          style:
                              TextStyle(fontSize: 12.sp, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        onPressed: () async {
                          final TextEditingController nameController =
                              TextEditingController(text: userName);
                          final TextEditingController phoneController =
                              TextEditingController(text: phoneNumber ?? '');

                          await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.white,
                              title: Center(
                                  child: Text('Edit User Info',
                                      style: TextStyle(fontSize: 16.sp))),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: nameController,
                                      decoration: InputDecoration(
                                        labelText: 'Name',
                                        labelStyle: TextStyle(fontSize: 14.sp),
                                      ),
                                      style: TextStyle(fontSize: 14.sp),
                                    ),
                                    SizedBox(height: 16.h),
                                    TextField(
                                      controller: phoneController,
                                      decoration: InputDecoration(
                                        labelText: 'Phone Number',
                                        labelStyle: TextStyle(fontSize: 14.sp),
                                      ),
                                      keyboardType: TextInputType.phone,
                                      style: TextStyle(fontSize: 14.sp),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                Center(
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width * 0.8,
                                    child: GestureDetector(
                                      onTap: () async {
                                        try {
                                          await supabase.from('users').update({
                                            'name': nameController.text,
                                            'phone': phoneController.text,
                                          }).eq('id', userId ?? '');

                                          setState(() {
                                            phoneNumber = phoneController.text;
                                          });

                                          // Show success popup
                                          await showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor: Colors.white,
                                              title: Center(
                                                  child: Text('Profile Updated',
                                                      style: TextStyle(
                                                          fontSize: 16.sp))),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Center(
                                                    child: Text(
                                                      'Looks good!\nWe have saved your changes.',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                          color: const Color
                                                              .fromARGB(
                                                              255, 75, 75, 75),
                                                          fontSize: 14.sp),
                                                    ),
                                                  ),
                                                  SizedBox(height: 24.h),
                                                  GestureDetector(
                                                    onTap: () {
                                                      Navigator.pop(
                                                          context); // Close success popup
                                                      Navigator.pop(
                                                          context); // Close edit dialog
                                                      Navigator.pushReplacement(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) {
                                                            // Create a new instance with the same email
                                                            final newScreen =
                                                                UserlandingScreen(
                                                              email:
                                                                  widget.email,
                                                            );
                                                            // Force rebuild by using a UniqueKey
                                                            return KeyedSubtree(
                                                              key: UniqueKey(),
                                                              child: newScreen,
                                                            );
                                                          },
                                                        ),
                                                      );
                                                    },
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 24.w,
                                                              vertical: 12.h),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.r),
                                                        border: Border.all(
                                                          color: Colors.black
                                                              .withOpacity(0.3),
                                                          width: 1.w,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: const Color
                                                                    .fromARGB(
                                                                    255,
                                                                    0,
                                                                    0,
                                                                    0)
                                                                .withOpacity(
                                                                    0.4),
                                                            blurRadius: 4.r,
                                                            offset:
                                                                Offset(0, 3.h),
                                                          ),
                                                          BoxShadow(
                                                            color:
                                                                Color.fromARGB(
                                                                    255,
                                                                    8,
                                                                    84,
                                                                    146),
                                                            offset: Offset(
                                                                3.w, 4.h),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          'Got it!',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 14.sp),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Error updating user: $e',
                                                    style: TextStyle(
                                                        fontSize: 14.sp))),
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 24.w, vertical: 12.h),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius:
                                              BorderRadius.circular(8.r),
                                          border: Border.all(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            width: 1.w,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color.fromARGB(
                                                      255, 0, 0, 0)
                                                  .withOpacity(0.4),
                                              blurRadius: 4.r,
                                              offset: Offset(0, 3.h),
                                            ),
                                            BoxShadow(
                                              color: Color.fromARGB(
                                                  255, 8, 84, 146),
                                              offset: Offset(3.w, 4.h),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Save',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14.sp),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: Icon(Icons.edit, color: Colors.black),
                      ),
                      IconButton(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: Colors.white,
                                title: Center(
                                    child: Text('Confirm Deletion',
                                        style: TextStyle(fontSize: 16.sp))),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Center(
                                      child: Text(
                                        'You are about to erase your journey\nAll progress will be gone forever.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: const Color.fromARGB(
                                                255, 75, 75, 75),
                                            fontSize: 14.sp),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  Column(
                                    children: [
                                      Center(
                                        child: SizedBox(
                                          width: 300.w,
                                          child: GestureDetector(
                                            onTap: () async {
                                              try {
                                                await supabase
                                                    .from('users')
                                                    .delete()
                                                    .eq('id', userId ?? '');

                                                Navigator.of(context)
                                                    .pushReplacement(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        UserlandScreen(),
                                                  ),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          'Error deleting user: $e',
                                                          style: TextStyle(
                                                              fontSize:
                                                                  14.sp))),
                                                );
                                              }
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 24.w,
                                                  vertical: 12.h),
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                                border: Border.all(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  width: 1.w,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color.fromARGB(
                                                            255, 0, 0, 0)
                                                        .withOpacity(0.4),
                                                    blurRadius: 4.r,
                                                    offset: Offset(0, 3.h),
                                                  ),
                                                  BoxShadow(
                                                    color: Color.fromARGB(
                                                        255, 8, 84, 146),
                                                    offset: Offset(3.w, 4.h),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Proceed...',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14.sp),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10.h),
                                      Center(
                                        child: SizedBox(
                                          width: 300.w,
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.pop(context);
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 24.w,
                                                  vertical: 12.h),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                                border: Border.all(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  width: 1.w,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color.fromARGB(
                                                            255, 0, 0, 0)
                                                        .withOpacity(0.4),
                                                    blurRadius: 4.r,
                                                    offset: Offset(0, 3.h),
                                                  ),
                                                  BoxShadow(
                                                    color: Color.fromARGB(
                                                        255, 33, 32, 32),
                                                    offset: Offset(3.w, 4.h),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 14.sp),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon:
                            Icon(Icons.delete, size: 24.w, color: Colors.black),
                      ),
                    ],
                  )
                ],
              ),
              SizedBox(height: 12.h),
              _buildWeeklyTracker(),
              SizedBox(height: 12.h),
              Text(
                "Weekly Tracker",
                style: TextStyle(fontSize: 16.sp),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                        "Attendance\nStreak", "$attendanceStreak 🔥"),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _buildStatCard("Working\nHours", "$workingHours ⏱️"),
                  ),
                ],
              ),
              SizedBox(
                height: 16.h,
              ),
              Text(
                "Attendance History",
                style: TextStyle(fontSize: 16.sp),
              ),
              SizedBox(height: 2.h),
              FutureBuilder(
                future: supabase
                    .from('attendance2')
                    .select()
                    .eq('user_id', userId ?? '')
                    .order('time_in', ascending: false),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading attendance data'));
                  }
                  final attendanceList = snapshot.data as List<dynamic>? ?? [];
                  if (attendanceList.isEmpty) {
                    return Center(
                      child: Text(
                        "No attendance records found",
                        style:
                            TextStyle(fontSize: 12.sp, color: Colors.black26),
                      ),
                    );
                  }
                  return Container(
                    height: 150.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.3),
                        width: 1.w,
                      ),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.all(8.w),
                      itemCount: attendanceList.length,
                      itemBuilder: (context, index) {
                        final record = attendanceList[index];
                        return Container(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.withOpacity(0.3),
                                width: 1.w,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat('MMM d').format(
                                      DateTime.parse(record['time_in'])),
                                  style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.black.withOpacity(0.7)),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'In: ${DateFormat.jm().format(DateTime.parse(record['time_in']))}',
                                  style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.black.withOpacity(0.7)),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  record['time_out'] != null
                                      ? 'Out: ${DateFormat.jm().format(DateTime.parse(record['time_out']))}'
                                      : 'Out: N/A',
                                  style: TextStyle(
                                      fontSize: 10.sp,
                                      color: Colors.black.withOpacity(0.7)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              SizedBox(height: 12.h),
              Text(
                "Rewards",
                style: TextStyle(fontSize: 16.sp),
              ),
              SizedBox(height: 2.h),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRewards(
                        Image.asset(
                          'assets/level1.gif',
                          height: 80.h,
                        ),
                        'Level 1',
                        totalworkinghours >= 75
                            ? "50 Hours\nCompleted"
                            : "50 Working\nHours",
                        isActive:
                            totalworkinghours > 50 && totalworkinghours < 75,
                        isCompleted: totalworkinghours >= 75),
                    SizedBox(
                      width: 12.w,
                    ),
                    _buildRewards(
                        Image.asset(
                          'assets/level2.gif',
                          height: 80.h,
                        ),
                        'Level 2',
                        totalworkinghours >= 100
                            ? "75 Hours\nCompleted"
                            : "75 Working\nHours",
                        isActive:
                            totalworkinghours > 75 && totalworkinghours < 100,
                        isCompleted: totalworkinghours >= 100),
                    SizedBox(
                      width: 12.w,
                    ),
                    _buildRewards(
                        Image.asset(
                          'assets/level3.gif',
                          height: 80.h,
                        ),
                        'Level 3',
                        totalworkinghours >= 150
                            ? "100 Hours\nCompleted"
                            : "100 Working\nHours",
                        isActive:
                            totalworkinghours > 100 && totalworkinghours < 150,
                        isCompleted: totalworkinghours >= 150),
                    SizedBox(
                      width: 12.w,
                    ),
                    _buildRewards(
                        Image.asset(
                          'assets/level3.gif',
                          height: 80.h,
                        ),
                        'Level 4',
                        "150 Working\nHours",
                        isActive: totalworkinghours >= 150,
                        isCompleted: false),
                  ],
                ),
              ),
              SizedBox(
                height: 12.h,
              ),
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        if (!isAttendanceFrozen)
                          // Freeze Attendance button (your exact existing code)
                          GestureDetector(
                            onTap: () async {
                              DateTime? startDate;
                              DateTime? endDate;
                              final startController = TextEditingController();
                              final endController = TextEditingController();

                              await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: Center(
                                      child: Text('Choose Duration',
                                          style: TextStyle(fontSize: 16.sp))),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: startController,
                                        readOnly: true,
                                        style: TextStyle(
                                            fontSize: 14
                                                .sp), // Added to reduce text size
                                        decoration: InputDecoration(
                                          labelText: 'Start Date',
                                          suffixIcon: IconButton(
                                            icon: Icon(Icons.calendar_today),
                                            onPressed: () async {
                                              final picked =
                                                  await showDatePicker(
                                                context: context,
                                                initialDate: DateTime.now(),
                                                firstDate: DateTime(2000),
                                                lastDate: DateTime(2100),
                                                builder: (context, child) {
                                                  return Theme(
                                                    data: Theme.of(context)
                                                        .copyWith(
                                                      textTheme: GoogleFonts
                                                          .kronaOneTextTheme(
                                                        TextTheme(
                                                          bodySmall: TextStyle(
                                                              fontSize: 12.sp,
                                                              color:
                                                                  Colors.grey),
                                                        ),
                                                      ),
                                                      datePickerTheme:
                                                          DatePickerThemeData(
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.r),
                                                        ),
                                                        dayStyle: GoogleFonts
                                                            .kronaOne(
                                                                fontSize: 12.sp,
                                                                color: Colors
                                                                    .blue),
                                                        yearStyle: GoogleFonts
                                                            .kronaOne(
                                                                fontSize: 12.sp,
                                                                color: Colors
                                                                    .grey),
                                                        headerHeadlineStyle:
                                                            GoogleFonts.kronaOne(
                                                                fontSize: 24.sp,
                                                                color: Colors
                                                                    .black),
                                                        weekdayStyle:
                                                            GoogleFonts.kronaOne(
                                                                fontSize: 12.sp,
                                                                color: Colors
                                                                    .grey),
                                                      ),
                                                    ),
                                                    child: child!,
                                                  );
                                                },
                                              );
                                              if (picked != null) {
                                                startDate = picked;
                                                startController.text =
                                                    DateFormat('dd MMM yyyy')
                                                        .format(picked);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                      TextField(
                                        controller: endController,
                                        readOnly: true,
                                        style: TextStyle(fontSize: 14.sp),
                                        decoration: InputDecoration(
                                          labelText: 'End Date',
                                          suffixIcon: IconButton(
                                            icon: Icon(Icons.calendar_today),
                                            onPressed: () async {
                                              final picked =
                                                  await showDatePicker(
                                                context: context,
                                                initialDate: DateTime.now(),
                                                firstDate: DateTime(2000),
                                                lastDate: DateTime(2100),
                                                builder: (context, child) {
                                                  return Theme(
                                                    data: Theme.of(context)
                                                        .copyWith(
                                                      textTheme: GoogleFonts
                                                          .kronaOneTextTheme(
                                                        TextTheme(
                                                          bodySmall: TextStyle(
                                                              fontSize: 12.sp,
                                                              color:
                                                                  Colors.grey),
                                                        ),
                                                      ),
                                                      datePickerTheme:
                                                          DatePickerThemeData(
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.r),
                                                        ),
                                                        dayStyle: GoogleFonts
                                                            .kronaOne(
                                                                fontSize: 12.sp,
                                                                color: Colors
                                                                    .blue),
                                                        yearStyle: GoogleFonts
                                                            .kronaOne(
                                                                fontSize: 12.sp,
                                                                color: Colors
                                                                    .grey),
                                                        headerHeadlineStyle:
                                                            GoogleFonts.kronaOne(
                                                                fontSize: 24.sp,
                                                                color: Colors
                                                                    .black),
                                                        weekdayStyle:
                                                            GoogleFonts.kronaOne(
                                                                fontSize: 12.sp,
                                                                color: Colors
                                                                    .grey),
                                                      ),
                                                    ),
                                                    child: child!,
                                                  );
                                                },
                                              );
                                              if (picked != null) {
                                                endDate = picked;
                                                endController.text =
                                                    DateFormat('dd MMM yyyy')
                                                        .format(picked);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    Column(
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            if (startDate != null &&
                                                endDate != null) {
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (context) => Center(
                                                  child: Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
                                                ),
                                              );

                                              try {
                                                // Check if end date is in the past
                                                if (endDate!
                                                    .isBefore(DateTime.now())) {
                                                  // If end date is passed, clear the freeze
                                                  await supabase
                                                      .from('users')
                                                      .update({
                                                    'freeze_start': null,
                                                    'freeze_end': null,
                                                  }).eq('id', userId ?? '');
                                                } else {
                                                  // Set new freeze period
                                                  await supabase
                                                      .from('users')
                                                      .update({
                                                    'freeze_start': startDate!
                                                        .toIso8601String(),
                                                    'freeze_end': endDate!
                                                        .toIso8601String(),
                                                  }).eq('id', userId ?? '');
                                                }

                                                Navigator.pop(
                                                    context); // Close loading
                                                Navigator.pop(
                                                    context); // Close date picker
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => Center(
                                                    child: AlertDialog(
                                                      backgroundColor:
                                                          Colors.white,
                                                      contentPadding:
                                                          EdgeInsets.all(24.w),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16.r),
                                                      ),
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'All Set',
                                                            style: TextStyle(
                                                              fontSize: 18.sp,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                          SizedBox(
                                                              height: 16.h),
                                                          Text(
                                                            endDate!.isBefore(
                                                                    DateTime
                                                                        .now())
                                                                ? 'Attendance freeze\ncleared as end date\nhas passed'
                                                                : 'Attendance freeze\nfor chosen duration',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                                fontSize:
                                                                    14.sp),
                                                          ),
                                                          SizedBox(
                                                              height: 24.h),
                                                          Center(
                                                            child:
                                                                GestureDetector(
                                                              onTap: () {
                                                                Navigator.pop(
                                                                    context);
                                                                setState(() {
                                                                  isAttendanceFrozen =
                                                                      !endDate!.isBefore(
                                                                          DateTime
                                                                              .now());
                                                                });
                                                                fetchAttendanceData();
                                                              },
                                                              child: Container(
                                                                width: double
                                                                    .infinity,
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        vertical:
                                                                            12.h),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .blue,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8.r),
                                                                  border: Border
                                                                      .all(
                                                                    color: Colors
                                                                        .black
                                                                        .withOpacity(
                                                                            0.3),
                                                                    width: 1.w,
                                                                  ),
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: const Color
                                                                              .fromARGB(
                                                                              255,
                                                                              0,
                                                                              0,
                                                                              0)
                                                                          .withOpacity(
                                                                              0.4),
                                                                      blurRadius:
                                                                          4.r,
                                                                      offset:
                                                                          Offset(
                                                                              0,
                                                                              3.h),
                                                                    ),
                                                                    BoxShadow(
                                                                      color: Color.fromARGB(
                                                                          255,
                                                                          8,
                                                                          84,
                                                                          146),
                                                                      offset: Offset(
                                                                          3.w,
                                                                          4.h),
                                                                    ),
                                                                  ],
                                                                ),
                                                                child: Center(
                                                                  child: Text(
                                                                    'Got it',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          14.sp,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                Navigator.pop(
                                                    context); // Close loading
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => Center(
                                                    child: AlertDialog(
                                                      backgroundColor:
                                                          Colors.white,
                                                      contentPadding:
                                                          EdgeInsets.all(24),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                      ),
                                                      content: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'Error',
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                          SizedBox(height: 16),
                                                          Text(
                                                            'Failed to set Freeze Period',
                                                            textAlign: TextAlign
                                                                .center,
                                                          ),
                                                          SizedBox(height: 24),
                                                          Center(
                                                            child:
                                                                GestureDetector(
                                                              onTap: () =>
                                                                  Navigator.pop(
                                                                      context),
                                                              child: Container(
                                                                width: 100,
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        vertical:
                                                                            12),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .white,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                  border: Border
                                                                      .all(
                                                                    color: Colors
                                                                        .black
                                                                        .withOpacity(
                                                                            0.3),
                                                                    width: 1.w,
                                                                  ),
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: const Color
                                                                              .fromARGB(
                                                                              255,
                                                                              0,
                                                                              0,
                                                                              0)
                                                                          .withOpacity(
                                                                              0.4),
                                                                      blurRadius:
                                                                          4.r,
                                                                      offset:
                                                                          Offset(
                                                                              0,
                                                                              3.h),
                                                                    ),
                                                                    BoxShadow(
                                                                      color: Color.fromARGB(
                                                                          255,
                                                                          8,
                                                                          84,
                                                                          146),
                                                                      offset: Offset(
                                                                          3.w,
                                                                          4.h),
                                                                    ),
                                                                  ],
                                                                ),
                                                                child: Center(
                                                                  child: Text(
                                                                    'Try later',
                                                                    style:
                                                                        TextStyle(
                                                                      color: Colors
                                                                          .black,
                                                                      fontSize:
                                                                          14.sp,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }
                                            } else {
                                              showDialog(
                                                context: context,
                                                builder: (context) => Center(
                                                  child: AlertDialog(
                                                    backgroundColor:
                                                        Colors.white,
                                                    contentPadding:
                                                        EdgeInsets.all(24.w),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16.r),
                                                    ),
                                                    content: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          'Error',
                                                          style: TextStyle(
                                                            fontSize: 18.sp,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                        SizedBox(height: 16.h),
                                                        Text(
                                                          'Please select both\nstart and end dates',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: TextStyle(
                                                            fontSize: 14.sp,
                                                          ),
                                                        ),
                                                        SizedBox(height: 24.h),
                                                        Center(
                                                          child:
                                                              GestureDetector(
                                                            onTap: () =>
                                                                Navigator.pop(
                                                                    context),
                                                            child: Container(
                                                              width: double
                                                                  .infinity,
                                                              padding: EdgeInsets
                                                                  .symmetric(
                                                                      vertical:
                                                                          12.h),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color:
                                                                    Colors.blue,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8.r),
                                                                border:
                                                                    Border.all(
                                                                  color: Colors
                                                                      .black
                                                                      .withOpacity(
                                                                          0.3),
                                                                  width: 1.w,
                                                                ),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: const Color
                                                                            .fromARGB(
                                                                            255,
                                                                            0,
                                                                            0,
                                                                            0)
                                                                        .withOpacity(
                                                                            0.4),
                                                                    blurRadius:
                                                                        4.r,
                                                                    offset:
                                                                        Offset(
                                                                            0,
                                                                            3.h),
                                                                  ),
                                                                  BoxShadow(
                                                                    color: Color
                                                                        .fromARGB(
                                                                            255,
                                                                            8,
                                                                            84,
                                                                            146),
                                                                    offset:
                                                                        Offset(
                                                                            3.w,
                                                                            4.h),
                                                                  ),
                                                                ],
                                                              ),
                                                              child: Center(
                                                                child: Text(
                                                                  'OK',
                                                                  style:
                                                                      TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        14.sp,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12.h,
                                                horizontal: 24.w),
                                            decoration: BoxDecoration(
                                              color: Colors.blue,
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                              border: Border.all(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                width: 1.w,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color.fromARGB(
                                                          255, 0, 0, 0)
                                                      .withOpacity(0.6),
                                                  blurRadius: 4.r,
                                                  offset: Offset(0, 3.h),
                                                ),
                                                BoxShadow(
                                                  color: Color.fromARGB(
                                                      255, 8, 84, 146),
                                                  offset: Offset(4.w, 5.h),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Save',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14.sp,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 12.h),
                                        GestureDetector(
                                          onTap: () => Navigator.pop(context),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12.h,
                                                horizontal: 24.w),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                              border: Border.all(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                width: 1.w,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color.fromARGB(
                                                          255, 0, 0, 0)
                                                      .withOpacity(0.6),
                                                  blurRadius: 4.r,
                                                  offset: Offset(0, 3.h),
                                                ),
                                                BoxShadow(
                                                  color: Color.fromARGB(
                                                      255, 33, 32, 32),
                                                  offset: Offset(4.w, 5.h),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14.sp,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              height: 56.h,
                              width: MediaQuery.of(context).size.width,
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.3),
                                  width: 1.w,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(255, 0, 0, 0)
                                        .withOpacity(0.6),
                                    blurRadius: 4.r,
                                    offset: Offset(0, 3.h),
                                  ),
                                  BoxShadow(
                                    color: Color.fromARGB(255, 8, 84, 146),
                                    offset: Offset(5.w, 6.h),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Freeze Attendance',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14.sp),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        if (!isAttendanceFrozen) SizedBox(height: 12.h),
                        if (isAttendanceFrozen)
                          // Resume Attendance button (your exact existing code)
                          GestureDetector(
                            onTap: () async {
                              try {
                                await supabase.from('users').update({
                                  'freeze_start': null,
                                  'freeze_end': null,
                                }).eq('id', userId ?? '');
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    contentPadding: EdgeInsets.all(24.w),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                    title: Center(
                                        child: Text('Lets Go',
                                            style: TextStyle(fontSize: 20.sp))),
                                    content: Text(
                                      'Attendance\nresumed successfully',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14.sp),
                                    ),
                                    actions: [
                                      Center(
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.pop(
                                                context); // Close dialog
                                            setState(() {
                                              isAttendanceFrozen =
                                                  false; // Update state
                                            });
                                            fetchAttendanceData(); // Refresh data
                                          },
                                          child: Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12.h),
                                            decoration: BoxDecoration(
                                              color: Colors.blue,
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                              border: Border.all(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                width: 1.w,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color.fromARGB(
                                                          255, 0, 0, 0)
                                                      .withOpacity(0.6),
                                                  blurRadius: 4.r,
                                                  offset: Offset(0, 3.h),
                                                ),
                                                BoxShadow(
                                                  color: Color.fromARGB(
                                                      255, 8, 84, 146),
                                                  offset: Offset(4.w, 5.h),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                'OK',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14.sp,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } catch (e) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Colors.white,
                                    title: Text('Error'),
                                    content:
                                        Text('Failed to resume attendance: $e'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            child: Container(
                              height: 56.h,
                              width: MediaQuery.of(context).size.width,
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.3),
                                  width: 1.w,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromARGB(255, 0, 0, 0)
                                        .withOpacity(0.6),
                                    blurRadius: 4.r,
                                    offset: Offset(0, 3.h),
                                  ),
                                  BoxShadow(
                                    color: Color.fromARGB(255, 33, 32, 32),
                                    offset: Offset(5.w, 6.h),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Resume Attendance',
                                style: TextStyle(
                                    color: const Color.fromARGB(255, 0, 0, 0),
                                    fontSize: 14.sp),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      child: Container(
        height: 120.h,
        width: MediaQuery.of(context).size.width * 0.4, // Responsive width
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black26, width: 1.w),
          borderRadius: BorderRadius.circular(8.r), // Responsive radius
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 14.sp, // Responsive font size
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
                textAlign: TextAlign.center),
            SizedBox(height: 8.h), // Responsive spacing
            Text(value,
                style: TextStyle(
                    fontSize: 20.sp, // Responsive font size
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

Widget _buildRewards(Image image, String title, String desc,
    {bool isActive = true, bool isCompleted = false}) {
  return Container(
    width: 140.w,
    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(
          color: isActive ? Colors.black26 : Colors.grey, width: 1.w),
      color: isCompleted
          ? Colors.white
          : (isActive ? Colors.white : Colors.grey[200]),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 4.r,
          offset: Offset(0, 2.h),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            isCompleted || isActive
                ? Colors.transparent
                : const Color.fromARGB(255, 240, 238, 238),
            BlendMode.saturation,
          ),
          child: image,
        ),
        SizedBox(height: 10.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: isCompleted
                ? Colors.green
                : (isActive ? Colors.blue : Colors.grey[600]),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          desc,
          style: TextStyle(
            fontSize: 12.sp,
            color: isCompleted
                ? Colors.black
                : (isActive ? Colors.black : Colors.grey[600]),
          ),
        ),
      ],
    ),
  );
}
