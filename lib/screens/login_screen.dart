import 'package:flutter/material.dart';
import '../widgets/animated_fade_slide.dart';
import 'main_page.dart';
import 'register_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool isLoading = false;
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    Future<void> _login(BuildContext context, VoidCallback onLoading) async {
      onLoading();
      final error = await AuthService.signIn(
        emailController.text,
        passwordController.text,
      );
      if (error == null) {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainPage()),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Login failed: $error',
                style: const TextStyle(fontSize: 14),
              ),
              duration: const Duration(milliseconds: 1500),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: Colors.grey[900],
              elevation: 6,
            ),
          );
        }
      }
      if (context.mounted) {
        onLoading();
      }
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 200),
                    child: Text('Welcome Back', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
                  ),
                  const SizedBox(height: 8),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 300),
                    child: Text('Sign in to continue your adventure', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                  ),
                  const SizedBox(height: 48),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 400),
                    child: TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 500),
                    child: TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                      obscureText: true,
                    ),
                  ),
                  const SizedBox(height: 40),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 600),
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: () => _login(context, () => setState(() => isLoading = !isLoading)),
                            child: const Text('Login'),
                          ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedFadeSlide(
                    delay: const Duration(milliseconds: 700),
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                          children: [
                            TextSpan(
                              text: 'Register',
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}