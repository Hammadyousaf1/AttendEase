import 'package:ae/Dashboard.dart';
import 'package:ae/Home_Screen.dart';
import 'package:ae/RecognitionScreen.dart';
import 'package:ae/UserManagement.dart';

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class Nav extends StatefulWidget {
  const Nav({super.key});

  @override
  State<Nav> createState() => _NavState();
}

class _NavState extends State<Nav> {
  int currentindex = 0;

  List<Widget> myScreens = [
    HomeScreen(),
    FaceRectScreen(),
    UserManagementScreen(),
    DashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: GNav(
            onTabChange: (value) {
              setState(() {
                currentindex = value;
              });
            },
            selectedIndex: currentindex,
            activeColor: Colors.blue,
            tabMargin: EdgeInsets.symmetric(
                horizontal: 15, vertical: 8), // Reduce vertical padding
            padding: EdgeInsets.symmetric(
                horizontal: 12, vertical: 12), // Add margin on left and right
            tabs: [
              GButton(
                icon: Icons.home,
                text: ' Home',
                iconSize: 20,
                textStyle: TextStyle(fontSize: 10, color: Colors.blue),
                iconColor: Colors.blue,
                backgroundColor:
                    const Color.fromARGB(255, 0, 0, 0).withOpacity(0.1),
              ),
              GButton(
                icon: Icons.person_sharp,
                text: 'Attendence',
                iconSize: 20,
                textStyle: TextStyle(fontSize: 10, color: Colors.blue),
                iconColor: Colors.blue,
                backgroundColor:
                    const Color.fromARGB(255, 0, 0, 0).withOpacity(0.1),
              ),
              GButton(
                icon: Icons.supervised_user_circle_sharp,
                text: 'User',
                iconSize: 20,
                textStyle: TextStyle(fontSize: 10, color: Colors.blue),
                iconColor: Colors.blue,
                backgroundColor:
                    const Color.fromARGB(255, 0, 0, 0).withOpacity(0.1),
              ),
              GButton(
                icon: Icons.dashboard,
                text: '  Dashboard',
                iconSize: 20,
                textStyle: TextStyle(fontSize: 10, color: Colors.blue),
                iconColor: Colors.blue,
                backgroundColor:
                    const Color.fromARGB(255, 0, 0, 0).withOpacity(0.1),
              ),
            ]),
      ),
      backgroundColor: Colors.white,
      body: Center(child: myScreens[currentindex]),
    );
  }
}
