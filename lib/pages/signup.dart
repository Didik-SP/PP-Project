import '../providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'widget/button.dart';

class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  bool _obscureText = true;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _whatsappController.dispose();
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
        title: 'Register',
        showBackButton: true,
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
                      radius: 60,
                      hasCircleAvatar: false,
                    ),

                    // Username field using shared widget
                    CustomTextField(
                      controller: _usernameController,
                      hintText: 'Username',
                      prefixIcon: Icons.person_outline,
                    ),

                    // WhatsApp field using shared widget
                    CustomTextField(
                      controller: _whatsappController,
                      hintText: 'No. Whatsapp',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    // Email field using shared widget
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    // Password field using shared widget
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscureText,
                      suffixIcon: PasswordVisibilityIcon(
                        obscureText: _obscureText,
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sign Up button using shared widget
                    GradientButton(
                      text: 'Sign Up',
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          // Handle registration logic here
                          await AuthService().sendOTPViaWhatsApp(
                              username: _usernameController.text,
                              whatsapp: _whatsappController.text,
                              email: _emailController.text,
                              password: _passwordController.text,
                              context: context);
                        }
                      },
                    ),

                    const SizedBox(height: 80),

                    // Already have account text using shared widget
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: LinkText(
                        normalText: "Already Have Account? ",
                        linkText: "Log In",
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                    )
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
