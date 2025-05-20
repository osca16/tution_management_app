import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tution_management_app/constants/colors.dart';
import 'package:tution_management_app/pages/student_dashboard.dart';
import 'package:tution_management_app/pages/teacher_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? selectedUserType;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey _studentKey = GlobalKey();
  final GlobalKey _teacherKey = GlobalKey();
  double _indicatorPosition = 0;
  bool _isLoading = false;

  void _updateIndicatorPosition(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox =
          key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final position = renderBox.localToGlobal(Offset.zero);
      setState(() {
        _indicatorPosition = position.dx + renderBox.size.width / 2 - 25;
      });
    });
  }

  Future<void> _loginUser() async {
    if (selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select user type (Student/Teacher)'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Authenticate with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      User? user = userCredential.user;
      if (user == null) return;

      // Determine collection based on user type
      final collectionName =
          selectedUserType!.toLowerCase() == 'teacher' ? 'teachers' : 'users';

      // Check existence
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection(collectionName)
              .doc(user.uid)
              .get();

      if (!userDoc.exists) {
        throw Exception('User not found in $collectionName collection');
      }

      final role = userDoc.get('role')?.toString().toLowerCase() ?? '';
      if (role != selectedUserType!.toLowerCase()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account is registered as $role, not $selectedUserType',
            ),
          ),
        );
        return;
      }

      if (role == 'admin') {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin login not allowed through this portal'),
          ),
        );
        return;
      }

      // Navigate to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  role == 'student'
                      ? StudentDashboard()
                      : const TeacherDashboard(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student/Teacher Login'),
        backgroundColor: sbtnColor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 60,
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              left: _indicatorPosition,
                              child: Image.asset(
                                "images/students.png",
                                width: 50,
                                height: 50,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        const Icon(Icons.person, size: 50),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildUserTypeButton('Student', _studentKey),
                          _buildUserTypeButton('Teacher', _teacherKey),
                        ],
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _loginUser,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: sbtnColor,
                        ),
                        child:
                            _isLoading
                                ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                : const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserTypeButton(String type, GlobalKey key) {
    final isSelected = selectedUserType == type;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      key: key,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedUserType = type;
            _updateIndicatorPosition(key);
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? sbtnColor : pbtnColor,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 30 : 40,
            vertical: 20,
          ),
          minimumSize: Size(isMobile ? 120 : 150, 60),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(type),
      ),
    );
  }
}
