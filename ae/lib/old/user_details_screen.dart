import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final List<String> capturedImages;

  const ProfileScreen({Key? key, required this.capturedImages}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(); // New controller for phone number
  bool _isSubmitting = false;

  Future<void> _submitData() async {
    if (_nameController.text.isEmpty || _idController.text.isEmpty || _phoneController.text.length != 11) { // Check for phone number length
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all fields and ensure phone number is 11 digits")),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://192.168.100.5:5000/train'));
      request.fields['name'] = _nameController.text;
      request.fields['id'] = _idController.text;
      request.fields['phone'] = _phoneController.text; // Add phone number to request

      for (var imagePath in widget.capturedImages) {
        request.files.add(await http.MultipartFile.fromPath('images', imagePath));
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
                Navigator.pushReplacementNamed(context, '/'); // Navigate to main screen
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
    return Scaffold(
      appBar: AppBar(title: Text("Enter Profile Details")),
      body: SingleChildScrollView( // Make the body scrollable
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.capturedImages.isNotEmpty)
              CircleAvatar(
                radius: 130,
                backgroundImage: FileImage(File(widget.capturedImages.first)),
              ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: _idController,
              decoration: InputDecoration(labelText: "ID"),
            ),
            TextField(
              controller: _phoneController, // New TextField for phone number
              decoration: InputDecoration(labelText: "Phone No"),
              maxLength: 11, // Limit input to 11 characters
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitData,
              child: _isSubmitting
                  ? CircularProgressIndicator()
                  : Text("Create Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
