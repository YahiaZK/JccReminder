import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jcc_reminder/screens/login_screen.dart';
import 'package:jcc_reminder/services/auth_service.dart';
import 'package:jcc_reminder/screens/dashboard_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _isLoading = true);
    try {
      final UserCredential? userCredential = await _authService
          .signUpWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

      if (userCredential?.user != null && mounted) {
        await userCredential!.user!.sendEmailVerification();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Verification email sent. Please check your inbox.',
              ),
            ),
          );
        }
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (Route<dynamic> route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Signup Error: ${e.toString()}");
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already in use. Please log in.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'The password is too weak.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.isEmpty ? 'Please enter an email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => v!.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('SIGN UP'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text("Already have an account? Log In"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
