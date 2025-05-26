import 'dart:io';

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

class UserlandScreen extends StatefulWidget {
  final String? email;
  const UserlandScreen({super.key, this.email});

  @override
  State<UserlandScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserlandScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo5.png',
              height: 56.h,
            ),
            SizedBox(height: 20.h),
            Image.asset(
              'assets/error.jpg',
              height: 200.h,
              width: 200.w,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 20.h),
            Text(
              "User not Found\nPlease Register Yourself",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp),
            ),
            SizedBox(height: 20.h),
            
            SizedBox(
              width: 300.w,
              child: GestureDetector(
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 52.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
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
                  child: Center(
                    child: Text(
                      'Go Back',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
