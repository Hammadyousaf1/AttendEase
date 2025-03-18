import 'package:ae/Splash_Screen.dart';
import 'package:ae/reports_Screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://tsdqafsqvewaaqrmedlg.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRzZHFhZnNxdmV3YWFxcm1lZGxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5NjI3NDUsImV4cCI6MjA1NTUzODc0NX0.06M-zKOUc7mIOBoaW8Iy9cQf3tC_BiDYGBFqdQoFXBI',
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
        home: ReportsScreen(),
      ),
    );
  }
}
