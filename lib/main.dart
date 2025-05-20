import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tution_management_app/constants/colors.dart';
import 'package:tution_management_app/pages/starting_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCF7r_Bog41DioJjatm2I3cIYkuM7JdcJo",
      authDomain: "tution-class-management-app.firebaseapp.com",
      projectId: "tution-class-management-app",
      storageBucket:
          "tution-class-management-app.appspot.com", // Corrected `.app` to `.appspot.com`
      messagingSenderId: "456403472897",
      appId: "1:456403472897:web:f0cc4da27378214eb2a600",
      measurementId: "G-Y7JR8NG2GT",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tution Class Management App',
      theme: ThemeData(scaffoldBackgroundColor: bgColor),
      home: const StartingPage(),
    );
  }
}
