import 'package:flutter/material.dart';

class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Safety"),
      ),
      body: const Center(
        child: Text(
          "Safety tip",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}