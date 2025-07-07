import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool termsAccepted = false;
  bool isLoading = false;

  void _register() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Please enter your name.",
            style: TextStyle(fontSize: 14),
          ),
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          backgroundColor: Colors.grey,
          elevation: 6,
        ),
      );
      return;
    }
    if (passwordController.text != confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Passwords do not match.",
            style: TextStyle(fontSize: 14),
          ),
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          backgroundColor: Colors.grey,
          elevation: 6,
        ),
      );
      return;
    }
    if (!termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Please accept the Terms and Conditions.",
            style: TextStyle(fontSize: 14),
          ),
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          backgroundColor: Colors.grey,
          elevation: 6,
        ),
      );
      return;
    }
    setState(() => isLoading = true);
    final error = await AuthService.register(
      emailController.text,
      passwordController.text,
    );
    if (error == null) {
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Registration failed: $error',
              style: const TextStyle(fontSize: 14),
            ),
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Colors.grey[900],
            elevation: 6,
          ),
        );
      }
    }
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), centerTitle: true, backgroundColor: Colors.transparent),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Join Us', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Create an account to start exploring', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 48),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline)), keyboardType: TextInputType.name),
              const SizedBox(height: 20),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)), obscureText: true),
              const SizedBox(height: 20),
              TextField(controller: confirmController, decoration: const InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_outline)), obscureText: true),
              const SizedBox(height: 20),
              Row(children: [
                Checkbox(
                  value: termsAccepted,
                  onChanged: (value) => setState(() => termsAccepted = value ?? false),
                  activeColor: theme.colorScheme.primary,
                ),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: 'I agree to the ',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                      children: [
                        TextSpan(
                          text: 'Terms and Conditions',
                          style: TextStyle(color: theme.colorScheme.tertiary, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Terms and Conditions"),
                                    content: const SingleChildScrollView(child: Text("Here are the terms...")),
                                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 30),
              isLoading ? const Center(child: CircularProgressIndicator()) : ElevatedButton(onPressed: _register, child: const Text('Register')),
            ],
          ),
        ),
      ),
    );
  }
}