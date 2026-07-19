import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'custom_app_bar.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> steps = [
      {
        'icon': Icons.person_outline,
        'title': 'Complete Your Profile',
        'desc': 'Add your name, phone, address, blood group, and gender so emergency contacts know who you are.',
      },
      {
        'icon': Icons.contact_emergency_outlined,
        'title': 'Add Emergency Contacts',
        'desc': 'Add at least three trusted contacts. They will receive your SOS alerts and location.',
      },
      {
        'icon': Icons.location_on_outlined,
        'title': 'Enable Live Location',
        'desc': 'Turn on location sharing so your contacts can see your real‑time location during an emergency.',
      },
      {
        'icon': Icons.sos_rounded,
        'title': 'Add Widget on Home',
        'desc': 'Long press on home screen of phone and add SafeHer widget and tap in alarming situation.',
      },
      {
        'icon': Icons.record_voice_over,
        'title': 'Audio Recording',
        'desc': 'When widget is activated, the app automatically records audio and send message. Tap "Stop Recording" to save it.',
      },
      {
        'icon': Icons.history_rounded,
        'title': 'View History',
        'desc': 'Check your past SOS events in the History section to track all alerts.',
      },
    ];

    return Scaffold(
      appBar: const CustomAppBar(title: 'How to Use SafeHer'),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final step = steps[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(step['icon'], color: AppColors.primary, size: 24),
              ),
              title: Text(
                step['title'],
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                step['desc'],
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        },
      ),
    );
  }
}