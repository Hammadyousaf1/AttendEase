import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.userData != null) {
      _nameController.text = widget.userData!['name'] ?? '';
      _idController.text = widget.userData!['id'] ?? '';
      _phoneController.text = widget.userData!['phone'] ?? '';
    }
  }

  Future<void> _submitData() async {
    if (_nameController.text.isEmpty ||
        _idController.text.isEmpty ||
        _phoneController.text.length != 11) {
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
      if (widget.userData != null) {
        // Update existing user
        await supabase.from('users').update({
          'name': _nameController.text,
          'phone': _phoneController.text,
        }).eq('id', widget.userData!['id']);
      } else {
        // Create new user
        var request = http.MultipartRequest(
            'POST', Uri.parse('http://172.31.12.218:8000/train'));
        request.fields['name'] = _nameController.text;
        request.fields['id'] = _idController.text;
        request.fields['phone'] = _phoneController.text;

        for (var imagePath in widget.capturedImages) {
          request.files
              .add(await http.MultipartFile.fromPath('images', imagePath));
        }

        var response = await request.send();

        if (response.statusCode == 200) {
          // Also add to Supabase
          await supabase.from('users').insert({
            'id': _idController.text,
            'name': _nameController.text,
            'phone': _phoneController.text,
          });
        } else {
          throw Exception('Failed to upload data');
        }
      }

      _showSuccessDialog();
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
      body: Padding(
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
                  onPressed: () => Navigator.pop(context),
                ),
                Image.asset(
                  'assets/logo2.png',
                  height: 35.h,
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: double.infinity,
                  height: 52.h,
                  margin: EdgeInsets.only(left: 3.w, top: 8.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: Colors.black,
                  ),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: Size(double.infinity, 52.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: _isSubmitting
                      ? CircularProgressIndicator.adaptive()
                      : Text(
                          widget.userData != null
                              ? "Update Profile"
                              : "Create Profile",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14.sp,
                          ),
                        ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
