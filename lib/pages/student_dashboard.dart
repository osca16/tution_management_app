import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tution_management_app/constants/colors.dart';
import 'package:tution_management_app/pages/login_page.dart';
import 'student_profile.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? studentId;
  String? studentEmail;
  String? studentGrade;
  List<dynamic> studentSubjects = [];

  @override
  void initState() {
    super.initState();
    fetchStudentDetails();
  }

  Future<void> fetchStudentDetails() async {
    User? user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          studentId = user.uid;
          studentEmail = doc['email'];
          studentGrade = doc['grade'];
          studentSubjects = doc['subjects'] ?? [];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: sbtnColor,
        elevation: 5,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body:
          studentId == null
              ? Center(child: CircularProgressIndicator())
              : _buildDashboardContent(context),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: sbtnColor,
      child: Column(
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(color: Color(0xFF3B03AC)),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20.0,
                top: 15.0,
                bottom: 15.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.menu, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
          _buildDrawerItem("Profile", icon: Icons.person),
          Spacer(),
          _buildDrawerItem("Log Out", icon: Icons.logout),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(String title, {IconData? icon}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Color(0xFF3B03AC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: icon != null ? Icon(icon, color: Colors.white) : null,
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () async {
          Navigator.pop(context);

          if (title == "Profile") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        StudentProfilePage(studentEmail: studentEmail!),
              ),
            );
          } else if (title == "Log Out") {
            bool confirm = await _showLogoutConfirmationDialog();
            if (confirm) {
              await _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            }
          }
        },
      ),
    );
  }

  Future<bool> _showLogoutConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Confirm Logout'),
                content: Text('Are you sure you want to log out?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Logout', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
        ) ??
        false;
  }

  Widget _buildDashboardContent(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            _buildAttendanceCard(),
            SizedBox(height: 20),
            _buildHomeworkCard(),
            SizedBox(height: 20),
            _buildPaymentHistoryCard(),
            SizedBox(height: 20),
            _buildUpcomingClassesCard(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return FutureBuilder<QuerySnapshot>(
      future:
          _firestore
              .collection('attendance')
              .where('studentId', isEqualTo: studentId)
              .where('present', isEqualTo: true)
              .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        int presentDays = snapshot.data!.docs.length;
        return _buildCard(
          title: 'Attendance',
          subtitle: 'Present Days: $presentDays',
          icon: Icons.person_outline,
          color: Color(0xFFE685E6),
          context: context,
        );
      },
    );
  }

  Widget _buildHomeworkCard() {
    return FutureBuilder<QuerySnapshot>(
      future:
          _firestore
              .collection('homework')
              .where('subject', whereIn: studentSubjects)
              .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        List<String> homeworkList = [];
        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          String task = data['task'] ?? 'No task available';
          String subject = data['subject'] ?? 'No subject';
          homeworkList.add('$subject - $task');
        }

        return _buildCard(
          title: 'Assigned Homework',
          subtitle:
              homeworkList.isEmpty
                  ? 'No homework assigned'
                  : homeworkList.join('\n'),
          icon: Icons.assignment,
          color: Color(0xFF90EE90),
          context: context,
        );
      },
    );
  }

  Widget _buildPaymentHistoryCard() {
    return FutureBuilder<QuerySnapshot>(
      future:
          _firestore
              .collection('payments')
              .where('studentEmail', isEqualTo: studentEmail)
              .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        double totalPaid = 0;
        String monthPaid = "";
        String lastPaymentDate = 'No payment yet';
        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'completed') {
            totalPaid += data['amount'];
            monthPaid = data['month'] ?? '';
            Timestamp? createdAt = data['createdAt'];
            if (createdAt != null) {
              DateTime date = createdAt.toDate();
              lastPaymentDate = DateFormat(
                'yyyy-MM-dd \n  HH:mm:ss',
              ).format(date); // formatted nicely
            }
          }
        }
        return _buildCard(
          title: 'Payment History',
          subtitle:
              'Total Paid: Rs. ${totalPaid.toStringAsFixed(2)}\nLast Payment: $lastPaymentDate\nPaid Month: $monthPaid',
          icon: Icons.payment,
          color: Color(0xFF8787F2),
          context: context,
        );
      },
    );
  }

  Widget _buildUpcomingClassesCard() {
    if (studentSubjects.isEmpty || studentGrade == null) {
      return _buildCard(
        title: 'Upcoming Classes',
        subtitle: 'No subjects registered yet.',
        icon: Icons.schedule,
        color: Color(0xFFFFC300),
        context: context,
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future:
          _firestore
              .collection('classSchedules')
              .where('grade', isEqualTo: studentGrade)
              .where('subject', whereIn: studentSubjects)
              .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return _buildCard(
            title: 'Upcoming Classes',
            subtitle: 'Something went wrong!',
            icon: Icons.error,
            color: Color(0xFFFFC300),
            context: context,
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildCard(
            title: 'Upcoming Classes',
            subtitle: 'No upcoming classes available.',
            icon: Icons.schedule,
            color: Color(0xFFFFC300),
            context: context,
          );
        }

        List<String> upcomingClasses = [];
        DateTime now = DateTime.now();

        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          DateTime classDate = (data['dateTime'] as Timestamp).toDate();

          if (classDate.isAfter(now)) {
            String subject = data['subject'] ?? '';
            String description = data['description'] ?? 'No description';
            String formattedDate = DateFormat(
              'yyyy-MM-dd \n  hh:mm a',
            ).format(classDate);
            upcomingClasses.add('$subject on $formattedDate\n$description');
          }
        }

        if (upcomingClasses.isEmpty) {
          return _buildCard(
            title: 'Upcoming Classes',
            subtitle: 'No upcoming classes available.',
            icon: Icons.schedule,
            color: Color(0xFFFFC300),
            context: context,
          );
        }

        return _buildCard(
          title: 'Upcoming Classes',
          subtitle: upcomingClasses.join('\n\n'),
          icon: Icons.schedule,
          color: Color(0xFFFFC300),
          context: context,
        );
      },
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required BuildContext context,
  }) {
    double width = MediaQuery.of(context).size.width;
    double cardWidth = width < 400 ? width - 40 : 320;

    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 30),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(subtitle, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
