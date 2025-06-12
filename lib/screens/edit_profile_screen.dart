// File: lib/screens/edit_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:volunteervibe/services/pocketbase_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String currentName;
  final String? currentAvatarUrl;

  const EditProfileScreen({
    Key? key,
    required this.currentName,
    this.currentAvatarUrl,
  }) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final PocketBaseService _pbService = PocketBaseService();
  late final TextEditingController _nameController;
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  bool _isUploading = false;
  String? _newAvatarUrl; // To hold the current avatar URL or the newly selected image's temporary URL

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _newAvatarUrl = widget.currentAvatarUrl;

    // --- DEBUGGING PRINTS ---
    print('EditProfileScreen: Received currentName: ${widget.currentName}');
    print('EditProfileScreen: Received currentAvatarUrl: ${widget.currentAvatarUrl}');
    // --- END DEBUGGING PRINTS ---
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        // We don't update _newAvatarUrl here yet, as it's only truly updated
        // after a successful save. The _imageFile takes precedence for display.
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_isUploading) return;
    
    setState(() => _isUploading = true);

    try {
      await _pbService.updateUserProfile(
        name: _nameController.text.trim(),
        avatarFile: _imageFile,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      // Kirim 'true' kembali ke halaman profil untuk menandakan ada pembaruan
      Navigator.pop(context, true); 

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if(mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        actions: [
          _isUploading
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : TextButton(
                  onPressed: _saveProfile,
                  child: Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildAvatarEditor(),
            SizedBox(height: 32),
            _buildNameTextField(),
            SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Color(0xFF6C63FF), // Add a primary color for the button
                  foregroundColor: Colors.white, // Text color
                ),
                child: _isUploading
                  ? Text("Saving...")
                  : Text('Save Changes', style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarEditor() {
    ImageProvider? backgroundImage;
    if (_imageFile != null) {
      // If a new image is picked, use it
      backgroundImage = FileImage(_imageFile!);
    } else if (_newAvatarUrl != null && _newAvatarUrl!.isNotEmpty) {
      // Otherwise, if there's a current avatar URL, use it
      backgroundImage = NetworkImage(_newAvatarUrl!);
    }

    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: backgroundImage,
            child: backgroundImage == null
                ? Icon(Icons.person, size: 60, color: Colors.grey.shade400)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Theme.of(context).primaryColor, // Use theme's primary color
                child: Icon(Icons.edit, color: Colors.white, size: 22),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNameTextField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Full Name',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
    );
  }
}