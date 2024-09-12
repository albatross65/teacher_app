import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/course_model.dart';
import '../controllers/course_controller.dart'; // Import CourseController

class NotificationsView extends StatefulWidget {
  @override
  _NotificationsViewState createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CourseController _courseController = CourseController(); // Initialize CourseController
  List<Course> _courses = [];
  String? _selectedCourseId;
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  void _loadCourses() async {
    try {
      final snapshot = await _firestore.collection('courses').get();
      List<Course> courses = snapshot.docs.map((doc) {
        return Course.fromMap({
          'id': doc.id,
          'name': doc['name'],
          'topics': [],
          'topicCount': 0,
        });
      }).toList();

      setState(() {
        _courses = courses;
      });
    } catch (e) {
      print("Error loading courses: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load courses")),
      );
    }
  }
  void _sendNotificationToAll() async {
    if (_selectedCourseId != null && _messageController.text.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get all enrolled students for the selected course
        final enrolledStudents = await _courseController.getEnrolledStudents(_selectedCourseId!);

        for (var student in enrolledStudents) {
          final studentId = student['id'];

          final studentDoc = await _firestore.collection('students').doc(studentId).get();
          final fcmToken = studentDoc.data()?['fcmToken'];

          if (fcmToken != null) {
            await _sendFCMNotification(fcmToken, _messageController.text);

            await _firestore.collection('students').doc(studentId).collection('notifications').add({
              'message': _messageController.text,
              'timestamp': FieldValue.serverTimestamp(),
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Notification sent to ${student['name']}")),
            );
          } else {
            // Log and inform the teacher
            print("FCM token not found for student: ${student['name']}");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("FCM token not found for ${student['name']}")),
            );
          }
        }

        _messageController.clear();
      } catch (e) {
        print("Error sending notification: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send notification")),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a course and enter a message")),
      );
    }
  }


  Future<void> _sendFCMNotification(String fcmToken, String message) async {
    const String serverKey = 'YOUR_SERVER_KEY'; // Replace with your actual FCM server key

    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode({
        'to': fcmToken,
        'notification': {
          'title': 'New Notification from Teacher',
          'body': message,
        },
      }),
    );

    if (response.statusCode != 200) {
      print('FCM Error: ${response.body}');
      throw Exception('Failed to send FCM notification');
    } else {
      print('FCM Response: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Send Notifications',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.red),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.red),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xffb3e5fc),
                Color(0xffe1bee7),
                Color(0xffb3e5fc),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xffb3e5fc),
              Color(0xffe1bee7),
              Color(0xffb3e5fc),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 10,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Send Notification",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Select Course",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        value: _selectedCourseId,
                        items: _courses.map((course) {
                          return DropdownMenuItem<String>(
                            value: course.id,
                            child: Text(course.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCourseId = value;
                          });
                        },
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          labelText: "Enter Message",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 5,
                      ),
                      SizedBox(height: 20),
                      _isLoading
                          ? CircularProgressIndicator()
                          : ElevatedButton.icon(
                        onPressed: _sendNotificationToAll,
                        icon: Icon(Icons.send),
                        label: Text("Send Notification to All Enrolled Students"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
