import 'package:ae/RegisrationScreen.dart';
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
                      'assets/logo2.png',
                      height: 35.h,
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 0.0),
                      child: Text(
                        'User\nManagement',
                        style: TextStyle(
                            color: Colors.black, fontSize: 20.sp, height: 0.0),
                      ),
                    ),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _usersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error',
                              style: TextStyle(color: Colors.red));
                        }
                        return Padding(
                          padding: EdgeInsets.only(right: 0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.w),
                                margin: EdgeInsets.only(
                                    left: constraints.maxWidth * 0.01,
                                    top: constraints.maxHeight * 0.01),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                width: constraints.maxWidth * 0.24,
                                height: constraints.maxHeight * 0.07,
                              ),
                              Container(
                                width: constraints.maxWidth * 0.24,
                                height: constraints.maxHeight * 0.07,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    width: 1.w,
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Total ',
                                        style: TextStyle(
                                            color: Color.fromARGB(255, 0, 0, 0),
                                            fontSize: 12.sp),
                                      ),
                                      Text(
                                        '${snapshot.data?.length ?? 0}',
                                        style: TextStyle(
                                            color: Color.fromARGB(255, 0, 0, 0),
                                            fontSize: 12.sp),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                        return Center(child: CircularProgressIndicator());
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
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: constraints.maxWidth * 0.00,
                            ),
                            child: Card(
                              child: ListTile(
                                tileColor: Colors.white,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 12.w),
                                leading: Text('${user['id'] ?? ''}',
                                    style: TextStyle(
                                        fontSize:
                                            constraints.maxWidth * 0.035)),
                                title: Text('${user['name'] ?? 'Unknown'}',
                                    style: TextStyle(
                                        fontSize:
                                            constraints.maxWidth * 0.035)),
                                trailing: Container(
                                  width: 96.w,
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit,
                                            color: Colors.blue,
                                            size: constraints.maxWidth * 0.05),
                                        onPressed: () {
                                          // Handle edit user
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete,
                                            color: Colors.red,
                                            size: constraints.maxWidth * 0.05),
                                        onPressed: () =>
                                            deleteUser(int.parse(user['id'])),
                                      ),
                                    ],
                                  ),
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
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: constraints.maxWidth * 0.20,
                          height: constraints.maxHeight * 0.1,
                          padding: EdgeInsets.all(12.w),
                          margin: EdgeInsets.only(
                              right: constraints.maxWidth * 0.035,
                              bottom: constraints.maxHeight * 0.045),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        Container(
                          width: constraints.maxWidth * 0.20,
                          height: constraints.maxHeight * 0.1,
                          padding: EdgeInsets.all(12.w),
                          margin: EdgeInsets.only(
                              right: constraints.maxWidth * 0.05,
                              bottom: constraints.maxHeight * 0.05),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            border: Border(
                              bottom: BorderSide(
                                color:
                                    Color.fromARGB(255, 0, 0, 0).withOpacity(1),
                                width: 1.w,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.2),
                                blurRadius: 4.r,
                                offset: Offset(0, 2.h),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(Icons.add,
                              color: const Color.fromARGB(255, 0, 0, 0),
                              size: 24.w),
                        ),
                      ],
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
