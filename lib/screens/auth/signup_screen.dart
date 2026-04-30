import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedGender = 'male';
  bool _isLoading = false;

  Future<void> _handleSignup(AuthService authService) async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      _showSnackBar("All fields are required.", Colors.red);
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar("Please enter a valid email address.", Colors.red);
      return;
    }

    if (pass.length < 6) {
      _showSnackBar("Password must be at least 6 characters.", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await authService.signUp(email, pass, name, _selectedGender);
    } catch (e) {
      final message = e.toString().replaceAll("Exception: ", "");

      if (message.toLowerCase().contains("verification email")) {
        _showSnackBar(message, Colors.green, duration: 5);

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) Navigator.pop(context);
        });
      } else {

        _showSnackBar(message, Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(email);
  }

  void _showSnackBar(String msg, Color color, {int duration = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: Duration(seconds: duration),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final accent = Theme.of(context).primaryColor;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Text(
                "Create Account",
                style: TextStyle(
                    color: textColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text("Verify your email to start chatting"),
              const SizedBox(height: 35),

              _buildInput("Full Name", _nameController, Icons.person_outline),
              const SizedBox(height: 18),
              _buildInput("Email", _emailController, Icons.email_outlined),
              const SizedBox(height: 18),
              _buildInput("Password", _passwordController, Icons.lock_outline,
                  isPass: true),

              const SizedBox(height: 20),
              _buildGender(textColor, accent),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => _handleSignup(authService),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Sign Up",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGender(Color textColor, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select Gender:",
            style: TextStyle(color: textColor.withOpacity(0.7))),
        Row(
          children: [
            Radio(
              value: 'male',
              groupValue: _selectedGender,
              activeColor: accent,
              onChanged: (v) => setState(() => _selectedGender = v.toString()),
            ),
            Text("Male", style: TextStyle(color: textColor)),
            const SizedBox(width: 20),
            Radio(
              value: 'female',
              groupValue: _selectedGender,
              activeColor: accent,
              onChanged: (v) => setState(() => _selectedGender = v.toString()),
            ),
            Text("Female", style: TextStyle(color: textColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildInput(String label, TextEditingController c, IconData icon,
      {bool isPass = false}) {
    return TextField(
      controller: c,
      obscureText: isPass,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}
