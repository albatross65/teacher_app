import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/auth_controller.dart';

class SettingsView extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _changePassword(BuildContext context) {
    final TextEditingController _passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(hintText: 'Enter new password'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.redAccent,fontSize: 18),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _auth.currentUser!.updatePassword(_passwordController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Password changed successfully')),
                );
                Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to change password')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xff330867),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 25),
              elevation: 5,
            ),
            child: Text(
              'Save',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleTheme() {
    // Logic to toggle theme
  }

  void _changeLanguage(BuildContext context) {
    // Logic to change language
  }

  void _showPrivacyPolicy(BuildContext context) {
    // Logic to show privacy policy
  }

  void _showTerms(BuildContext context) {
    // Logic to show terms of service
  }

  void _logout(BuildContext context) {
    AuthController().signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xffd299c2),
                Color(0xfffef9d7),
                Color(0xffd299c2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xffd299c2),
              Color(0xfffef9d7),
              Color(0xffd299c2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            ListTile(
              leading: Icon(Icons.palette, color: Colors.deepPurple),
              title: Text('Change Theme', style: GoogleFonts.poppins()),
              trailing: Switch(
                value: true, // Placeholder for current theme state
                onChanged: (value) {
                  _toggleTheme();
                },
              ),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.language, color: Colors.deepPurple),
              title: Text('Change Language', style: GoogleFonts.poppins()),
              onTap: () {
                _changeLanguage(context);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.lock, color: Colors.deepPurple),
              title: Text('Change Password', style: GoogleFonts.poppins()),
              onTap: () {
                _changePassword(context); // Trigger password change dialog
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.privacy_tip, color: Colors.deepPurple),
              title: Text('Privacy Policy', style: GoogleFonts.poppins()),
              onTap: () {
                _showPrivacyPolicy(context);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.description, color: Colors.deepPurple),
              title: Text('Terms of Service', style: GoogleFonts.poppins()),
              onTap: () {
                _showTerms(context);
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.deepPurple),
              title: Text('Log Out', style: GoogleFonts.poppins()),
              onTap: () {
                _logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
