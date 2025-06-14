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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);

    try {
      // [MODIFIKASI] Panggil fungsi updateProfile yang baru dan lebih sederhana
      await _pbService.updateProfile(
        name: _nameController.text.trim(),
        avatarFile: _imageFile,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); 

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if(mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        elevation: 1,
        actions: [
          _isSaving
              ? Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
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
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                ),
                icon: _isSaving ? SizedBox.shrink() : Icon(Icons.save, size: 20),
                label: _isSaving
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                    : Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
      backgroundImage = FileImage(_imageFile!);
    } else if (widget.currentAvatarUrl != null) {
      backgroundImage = NetworkImage(widget.currentAvatarUrl!);
    }
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: backgroundImage,
            child: backgroundImage == null ? Icon(Icons.person_outline, size: 60, color: Colors.grey.shade400) : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF6C63FF), 
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
        labelText: 'Full Name / Organization Name',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: (value) => (value == null || value.trim().isEmpty) ? 'Name cannot be empty' : null,
    );
  }
}