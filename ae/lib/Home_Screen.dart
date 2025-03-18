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
    'assets/slide1.png',
    'assets/slide2.png',
    'assets/slide3.png',
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 70.h,
        backgroundColor: Colors.transparent,
        title: Text(
          'WELCOME',
          style: TextStyle(
              color: Color.fromARGB(255, 7, 22, 47),
              fontWeight: FontWeight.bold,
              fontSize: 30.sp),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 30.w),
            child: Image.asset(
              'assets/Group2.png',
              height: 35.h,
              color: const Color.fromARGB(255, 7, 22, 47),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Padding(
            padding: EdgeInsets.only(left: 32.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today is',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 24.sp),
                ),
                Text(
                  DateFormat.EEEE().format(DateTime.now()),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 24.sp),
                ),
                Text(
                  DateFormat('dd MMMM yyyy').format(DateTime.now()),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 24.sp),
                ),
                SizedBox(
                  height: 17.h,
                ),
                Text(
                  'Time',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 24.sp),
                ),
                Text(
                  currentime,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 24.sp),
                )
              ],
            ),
          ),
          SizedBox(height: 10.h),
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
                    ),
                    height: 0.3.sh,
                    width: 0.4.sw,
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
                          height: 30.h,
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: Text(
                            'Start face Attendence',
                            style:
                                TextStyle(color: Colors.white, fontSize: 20.sp),
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
                    ),
                    height: 0.3.sh,
                    width: 0.4.sw,
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
                          height: 30.h,
                        ),
                        Padding(
                          padding: EdgeInsets.only(right: 45.w),
                          child: Text(
                            'Create \nProfile',
                            style:
                                TextStyle(color: Colors.white, fontSize: 20.sp),
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
