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
                horizontal: 14.5, vertical: 8), // Reduce vertical padding
            padding: EdgeInsets.symmetric(
                horizontal: 12, vertical: 12), // Add margin on left and right
            tabs: [
              GButton(
                icon: Icons.home,
                text: '   Home',
                iconSize: 20,
                textStyle: TextStyle(
                    fontSize: 10,
                    color: currentindex == 0 ? Colors.blue : Colors.black),
                iconColor: currentindex == 0 ? Colors.blue : Colors.black,
                border: currentindex == 0
                    ? Border.all(
                        color: Colors.blue,
                        width: 1,
                      )
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              GButton(
                icon: Icons.face_retouching_natural_sharp,
                text: '   Attendence',
                iconSize: 20,
                textStyle: TextStyle(
                    fontSize: 10,
                    color: currentindex == 1 ? Colors.blue : Colors.black),
                iconColor: currentindex == 1 ? Colors.blue : Colors.black,
                border: currentindex == 1
                    ? Border.all(
                        color: Colors.blue,
                        width: 1,
                      )
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              GButton(
                icon: Icons.group,
                text: '  Users List',
                iconSize: 20,
                textStyle: TextStyle(
                    fontSize: 10,
                    color: currentindex == 2 ? Colors.blue : Colors.black),
                iconColor: currentindex == 2 ? Colors.blue : Colors.black,
                border: currentindex == 2
                    ? Border.all(
                        color: Colors.blue,
                        width: 1,
                      )
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              GButton(
                icon: Icons.space_dashboard_sharp,
                text: ' Dashboard',
                iconSize: 20,
                textStyle: TextStyle(
                    fontSize: 10,
                    color: currentindex == 3 ? Colors.blue : Colors.black),
                iconColor: currentindex == 3 ? Colors.blue : Colors.black,
                border: currentindex == 3
                    ? Border.all(
                        color: Colors.blue,
                        width: 1,
                      )
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
            ]),
      ),
      backgroundColor: Colors.white,
      body: Center(child: myScreens[currentindex]),
    );
  }
}
