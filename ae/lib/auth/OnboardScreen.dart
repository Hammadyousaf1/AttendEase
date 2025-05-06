import 'package:ae/auth/SignupScreen.dart';
import 'package:flutter/material.dart';
import 'LoginScreen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: EdgeInsets.only(bottom: 20),
                child: Image.asset(
                  'assets/logo.png',
                  height: 80,
                  width: 240,
                  fit: BoxFit.contain,
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                height: 350,
                width: 350,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Start Your Journey\nChoose a Role',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 18.sp,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SignupScreen(isAdmin: true),
                          ),
                        );
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  'For Teacher, Manager\nor Administrator.',
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.7),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.black.withOpacity(0.7),
                              size: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SignupScreen(isAdmin: false),
                          ),
                        );
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'User',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  'For Staff, Students\nor Employees.',
                                  style: TextStyle(
                                    color: Colors.black.withOpacity(0.7),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.black.withOpacity(0.7),
                              size: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
