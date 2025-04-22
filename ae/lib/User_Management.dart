import 'package:ae/Dashboard.dart';
import 'package:ae/Home_Screen.dart';
import 'package:ae/Recognition_Screen.dart';
import 'package:ae/User_Detail.dart';
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
    with TickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _usersFuture;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool showSearchBar = false;
  TextEditingController _searchController = TextEditingController();

  bool isMenuOpen = false;
  bool isAnimatingOut = false; // ✅ NEW: To delay widget removal
  late AnimationController _animationController;
  late Animation<double> _rotateAnimation;
  late AnimationController controller2;
  late AnimationController controller3;
  late Animation<Offset> animation;
  late Animation<Offset> animation2;
  int _selectedIndex = 2;
  late List<Animation<Offset>> slide;
  late AnimationController controller4;

  @override
  void initState() {
    super.initState();
    _usersFuture = fetchUsers();
    _animationController =
        AnimationController(duration: Duration(milliseconds: 800), vsync: this);
    _rotateAnimation =
        Tween<double>(begin: 0, end: 0.5).animate(_animationController);
    controller2 =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    controller3 =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    animation = Tween<Offset>(begin: Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: controller2,
        curve: Curves.easeOut,
      ),
    );
    animation2 = Tween<Offset>(begin: Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: controller3,
        curve: Curves.easeOut,
      ),
    );

    controller4 =
        AnimationController(vsync: this, duration: Duration(seconds: 2));

    controller4.forward();
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
    if (isMenuOpen) {
      setState(() {
        isAnimatingOut = true; // ✅ Delay widget removal
      });
      _animationController.reverse();
      controller2.reverse();
      controller3.reverse();

      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            isMenuOpen = false;
            isAnimatingOut = false;
          });
        }
      });
    } else {
      setState(() {
        isMenuOpen = true;
      });
      _animationController.forward();
      controller2.forward();
      controller3.forward();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    controller2.dispose();
    controller3.dispose();
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
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon:
                          Icon(Icons.arrow_back, color: Colors.black, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Image.asset('assets/logo5.png', height: 28.h),
                  ],
                ),
                SizedBox(height: 8.h),
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
                              StreamBuilder<int>(
                                stream: Stream.periodic(Duration(seconds: 1),
                                    (_) => _filteredUsers.length),
                                builder: (context, snapshot) {
                                  return Text(
                                      '${snapshot.data ?? _filteredUsers.length}',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 12.sp));
                                },
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
                    height: 48.h,
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
                        contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 0.h),
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

                      final users = _filteredUsers;

                      users.sort((a, b) => (a['id'] ?? '')
                          .toString()
                          .compareTo((b['id'] ?? '').toString()));

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index];
                          return AnimatedSwitcher(
                            duration: Duration(milliseconds: 500),
                            switchInCurve: Curves.easeOutQuart,
                            switchOutCurve: Curves.easeInOut,
                            child: SlideTransition(
                              key: ValueKey(user['id']),
                              position: Tween<Offset>(
                                begin: Offset(1.5, 0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: controller4,
                                curve: Interval(
                                  index * (0.8 / users.length),
                                  1.0,
                                  curve: Curves.easeOutBack,
                                ),
                              )),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => UserDetailScreen(
                                          userId: user['id'],
                                          profileImageUrl:
                                              'https://arlexrfzqvahegtolcjp.supabase.co/storage/v1/object/public/profile/${user['id']}.png',
                                        ),
                                      ),
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    color: Colors.white,
                                    width: constraints.maxWidth,
                                    padding: EdgeInsets.all(16.w),
                                    child: Row(
                                      children: [
                                        AnimatedContainer(
                                          duration: Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                          width: constraints.maxWidth * 0.15,
                                          height: constraints.maxWidth * 0.15,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              'https://arlexrfzqvahegtolcjp.supabase.co/storage/v1/object/public/profile/${user['id']}.png',
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Image.network(
                                                  'https://arlexrfzqvahegtolcjp.supabase.co/storage/v1/object/public/profile/Icon.png',
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
                                              Text(
                                                  '${user['name'] ?? 'Unknown'}',
                                                  style: TextStyle(
                                                      fontSize:
                                                          constraints.maxWidth *
                                                              0.040),
                                                  overflow:
                                                      TextOverflow.ellipsis),
                                              SizedBox(height: 4.h),
                                              Text('ID: ${user['id'] ?? ''}',
                                                  style: TextStyle(
                                                      fontSize:
                                                          constraints.maxWidth *
                                                              0.035)),
                                            ],
                                          ),
                                        ),
                                        AnimatedContainer(
                                          duration: Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
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
          if (isMenuOpen || isAnimatingOut) ...[
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
                child: SlideTransition(
                  position: animation,
                  child: _buildMiniFAB(icon: Icons.add),
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
                child: SlideTransition(
                  position: animation2,
                  child: _buildMiniFAB(icon: Icons.search),
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
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildMiniFAB({required IconData icon}) {
    return Container(
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
            color: Colors.black.withOpacity(0.4),
            blurRadius: 4.r,
            offset: Offset(0, 3.h),
          ),
          BoxShadow(
            color: Color.fromARGB(255, 33, 32, 32),
            offset: Offset(3.w, 4.h),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.black),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
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
    );
  }
}
