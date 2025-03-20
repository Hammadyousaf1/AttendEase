import 'package:ae/Dashboard.dart';
import 'package:ae/Splash_Screen.dart';
import 'package:ae/mys/Dashboard.dart';
import 'package:ae/reports_Screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://arlexrfzqvahegtolcjp.supabase.co/',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFybGV4cmZ6cXZhaGVndG9sY2pwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg2ODE4MjcsImV4cCI6MjA1NDI1NzgyN30.ksThqyqHmQt16ZmlYM7hrutQVmBOcYt-0xap6a7QlhQ',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(375, 812),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AttendEase',
        theme: ThemeData(
          textTheme: GoogleFonts.kronaOneTextTheme(),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            primary: Colors.blue,
            secondary: Colors.black,
          ),
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: SplashScreen(),
      ),
    );
  }
}
