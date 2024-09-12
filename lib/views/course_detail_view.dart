import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../controllers/course_controller.dart';
import '../models/course_model.dart';

class CourseDetailView extends StatefulWidget {
  final Course course;

  CourseDetailView({required this.course});

  @override
  _CourseDetailViewState createState() => _CourseDetailViewState();
}

class _CourseDetailViewState extends State<CourseDetailView>
    with SingleTickerProviderStateMixin {
  final CourseController _courseController = CourseController();
  late Stream<List<Topic>> _topicsStream;
  late Stream<List<Map<String, dynamic>>> _studentsStream;
  late List<String> _certifiedStudents;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _topicsStream = _courseController.streamTopics(widget.course.id);
    _studentsStream = _courseController.streamEnrolledStudents(widget.course.id);
    _certifiedStudents = [];
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTopic() async {
    final newTopic = await _showAddTopicDialog(context);
    if (newTopic != null) {
      await _courseController.addTopic(widget.course.id, newTopic);
      setState(() {});
    }
  }

  void _deleteTopic(String topicId) async {
    await _courseController.deleteTopic(widget.course.id, topicId);
    setState(() {});
  }

  void _editTopic(String topicId, Topic updatedTopic) async {
    await _courseController.updateTopic(widget.course.id, updatedTopic);
    setState(() {});
  }

  void _certifyStudent(String studentId) {
    _courseController.addCertification(widget.course.id, studentId).then((_) {
      setState(() {
        _certifiedStudents.add(studentId);
      });
      print('Student certified: $studentId');
    }).catchError((error) {
      print('Error certifying student: $error');
    });
  }

  void _uncertifyStudent(String studentId) {
    _courseController.removeCertification(widget.course.id, studentId).then((_) {
      setState(() {
        _certifiedStudents.remove(studentId);
      });
      print('Student uncertified: $studentId');
    }).catchError((error) {
      print('Error uncertifying student: $error');
    });
  }

  Future<Topic?> _showAddTopicDialog(BuildContext context) async {
    String topicName = '';
    String topicUrl = '';
    String topicDescription = '';

    return await showDialog<Topic>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        title: Text(
          "Add Topic",
          style: GoogleFonts.poppins(
            textStyle: TextStyle(
              color: Colors.teal,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField('Topic Name', (value) => topicName = value),
            SizedBox(height: 10),
            _buildTextField('URL', (value) => topicUrl = value),
            SizedBox(height: 10),
            _buildTextField('Description', (value) => topicDescription = value),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text("Cancel", style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () {
              if (topicName.isNotEmpty) {
                final newTopicId = Uuid().v4();
                Navigator.of(context).pop(Topic(
                  id: newTopicId,
                  name: topicName,
                  url: topicUrl,
                  text: topicDescription,
                  isVisible: true,
                  isCompleted: false,
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Topic name cannot be empty')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<Topic?> _showEditTopicDialog(BuildContext context, Topic topic) async {
    String topicName = topic.name;
    String topicUrl = topic.url;
    String topicDescription = topic.text;

    return await showDialog<Topic>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        title: Text(
          "Edit Topic",
          style: GoogleFonts.poppins(
            textStyle: TextStyle(
              color: Colors.teal,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField('Topic Name', (value) => topicName = value, initialValue: topicName),
            SizedBox(height: 10),
            _buildTextField('URL', (value) => topicUrl = value, initialValue: topicUrl),
            SizedBox(height: 10),
            _buildTextField('Description', (value) => topicDescription = value, initialValue: topicDescription),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text("Cancel", style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            onPressed: () {
              if (topicName.isNotEmpty) {
                Navigator.of(context).pop(Topic(
                  id: topic.id,
                  name: topicName,
                  url: topicUrl,
                  text: topicDescription,
                  isVisible: topic.isVisible,
                  isCompleted: topic.isCompleted,
                  gitLink: topic.gitLink,
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Topic name cannot be empty')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  TextField _buildTextField(String label, Function(String) onChanged, {String? initialValue}) {
    return TextField(
      onChanged: onChanged,
      controller: TextEditingController(text: initialValue),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.teal),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.teal),
        ),
      ),
    );
  }

  void _updateTopicVisibility(Topic topic) {
    Topic updatedTopic = Topic(
      id: topic.id,
      name: topic.name,
      url: topic.url,
      text: topic.text,
      isVisible: !topic.isVisible, // Toggle visibility
      isCompleted: topic.isCompleted,
      gitLink: topic.gitLink,
    );
    _courseController.updateTopic(widget.course.id, updatedTopic).then((_) {
      setState(() {}); // Refresh UI to reflect the visibility change
    });
  }

  void _updateTopicCompletion(Topic topic) {
    Topic updatedTopic = Topic(
      id: topic.id,
      name: topic.name,
      url: topic.url,
      text: topic.text,
      isVisible: topic.isVisible,
      isCompleted: !topic.isCompleted, // Toggle completion
      gitLink: topic.gitLink,
    );
    _courseController.updateTopic(widget.course.id, updatedTopic).then((_) {
      setState(() {}); // Refresh UI to reflect the completion change
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.course.name,
          style: GoogleFonts.poppins(
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.teal.shade700,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffb3e5fc), Color(0xffe1bee7), Color(0xffb3e5fc)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 20),
                  Expanded(
                    child: StreamBuilder<List<Topic>>(
                      stream: _topicsStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          print("Error fetching topics: ${snapshot.error}");
                          return Center(child: Text("Error loading topics"));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          print("No topics found for course: ${widget.course.id}");
                          return Center(child: Text("No topics available"));
                        }

                        final topics = snapshot.data!;
                        print("Fetched ${topics.length} topics for course: ${widget.course.id}");
                        return ListView.builder(
                          itemCount: topics.length,
                          itemBuilder: (context, index) {
                            final topic = topics[index];
                            return _buildTopicCard(topic, index);
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _addTopic,
                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text(
                        "Add Topic",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        textStyle: GoogleFonts.poppins(
                          textStyle: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Details',
          style: GoogleFonts.poppins(
            textStyle: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Course Name: ${widget.course.name}',
          style: GoogleFonts.poppins(
            textStyle: TextStyle(
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopicCard(Topic topic, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Color(0xffe1bee7), Color(0xffb3e5fc)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopicHeader(topic, index),
            SizedBox(height: 10),
            Text(
              'URL: ${topic.url}',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Description: ${topic.text}',
              style: GoogleFonts.poppins(
                textStyle: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            if (topic.gitLink != null && topic.gitLink!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  'GitHub Link: ${topic.gitLink}',
                  style: GoogleFonts.poppins(
                    textStyle: TextStyle(
                      fontSize: 16,
                      color: Colors.teal.shade900,
                    ),
                  ),
                ),
              ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => _updateTopicVisibility(topic),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: topic.isVisible
                        ? Colors.orange
                        : Colors.teal.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    topic.isVisible ? 'Show' : 'Hide',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _updateTopicCompletion(topic),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: topic.isCompleted
                        ? Colors.teal.shade800
                        : Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    topic.isCompleted ? 'Completed' : 'Pending',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicHeader(Topic topic, int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          topic.name,
          style: GoogleFonts.poppins(
            textStyle: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade900,
            ),
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.teal),
              onPressed: () async {
                final updatedTopic = await _showEditTopicDialog(context, topic);
                if (updatedTopic != null) {
                  _editTopic(topic.id, updatedTopic);
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _confirmDeleteTopic(topic.id),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmDeleteTopic(String topicId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        title: Text(
          "Delete Topic",
          style: GoogleFonts.poppins(
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
              fontSize: 20,
            ),
          ),
        ),
        content: Text(
          "Are you sure you want to delete this topic?",
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel", style: TextStyle(color: Colors.teal)),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteTopic(topicId);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
