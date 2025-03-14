import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final List<String> capturedImages;

  const ProfileScreen({Key? key, required this.capturedImages})
      : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _phoneController =
      TextEditingController(); // New controller for phone number
  bool _isSubmitting = false;

  Future<void> _submitData() async {
    if (_nameController.text.isEmpty ||
        _idController.text.isEmpty ||
        _phoneController.text.length != 11) {
      // Check for phone number length
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Please fill in all fields and ensure phone number is 11 digits")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://172.31.12.218:8000/train'));
      request.fields['name'] = _nameController.text;
      request.fields['id'] = _idController.text;
      request.fields['phone'] =
          _phoneController.text; // Add phone number to request

      for (var imagePath in widget.capturedImages) {
        request.files
            .add(await http.MultipartFile.fromPath('images', imagePath));
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload data!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text("Profile Created"),
          content: Text("Your profile has been successfully registered!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close popup
                Navigator.pushReplacementNamed(
                    context, '/'); // Navigate to main screen
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        // Make the body scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(
                  "Profile Creation",
                  style: TextStyle(fontSize: screenWidth * 0.05),
                ),
              ],
            ),
            SizedBox(height: 20),
            if (widget.capturedImages.isNotEmpty)
              CircleAvatar(
                radius: screenWidth * 0.3,
                backgroundImage: FileImage(File(widget.capturedImages.first)),
              ),
            SizedBox(height: 24),
            TextField(
              controller: _nameController,
              style: TextStyle(
                  fontSize: screenWidth * 0.03), // Responsive input text size
              decoration: InputDecoration(
                labelText: "Name",
                labelStyle: TextStyle(
                  fontSize: screenWidth * 0.03, // Responsive label text size
                  color: Colors.black,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _idController,
              style: TextStyle(
                  fontSize: screenWidth * 0.03), // Responsive input text size
              decoration: InputDecoration(
                labelText: "ID",
                labelStyle: TextStyle(
                  fontSize: screenWidth * 0.03, // Responsive label text size
                  color: Colors.black,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              style: TextStyle(
                  fontSize: screenWidth * 0.03), // Responsive input text size
              decoration: InputDecoration(
                labelText: "Whatsapp No",
                labelStyle: TextStyle(
                  fontSize: screenWidth * 0.03, // Responsive label text size
                  color: Colors.black,
                ),
                //prefixText: "+92 ", // Added pretext for country code
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                // Background for 3D effect
                Container(
                  width: double.infinity,
                  height: 52,
                  margin: EdgeInsets.only(left: 3, top: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.black,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        offset: Offset(0, 3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: Size(screenWidth - 35, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? CircularProgressIndicator.adaptive()
                        : Text(
                            "Create Profile",
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
