import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/auth/login_screen.dart';
import 'package:in_app_purchase/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child:
            CircularProgressIndicator(), // Show loading indicator while checking authentication state
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    checkAuthState();
  }

  void checkAuthState() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    await Future.delayed(const Duration(
        seconds: 2)); // Simulate a delay for demonstration purposes
    if (auth.currentUser != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => InApp(
                  user: auth.currentUser!,
                )),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
    }
  }
}
