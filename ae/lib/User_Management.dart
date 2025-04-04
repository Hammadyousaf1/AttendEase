import 'package:ae/Home_Screen.dart';
import 'package:ae/User_Detail.dart';
import 'package:ae/User_Input_Screen.dart';
import 'package:ae/Regisration_Screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = fetchUsers();
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final response = await supabase.from('users').select();
      return response;
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      await supabase.from('users').delete().eq('id', userId);
      setState(() {
        _usersFuture = fetchUsers(); // Refetch users after deletion
      });
    } catch (e) {
      print('Error deleting user: $e');
    }
  }

  Future<void> editUser(Map<String, dynamic> userData) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(
            userData: userData,
            capturedImages: [],
          ),
        ),
      );

      if (result == true) {
        // Refresh the users list if edit was successful
        setState(() {
          _usersFuture = fetchUsers();
        });
      }
    } catch (e) {
      print('Error navigating to edit screen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(20.w), // Responsive padding
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: Color.fromARGB(255, 0, 0, 0),
                          size: 24.w), // Responsive icon size
                      onPressed: () => Navigator.pop(context),
                    ),
                    Image.asset(
                      'assets/logo5.png',
                      height: 55.h,
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 0.0),
                      child: Text(
                        'User\nManagement',
                        style: TextStyle(color: Colors.black, fontSize: 20.sp),
                      ),
                    ),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _usersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator(strokeWidth: 2);
                        }
                        if (snapshot.hasError) {
                          return Text('Error',
                              style: TextStyle(color: Colors.red));
                        }
                        return Padding(
                          padding: EdgeInsets.only(
                              right: 3.5.w), // Added right padding
                          child: Container(
                            width: constraints.maxWidth * 0.20,
                            height: constraints.maxHeight * 0.07,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              /*boxShadow: [
                                BoxShadow(
                                  color: Color.fromARGB(255, 40, 40, 40),
                                  offset: Offset(3.w, 3.5.h),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.black.withOpacity(0.3),
                                width: 1.w,
                              ),
                              borderRadius: BorderRadius.all(
                                Radius.circular(8.r),
                              ),*/
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Total ',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: const Color.fromARGB(
                                            255, 99, 99, 99),
                                        fontSize: 12.sp),
                                  ),
                                  Text(
                                    '${snapshot.data?.length ?? 0}',
                                    style: TextStyle(
                                        color: const Color.fromARGB(
                                            255, 99, 99, 99),
                                        fontSize: 12.sp),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _usersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                            child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading users'));
                      }
                      final users = snapshot.data ?? [];

                      // Sort users by id (as string)
                      users.sort((a, b) =>
                          (a['id'] as String).compareTo(b['id'] as String));

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return Card(
                            child: Container(
                              color: Colors.white,
                              width: constraints
                                  .maxWidth, // Set width to screen width
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Row(
                                  children: [
                                    Container(
                                      width: constraints.maxWidth * 0.15,
                                      height: constraints.maxWidth * 0.15,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          'https://arlexrfzqvahegtolcjp.supabase.co/storage/v1/object/public/profile_pictures/${user['id'] ?? 'Icon'}.png',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            // If the image fails to load, use Icon.png
                                            return Image.network(
                                              'https://arlexrfzqvahegtolcjp.supabase.co/storage/v1/object/public/profile_pictures/Icon.png',
                                              fit: BoxFit.cover,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('${user['name'] ?? 'Unknown'}',
                                              style: TextStyle(
                                                  fontSize:
                                                      constraints.maxWidth *
                                                          0.040),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1),
                                          SizedBox(height: 4.h),
                                          Text('ID: ${user['id'] ?? ''}',
                                              style: TextStyle(
                                                  fontSize:
                                                      constraints.maxWidth *
                                                          0.035)),
                                        ],
                                      ),
                                    ),
                                    /*Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () => editUser(user),
                                          child: Container(
                                            width: constraints.maxWidth * 0.06,
                                            height: constraints.maxWidth * 0.06,
                                            child: Icon(Icons.edit,
                                                color: Colors.black,
                                                size: constraints.maxWidth *
                                                    0.05),
                                          ),
                                        ),
                                        SizedBox(height: 12.h),
                                        GestureDetector(
                                          onTap: () =>
                                              deleteUser(int.parse(user['id'])),
                                          child: Container(
                                            width: constraints.maxWidth * 0.06,
                                            height: constraints.maxWidth * 0.06,
                                            child: Icon(Icons.delete,
                                                color: Colors.red,
                                                size: constraints.maxWidth *
                                                    0.05),
                                          ),
                                        ),
                                      ],
                                    ),*/
                                    SizedBox(
                                      width: 8.w,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                UserDetailScreen(
                                                    userId: user['id'],
                                                    userName: user['name'] ?? 'Unknown',
                                                    profileImageUrl: 'https://arlexrfzqvahegtolcjp.supabase.co/storage/v1/object/public/profile_pictures/${user['id'] ?? 'Icon'}.png'),
                                        ));
                                      },
                                      child: Container(
                                        width: constraints.maxWidth * 0.15,
                                        height: constraints.maxWidth * 0.15,
                                        child: Icon(Icons.chevron_right,
                                            color: Colors.blue,
                                            size: constraints.maxWidth * 0.1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Registrationscreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.15,
                      height: MediaQuery.of(context).size.height * 0.08,
                      padding: EdgeInsets.all(0.w),
                      margin: EdgeInsets.only(
                          bottom: MediaQuery.of(context).size.height * 0.008),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        border: Border.all(
                          color: Colors.black.withOpacity(0.3),
                          width: 1.w,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 0, 0, 0)
                                .withOpacity(0.4),
                            blurRadius: 4.r,
                            offset: Offset(0, 3.h),
                          ),
                          BoxShadow(
                            color: Color.fromARGB(255, 8, 84, 146),
                            offset: Offset(3.w, 4.h),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(Icons.add,
                          color: Colors.white, size: 28.w, weight: 3.0),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
