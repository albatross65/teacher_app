import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'teacher_dashboard.dart';

class LoginView extends StatefulWidget {
  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _isLogin = true; // Toggle between login and signup
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final AuthController _authController = AuthController();

  void _toggleForm() {
    setState(() {
      _isLogin = !_isLogin; // Switch between login and signup
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authController.signIn(_emailController.text.trim(), _passwordController.text.trim());
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TeacherDashboard()));
    } catch (e) {
      _showError(e.toString());
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _signup() async {
    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      _showError("Passwords do not match");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authController.signUp(_emailController.text.trim(), _passwordController.text.trim());
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => TeacherDashboard()));
    } catch (e) {
      _showError(e.toString());
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showError(String error) {
    String errorMessage;

    if (error.contains('invalid-email')) {
      errorMessage = 'The email address is badly formatted.';
    } else if (error.contains('weak-password')) {
      errorMessage = 'The password provided is too weak.';
    } else if (error.contains('email-already-in-use')) {
      errorMessage = 'The email address is already in use by another account.';
    } else if (error.contains('operation-not-allowed')) {
      errorMessage = 'Email/Password accounts are not enabled.';
    } else {
      errorMessage = 'An error occurred: $error';
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/22.jpg'), // Add your own background image
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xffb3e5fc).withOpacity(0.4), Color(0xffe1bee7).withOpacity(0.4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isLogin ? 'Welcome Back!' : 'Create an Account',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 30),
                    _buildTextField(_emailController, 'Email', Icons.email),
                    SizedBox(height: 20),
                    _buildTextField(_passwordController, 'Password', Icons.lock, obscureText: true),
                    if (!_isLogin) ...[
                      SizedBox(height: 20),
                      _buildTextField(_confirmPasswordController, 'Confirm Password', Icons.lock, obscureText: true),
                    ],
                    SizedBox(height: 30),
                    _isLoading
                        ? CircularProgressIndicator(color: Color(0xffeea849))
                        : ElevatedButton(
                      onPressed: _isLogin ? _login : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xffeea849),
                        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        _isLogin ? ' Login ' : 'Sign Up',
                        style: TextStyle(color: Colors.black, fontSize: 20),
                      ),
                    ),
                    SizedBox(height: 20),
                    GestureDetector(
                      onTap: _toggleForm,
                      child: Text(
                        _isLogin ? 'Don\'t have an account? Sign Up' : 'Already have an account? Login',
                        style: TextStyle(color: Colors.black, fontSize: 16, decoration: TextDecoration.underline),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, IconData icon, {bool obscureText = false, Function()? togglePasswordVisibility}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        suffixIcon: obscureText
            ? IconButton(
          icon: Icon(Icons.visibility, color: Colors.white),
          onPressed: togglePasswordVisibility,
        )
            : null,
      ),
      style: TextStyle(color: Colors.white),
    );
  }
}
