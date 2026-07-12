import 'package:flutter/material.dart';

import 'app_colors.dart';

class SafetyTipsScreen extends StatelessWidget {
  const SafetyTipsScreen({super.key});

  static final List<_TipCategory> _categories = [
    _TipCategory(
      icon: Icons.directions_walk_rounded,
      title: "Walking Alone",
      tips: const [
        "Stay in well-lit, populated areas whenever possible.",
        "Walk facing traffic so you can see approaching vehicles.",
        "Keep one earbud out so you can stay aware of your surroundings.",
        "Share your live location with a trusted contact before you set off.",
        "Trust your instincts — if a place or person feels wrong, leave.",
      ],
    ),
    _TipCategory(
      icon: Icons.directions_bus_filled_rounded,
      title: "Public Transport",
      tips: const [
        "Sit near the driver or in a carriage with other passengers.",
        "Keep your bag in front of you, not on your back.",
        "Have your keys and phone ready before you reach your stop.",
        "Avoid displaying valuables like jewelry or expensive electronics.",
        "Note the vehicle number or plate when using a taxi or rideshare.",
      ],
    ),
    _TipCategory(
      icon: Icons.home_rounded,
      title: "Home Safety",
      tips: const [
        "Always verify who's at the door before opening it.",
        "Keep doors and windows locked, even when you're home.",
        "Don't announce on social media that you're home alone.",
        "Know your neighbours — a familiar face nearby is a safety net.",
        "Keep emergency numbers saved and easy to reach.",
      ],
    ),
    _TipCategory(
      icon: Icons.smartphone_rounded,
      title: "Digital Safety",
      tips: const [
        "Avoid sharing your live location publicly on social media.",
        "Use strong, unique passwords and enable two-factor authentication.",
        "Be cautious about meeting someone you only know online.",
        "Turn off location metadata on photos before posting them.",
        "Block and report anyone who makes you uncomfortable online.",
      ],
    ),
    _TipCategory(
      icon: Icons.emergency_rounded,
      title: "In an Emergency",
      tips: const [
        "Use the SOS feature in this app to alert your emergency contacts instantly.",
        "Call out loudly for help — drawing attention often deters an attacker.",
        "Head toward the nearest populated, well-lit space.",
        "If you can, call local emergency services as soon as it's safe to do so.",
        "After the incident, note down details while they're fresh — time, place, description.",
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Safety Tips",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ---- Gradient header ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 90, 20, 26),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      "Simple habits that make a real difference. Tap a category to explore.",
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: _categories
                    .map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _CategoryCard(category: category),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TipCategory {
  final IconData icon;
  final String title;
  final List<String> tips;

  const _TipCategory({
    required this.icon,
    required this.title,
    required this.tips,
  });
}

class _CategoryCard extends StatelessWidget {
  final _TipCategory category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.textDark.withOpacity(0.4),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(category.icon, color: AppColors.primary, size: 22),
          ),
          title: Text(
            category.title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          subtitle: Text(
            "${category.tips.length} tips",
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textDark.withOpacity(0.5),
            ),
          ),
          children: category.tips
              .map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tip,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            color: AppColors.textDark.withOpacity(0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
