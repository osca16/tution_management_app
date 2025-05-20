import 'package:flutter/material.dart';

class TeacherProfilePage extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String subject;
  final String feePerSubject;
  final Function(String, String, String, String) onProfileUpdated;

  const TeacherProfilePage({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.subject,
    required this.feePerSubject,
    required this.onProfileUpdated,
  });

  @override
  State<TeacherProfilePage> createState() => _TeacherProfilePageState();
}

class _TeacherProfilePageState extends State<TeacherProfilePage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _subjectController;
  late TextEditingController _feeController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.firstName);
    _lastNameController = TextEditingController(text: widget.lastName);
    _subjectController = TextEditingController(text: widget.subject);
    _feeController = TextEditingController(text: widget.feePerSubject);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _subjectController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  void _submitChanges() {
    widget.onProfileUpdated(
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
      _subjectController.text.trim(),
      _feeController.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Profile'),
        backgroundColor: const Color(0xFF3B03AC),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField("First Name", _firstNameController),
            _buildTextField("Last Name", _lastNameController),
            _buildTextField("Subject", _subjectController),
            _buildTextField("Fee per Subject", _feeController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B03AC),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
              child: const Text('Save Changes', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
