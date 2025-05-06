import 'package:ae/UserManagement/Dashboard.dart';
import 'package:ae/auth/LoginScreen.dart';
import 'package:ae/auth/OnboardScreen.dart';
import 'package:ae/ModelScreen/Recognition_Screen.dart';
import 'package:ae/ModelScreen/Regisration_Screen.dart';
import 'package:ae/UserManagement/User_Management.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  final String? email;
  const HomeScreen({super.key, this.email});

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
  late Timer _timer;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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

    // Initialize with current time immediately
    currentime = DateFormat('hh:mm:ss a').format(DateTime.now());

    // Start timer to update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) {
        setState(() {
          currentime = DateFormat('hh:mm:ss a').format(DateTime.now());
        });
      }
    });
  }

  List<String> images = [
    'assets/Frame (3).png',
    'assets/Frame (2).png',
    'assets/Frame (1).png',
  ];
  @override
  Widget build(BuildContext context) {
    final email = widget.email ??
        (ModalRoute.of(context)?.settings.arguments
            as Map<String, dynamic>?)?['email'] ??
        Supabase.instance.client.auth.currentUser?.email ??
        '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 36.h,
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
                    'Welcome 👋🎉',
                    style: TextStyle(
                        color: Color.fromARGB(255, 7, 22, 47),
                        fontSize: 24.sp,
                        letterSpacing: -1.0), // Reduced letter spacing
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: Colors.white,
                            content: Container(
                              height: 235,
                              width: MediaQuery.of(context).size.width *
                                  0.9, // Set width to 80% of screen width
                              padding: EdgeInsets.all(8), // Added padding
                              child: FutureBuilder(
                                future: Supabase.instance.client
                                    .from('auth_users')
                                    .select()
                                    .eq('email', email)
                                    .single(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError) {
                                    return Text('Error loading user data');
                                  }
                                  final userData = snapshot.data;
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Column(
                                        children: [
                                          CircleAvatar(
                                            radius: 45,
                                            backgroundColor:
                                                const Color.fromARGB(
                                                    255, 208, 207, 207),
                                            child: Icon(
                                              Icons.person,
                                              color: Colors.black,
                                              size: 40,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            userData?['name'] ?? 'User',
                                            style: TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            userData?['email']?.replaceAll(
                                                    '@gmail.com', '') ??
                                                '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 24),
                                      GestureDetector(
                                        onTap: () async {
                                          await Supabase.instance.client.auth
                                              .signOut();
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    LoginScreen()),
                                          );
                                        },
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 12, horizontal: 24),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color:
                                                  Colors.black.withOpacity(0.3),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.3),
                                                spreadRadius: 1.5,
                                                blurRadius: 8,
                                                offset: Offset(1, 2),
                                              ),
                                              BoxShadow(
                                                color: Color.fromARGB(
                                                    255, 8, 84, 146),
                                                offset: Offset(3, 5),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.logout,
                                                  size: 20,
                                                  color: Colors.white),
                                              SizedBox(width: 8),
                                              Text('Logout',
                                                  style: TextStyle(
                                                      color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: CircleAvatar(
                      backgroundColor: const Color.fromARGB(255, 217, 223, 227),
                      child: Icon(Icons.person, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 4.h,
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
            height: 4.h,
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
                      'Today Is',
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
                    height: 8.h,
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
          items: <BottomNavigationBarItem>[
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
