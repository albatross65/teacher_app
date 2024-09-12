import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teacher_app/views/login_view.dart';
import 'package:teacher_app/views/teacher_dashboard.dart';
import 'controllers/auth_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.brown[400],
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.brown[400],
    ));
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Teacher App',
      home: AuthController().isUserLoggedIn() ? TeacherDashboard() : LoginView(),
    );
  }
}
