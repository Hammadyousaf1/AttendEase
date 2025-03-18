import 'package:ae/RegisrationScreen.dart';
import 'package:flutter/material.dart';
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
      final response =
          await supabase.from('attendance').select().eq('status', 'enrolled');
      return response;
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      await supabase.from('attendance').delete().eq('id', userId);
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
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: const Color.fromARGB(255, 0, 0, 0)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: constraints.maxWidth * 0.04, vertical: 8.0),
                    child: Text(
                      'User\nManagement',
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: constraints.maxWidth * 0.043),
                    ),
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _usersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      if (snapshot.hasError) {
                        return Text('Error',
                            style: TextStyle(color: Colors.red));
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              margin: EdgeInsets.only(
                                  left: constraints.maxWidth * 0.01,
                                  top: constraints.maxHeight * 0.01),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius:
                                    BorderRadius.circular(8), // Set radius to 8
                              ),
                              width: constraints.maxWidth *
                                  0.16, // Responsive width
                              height: constraints.maxHeight *
                                  0.07, // Responsive height
                            ),
                            Container(
                              width: constraints.maxWidth *
                                  0.16, // Responsive width
                              height: constraints.maxHeight *
                                  0.07, // Responsive height
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Color.fromARGB(255, 0, 0, 0),
                                  width: 1,
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
                                          fontSize:
                                              constraints.maxWidth * 0.030),
                                    ),
                                    Text(
                                      '${snapshot.data?.length ?? 0}',
                                      style: TextStyle(
                                          color: Color.fromARGB(255, 0, 0, 0),
                                          fontSize:
                                              constraints.maxWidth * 0.030),
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
              SizedBox(height: 12),
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

                    // Sort users by roll_no
                    users.sort((a, b) => (a['roll_no'] as String)
                        .compareTo(b['roll_no'] as String));

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
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.0), // Ensures padding
                              leading: Text('${user['roll_no'] ?? ''}',
                                  style: TextStyle(
                                      fontSize: constraints.maxWidth * 0.035)),
                              title: Text('${user['name'] ?? 'Unknown'}',
                                  style: TextStyle(
                                      fontSize: constraints.maxWidth * 0.035)),
                              trailing: Container(
                                width:
                                    96, // Fixed width to align buttons properly
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
                                      onPressed: () => deleteUser(
                                          int.parse(user['roll_no'])),
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
                        width: constraints.maxWidth * 0.16, // Responsive width
                        height:
                            constraints.maxHeight * 0.1, // Responsive height
                        // Black background container
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(
                            right: constraints.maxWidth * 0.035,
                            bottom: constraints.maxHeight * 0.045),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius:
                              BorderRadius.circular(8), // Set radius to 8
                        ),
                      ),
                      Container(
                        width: constraints.maxWidth * 0.16, // Responsive width
                        height:
                            constraints.maxHeight * 0.1, // Responsive height
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(
                            right: constraints.maxWidth * 0.05,
                            bottom: constraints.maxHeight *
                                0.05), // Responsive margin
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          border: Border(
                            bottom: BorderSide(
                              color: Color.fromARGB(255, 0, 0, 0)
                                  .withOpacity(1), // Updated border color
                              width: 1,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue
                                  .withOpacity(0.2), // Updated box shadow color
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.add,
                            color: const Color.fromARGB(255, 0, 0, 0),
                            size: constraints.maxWidth *
                                0.07), // Responsive icon size
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
