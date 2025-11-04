import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/auth_provider.dart';
import 'signup.dart';
import 'widget/button.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool _obscureText = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  void _showForgotPasswordDialog() {
    final TextEditingController emailDialogController =
        TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: const Text(
            'Lupa Kata Sandi',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Masukkan email Anda untuk menerima link reset kata sandi.'),
              const SizedBox(height: 20),
              TextField(
                controller: emailDialogController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (emailDialogController.text.isNotEmpty) {
                  AuthService().sendPasswordResetEmail(
                    email: emailDialogController.text.trim(),
                    context: context,
                  );
                  Navigator.pop(context); // Tutup dialog
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Kirim'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: false,
      appBar: const CustomAppBar(
        title: 'Login',
        showBackButton: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Profile Image using shared widget
                    const ProfileImage(
                      radius: 40,
                      hasCircleAvatar: true,
                    ),

                    // Business Name with better typography
                    Container(
                      margin: const EdgeInsets.only(bottom: 40),
                      child: const Text(
                        'Dina Griya Rias',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    // Welcome Text Section
                    const Column(
                      children: [
                        Text(
                          'Login Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 8),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Email Field using shared widget
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      marginBottom: 20,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),

                    // Password Field using shared widget
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureText,
                      marginBottom: 20,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      suffixIcon: PasswordVisibilityIcon(
                        obscureText: _obscureText,
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // PANGGIL METODE DIALOG DI SINI
                          _showForgotPasswordDialog();
                        },
                        child: const Text(
                          'Forget Password',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Login Button using shared widget
                    GradientButton(
                      text: 'Log In',
                      gradientColors: const [Colors.orange, Color(0xFF8B4513)],
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await AuthService().signin(
                              email: _emailController.text,
                              password: _passwordController.text,
                              context: context);
                        }
                      },
                    ),

                    const SizedBox(height: 30),

                    // Sign Up Link using shared widget
                    LinkText(
                      normalText: "Don't have an account? ",
                      linkText: "Sign Up",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Signup()),
                        );
                      },
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
