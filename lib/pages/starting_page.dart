import 'package:flutter/material.dart';
import 'package:tution_management_app/constants/colors.dart';
import 'package:tution_management_app/pages/login_page.dart';

class StartingPage extends StatelessWidget {
  const StartingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  'Welcome!',
                  style: TextStyle(
                    fontSize: 32,
                    color: pTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sbtnColor,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      textStyle: TextStyle(fontSize: 20,),
                    ),
                    child: Text('Get Started',
                    style: TextStyle(
                      color: pbtnColor,
                    ),),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}