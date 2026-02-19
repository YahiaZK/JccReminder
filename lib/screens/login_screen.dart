import 'package:flutter/material.dart';
import 'package:jcc_reminder/screens/signup_screen.dart';
import 'package:jcc_reminder/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jcc_reminder/screens/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _onLoginSuccess() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _onLoginError(String message) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _signInWithEmail() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      _onLoginSuccess();
    } on FirebaseAuthException catch (e) {
      debugPrint("Login Error: ${e.code}");
      _onLoginError('Failed to sign in. Please check your credentials.');
    } catch (e) {
      debugPrint("Generic Login Error: $e");
      _onLoginError('An unexpected error occurred.');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final userCredential = await _authService.signInWithGoogle();
      if (userCredential != null) {
        _onLoginSuccess();
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Google Sign In Error: $e");
      _onLoginError('Could not sign in with Google. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log In")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                icon: Image.asset(
                  'lib/assets/google.png',
                  height: 24,
                  width: 24,
                ),
                label: const Text('Sign in with Google'),
                onPressed: _isLoading ? null : _signInWithGoogle,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('OR', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          v!.isEmpty ? 'Please enter an email' : null,
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
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _signInWithEmail,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('LOG IN WITH EMAIL'),
              ),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignUpScreen(),
                          ),
                        );
                      },
                child: const Text("Don't have an account? Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
