import 'dart:async';

import 'package:ae/RecognitionScreen.dart';
import 'package:ae/RegisrationScreen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String currentime = '';
  late Timer _timer;
  @override
  @override
  void initState() {
    super.initState();
    updateTime();
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      if (mounted) {
        updateTime();
      }
    });
  }

  void updateTime() {
    final String formattedTime =
        DateFormat('hh:mm:ss a').format(DateTime.now());
    setState(() {
      currentime = formattedTime;
    });
  }

  List<String> images = [
    'assets/Frame (3).png',
    'assets/Frame (2).png',
    'assets/Frame (1).png',
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 32,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/logo2.png',
                  height: 40.h,
                ),
                Text(
                  'WELCOME',
                  style: TextStyle(
                      color: Color.fromARGB(255, 7, 22, 47),
                      fontSize: 28.sp,
                      letterSpacing: -4.0), // Reduced letter spacing
                ),
              ],
            ),
          ),
          SizedBox(
            height: 12.h,
          ),
          CarouselSlider(
            items: images
                .map((e) => Center(child: Image(image: AssetImage(e))))
                .toList(),
            options: CarouselOptions(
                viewportFraction: 2,
                aspectRatio: 16 / 9.5,
                autoPlay: true,
                enlargeCenterPage: true,
                enlargeFactor: 0.4),
          ),
          SizedBox(
            height: 8.h,
          ),
          Padding(
            padding: EdgeInsets.only(left: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today is',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 18.sp),
                ),
                Text(
                  DateFormat.EEEE().format(DateTime.now()),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 14.sp),
                ),
                Text(
                  DateFormat('dd MMMM yyyy').format(DateTime.now()),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 14.sp),
                ),
                SizedBox(
                  height: 12.h,
                ),
                Text(
                  'Time',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 18.sp),
                ),
                Text(
                  currentime,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 14.sp),
                )
              ],
            ),
          ),
          SizedBox(height: 28.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FaceRectScreen()));
                },
                child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.3),
                        width: 1.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          spreadRadius: 2.w,
                          blurRadius: 8.w,
                          offset: Offset(2.w, 3.h),
                        ),
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(3.5.w, 4.5.h),
                        ),
                      ],
                    ),
                    height: 0.3.sh,
                    width: 0.43.sw,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 20.h,
                        ),
                        Image.asset(
                          'assets/gif3.gif',
                          height: 120.h,
                        ),
                        SizedBox(
                          height: 24.h,
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 20.w),
                          child: Text(
                            'Start Face\nAttendance',
                            style:
                                TextStyle(color: Colors.white, fontSize: 14.sp),
                          ),
                        )
                      ],
                    )),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Registrationscreen()));
                },
                child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.3),
                        width: 1.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          spreadRadius: 2.w,
                          blurRadius: 8.w,
                          offset: Offset(2.w, 3.h),
                        ),
                        BoxShadow(
                          color: Colors.black,
                          offset: Offset(4.w, 5.h),
                        ),
                      ],
                    ),
                    height: 0.3.sh,
                    width: 0.43.sw,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 20.h,
                        ),
                        Image.asset(
                          'assets/gif2.gif',
                          height: 120.h,
                        ),
                        SizedBox(
                          height: 24.h,
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 72.w),
                          child: Text(
                            'Create\nProfile',
                            style:
                                TextStyle(color: Colors.white, fontSize: 14.sp),
                          ),
                        )
                      ],
                    )),
              )
            ],
          )
        ],
      ),
    );
  }
}
