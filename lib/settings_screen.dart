import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_colors.dart';
import 'LoginPage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Local preference toggles (UI only — wire to Firestore/shared_preferences
  // later if you want these to actually persist and take effect).
  bool notificationsEnabled = true;
  bool locationSharingEnabled = true;
  bool sosSoundEnabled = true;

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _changePassword() async {
    final user = _auth.currentUser;
    if (user?.email == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Reset Password"),
        content: Text("Send a password reset link to ${user!.email}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Send"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _auth.sendPasswordResetEmail(email: user!.email!);
      _showSnackBar("Password reset link sent to ${user.email}");
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Couldn't send reset email");
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Log out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Log out"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // ---------------- SECTION HEADER ----------------
  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: AppColors.textDark.withOpacity(0.45),
        ),
      ),
    );
  }

  // ---------------- CARD CONTAINER FOR A GROUP OF ROWS ----------------
  Widget _groupCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    indent: 60,
    color: AppColors.textDark.withOpacity(0.06),
  );

  // ---------------- TAPPABLE ROW ----------------
  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor ?? AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textDark.withOpacity(0.5),
              ),
            )
          : null,
      trailing:
          trailing ??
          (onTap != null
              ? Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textDark.withOpacity(0.3),
                )
              : null),
    );
  }

  // ---------------- TOGGLE ROW ----------------
  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _tile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        activeThumbColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Settings",
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
            // ---- Gradient header with account summary ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 90, 20, 28),
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
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "App Settings",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          user?.email ?? "Manage your account & preferences",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel("Account"),
                  _groupCard([
                    _tile(
                      icon: Icons.lock_outline_rounded,
                      title: "Change Password",
                      subtitle: "Send yourself a reset link",
                      onTap: _changePassword,
                    ),
                  ]),

                  _sectionLabel("Safety & Privacy"),
                  _groupCard([
                    _toggleTile(
                      icon: Icons.location_on_outlined,
                      title: "Location Sharing",
                      subtitle: "Share live location during alerts",
                      value: locationSharingEnabled,
                      onChanged: (v) =>
                          setState(() => locationSharingEnabled = v),
                    ),
                    _divider(),
                    _toggleTile(
                      icon: Icons.volume_up_outlined,
                      title: "SOS Sound Alert",
                      subtitle: "Play a loud siren on SOS trigger",
                      value: sosSoundEnabled,
                      onChanged: (v) => setState(() => sosSoundEnabled = v),
                    ),
                  ]),

                  _sectionLabel("Preferences"),
                  _groupCard([
                    _toggleTile(
                      icon: Icons.notifications_none_rounded,
                      title: "Notifications",
                      subtitle: "Alerts, reminders & updates",
                      value: notificationsEnabled,
                      onChanged: (v) =>
                          setState(() => notificationsEnabled = v),
                    ),
                  ]),

                  _sectionLabel("Support"),
                  _groupCard([
                    _tile(
                      icon: Icons.help_outline_rounded,
                      title: "Help & Support",
                      onTap: () => _showSnackBar("Support coming soon"),
                    ),
                    _divider(),
                    _tile(
                      icon: Icons.privacy_tip_outlined,
                      title: "Privacy Policy",
                      onTap: () => _showSnackBar("Privacy policy coming soon"),
                    ),
                  ]),

                  _sectionLabel("Account Actions"),
                  _groupCard([
                    _tile(
                      icon: Icons.logout_rounded,
                      iconColor: Colors.redAccent,
                      title: "Log out",
                      onTap: _logout,
                    ),
                  ]),

                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      "SafeHer v1.0.0",
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textDark.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
