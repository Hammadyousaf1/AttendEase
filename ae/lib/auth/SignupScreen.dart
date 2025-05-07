import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'LoginScreen.dart';

class SignupScreen extends StatefulWidget {
  final bool isAdmin;
  const SignupScreen({super.key, this.isAdmin = false});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // First sign up with Supabase authentication
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (authResponse.user == null) {
        throw Exception('Authentication failed');
      }

      // Then insert user data into auth_users table
      await Supabase.instance.client.from('auth_users').insert({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'admin': widget.isAdmin,
        'admin_id': widget.isAdmin ? authResponse.user!.id : null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signup successful!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(360, 840));

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
          padding: EdgeInsets.all(16.w),
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
                      height: 560.h,
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
                                'Join and Steps in the\nsmart Future',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 18.sp,
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            SizedBox(
                              width: 300.w,
                              height: 56.h,
                              child: TextFormField(
                                controller: _nameController,
                                style: TextStyle(
                                    fontSize: 14.sp, color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Name',
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
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(height: 12.h),
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
                            SizedBox(height: 12.h),
                            SizedBox(
                              width: 300.w,
                              height: 56.h,
                              child: TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: !_passwordVisible,
                                style: TextStyle(
                                    fontSize: 14.sp, color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
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
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _passwordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _passwordVisible = !_passwordVisible;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(height: 20.h),
                            SizedBox(
                              width: 300.w,
                              child: GestureDetector(
                                onTap: _isLoading ? null : _signUp,
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
                            SizedBox(height: 28.h),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                              'Already have Account?',
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
                                        builder: (context) => LoginScreen()),
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
