import 'package:ae/Dashboard.dart';
import 'package:ae/Home_Screen.dart';
import 'package:ae/Recognition_Screen.dart';
import 'package:ae/Regisration_Screen.dart';
import 'package:ae/User_Management.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final List<String> capturedImages;
  final Map<String, dynamic>? userData;

  const ProfileScreen({Key? key, required this.capturedImages, this.userData})
      : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isSubmitting = false;
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    if (widget.userData != null) {
      _nameController.text = widget.userData!['name'] ?? '';
      _idController.text = widget.userData!['id'] ?? '';
      _phoneController.text = widget.userData!['phone'] ?? '';
    }
  }
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _submitData() async {
    if (_nameController.text.isEmpty ||
        _idController.text.isEmpty ||
        _phoneController.text.length != 13) {
      // Check for phone number length
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Please fill in all fields and ensure phone number is 11 digits")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://192.168.100.6:5000/train'));
      request.fields['name'] = _nameController.text;
      request.fields['id'] = _idController.text;
      request.fields['phone'] =
          _phoneController.text; // Add phone number to request

      for (var imagePath in widget.capturedImages) {
        request.files
            .add(await http.MultipartFile.fromPath('images', imagePath));
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload data!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(
              widget.userData != null ? "Profile Updated" : "Profile Created"),
          content: Text(widget.userData != null
              ? "Your profile has been successfully updated!"
              : "Your profile has been successfully registered!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context, true);
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: Color.fromARGB(255, 0, 0, 0), size: 24.w),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Registrationscreen()),
                  ),
                ),
                Image.asset(
                  'assets/logo5.png',
                  height: 55.h,
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Text(
              widget.userData != null ? "Edit Profile" : "Create Profile",
              style: TextStyle(fontSize: 20.sp),
            ),
            SizedBox(height: 20.h),
            if (widget.capturedImages.isNotEmpty && widget.userData == null)
              Center(
                child: CircleAvatar(
                  radius: 100.r,
                  backgroundImage: FileImage(File(widget.capturedImages.first)),
                ),
              ),
            SizedBox(height: 24.h),
            TextField(
              controller: _nameController,
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                labelText: "Name",
                labelStyle: TextStyle(fontSize: 14.sp, color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _idController,
              enabled: widget.userData == null,
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                labelText: "ID",
                labelStyle: TextStyle(fontSize: 14.sp, color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: _phoneController,
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                labelText: "Whatsapp No",
                labelStyle: TextStyle(fontSize: 14.sp, color: Colors.black),
                prefixText: "+92 ",
                prefixStyle: TextStyle(fontSize: 14.sp, color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.black),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            GestureDetector(
              onTap: _isSubmitting ? null : _submitData,
              child: Container(
                width: double.infinity,
                height: 52.h,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.3),
                    width: 1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 1.5,
                      blurRadius: 8,
                      offset: Offset(1, 2),
                    ),
                    BoxShadow(
                      color: Color.fromARGB(255, 8, 84, 146),
                      offset: Offset(3, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: _isSubmitting
                      ? CircularProgressIndicator.adaptive(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : Text(
                          widget.userData != null
                              ? "Update Profile"
                              : "Create Profile",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                ),
              ),
            ),
            SizedBox(height: 20.h), // Added extra space for better scrolling
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (index == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            } else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FaceRectScreen()),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserManagementScreen()),
              );
            } else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
            } else {
              _onItemTapped(index);
            }
          },
          type: BottomNavigationBarType.fixed,
          items:  <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 24.w),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.scanFace, size: 24.w),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people, size: 24.w),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard, size: 24.w),
              label: 'Dashboard',
            ),
          ],
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.black54,
          selectedLabelStyle: TextStyle(fontSize: 10.sp),
          unselectedLabelStyle: TextStyle(fontSize: 10.sp),
        ),
      ),
    );
  }
}
