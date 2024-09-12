import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/auth_controller.dart';

class ProfileView extends StatefulWidget {
  @override
  _ProfileViewState createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String? _profileImageUrl;
  String _name = '';
  String _email = '';
  String _about = '';
  String _phone = '';
  String _address = '';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); // Added email controller

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = AuthController().currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('students').doc(user.uid);
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        setState(() {
          _name = data['name'] ?? 'Student';
          _email = user.email ?? '';  // Set the email directly from the authenticated user
          _about = data['about'] ?? '';
          _phone = data['phone'] ?? '';
          _address = data['address'] ?? '';
          _profileImageUrl = data['profileImageUrl'] ?? '';

          // Update controllers with the loaded data
          _nameController.text = _name;
          _aboutController.text = _about;
          _phoneController.text = _phone;
          _addressController.text = _address;
          _emailController.text = _email; // Set email in the controller
        });
      } else {
        // Create document if it does not exist and set email
        _email = user.email ?? '';
        await docRef.set({
          'name': _name,
          'email': _email, // Save email in Firestore
          'about': _about,
          'phone': _phone,
          'address': _address,
          'profileImageUrl': _profileImageUrl,
        });
        setState(() {
          _emailController.text = _email; // Set email in the controller
        });
      }
    }
  }

  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = FirebaseStorage.instance.ref().child('profile_images').child('${user.uid}.jpg');

        try {
          await ref.putFile(File(pickedFile.path));
          final url = await ref.getDownloadURL();
          await FirebaseFirestore.instance.collection('students').doc(user.uid).set({
            'profileImageUrl': url,
          }, SetOptions(merge: true)); // Merge true to prevent overwriting

          setState(() {
            _profileImageUrl = url;
          });

          _loadProfileData(); // Refresh data to update UI
        } catch (e) {
          print("Error uploading image: $e");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image')),
          );
        }
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final user = AuthController().currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance.collection('students').doc(user.uid).set({
            'name': _nameController.text,
            'about': _aboutController.text,
            'phone': _phoneController.text,
            'address': _addressController.text,
            'profileImageUrl': _profileImageUrl ?? '', // Default to empty if null
          }, SetOptions(merge: true)); // Merge true to prevent overwriting
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully')),
          );

          // After saving, navigate back to the dashboard
          Navigator.pop(context);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xffd299c2), Color(0xfffef9d7), Color(0xffd299c2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffd299c2), Color(0xfffef9d7), Color(0xffd299c2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: _uploadProfileImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                            ? Icon(Icons.camera_alt, size: 40, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildTextField('Name', _nameController),
                  SizedBox(height: 20),
                  _buildTextField('Email', _emailController, readOnly: true), // Display email as non-editable
                  SizedBox(height: 20),
                  _buildTextField('Phone', _phoneController),
                  SizedBox(height: 20),
                  _buildTextField('Address', _addressController),
                  SizedBox(height: 20),
                  _buildTextField('About', _aboutController),
                  SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xff330867),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                      ),
                      child: Text('Save', style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      validator: (value) {
        if (!readOnly && (value == null || value.isEmpty)) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
