//import 'package:ae/face_recognition_screen.dart';
import 'package:ae/auto%20_register_2.dart';
import 'package:ae/old/face_recognition_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:ae/old/auto_register.dart';
import 'package:ae/trail/Recognition.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AttendEase',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _timeString = "";
  String _dateString = "";
  String _dayString = "";

  @override
  void initState() {
    super.initState();
    _updateTime();
    Timer.periodic(Duration(seconds: 1), (Timer t) => _updateTime());
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    setState(() {
      _timeString = DateFormat('hh:mm:ss a').format(now);
      _dateString = DateFormat('d MMMM yyyy').format(now);
      _dayString = DateFormat('EEEE').format(now);
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "WELCOME",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.05,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.02),

              // Responsive Image Scroll View
              SizedBox(
                height: screenHeight * 0.22,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildImageCard(screenWidth, "Take Attendance",
                        "Smart Attendance through Face Recognition"),
                    _buildImageCard(screenWidth, "User Management",
                        "Create & Manage User Profiles"),
                    _buildImageCard(screenWidth, "Attendance Records",
                        "Check & Export Attendance Logs"),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              // Date & Time Display
              Text("Today is", style: TextStyle(fontSize: screenWidth * 0.04)),
              Text(_dayString,
                  style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),
              Text(_dateString,
                  style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: screenHeight * 0.01),
              Text("Time", style: TextStyle(fontSize: screenWidth * 0.04)),
              Text(_timeString,
                  style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue)),

              SizedBox(height: screenHeight * 0.04),

              // Buttons Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 165,
                    height: 260,
                    child: _buildButton(screenWidth, "Start Face Attendance",
                        Icons.camera_alt, Colors.blue, () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FaceDetectionScreen(),
                        ),
                      );
                    }),
                  ),
                  SizedBox(width: 12), // Added 20px gap
                  SizedBox(
                    width: 165,
                    height: 260,
                    child: _buildButton(screenWidth, "Create Profile",
                        Icons.person_add, Colors.blue, () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => FaceDetectioncaptureScreen(),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_circle), label: "Attendance"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "User"),
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: "Dashboard"),
        ],
      ),
    );
  }

  // Responsive Image Card Widget
  Widget _buildImageCard(double screenWidth, String title, String subtitle) {
    return Container(
      width: screenWidth * 0.5,
      margin: EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey[200],
      ),
      child: Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              title,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.045),
            ),
            Text(
              subtitle,
              style: TextStyle(
                  color: Colors.white70, fontSize: screenWidth * 0.03),
            ),
          ],
        ),
      ),
    );
  }

  // Responsive Button Widget
  Widget _buildButton(double screenWidth, String text, IconData icon,
      Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: Size(screenWidth * 0.4, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, color: Colors.white, size: screenWidth * 0.06),
      label: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.035),
      ),
      onPressed: onPressed,
    );
  }
}
