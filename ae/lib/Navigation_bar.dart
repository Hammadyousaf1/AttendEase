import 'package:ae/Dashboeard.dart';
import 'package:ae/Home_Screen.dart';
import 'package:ae/RecognitionScreen.dart';
import 'package:ae/UserManagement..dart';

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
    Dashboeard(),
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
            tabs: [
              GButton(
                icon: Icons.home,
                text: 'Home',
              ),
              GButton(
                icon: Icons.person_sharp,
                text: 'Attendence',
              ),
              GButton(
                icon: Icons.supervised_user_circle_sharp,
                text: 'User',
              ),
              GButton(
                icon: Icons.dashboard,
                text: 'Dashboard',
              ),
            ]),
      ),
      backgroundColor: Colors.white,
      body: myScreens[currentindex],
    );
  }
}
