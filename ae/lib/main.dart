//import 'package:ae/face_recognition_screen.dart';
import 'package:ae/Home_Screen.dart';
import 'package:ae/RegisrationScreen.dart';
//import 'package:ae/auto%20_register_2.dart';
import 'package:ae/RecognitionScreen.dart';
import 'package:ae/UserManagement..dart';
//import 'package:ae/old/face_recognition_screen.dart';
//import 'package:ae/trail/auto_recognize.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:async';
//import 'package:ae/old/auto_register.dart';
//import 'package:ae/trail/Recognition.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://arlexrfzqvahegtolcjp.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFybGV4cmZ6cXZhaGVndG9sY2pwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg2ODE4MjcsImV4cCI6MjA1NDI1NzgyN30.ksThqyqHmQt16ZmlYM7hrutQVmBOcYt-0xap6a7QlhQ',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AttendEase',
      theme: ThemeData(
        textTheme: GoogleFonts.kronaOneTextTheme(),
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}
