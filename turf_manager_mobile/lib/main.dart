import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const TurfManagerApp());
}

class TurfManagerApp extends StatelessWidget {
  const TurfManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Turf Manager',
      debugShowCheckedModeBanner: false,
      // Here is our new Red & Black Global Theme
      theme: ThemeData(
        brightness: Brightness.dark, // Automatically turns default text white
        scaffoldBackgroundColor: const Color(0xFF121212), // Deep modern black
        primaryColor: Colors.red,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.red, // Red text on the App Bar
          elevation: 0,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.red,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- THIS IS THE UPDATED SECTION ---
  Future<void> _handleLogin() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    // Use the exact IP address from your hotspot
    final url = Uri.parse('http://10.73.60.1:8000/login'); 

    try {
      // Sending the POST request to your Python backend
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      // Check if the backend gave us a thumbs up (Status 200 OK)
      if (response.statusCode == 200) {
        // Success! Push to the dashboard
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TurfDashboardScreen(),
            ),
          );
        }
      } else {
        // Show an error banner on the phone screen if login fails
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login Failed: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Catch network errors (like if the server isn't running)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network Error: Could not connect to server.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  // --- END OF UPDATED SECTION ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turf Manager', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.sports_soccer,
                size: 80,
                color: Colors.red, // Updated to Red
              ),
              const SizedBox(height: 20),
              const Text(
                'Player Login',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              
              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  labelStyle: const TextStyle(color: Colors.grey),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  prefixIcon: const Icon(Icons.email, color: Colors.red),
                ),
              ),
              const SizedBox(height: 20),
              
              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: Colors.grey),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  prefixIcon: const Icon(Icons.lock, color: Colors.red),
                ),
              ),
              const SizedBox(height: 40),
              
              // Login Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Updated to Red
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _handleLogin,
                child: const Text(
                  'LOGIN',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TurfDashboardScreen extends StatelessWidget {
  const TurfDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pitch Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_soccer, size: 100, color: Colors.red), // Updated to Red
            SizedBox(height: 20),
            Text(
              'Welcome to the Pitch!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Your weekend football match is confirmed.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}