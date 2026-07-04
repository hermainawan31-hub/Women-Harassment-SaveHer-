import 'package:flutter/material.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency "),
      ),
      body: const Center(
        child: Text(
          "Emergency contact screen",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}