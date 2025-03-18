import 'package:ae/Dashboeard.dart';
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
            tabMargin:
                EdgeInsets.symmetric(vertical: 7), // Reduce vertical padding
            padding: EdgeInsets.symmetric(
                horizontal: 26, vertical: 10), // Reduce overall padding
            tabs: [
              GButton(
                icon: Icons.home,
                text: 'Home',
                iconSize: 20, // Smaller icon
              ),
              GButton(
                icon: Icons.person_sharp,
                text: 'Attendence',
                iconSize: 20,
              ),
              GButton(
                icon: Icons.supervised_user_circle_sharp,
                text: 'User',
                iconSize: 20,
              ),
              GButton(
                icon: Icons.dashboard,
                text: 'Dashboard',
                iconSize: 20,
              ),
            ]),
      ),
      backgroundColor: Colors.white,
      body: myScreens[currentindex],
    );
  }
}
