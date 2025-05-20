import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tution_management_app/constants/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const StudentManagementApp());
}

class StudentManagementApp extends StatelessWidget {
  const StudentManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        cardTheme: CardTheme(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        ),
      ),
      home: const StudentListScreen(),
    );
  }
}

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  _StudentListScreenState createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  String _selectedGrade = 'All';

  String _getFullName(Map<String, dynamic> data) {
    return '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: sbtnColor,
        title: const Text('Students'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          const Divider(height: 1),
          Expanded(child: _buildStudentList()),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search by Student Number or Name',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.search),
            ),
            onChanged:
                (value) => setState(() => _searchQuery = value.toLowerCase()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedGrade,
            decoration: const InputDecoration(
              labelText: 'Filter by Grade',
              border: OutlineInputBorder(),
            ),
            items:
                [
                      'All',
                      'Grade 6',
                      'Grade 7',
                      'Grade 8',
                      'Grade 9',
                      'Grade 10',
                      'Grade 11',
                      'Grade 12',
                      'Grade 13',
                    ]
                    .map(
                      (grade) =>
                          DropdownMenuItem(value: grade, child: Text(grade)),
                    )
                    .toList(),
            onChanged: (value) => setState(() => _selectedGrade = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          _firestore
              .collection('users')
              .where('role', isEqualTo: 'student')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No students found'));
        }

        final students =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final fullName = _getFullName(data).toLowerCase();
              final studentNumber = data['studentNumber']?.toString() ?? '';
              final matchesSearch =
                  fullName.contains(_searchQuery) ||
                  studentNumber.toLowerCase().contains(_searchQuery);
              final matchesGrade =
                  _selectedGrade == 'All' || data['grade'] == _selectedGrade;
              return matchesSearch && matchesGrade;
            }).toList();

        if (students.isEmpty) {
          return const Center(child: Text('No students match your criteria'));
        }

        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            final studentData = student.data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(_getFullName(studentData)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studentData['studentNumber']?.toString() ??
                          'No Student Number',
                    ),
                    Text('Grade: ${studentData['grade'] ?? 'N/A'}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => _showStudentDetails(student.id, studentData),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showStudentDetails(String studentId, Map<String, dynamic> studentData) {
    String? localSelectedSubject;
    final subjects = List<String>.from(studentData['subjects'] ?? []);

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Student Details'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Name: ${_getFullName(studentData)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Student Number: ${studentData['studentNumber']?.toString() ?? 'N/A'}',
                      ),
                      const SizedBox(height: 8),
                      Text('Grade: ${studentData['grade'] ?? 'N/A'}'),
                      const SizedBox(height: 16),
                      const Text(
                        'Subjects:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...subjects.map((subject) => Text('- $subject')),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: localSelectedSubject,
                              decoration: const InputDecoration(
                                labelText: 'Add Subject',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  ['Math', 'Science', 'History', 'English']
                                      .map(
                                        (subject) => DropdownMenuItem(
                                          value: subject,
                                          child: Text(subject),
                                        ),
                                      )
                                      .toList(),
                              onChanged:
                                  (value) => setState(
                                    () => localSelectedSubject = value,
                                  ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () async {
                              if (localSelectedSubject != null &&
                                  !subjects.contains(localSelectedSubject)) {
                                await _firestore
                                    .collection('users')
                                    .doc(studentId)
                                    .update({
                                      'subjects': FieldValue.arrayUnion([
                                        localSelectedSubject!,
                                      ]),
                                    });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Subject added successfully'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              );
            },
          ),
    );
  }
}
