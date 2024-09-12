import 'package:flutter/material.dart';
import '../controllers/course_controller.dart';
import '../models/course_model.dart';

class StudentListView extends StatefulWidget {
  final Course course;

  StudentListView({required this.course});

  @override
  _StudentListViewState createState() => _StudentListViewState();
}

class _StudentListViewState extends State<StudentListView> {
  final CourseController _courseController = CourseController();
  List<Map<String, dynamic>> _students = [];
  List<String> _certifiedStudents = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  void _loadStudents() {
    _courseController.streamEnrolledStudents(widget.course.id).listen((students) {
      setState(() {
        _students = students; // students is now a List<Map<String, dynamic>>
      });
    });

    _courseController.streamCertifiedStudents(widget.course.id).listen((certifiedStudents) {
      setState(() {
        _certifiedStudents = certifiedStudents;
      });
    });
  }


  void _certifyStudent(String studentId) {
    _courseController.addCertification(widget.course.id, studentId).then((_) {
      // Optionally, refresh data or show confirmation
      print('Student certified: $studentId'); // Debugging: Log certification action
    }).catchError((error) {
      // Handle any errors here
      print('Error certifying student: $error');
    });
  }

  void _uncertifyStudent(String studentId) {
    _showUncertifyConfirmation(studentId);
  }

  void _showUncertifyConfirmation(String studentId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Uncertify'),
          content: Text('Are you sure you want to uncertify this student?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _courseController.removeCertification(widget.course.id, studentId).then((_) {
                  print('Student uncertified: $studentId'); // Debugging: Log uncertify action
                }).catchError((error) {
                  print('Error uncertifying student: $error'); // Debugging: Log error
                });
                Navigator.of(context).pop();
              },
              child: Text('Uncertify'),
            ),
          ],
        );
      },
    );
  }

  void _onViewCertifiedStudents() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CertifiedStudentsView(
          course: widget.course,
          certifiedStudents: _certifiedStudents,
          onUncertify: _uncertifyStudent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.course.name} - Students',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xffed5565),
                Color(0xffffc371),
                Color(0xffed5565),
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
            _buildViewCertifiedButton(),
            _buildStudentList(),
          ],
        ),
      ),
    );
  }

  Widget _buildViewCertifiedButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: GestureDetector(
        onTap: _onViewCertifiedStudents,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Color(0xff2193b0),
                Color(0xff6dd5ed),
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
          child: Center(
            child: Text(
              "View Certified Students",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentList() {
    return _students.isEmpty
        ? Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "No students enrolled",
          style: TextStyle(
            fontSize: 20,
            color: Colors.black54,
          ),
        ),
      ),
    )
        : Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          final studentName = student['name'];
          final studentEmail = student['email'];
          final isCertified = _certifiedStudents.contains(studentName);

          if (isCertified) return SizedBox.shrink();

          return Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                colors: [Color(0xffffc371), Color(0xffed5565)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              title: Text(
                studentName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                studentEmail ?? 'No Email Provided',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.deepOrange,
                child: Icon(Icons.person, color: Colors.white),
              ),
              trailing: ElevatedButton(
                onPressed: () => _certifyStudent(studentName),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: Text('Certify'),
              ),
            ),
          );
        },
      ),
    );
  }

}

class CertifiedStudentsView extends StatelessWidget {
  final Course course;
  final List<String> certifiedStudents;
  final void Function(String) onUncertify;

  CertifiedStudentsView({
    required this.course,
    required this.certifiedStudents,
    required this.onUncertify,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Certified Students',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xffa8e063),
                Color(0xff56ab2f),
                Color(0xffa8e063),
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
        child: certifiedStudents.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "No certified students",
              style: TextStyle(
                fontSize: 20,
                color: Colors.black54,
              ),
            ),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: certifiedStudents.length,
          itemBuilder: (context, index) {
            final student = certifiedStudents[index];
            return Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [Color(0xffa8e063), Color(0xff56ab2f)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                title: Text(
                  student,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                trailing: ElevatedButton(
                  onPressed: () => onUncertify(student),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Text('Uncertify'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
