import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:tution_management_app/constants/colors.dart';
import 'package:tution_management_app/pages/attendence_mark.dart';

class ScheduledClassesPage extends StatelessWidget {
  final DateTime selectedDate;

  const ScheduledClassesPage({required this.selectedDate, super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentTeacherId = FirebaseAuth.instance.currentUser?.uid;

    if (currentTeacherId == null) {
      return Scaffold(
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: sbtnColor,
          title: const Text(
            'Scheduled Classes',
            style: TextStyle(color: Colors.white),
          ),
        ),
        body: const Center(child: Text('User not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: sbtnColor,
        title: const Text(
          'Scheduled Classes',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('classSchedules')
                .where('teacherId', isEqualTo: currentTeacherId)
                .orderBy('dateTime', descending: false)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No classes scheduled yet.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final schedule = docs[index].data() as Map<String, dynamic>;
              final DateTime classDateTime =
                  (schedule['dateTime'] as Timestamp).toDate();

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: ListTile(
                  title: Text(
                    'Grade ${schedule['grade']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule['description'] ?? 'No Description',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(classDateTime),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.access_time, size: 16),
                            const SizedBox(width: 4),
                            Text(DateFormat('hh:mm a').format(classDateTime)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteSchedule(context, docs[index].id),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AttendancePage(
                              scheduleId: docs[index].id,
                              scheduleData: schedule,
                            ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteSchedule(BuildContext context, String scheduleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Class'),
            content: const Text('Are you sure you want to delete this class?'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('classSchedules')
            .doc(scheduleId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting class: $e')));
      }
    }
  }
}
