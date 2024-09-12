import 'package:flutter/material.dart';
import '../controllers/course_controller.dart';
import '../models/course_model.dart';
import 'StudentListView.dart';

class ManageStudentsView extends StatefulWidget {
  @override
  _ManageStudentsViewState createState() => _ManageStudentsViewState();
}

class _ManageStudentsViewState extends State<ManageStudentsView> {
  final CourseController _courseController = CourseController();
  List<Course> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  void _loadCourses() {
    // Listening to the stream of courses
    _courseController.streamCoursesWithTopicCount().listen((courses) {
      setState(() {
        _courses = courses;
      });
    });
  }

  void _onCourseSelected(Course course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentListView(course: course),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Students',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xff2193b0),
                Color(0xff6dd5ed),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 5,
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
        child: Column(
          children: [
            _buildCourseSelectionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseSelectionSection() {
    return _courses.isEmpty
        ? Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "No courses available",
          style: TextStyle(
            fontSize: 20,
            color: Colors.black54,
          ),
        ),
      ),
    )
        : Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];
          return GestureDetector(
            onTap: () => _onCourseSelected(course),
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Color(0xffe1bee7),
                    Color(0xffb3e5fc),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    course.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xff2193b0),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Color(0xff2193b0)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
