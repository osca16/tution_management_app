import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkSchedule extends StatefulWidget {
  const HomeworkSchedule({super.key});

  @override
  _HomeworkScheduleState createState() => _HomeworkScheduleState();
}

class _HomeworkScheduleState extends State<HomeworkSchedule> {
  String? teacherSubject;
  String? selectedGrade;
  TextEditingController homeworkController = TextEditingController();
  List<String> availableGrades = [];

  @override
  void initState() {
    super.initState();
    _loadTeacherSubject();
    _loadAvailableGrades();
  }

  // Fetch teacher's subject from Firestore
  Future<void> _loadTeacherSubject() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final teacherDoc =
        await FirebaseFirestore.instance.collection('teachers').doc(uid).get();

    setState(() {
      teacherSubject = teacherDoc.data()?['subject'];
    });
  }

  // Load available grades based on students
  Future<void> _loadAvailableGrades() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    final grades =
        snapshot.docs
            .map((doc) => doc['grade'] as String?)
            .where((grade) => grade != null)
            .toSet()
            .cast<String>()
            .toList();

    grades.sort(); // optional: sort grades alphabetically
    setState(() {
      availableGrades = grades;
    });
  }

  // Assign homework to all students in the selected grade and subject
  Future<void> _assignHomeworkToSubject() async {
    final task = homeworkController.text.trim();
    if (task.isEmpty || selectedGrade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter homework and select grade')),
      );
      return;
    }

    try {
      // Get students who match the selected grade and subject
      final studentsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('grade', isEqualTo: selectedGrade)
              .where('subjects', arrayContains: teacherSubject)
              .get();

      final batch = FirebaseFirestore.instance.batch();

      for (var doc in studentsSnapshot.docs) {
        final studentNumber = doc['studentNumber'];

        // Create homework document for each student
        final newHomeworkRef =
            FirebaseFirestore.instance.collection('homework').doc();
        batch.set(newHomeworkRef, {
          'subject': teacherSubject, // Assign based on the subject
          'task': task,
          'assignedAt': Timestamp.now(),
          'teacherId': FirebaseAuth.instance.currentUser?.uid,
          'grade': selectedGrade,
        });
      }

      // Commit all homework assignments in batch
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Homework assigned to all students successfully!'),
        ),
      );

      // Clear input fields after assignment
      homeworkController.clear();
      setState(() {
        selectedGrade = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Schedule Homework',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF3B03AC),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          teacherSubject == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: homeworkController,
                        decoration: const InputDecoration(
                          labelText: 'Enter Homework Task',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: selectedGrade,
                        hint: const Text('Select Grade'),
                        items:
                            availableGrades.map((grade) {
                              return DropdownMenuItem(
                                value: grade,
                                child: Text(grade),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedGrade = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Grade',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed:
                            _assignHomeworkToSubject, // Updated function name
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B03AC),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 15,
                          ),
                        ),
                        child: const Text(
                          'Assign Homework',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
