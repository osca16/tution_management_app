import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tution_management_app/pages/login_page.dart';
import 'package:tution_management_app/pages/students.dart';
import 'package:tution_management_app/pages/teacher_profile.dart';
import 'view_schedule.dart';
import 'class_schedule.dart';
import 'homework_schedule.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => TeacherDashboardState();
}

class TeacherDashboardState extends State<TeacherDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String firstName = "";
  String lastName = "";
  String subject = "";
  String feePerSubject = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTeacherData();
  }

  Future<void> _fetchTeacherData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final teacherDoc =
            await FirebaseFirestore.instance
                .collection('teachers')
                .doc(user.uid)
                .get();

        if (teacherDoc.exists) {
          setState(() {
            firstName = teacherDoc.data()?['firstName'] ?? '';
            lastName = teacherDoc.data()?['lastName'] ?? '';
            subject = teacherDoc.data()?['subject'] ?? '';
            feePerSubject =
                teacherDoc.data()?['feePerSubject']?.toString() ?? '';
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching teacher data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _logoutUser() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  void _navigateToScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  Drawer _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF3B03AC),
      child: Column(
        children: [
          Container(
            height: 80,
            decoration: const BoxDecoration(color: Color(0xFF3B03AC)),
            child: const Padding(
              padding: EdgeInsets.only(left: 20.0, top: 15.0, bottom: 15.0),
              child: Row(
                children: [Icon(Icons.menu, color: Colors.white, size: 24)],
              ),
            ),
          ),
          _buildDrawerItem(
            "Profile",
            icon: Icons.person,
            onPressed: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 200), () {
                _navigateToScreen(
                  TeacherProfilePage(
                    firstName: firstName,
                    lastName: lastName,
                    subject: subject,
                    feePerSubject: feePerSubject,
                    onProfileUpdated: (
                      updatedFirstName,
                      updatedLastName,
                      updatedSubject,
                      updatedFee,
                    ) {
                      _updateTeacherProfile(
                        updatedFirstName,
                        updatedLastName,
                        updatedSubject,
                        updatedFee,
                      );
                    },
                  ),
                );
              });
            },
          ),
          _buildDrawerItem(
            "Students",
            icon: Icons.people,
            onPressed: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 200), () {
                _navigateToScreen(const StudentListScreen());
              });
            },
          ),
          const Spacer(),
          _buildDrawerItem(
            "Log Out",
            icon: Icons.logout,
            onPressed: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 300), () {
                _logoutUser();
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateTeacherProfile(
    String updatedFirstName,
    String updatedLastName,
    String updatedSubject,
    String updatedFee,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(user.uid)
            .update({
              'firstName': updatedFirstName,
              'lastName': updatedLastName,
              'subject': updatedSubject,
              'feePerSubject': updatedFee,
            });
        setState(() {
          firstName = updatedFirstName;
          lastName = updatedLastName;
          subject = updatedSubject;
          feePerSubject = updatedFee;
        });
      }
    } catch (e) {
      print('Error updating teacher profile: $e');
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF3B03AC),
      elevation: 5,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
    );
  }

  Widget _buildMainContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (firstName.isEmpty && lastName.isEmpty) {
      return const Center(
        child: Text('No Profile Found.', style: TextStyle(fontSize: 18)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildGreetingCard(),
            const SizedBox(height: 20),
            _buildButton(
              "Mark Attendance",
              Icons.check_box,
              const Color(0xFF3A3A3A),
              onPressed: () => _navigateToAttendance(),
            ),
            _buildButton(
              "Schedule Class",
              Icons.calendar_today,
              const Color(0xFF3A3A3A),
              onPressed: () => _navigateToClassSchedule(),
            ),
            _buildButton(
              "Schedule Homework",
              Icons.assignment,
              const Color(0xFF3A3A3A),
              onPressed: () => _navigateToHomework(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingCard() {
    String greeting = _getGreetingMessage();
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        child: Text(
          "$greeting $firstName $lastName!",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  String _getGreetingMessage() {
    int hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  void _navigateToAttendance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ScheduledClassesPage(selectedDate: DateTime.now()),
      ),
    );
  }

  void _navigateToClassSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClassSchedule()),
    );
  }

  void _navigateToHomework() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomeworkSchedule()),
    );
  }

  Widget _buildDrawerItem(
    String title, {
    IconData? icon,
    VoidCallback? onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF3B03AC),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: icon != null ? Icon(icon, color: Colors.white) : null,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onPressed,
      ),
    );
  }

  Widget _buildButton(
    String text,
    IconData icon,
    Color color, {
    VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 40.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
        ),
        icon: Icon(icon, color: Colors.white, size: 28),
        label: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildMainContent(),
    );
  }
}
