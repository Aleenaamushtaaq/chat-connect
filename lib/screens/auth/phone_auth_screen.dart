import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  String? _selectedGender;


  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty || _nameController.text.isEmpty) {
      _showSnackBar('Please fill all fields', Colors.red);
      return;
    }
    if (_selectedGender == null) {
      _showSnackBar('Please select your gender', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    String phoneNumber = _phoneController.text.trim();
    if (!phoneNumber.startsWith('+')) phoneNumber = '+92$phoneNumber';

    try {
      final error = await authService.verifyPhoneNumber(phoneNumber);
      if (mounted) {
        setState(() => _isLoading = false);
        if (error != null) {
          _showSnackBar(error, Colors.red);
        } else {
          setState(() => _otpSent = true);
          _showSnackBar('OTP sent successfully', Colors.green);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Failed to send OTP: ${e.toString()}", Colors.red);
    }
  }


  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      _showSnackBar('Please enter OTP', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    try {
      final error = await authService.verifyOTP(
        _otpController.text.trim(),
        _nameController.text.trim(),
        _selectedGender!,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (error != null) {
          _showSnackBar(error, Colors.red);
        } else {
          _showSnackBar('Login successful!', Colors.green);
          Navigator.pop(context); // Navigate back or to home screen
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('OTP verification failed: ${e.toString()}', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final accentPurple = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: surfaceColor, shape: BoxShape.circle),
                child: Icon(Icons.phone_android_rounded, size: 50, color: accentPurple),
              ),
              const SizedBox(height: 24),
              Text(
                'Phone Login',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 40),

              if (!_otpSent) ...[
                _buildDynamicInput(
                  'Full Name',
                  _nameController,
                  Icons.person_outline,
                  accentPurple,
                  surfaceColor,
                  textColor,
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Select Gender:", style: TextStyle(color: subTextColor)),
                ),
                Row(
                  children: [
                    Radio(
                      value: 'male',
                      groupValue: _selectedGender,
                      activeColor: accentPurple,
                      onChanged: (val) => setState(() => _selectedGender = val.toString()),
                    ),
                    Text("Male", style: TextStyle(color: textColor)),
                    const SizedBox(width: 20),
                    Radio(
                      value: 'female',
                      groupValue: _selectedGender,
                      activeColor: accentPurple,
                      onChanged: (val) => setState(() => _selectedGender = val.toString()),
                    ),
                    Text("Female", style: TextStyle(color: textColor)),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDynamicInput(
                  'Phone Number',
                  _phoneController,
                  Icons.phone_outlined,
                  accentPurple,
                  surfaceColor,
                  textColor,
                  isPhone: true,
                ),
              ] else ...[
                _buildDynamicInput(
                  'Enter OTP',
                  _otpController,
                  Icons.pin_outlined,
                  accentPurple,
                  surfaceColor,
                  textColor,
                  isOTP: true,
                ),
              ],

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_otpSent ? _verifyOTP : _sendOTP),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    _otpSent ? 'Verify & Login' : 'Send OTP',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              if (_otpSent)
                TextButton(
                  onPressed: () => setState(() => _otpSent = false),
                  child: Text('Edit Phone Number', style: TextStyle(color: accentPurple)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicInput(
      String label,
      TextEditingController controller,
      IconData icon,
      Color accent,
      Color surface,
      Color text, {
        bool isPhone = false,
        bool isOTP = false,
      }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: text),
      keyboardType: (isPhone || isOTP) ? TextInputType.phone : TextInputType.text,
      maxLength: isOTP ? 6 : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: text.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: accent),
        prefixText: isPhone ? '+92 ' : null,
        prefixStyle: TextStyle(color: text, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: surface,
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: text.withOpacity(0.1)),
        ),
      ),
    );
  }
}
