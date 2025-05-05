import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await authProvider.signInWithEmail(
                    _emailController.text,
                    _passwordController.text,
                  );
                  Navigator.pushReplacementNamed(context, '/');
                } catch (e) {
                  setState(() {
                    _errorMessage = e.toString();
                  });
                }
              },
              child: const Text('Sign In'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await authProvider.signUpWithEmail(
                    _emailController.text,
                    _passwordController.text,
                  );
                  Navigator.pushReplacementNamed(context, '/');
                } catch (e) {
                  setState(() {
                    _errorMessage = e.toString();
                  });
                }
              },
              child: const Text('Sign Up'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.g_mobiledata),
              label: const Text('Sign in with Google'),
              onPressed: () async {
                try {
                  await authProvider.signInWithGoogle();
                  Navigator.pushReplacementNamed(context, '/');
                } catch (e) {
                  setState(() {
                    _errorMessage = e.toString();
                  });
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud),
              label: const Text('Sign in with Microsoft'),
              onPressed: () async {
                try {
                  await authProvider.signInWithMicrosoft(context);
                  Navigator.pushReplacementNamed(context, '/');
                } catch (e) {
                  setState(() {
                    _errorMessage = e.toString();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}