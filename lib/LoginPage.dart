import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isSignIn = true;
  bool isLoading = false;
  bool obscurePassword = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  // ---------------- FORGOT PASSWORD (UPDATED) ----------------
  Future<void> resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar("Please enter your email to reset password.");
      return;
    }

    setState(() => isLoading = true);
    try {
      await _auth.sendPasswordResetEmail(email: email);

      // Show confirmation dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Check your inbox"),
          content: Text("We sent a password reset link to $email."),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              onPressed: () {
                Navigator.of(ctx).pop();
                // Clear fields
                emailController.clear();
                passwordController.clear();
                // If the user is somehow already signed in, go to home
                if (_auth.currentUser != null) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                }
                // Otherwise stay on login page (snackbar already shown)
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Error sending reset email");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ---------------- SIGN UP ----------------
  Future<void> signUp() async {
    setState(() => isLoading = true);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      await userCredential.user!.sendEmailVerification();
      _showSnackBar("Verification email sent. Check your inbox.");
      setState(() => isSignIn = true); // Switch to login view
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Signup failed");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ---------------- SIGN IN ----------------
  Future<void> signIn() async {
    setState(() => isLoading = true);
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await userCredential.user!.reload();
      final user = _auth.currentUser;

      if (user != null && user.emailVerified) {
        // No manual navigation needed here — AuthGate in main.dart listens
        // to FirebaseAuth.authStateChanges() and will automatically swap
        // to HomeScreen the moment sign-in succeeds.
      } else {
        await _auth.signOut();
        _showSnackBar("Please verify your email first.");
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Login failed");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ---------------- REUSABLE INPUT FIELD ----------------
  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textDark, fontSize: 15),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.textDark.withOpacity(0.4)),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 21),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF4F1FB),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
    );
  }

  // ---------------- UI BUILDER ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryDark,
              AppColors.primary,
              AppColors.accent,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ---- Logo / brand mark ----
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_moon_rounded,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Safe Her",
                    style: TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSignIn
                        ? "Welcome back, stay safe."
                        : "Create your account",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ---- Card ----
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ---- Segmented Sign In / Sign Up toggle ----
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F1FB),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              _buildTab("Sign In", true),
                              _buildTab("Sign Up", false),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        _buildField(
                          controller: emailController,
                          hint: "Email",
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 14),

                        _buildField(
                          controller: passwordController,
                          hint: "Password",
                          icon: Icons.lock_outline,
                          obscure: obscurePassword,
                          suffix: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textDark.withOpacity(0.4),
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => obscurePassword = !obscurePassword,
                            ),
                          ),
                        ),

                        if (isSignIn)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: isLoading ? null : resetPassword,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                        SizedBox(height: isSignIn ? 10 : 22),

                        // ---- Action Button ----
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      if (emailController.text.isEmpty ||
                                          passwordController.text.isEmpty) {
                                        _showSnackBar(
                                          "Please fill out all fields",
                                        );
                                        return;
                                      }
                                      isSignIn ? signIn() : signUp();
                                    },
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      isSignIn ? "Sign In" : "Sign Up",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ---- Toggle text ----
                        GestureDetector(
                          onTap: () => setState(() => isSignIn = !isSignIn),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 13.5,
                                color: AppColors.textDark.withOpacity(0.65),
                              ),
                              children: [
                                TextSpan(
                                  text: isSignIn
                                      ? "Don't have an account?  "
                                      : "Already have an account?  ",
                                ),
                                TextSpan(
                                  text: isSignIn ? "Sign Up" : "Sign In",
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, bool tabIsSignIn) {
    final bool selected = isSignIn == tabIsSignIn;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => isSignIn = tabIsSignIn),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : AppColors.textDark.withOpacity(0.55),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
