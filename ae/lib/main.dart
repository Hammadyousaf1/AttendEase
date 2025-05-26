import 'package:ae/LandingScreen/AdminScreen.dart';
import 'package:ae/LandingScreen/UserScreen.dart';
import 'package:ae/auth/LoginScreen.dart';
import 'package:ae/auth/OnboardScreen.dart';
import 'package:ae/auth/SignupScreen.dart';
import 'package:ae/LandingScreen/UserLand.dart';
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
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      return FutureBuilder(
        future: Supabase.instance.client
            .from('auth_users')
            .select()
            .eq('email', user.email!)
            .single(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final response = snapshot.data as Map<String, dynamic>;
            if (response['admin'] == true) {
              return HomeScreen();
            } else {
              return FutureBuilder(
                future: Supabase.instance.client
                    .from('users')
                    .select()
                    .eq('email', user.email!)
                    .single(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return UserlandingScreen(email: user.email);
                  } else {
                    return UserlandScreen(email: user.email);
                  }
                },
              );
            }
          }
          return LoginScreen();
        },
      );
    } else {
      return LoginScreen();
    }
  }
}
