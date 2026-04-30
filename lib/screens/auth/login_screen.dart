import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';
import 'phone_auth_screen.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _formatErrorMessage(String error) {
    final e = error.toLowerCase();

    if (e.contains('not verified')) {
      return "Please verify your email first. A verification link has been sent to your inbox. Also check Spam folder.";
    } else if (e.contains('wrong-password') ||
        e.contains('user-not-found') ||
        e.contains('invalid-credential')) {
      return "Invalid email or password. Please try again.";
    } else if (e.contains('network')) {
      return "Network error. Please check your internet connection.";
    } else if (e.contains('too-many-requests')) {
      return "Too many failed attempts. Please try again later.";
    } else if (e.contains('invalid-email')) {
      return "Invalid email format.";
    } else {
      return "Login failed. Please try again.";
    }
  }


  Future<void> _handleLogin(
      BuildContext context,
      AuthService authService,
      Color surface,
      Color text,
      Color accent,
      ) async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      _showDialog(
        context,
        "Missing Information",
        "Please enter both email and password.",
        surface,
        text,
        accent,
      );
      return;
    }

    try {
      await authService.signIn(email, pass);

    } catch (e) {
      final msg = _formatErrorMessage(e.toString());
      _showDialog(context, "Login Message", msg, surface, text, accent);
    }
  }

  void _showForgotPasswordDialog(
      BuildContext context,
      AuthService authService,
      Color scaffoldBg,
      Color surface,
      Color text,
      Color accent,
      ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Reset Password",
            style: TextStyle(color: text, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: text),
          decoration: InputDecoration(
            hintText: "Email Address",
            prefixIcon: Icon(Icons.email_outlined, color: accent),
            filled: true,
            fillColor: scaffoldBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: TextStyle(color: text.withOpacity(0.5))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await authService.sendPasswordResetEmail(controller.text.trim());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Reset link sent to your email."),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Send"),
          ),
        ],
      ),
    );
  }


  void _showDialog(
      BuildContext context,
      String title,
      String message,
      Color surface,
      Color text,
      Color accent,
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: text)),
          ],
        ),
        content:
        Text(message, style: TextStyle(color: text.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK",
                style:
                TextStyle(color: accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final theme = Theme.of(context);

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final surface = theme.colorScheme.surface;
    final accent = theme.primaryColor;
    final text = theme.brightness == Brightness.dark
        ? Colors.white
        : Colors.black;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              Icon(Icons.chat_bubble_rounded,
                  size: 80, color: accent),
              const SizedBox(height: 20),
              Text("Chat Connect",
                  style: TextStyle(
                      color: text,
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),

              _buildInput(
                "Email",
                _emailController,
                Icons.email_outlined,
                surface,
                accent,
                text,
                false,
                TextInputAction.next,
              ),
              const SizedBox(height: 20),

              _buildInput(
                "Password",
                _passwordController,
                Icons.lock_outline,
                surface,
                accent,
                text,
                true,
                TextInputAction.done,
                onSubmit: (_) => _handleLogin(
                    context, authService, surface, text, accent),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showForgotPasswordDialog(
                      context,
                      authService,
                      scaffoldBg,
                      surface,
                      text,
                      accent),
                  child: Text("Forgot Password?",
                      style: TextStyle(color: accent)),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () => _handleLogin(
                      context, authService, surface, text, accent),
                  child: const Text("Login",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 15),

              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PhoneAuthScreen()),
                ),
                icon: Icon(Icons.phone_android, color: accent),
                label: Text("Login with Phone",
                    style: TextStyle(color: accent)),
              ),

              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SignupScreen()),
                ),
                child: Text("Don't have an account? Sign Up",
                    style: TextStyle(color: text.withOpacity(0.6))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
      String label,
      TextEditingController controller,
      IconData icon,
      Color surface,
      Color accent,
      Color text,
      bool isPass,
      TextInputAction action, {
        Function(String)? onSubmit,
      }) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: TextStyle(color: text),
      textInputAction: action,
      onSubmitted: onSubmit,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: accent),
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
    );
  }
}
