import 'dart:async';

import 'package:ae/Unused/Navigation_bar.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool a = false;
  bool b = false;
  bool c = false;
  bool e = false;
  bool d = false;

  @override
  void initState() {
    super.initState();
    Timer(Duration(milliseconds: 400), () {
      setState(() {
        a = true;
      });
    });
    Timer(Duration(milliseconds: 400), () {
      setState(() {
        b = true;
      });
    });
    Timer(Duration(milliseconds: 1300), () {
      setState(() {
        c = true;
      });
    });
    Timer(Duration(milliseconds: 1700), () {
      setState(() {
        e = true;
      });
    });
    Timer(Duration(milliseconds: 3400), () {
      setState(() {
        d = true;
      });
    });
    Timer(Duration(milliseconds: 3900), () {
      setState(() {
        Navigator.of(context).pushReplacement(ThisisFade(route: const Nav()));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height;
    double w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedContainer(
              duration: Duration(seconds: d ? 900 : 2500),
              curve: d ? Curves.fastLinearToSlowEaseIn : Curves.easeInOut,
              height: d
                  ? 0
                  : a
                      ? h / 2
                      : 20,
              width: 20,
            ),
            AnimatedContainer(
                curve: Curves.fastLinearToSlowEaseIn,
                duration: Duration(
                  seconds: d
                      ? 2
                      : c
                          ? 2
                          : 0,
                ),
                height: d
                    ? h
                    : c
                        ? 80
                        : 20,
                width: d
                    ? w
                    : c
                        ? 200
                        : 20,
                decoration: BoxDecoration(
                  color: b ? Colors.white : Colors.transparent,
                  borderRadius:
                      d ? BorderRadius.zero : BorderRadius.circular(30),
                ),
                child: Center(
                  child: AnimatedOpacity(
                    duration: Duration(seconds: 2),
                    opacity: b ? 1.0 : 0.0,
                    child: TweenAnimationBuilder(
                      duration: Duration(milliseconds: 1650),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Image.asset(
                            'assets/logo5.png',
                            fit: BoxFit.cover,
                            width: 150,
                            
                          ),
                        );
                      },
                    ),
                  ),
                ))
          ]),
        ),
      ),
    );
  }
}

class ThisisFade extends PageRouteBuilder {
  final Widget? page;
  final Widget route;

  ThisisFade({this.page, required this.route})
      : super(
            pageBuilder: (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) =>
                page!,
            transitionsBuilder: (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) =>
                FadeTransition(
                  opacity: animation,
                  child: route,
                ));
}
