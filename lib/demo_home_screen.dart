import 'package:flutter/material.dart';

class DemoHomeScreen extends StatelessWidget {
  const DemoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(
        child: Text('You have already subscribed! a package'),
      ),
    );
  }
}
