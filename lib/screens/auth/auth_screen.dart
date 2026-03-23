import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home/demo_explore_screen.dart';
import '../home/subscription_plans_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/brand_mark.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isSignUp) {
        await _authService.signUp(
          _emailController.text.trim(),
          _passwordController.text,
          _displayNameController.text.trim(),
        );
      } else {
        await _authService.signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message ?? 'Authentication failed';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An error occurred: $e';
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1016),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BrandMark(size: 84, showWordmark: true),
              const SizedBox(height: 12),
              Text(
                'Share, critique, sell, and collect with a studio-first social marketplace.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[400],
                      height: 1.45,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Display Name Field (Sign Up only)
              if (_isSignUp)
                TextField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    hintText: 'Display Name',
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              if (_isSignUp) const SizedBox(height: 16),

              // Email Field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Email',
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_errorMessage.isNotEmpty) const SizedBox(height: 16),

              // Auth Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isSignUp ? 'Sign Up' : 'Sign In',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Demo Mode Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionPlansScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart_checkout),
                  label: const Text('View Subscription Packages'),
                ),
              ),
              const SizedBox(height: 12),

              // Demo Mode Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const DemoExploreScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.travel_explore),
                  label: const Text('Continue in Demo Mode'),
                ),
              ),
              const SizedBox(height: 16),

              // Toggle Sign Up/Sign In
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUp
                        ? 'Already have an account? '
                        : 'Don\'t have an account? ',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        _errorMessage = '';
                      });
                    },
                    child: Text(
                      _isSignUp ? 'Sign In' : 'Sign Up',
                      style: const TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
