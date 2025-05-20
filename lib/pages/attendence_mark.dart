import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tution_management_app/constants/colors.dart';

class AttendancePage extends StatefulWidget {
  final String scheduleId;
  final Map<String, dynamic> scheduleData;

  const AttendancePage({
    required this.scheduleId,
    required this.scheduleData,
    super.key,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  Map<String, bool> attendanceStatus = {};

  late String teacherId;
  late String subject;
  late String grade;

  @override
  void initState() {
    super.initState();
    teacherId = FirebaseAuth.instance.currentUser!.uid;
    subject =
        widget.scheduleData['description']; // Assuming description = subject
    grade = widget.scheduleData['grade'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: sbtnColor,
        title: Text('Mark Attendance'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .where('grade', isEqualTo: grade)
                .where('subjects', arrayContains: subject)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = snapshot.data!.docs;

          if (students.isEmpty) {
            return const Center(child: Text('No students found.'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final String studentId = student.id;
                    final String studentName =
                        '${student['firstName']} ${student['lastName']}';

                    return CheckboxListTile(
                      title: Text(studentName),
                      value: attendanceStatus[studentId] ?? false,
                      onChanged: (bool? value) {
                        setState(() {
                          attendanceStatus[studentId] = value ?? false;
                        });
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton(
                  onPressed: _submitAttendance,
                  child: const Text('Submit Attendance'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitAttendance() async {
    final batch = FirebaseFirestore.instance.batch();
    final now = DateTime.now();

    attendanceStatus.forEach((studentId, isPresent) {
      final docRef = FirebaseFirestore.instance.collection('attendance').doc();
      batch.set(docRef, {
        'classId': widget.scheduleId,
        'date': widget.scheduleData['dateTime'],
        'markedAt': now,
        'present': isPresent,
        'studentId': studentId,
        'subject': subject,
        'teacherId': teacherId,
      });
    });

    try {
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance submitted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting attendance: $e')),
      );
    }
  }
}
