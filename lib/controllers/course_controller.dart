import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';

class CourseController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new course
  Future<void> createCourse(Course course) async {
    await _firestore.collection('courses').doc(course.id).set(course.toMap());
  }

  // Update course details
  Future<void> updateCourse(Course course) async {
    await _firestore.collection('courses').doc(course.id).update(course.toMap());
  }

  // Add a specific topic within a course
  Future<void> addTopic(String courseId, Topic topic) async {
    await _firestore.collection('courses').doc(courseId).collection('topics').doc(topic.id).set(topic.toMap());
  }

  // Update a specific topic within a course
  Future<void> updateTopic(String courseId, Topic topic) async {
    await _firestore.collection('courses').doc(courseId).collection('topics').doc(topic.id).update(topic.toMap());
  }

  // Delete a specific topic within a course
  Future<void> deleteTopic(String courseId, String topicId) async {
    await _firestore.collection('courses').doc(courseId).collection('topics').doc(topicId).delete();
  }

  // Stream for real-time updates of enrolled students using courseId from students collection
  Stream<List<Map<String, dynamic>>> streamEnrolledStudents(String courseId) {
    return _firestore.collection('students').snapshots().asyncMap((snapshot) async {
      List<Map<String, dynamic>> enrolledStudents = [];
      for (var studentDoc in snapshot.docs) {
        var enrolledCoursesSnapshot = await studentDoc.reference.collection('enrolled_courses').where('id', isEqualTo: courseId).get();
        if (enrolledCoursesSnapshot.docs.isNotEmpty) {
          enrolledStudents.add({
            'name': studentDoc['name'],
            'email': studentDoc['email'] ?? 'No Email Provided',
            'studentId': studentDoc.id,
          });
          print("Student enrolled: ${studentDoc['name']} with courseId: $courseId");
        }
      }
      print("Fetched ${enrolledStudents.length} students for courseId: $courseId");
      return enrolledStudents;
    });
  }

  // Stream for real-time updates of enrolled students using courseId from students collection
  Future<List<Map<String, dynamic>>> getEnrolledStudents(String courseId) async {
    List<Map<String, dynamic>> enrolledStudents = [];

    // Get the student documents
    final studentDocs = await _firestore.collection('students').get();

    // Iterate through each student to find those enrolled in the given course
    for (var studentDoc in studentDocs.docs) {
      // Check if the student is enrolled in the selected course
      final enrolledCoursesSnapshot = await studentDoc.reference
          .collection('enrolled_courses')
          .where('id', isEqualTo: courseId)
          .get();

      if (enrolledCoursesSnapshot.docs.isNotEmpty) {
        enrolledStudents.add({
          'id': studentDoc.id,
          'name': studentDoc['name'],
          'email': studentDoc['email'] ?? 'No Email Provided',
        });
      }
    }

    return enrolledStudents;
  }
  // Stream for real-time updates of certified students
  Stream<List<String>> streamCertifiedStudents(String courseId) {
    return _firestore.collection('courses').doc(courseId).snapshots().map((snapshot) {
      final courseData = snapshot.data();
      if (courseData == null || !courseData.containsKey('certifiedStudents')) {
        return [];
      }
      return List<String>.from(courseData['certifiedStudents']);
    });
  }

  // Add a certification to a student
  Future<void> addCertification(String courseId, String studentId) async {
    await _firestore.collection('courses').doc(courseId).update({
      'certifiedStudents': FieldValue.arrayUnion([studentId]),
    });

    // Add the certification to the student's profile
    await _firestore.collection('students').doc(studentId).update({
      'certifications': FieldValue.arrayUnion([courseId]),
    });
  }

  // Remove a certification from a student
  Future<void> removeCertification(String courseId, String studentId) async {
    await _firestore.collection('courses').doc(courseId).update({
      'certifiedStudents': FieldValue.arrayRemove([studentId]),
    });

    // Remove the certification from the student's profile
    await _firestore.collection('students').doc(studentId).update({
      'certifications': FieldValue.arrayRemove([courseId]),
    });
  }

  // Delete a course
  Future<void> deleteCourse(String courseId) async {
    await _firestore.collection('courses').doc(courseId).delete();
  }

  // Stream for courses with topic counts
  Stream<List<Course>> streamCoursesWithTopicCount() {
    return _firestore.collection('courses').snapshots().asyncMap((coursesSnapshot) async {
      List<Course> courses = [];
      for (var courseDoc in coursesSnapshot.docs) {
        var topicsSnapshot = await courseDoc.reference.collection('topics').get();
        courses.add(Course(
          id: courseDoc.id,
          name: courseDoc['name'],
          topics: topicsSnapshot.docs.map((doc) => Topic.fromMap(doc.data())).toList(),
        ));
      }
      return courses;
    });
  }

  // Stream for real-time updates of courses
  Stream<List<Course>> streamCourses() {
    return _firestore.collection('courses').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Course.fromMap({
          'id': doc.id,
          'name': data['name'],
          'topics': data['topics'] ?? [],
          'topicCount': (data['topics'] as List<dynamic>?)?.length ?? 0,
        });
      }).toList();
    });
  }

  // Stream for real-time updates of topics within a course
  Stream<List<Topic>> streamTopics(String courseId) {
    return _firestore.collection('courses').doc(courseId).collection('topics').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final topicData = doc.data();
        return Topic.fromMap({
          'id': doc.id,
          'name': topicData['name'],
          'url': topicData['url'],
          'text': topicData['text'],
          'isVisible': topicData['isVisible'] ?? true,
          'isCompleted': topicData['isCompleted'] ?? false,
          'gitLink': topicData['gitLink'],
        });
      }).toList();
    });
  }

  // Real-time update for student topic completion status
  Stream<List<Topic>> streamStudentTopicCompletion(String courseId) {
    return _firestore.collection('courses').doc(courseId).collection('topics').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Topic.fromMap(data);
      }).toList();
    });
  }

  // Update the status of a topic for a specific student
  Future<void> updateStudentTopicStatus(
      String studentId, String courseId, String topicId,
      {bool? isCompleted, String? githubLink}) async {
    final Map<String, dynamic> updateData = {};
    if (isCompleted != null) updateData['isCompleted'] = isCompleted;
    if (githubLink != null) updateData['gitLink'] = githubLink;

    // Update in the main course topics collection
    await _firestore.collection('courses').doc(courseId).collection('topics').doc(topicId).update(updateData);

    // Propagate changes to each student enrolled in the course
    await _firestore.collection('students').where('enrolled_courses', arrayContains: courseId).get().then((snapshot) {
      for (var studentDoc in snapshot.docs) {
        studentDoc.reference.collection('enrolled_courses').doc(courseId).collection('topics').doc(topicId).set(updateData, SetOptions(merge: true));
      }
    });
  }

  // Update the status of a topic across both teacher and student side
  Future<void> toggleTopicCompletion(String courseId, String topicId, bool isCompleted) async {
    // Update in the main course topics collection
    await _firestore.collection('courses').doc(courseId).collection('topics').doc(topicId).update({'isCompleted': isCompleted});

    // Update in all students' enrolled courses
    await _firestore.collection('students').where('enrolled_courses', arrayContains: courseId).get().then((snapshot) {
      for (var studentDoc in snapshot.docs) {
        studentDoc.reference.collection('enrolled_courses').doc(courseId).collection('topics').doc(topicId).update({'isCompleted': isCompleted});
      }
    });
  }
}
