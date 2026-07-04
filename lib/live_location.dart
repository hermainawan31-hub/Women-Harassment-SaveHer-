import 'package:flutter/material.dart';

class LiveLocation extends StatelessWidget {
  const LiveLocation ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Location"),
      ),
      body: const Center(
        child: Text(
          "Live location",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}