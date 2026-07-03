import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auth App',
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.blue),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<LoginPage> {
  bool isSignIn = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. The main container that handles the full-screen background image
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/images/background.jpg',
            ), // Path with correct forward slashes
            fit: BoxFit.cover,
            // The ColorFilter tints the image darker by 45% so text becomes instantly readable
            colorFilter: ColorFilter.mode(Colors.black45, BlendMode.darken),
          ),
        ),

        // 2. The centered interactive form layer sitting cleanly on top
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 400,
                ), // Limits width on desktop/web screens
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Heading Title (White color pops against the dark image filter)
                    Text(
                      isSignIn ? 'Welcome Back' : 'Create Account',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 8.0,
                            color: Colors.black38,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Email Input Box
                    TextField(
                      style: const TextStyle(
                        color: Colors.white,
                      ), // Changes typing color to white
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(
                          color: Colors.white70,
                        ), // Changes label text to light gray/white
                        hintText: 'yourname@example.com',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(
                          Icons.email,
                          color: Colors.white70,
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white60,
                          ), // Input border when inactive
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white,
                            width: 2.0,
                          ), // Input border when active
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password Input Box
                    TextField(
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'Enter your password',
                        hintStyle: const TextStyle(color: Colors.white38),
                        prefixIcon: const Icon(
                          Icons.lock,
                          color: Colors.white70,
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white60),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 35),

                    // Submit Button
                    ElevatedButton(
                      onPressed: () {
                        if (isSignIn) {
                          print('Performing Sign In logic...');
                        } else {
                          print('Performing Sign Up/Registration logic...');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor:
                            Colors.white, // High contrast button color
                        foregroundColor:
                            Colors.blueAccent, // Color of button text
                      ),
                      child: Text(
                        isSignIn ? 'Sign In' : 'Sign Up',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Toggle Link Button
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isSignIn = !isSignIn;
                        });
                      },
                      child: Text(
                        isSignIn
                            ? "Don't have an account? Sign up"
                            : "Already have an account? Sign in",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
