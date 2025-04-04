import 'package:ae/Recognition_Screen.dart';
import 'package:ae/Regisration_Screen.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController Controller;
  late Animation<Offset> animation;
  late AnimationController Controller2;
  late Animation<double> animation2;
  late AnimationController Controller3;
  late Animation<Offset> animation3;

  String currentime = '';
  @override
  @override
  void initState() {
    super.initState();
    Controller = AnimationController(
        vsync: this, duration: Duration(milliseconds: 2000));
    animation = Tween<Offset>(begin: Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(parent: Controller, curve: Curves.easeOutBack));
    Controller.forward();
    Controller2 = AnimationController(
        vsync: this, duration: Duration(milliseconds: 1000));
    animation2 = Tween<double>(begin: 0, end: 1).animate(Controller2);
    Controller2.forward();
    Controller3 = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    animation3 = Tween<Offset>(begin: Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(parent: Controller3, curve: Curves.easeOutBack));
    Controller3.forward();
    updateTime();
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
            child: FadeTransition(
              opacity: animation2,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'WELCOME',
                    style: TextStyle(
                        color: Color.fromARGB(255, 7, 22, 47),
                        fontSize: 28.sp,
                        letterSpacing: -4.0), // Reduced letter spacing
                  ),
                  Image.asset(
                    'assets/logo5.png',
                    height: 55.h,
                  ),
                ],
              ),
            ),
          ),
          FadeTransition(
            opacity: animation2,
            child: CarouselSlider(
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
          ),
          SizedBox(
            height: 8.h,
          ),
          Padding(
            padding: EdgeInsets.only(left: 24.w),
            child: SlideTransition(
              position: animation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeTransition(
                    opacity: animation2,
                    child: Text(
                      'Today is',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 18.sp),
                    ),
                  ),
                  FadeTransition(
                    opacity: animation2,
                    child: Text(
                      DateFormat.EEEE().format(DateTime.now()),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14.sp),
                    ),
                  ),
                  FadeTransition(
                    opacity: animation2,
                    child: Text(
                      DateFormat('dd MMMM yyyy').format(DateTime.now()),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14.sp),
                    ),
                  ),
                  SizedBox(
                    height: 12.h,
                  ),
                  FadeTransition(
                    opacity: animation2,
                    child: Text(
                      'Time',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 18.sp),
                    ),
                  ),
                  FadeTransition(
                    opacity: animation2,
                    child: Text(
                      currentime,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14.sp),
                    ),
                  )
                ],
              ),
            ),
          ),
          SizedBox(height: 28.h),
          SlideTransition(
            position: animation,
            child: Row(
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
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.3),
                          width: 1.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 8.w,
                            offset: Offset(3.w, 4.h),
                          ),
                          BoxShadow(
                            color: const Color.fromARGB(255, 8, 84, 146),
                            offset: Offset(5.w, 6.h),
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
                              style: TextStyle(
                                  color: Colors.white, fontSize: 14.sp),
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
                  child: SlideTransition(
                    position: animation3,
                    child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.3),
                            width: 1.w,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 8.w,
                              offset: Offset(3.w, 4.h),
                            ),
                            BoxShadow(
                              color: const Color.fromARGB(255, 8, 84, 146),
                              offset: Offset(5.w, 6.h),
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
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14.sp),
                              ),
                            )
                          ],
                        )),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
