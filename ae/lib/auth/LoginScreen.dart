import 'package:ae/LandingScreen/AdminScreen.dart';
import 'package:ae/LandingScreen/UserLand.dart';
import 'package:ae/auth/OnboardScreen.dart';
import 'package:ae/auth/SignupScreen.dart';
import 'package:ae/LandingScreen/UserScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  final bool isAdmin;
  const LoginScreen({super.key, this.isAdmin = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // First authenticate with Supabase
      final authResponse =
          await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (authResponse.user == null) {
        throw Exception('Authentication failed');
      }

      // Then fetch user data from auth_users table
      final response = await Supabase.instance.client
          .from('auth_users')
          .select('admin')
          .eq('email', _emailController.text.trim())
          .single();

      if (response != null) {
        final isAdmin = response['admin'] as bool;
        
        if (isAdmin) {
          // If admin, navigate to home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(),
              settings: RouteSettings(
                  arguments: {'email': _emailController.text.trim()}),
            ),
          );
        } else {
          // Check if user exists in users table
          final userResponse = await Supabase.instance.client
              .from('users')
              .select()
              .eq('email', _emailController.text.trim())
              .maybeSingle();

          if (userResponse != null) {
            // User exists, navigate to UserlandingScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UserlandingScreen(
                  email: _emailController.text.trim(),
                ),
                settings: RouteSettings(
                    arguments: {'email': _emailController.text.trim()}),
              ),
            );
          } else {
            // User doesn't exist, navigate to UserlandScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UserlandScreen(
                  email: _emailController.text.trim(),
                ),
                settings: RouteSettings(
                    arguments: {'email': _emailController.text.trim()}),
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User data not found')),
        );
      }
    } catch (error) {
      String errorMessage = error.toString().contains('Invalid login credentials') 
          ? 'Invalid Credentials' 
          : error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: EdgeInsets.only(bottom: 20.h),
                      child: Image.asset(
                        'assets/logo.png',
                        height: 80.h,
                        width: 240.w,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Container(
                      height: 440.h,
                      width: 350.w,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      padding: EdgeInsets.all(20.w),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Welcome Back to\nAttendEase',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 18.sp,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: 300.w,
                              height: 56.h,
                              child: TextFormField(
                                controller: _emailController,
                                style: TextStyle(
                                    fontSize: 14.sp, color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: TextStyle(
                                      fontSize: 12.sp, color: Colors.white),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  floatingLabelBehavior:
                                      FloatingLabelBehavior.never,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                      .hasMatch(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(height: 12.h),
                            SizedBox(
                              width: 300.w,
                              height: 56.h,
                              child: StatefulBuilder(
                                builder: (context, setState) {
                                  return TextFormField(
                                    controller: _passwordController,
                                    obscureText: !_passwordVisible,
                                    style: TextStyle(
                                        fontSize: 14.sp, color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      labelStyle: TextStyle(
                                          fontSize: 12.sp, color: Colors.white),
                                      border: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.white),
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.white),
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                      ),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _passwordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _passwordVisible =
                                                !_passwordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a password';
                                      }
                                      if (value.length < 6) {
                                        return 'Password must be at least 6 characters';
                                      }
                                      return null;
                                    },
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 20.h),
                            SizedBox(
                              width: 300.w,
                              child: GestureDetector(
                                onTap: _isLoading ? null : _login,
                                child: Container(
                                  width: double.infinity,
                                  height: 52.h,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.3),
                                      width: 1.w,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        spreadRadius: 1.5,
                                        blurRadius: 8,
                                        offset: Offset(1, 2),
                                      ),
                                      BoxShadow(
                                        color: Color.fromARGB(255, 8, 84, 146),
                                        offset: Offset(3, 5),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white)
                                        : Text(
                                            'Log In',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 28.h),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Donot have an Account? ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            SizedBox(
                              width: 300.w,
                              height: 50.h,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => OnboardingScreen()),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 52.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.w,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
