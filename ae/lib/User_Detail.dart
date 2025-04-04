import 'package:ae/User_Input_Screen.dart';
import 'package:ae/User_Management.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String? profileImageUrl;

  const UserDetailScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.profileImageUrl,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool isLoading = false;
  String? profileImageUrl;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    profileImageUrl = widget.profileImageUrl;
  }

  Future<void> deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => isLoading = true);

        // Delete user from database
        await supabase.from('users').delete().eq('id', widget.userId);

        // Delete profile picture if exists
        final fileName = '${widget.userId}.png';
        try {
          await supabase.storage.from('profile_pictures').remove([fileName]);
        } catch (e) {
          // Ignore if image doesn't exist
        }

        // Navigate back to user management and restart it
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => UserManagementScreen()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete user: $e')),
        );
      }
    }
  }

  Future<void> editUser() async {
    final nameController = TextEditingController(text: widget.userName);
    final whatsappController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: whatsappController,
              decoration: const InputDecoration(
                labelText: 'WhatsApp Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                setState(() => isLoading = true);
                await supabase.from('users').update({
                  'name': nameController.text,
                  'phone': whatsappController.text,
                }).eq('id', widget.userId);
                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update user: $e')),
                );
                Navigator.pop(context, false);
              } finally {
                setState(() => isLoading = false);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      // Refresh the user details if edit was successful
      Navigator.pop(context, true);
    }
  }

  Future<void> _showImageOptions() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Picture'),
        content: const Text('What would you like to do?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'upload'),
            child: const Text('Upload New'),
          ),
          if (profileImageUrl != null)
            TextButton(
              onPressed: () => Navigator.pop(context, 'delete'),
              child: const Text('Delete Current',
                  style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result == 'upload') {
      await updateProfilePicture();
    } else if (result == 'delete') {
      await deleteProfilePicture();
    }
  }

  Future<void> deleteProfilePicture() async {
    try {
      setState(() => isLoading = true);
      final fileName = '${widget.userId}.png';

      await supabase.storage.from('profile_pictures').remove([fileName]);

      setState(() {
        profileImageUrl = null;
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture deleted successfully')),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete profile picture: $e')),
      );
    }
  }

  Future<void> updateProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      try {
        setState(() => isLoading = true);
        final imageBytes = await File(pickedFile.path).readAsBytes();
        final image = img.decodeImage(imageBytes);
        final pngBytes = img.encodePng(image!);
        final tempFile = File('${pickedFile.path}.png');
        await tempFile.writeAsBytes(pngBytes);

        final fileName = '${widget.userId}.png';

        // Delete existing image if it exists
        try {
          final existingFiles = await supabase.storage
              .from('profile_pictures')
              .list(path: fileName);

          if (existingFiles.isNotEmpty) {
            await supabase.storage.from('profile_pictures').remove([fileName]);
          }
        } catch (e) {
          // If file doesn't exist, continue with upload
        }

        // Upload new file
        await supabase.storage.from('profile_pictures').upload(
              fileName,
              tempFile,
              fileOptions: FileOptions(contentType: 'image/png', upsert: true),
            );

        final newImageUrl = await supabase.storage
            .from('profile_pictures')
            .createSignedUrl(fileName, 3600);

        await tempFile.delete();

        setState(() {
          profileImageUrl = newImageUrl;
          isLoading = false;
        });
      } catch (e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile picture: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: profileImageUrl != null
                            ? Image.network(
                                profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.person, size: 50),
                              )
                            : const Icon(Icons.person, size: 50),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: isLoading ? null : _showImageOptions,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 16,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${widget.userId}',
                        style:
                            const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: isLoading ? null : editUser,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: isLoading ? null : deleteUser,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
