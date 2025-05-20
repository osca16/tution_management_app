import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfilePage extends StatefulWidget {
  final String studentEmail;

  const StudentProfilePage({super.key, required this.studentEmail});

  @override
  _StudentProfilePageState createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  String _userId = '';
  Map<String, dynamic> _studentData = {
    'firstName': '',
    'lastName': '',
    'grade': '',
    'guardian': '',
    'school': '',
    'studentNumber': '',
  };

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _fetchStudentDetails();
  }

  Future<void> _fetchStudentDetails() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: widget.studentEmail)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        setState(() {
          _userId = doc.id;
          _studentData = doc.data();
          _firstNameController.text = _studentData['firstName'] ?? '';
          _lastNameController.text = _studentData['lastName'] ?? '';
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error fetching data: $e');
    }
  }

  Future<void> _submitChanges() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      _showErrorSnackbar('Please enter both first and last name');
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(_userId).update({
        'firstName': firstName,
        'lastName': lastName,
      });

      _showSuccessSnackbar('Profile updated successfully');
    } catch (e) {
      _showErrorSnackbar('Error updating data: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        backgroundColor: const Color(0xFF3B03AC),
      ),
      body: _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    if (_studentData['firstName'] == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildInfoCard('Personal Information', [
            _buildInfoRow(
              'Full Name',
              '${_studentData['firstName']} ${_studentData['lastName']}',
            ),
            _buildEditableNameFields(),
            _buildInfoRow('Student Number', _studentData['studentNumber']),
            _buildInfoRow('Grade', _studentData['grade']),
          ]),
          const SizedBox(height: 20),
          _buildInfoCard('School Information', [
            _buildInfoRow('School', _studentData['school']),
            _buildInfoRow('Guardian', _studentData['guardian']),
          ]),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B03AC),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            child: const Text(
              'Save Changes',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B03AC),
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not available',
              style: TextStyle(color: value.isEmpty ? Colors.grey : null),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableNameFields() {
    return Column(
      children: [
        const SizedBox(height: 10),
        TextField(
          controller: _firstNameController,
          decoration: const InputDecoration(
            labelText: 'First Name',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _lastNameController,
          decoration: const InputDecoration(
            labelText: 'Last Name',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
        ),
      ],
    );
  }
}
