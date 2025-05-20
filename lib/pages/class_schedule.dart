import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tution_management_app/constants/colors.dart';

class ClassSchedule extends StatefulWidget {
  const ClassSchedule({super.key});

  @override
  State<ClassSchedule> createState() => _ClassScheduleState();
}

class _ClassScheduleState extends State<ClassSchedule> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedGrade;
  List<String> _grades = [];
  bool _isLoadingGrades = true;

  @override
  void initState() {
    super.initState();
    _fetchGradesFromUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchGradesFromUsers() async {
    try {
      setState(() => _isLoadingGrades = true);
      final snapshot = await _firestore.collection('users').get();
      final grades = <String>{};

      for (var doc in snapshot.docs) {
        final grade = doc.data()['grade']?.toString();
        if (grade != null && grade.isNotEmpty) {
          grades.add(grade);
        }
      }

      setState(() {
        _grades = grades.toList()..sort((a, b) => a.compareTo(b));
        if (_grades.isEmpty) {
          _grades = [
            'Grade 1',
            'Grade 2',
            'Grade 3',
            'Grade 4',
            'Grade 5',
            'Grade 6',
          ];
        }
        _isLoadingGrades = false;
      });
    } catch (e) {
      print('Error fetching grades: $e');
      setState(() {
        _grades = [
          'Grade 1',
          'Grade 2',
          'Grade 3',
          'Grade 4',
          'Grade 5',
          'Grade 6',
        ];
        _isLoadingGrades = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submitSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null ||
        _selectedTime == null ||
        _selectedGrade == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      // ✅ Fetch subject from the teachers collection
      String subject = 'Unknown';
      final teacherSnapshot =
          await _firestore.collection('teachers').doc(user.uid).get();
      if (teacherSnapshot.exists) {
        subject = teacherSnapshot.data()?['subject'] ?? 'Unknown';
      }

      await _firestore.collection('classSchedules').add({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'dateTime': dateTime,
        'grade': _selectedGrade,
        'teacherId': user.uid,
        'teacherName': user.displayName ?? 'Teacher',
        'subject': subject, // ✅ subject added here
        'createdAt': FieldValue.serverTimestamp(),
      });

      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Class scheduled successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
      _selectedGrade = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Schedule Class',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: sbtnColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchGradesFromUsers,
            tooltip: 'Refresh Grades',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Class Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator:
                    (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator:
                    (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildGradeDropdown(),
              const SizedBox(height: 16),
              _buildDateTimeSelectors(),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.schedule),
                label: const Text('SCHEDULE CLASS'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF3B03AC),
                ),
                onPressed: _submitSchedule,
              ),
              const SizedBox(height: 24),
              const Divider(),
              const Text(
                'Upcoming Classes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildClassScheduleList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGradeDropdown() {
    return _isLoadingGrades
        ? const LinearProgressIndicator()
        : DropdownButtonFormField<String>(
          value: _selectedGrade,
          decoration: const InputDecoration(
            labelText: 'Select Grade',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.school),
          ),
          items:
              _grades
                  .map(
                    (grade) =>
                        DropdownMenuItem(value: grade, child: Text(grade)),
                  )
                  .toList(),
          onChanged: (value) => setState(() => _selectedGrade = value),
          validator: (value) => value == null ? 'Select a grade' : null,
        );
  }

  Widget _buildDateTimeSelectors() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _selectedDate == null
                  ? 'Select Date'
                  : DateFormat('MMM dd, yyyy').format(_selectedDate!),
            ),
            onPressed: () => _selectDate(context),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.access_time),
            label: Text(
              _selectedTime == null
                  ? 'Select Time'
                  : _selectedTime!.format(context),
            ),
            onPressed: () => _selectTime(context),
          ),
        ),
      ],
    );
  }

  Widget _buildClassScheduleList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('classSchedules')
              .where('teacherId', isEqualTo: _auth.currentUser?.uid)
              .orderBy('dateTime', descending: false)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _handleFirestoreError(snapshot.error!);
        if (!snapshot.hasData) return const CircularProgressIndicator();

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Text('No scheduled classes');

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final dateTime = (data['dateTime'] as Timestamp).toDate();

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                title: Text(
                  data['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['description']),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.school, size: 16),
                        const SizedBox(width: 4),
                        Text(data['grade']),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.menu_book, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          data['subject'] ?? 'Unknown Subject',
                        ), // 🆕 show subject
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 4),
                        Text(DateFormat('MMM dd, yyyy').format(dateTime)),
                        const SizedBox(width: 8),
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 4),
                        Text(DateFormat('hh:mm a').format(dateTime)),
                      ],
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteSchedule(docs[index].id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _handleFirestoreError(Object error) {
    final errorMessage = error.toString();
    if (errorMessage.contains('index')) {
      return Column(
        children: [
          const Text(
            'Firestore index is being created. This may take a few minutes.',
          ),
          TextButton(
            child: const Text('Retry'),
            onPressed: () => setState(() {}),
          ),
        ],
      );
    }
    return Text('Error: $errorMessage');
  }

  Future<void> _deleteSchedule(String scheduleId) async {
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
        await _firestore.collection('classSchedules').doc(scheduleId).delete();
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
