import 'package:ae/Dashboard.dart';
import 'package:ae/Home_Screen.dart';
import 'package:ae/Recognition_Screen.dart';
import 'package:ae/User_Detail.dart';
import 'package:ae/User_Input_Screen.dart';
import 'package:ae/Regisration_Screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _usersFuture;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool showSearchBar = false;
  TextEditingController _searchController = TextEditingController();

  bool isMenuOpen = false;
  late AnimationController _animationController;
  late Animation<double> _rotateAnimation;
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _usersFuture = fetchUsers();
    _animationController =
        AnimationController(duration: Duration(milliseconds: 800), vsync: this);
    _rotateAnimation =
        Tween<double>(begin: 0, end: 0.5).animate(_animationController);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    try {
      final response = await supabase.from('users').select();
      _allUsers = List<Map<String, dynamic>>.from(response);
      _filteredUsers = _allUsers;
      return _filteredUsers;
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  void filterUsers(String query) {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = (user['name'] ?? '').toString().toLowerCase();
        final id = (user['id'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase()) ||
            id.contains(query.toLowerCase());
      }).toList();
    });
  }

  void toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
      if (isMenuOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(20.w),
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
                          color: Colors.black, size: 24.w),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Image.asset('assets/logo5.png', height: 55.h),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'User\nManagement',
                      style: TextStyle(color: Colors.black, fontSize: 20.sp),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 3.5.w, bottom: 3.5.w),
                      child: Container(
                        width: constraints.maxWidth * 0.20,
                        height: constraints.maxHeight * 0.05,
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Total ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                      fontSize: 12.sp)),
                              Text(
                                '${_filteredUsers.length}',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12.sp),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (showSearchBar) ...[
                  SizedBox(height: 24.h),
                  SizedBox(
                    height: 48.h, // Reduced height
                    child: TextField(
                      controller: _searchController,
                      onChanged: filterUsers,
                      decoration: InputDecoration(
                        hintText: 'Search by name or ID',
                        hintStyle: TextStyle(fontSize: 12.sp),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        prefixIcon: Icon(Icons.search, size: 20.w),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 8.h), // Adjust padding
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 0.h),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _usersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return Center(
                            child: CircularProgressIndicator(strokeWidth: 2));
                      if (snapshot.hasError)
                        return Center(child: Text('Error loading users'));

                      final users = _filteredUsers;

                      users.sort((a, b) => (a['id'] ?? '')
                          .toString()
                          .compareTo((b['id'] ?? '').toString()));

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return Card(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => UserDetailScreen(
                                      userId: user['id'],
                                      profileImageUrl:
                                          'https://arlexrfzqvahegtolcjp.supabase.co/storage/v1/object/public/profile_pictures/${user['id']}.png',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                color: Colors.white,
                                width: constraints.maxWidth,
                                padding: EdgeInsets.all(16.w),
                                child: Row(
                                  children: [
                                    Container(
                                      width: constraints.maxWidth * 0.15,
                                      height: constraints.maxWidth * 0.15,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          'https://arlexrfzqvahegtolcjp.supabase.co/storage/v1/object/public/profile_pictures/${user['id']}.png',
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
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
                                              overflow: TextOverflow.ellipsis),
                                          SizedBox(height: 4.h),
                                          Text('ID: ${user['id'] ?? ''}',
                                              style: TextStyle(
                                                  fontSize:
                                                      constraints.maxWidth *
                                                          0.035)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: constraints.maxWidth * 0.15,
                                      height: constraints.maxWidth * 0.15,
                                      child: Icon(Icons.chevron_right,
                                          color: Colors.blue,
                                          size: constraints.maxWidth * 0.1),
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
              ],
            );
          },
        ),
      ),
      floatingActionButton: Stack(
        alignment: Alignment.bottomRight,
        children: [
          if (isMenuOpen) ...[
            Padding(
              padding: EdgeInsets.only(bottom: 136.h, right: 8.w),
              child: GestureDetector(
                onTap: () {
                  toggleMenu();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => Registrationscreen()),
                  );
                },
                child: Container(
                  width: 48.0,
                  height: 48.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.3),
                      width: 1.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color.fromARGB(255, 0, 0, 0).withOpacity(0.4),
                        blurRadius: 4.r,
                        offset: Offset(0, 3.h),
                      ),
                      BoxShadow(
                        color: Color.fromARGB(255, 33, 32, 32),
                        offset: Offset(3.w, 4.h),
                      ),
                    ],
                  ),
                  child: Icon(Icons.add,
                      color: const Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 75.h, right: 8.w),
              child: GestureDetector(
                onTap: () {
                  toggleMenu();
                  setState(() {
                    showSearchBar = !showSearchBar;
                    if (!showSearchBar) {
                      _searchController.clear();
                      filterUsers('');
                    }
                  });
                },
                child: Container(
                  width: 48.0,
                  height: 48.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.3),
                      width: 1.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            const Color.fromARGB(255, 0, 0, 0).withOpacity(0.4),
                        blurRadius: 4.r,
                        offset: Offset(0, 3.h),
                      ),
                      BoxShadow(
                        color: Color.fromARGB(255, 33, 32, 32),
                        offset: Offset(3.w, 4.h),
                      ),
                    ],
                  ),
                  child: Icon(Icons.search,
                      color: const Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
            ),
          ],
          GestureDetector(
            onTap: toggleMenu,
            child: Container(
              width: 64.0,
              height: 64.0,
              decoration: BoxDecoration(
                color: Colors.blue,
                border: Border.all(
                  color: Colors.black.withOpacity(0.3),
                  width: 1.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.4),
                    blurRadius: 4.r,
                    offset: Offset(0, 5.h),
                  ),
                  BoxShadow(
                    color: Color.fromARGB(255, 8, 84, 146),
                    offset: Offset(4.w, 5.h),
                  ),
                ],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: RotationTransition(
                turns: _rotateAnimation,
                child: Icon(Icons.menu, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            if (index == 0) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
              );
            } else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FaceRectScreen()),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserManagementScreen()),
              );
            } else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
            } else {
              _onItemTapped(index);
            }
          },
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 24.w),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.scanFace, size: 24.w),
              label: 'Attendance',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people, size: 24.w),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard, size: 24.w),
              label: 'Dashboard',
            ),
          ],
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.black54,
          selectedLabelStyle: TextStyle(fontSize: 10.sp),
          unselectedLabelStyle: TextStyle(fontSize: 10.sp),
        ),
      ),
    );
  }
}
