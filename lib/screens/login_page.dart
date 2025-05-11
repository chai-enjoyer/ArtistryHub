import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as local_auth_provider;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  String? _pendingEmail;
  AuthCredential? _pendingCredential;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<local_auth_provider.AuthProvider>(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome Back',
                    style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                    ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 12),
                  OutlinedButton(
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
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: theme.dividerColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text('or', style: theme.textTheme.bodyMedium),
                      ),
                      Expanded(child: Divider(color: theme.dividerColor)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.g_mobiledata),
                    label: const Text('Sign in with Google'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                      elevation: 0,
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
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
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.code),
                    label: const Text('Sign in with GitHub'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                      elevation: 0,
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        await authProvider.signInWithGitHub();
                        Navigator.pushReplacementNamed(context, '/');
                      } on FirebaseAuthException catch (e) {
                        if (e.code == 'account-exists-with-different-credential') {
                          setState(() {
                            _errorMessage = e.message;
                            _pendingEmail = e.email;
                            _pendingCredential = e.credential;
                          });
                        } else {
                          setState(() {
                            _errorMessage = e.toString();
                          });
                        }
                      } catch (e) {
                        setState(() {
                          _errorMessage = e.toString();
                        });
                      }
                    },
                  ),
                  if (_pendingCredential != null && _pendingEmail != null)
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'To link your GitHub account, sign in with your existing provider for $_pendingEmail.',
                          style: const TextStyle(color: Colors.orange),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.g_mobiledata),
                          label: const Text('Sign in with Google to link'),
                          onPressed: () async {
                            try {
                              await authProvider.signInWithGoogle();
                              final user = authProvider.user;
                              if (user != null && _pendingCredential != null) {
                                await user.linkWithCredential(_pendingCredential!);
                                setState(() {
                                  _pendingCredential = null;
                                  _pendingEmail = null;
                                  _errorMessage = null;
                                });
                                Navigator.pushReplacementNamed(context, '/');
                              }
                            } catch (e) {
                              setState(() {
                                _errorMessage = 'Failed to link account: \\${e.toString()}';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}