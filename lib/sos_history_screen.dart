import 'package:flutter/material.dart';

class SosHistoryScreen extends StatelessWidget {
  const SosHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
      ),
      body: const Center(
        child: Text(
          "History Screen",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}