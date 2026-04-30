import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../provider/theme_provider.dart';
import 'blocked_users_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    var doc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
    if (doc.exists) {
      setState(() {
        _nameController.text = doc['name'] ?? '';
        _aboutController.text = doc['about'] ?? 'Hey there! I am using ChatConnect';
        _emailController.text = _auth.currentUser!.email ?? '';
        _phoneController.text = doc['phone'] ?? '';
      });
    }
  }

  Color getAccentColor(BuildContext context) => Theme.of(context).primaryColor;
  Color getSurfaceColor(BuildContext context) => Theme.of(context).colorScheme.surface;
  Color getTextColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

  void _showEmailUpdateDialog() {
    final _passController = TextEditingController();
    final _newEmailController = TextEditingController(text: _emailController.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: getSurfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Update Email", style: TextStyle(color: getTextColor(context), fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField("New Email", _newEmailController, false),
            const SizedBox(height: 15),
            _buildDialogField("Current Password", _passController, true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: getAccentColor(context), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              try {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.updateEmail(_newEmailController.text.trim(), _passController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email Updated!")));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
              }
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController controller, bool obscure) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: getTextColor(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: getAccentColor(context).withOpacity(0.5))),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: getAccentColor(context))),
      ),
    );
  }

  void _updateProfile() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updateProfile({
        'name': _nameController.text.trim(),
        'about': _aboutController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile Updated!'), backgroundColor: Colors.green));
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: getTextColor(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings', style: TextStyle(color: getTextColor(context), fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('users').doc(user!.uid).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || !snapshot.data!.exists) return Center(child: CircularProgressIndicator(color: getAccentColor(context)));

            var userData = snapshot.data!.data() as Map<String, dynamic>;
            String gender = userData['gender'] ?? 'male';
            bool showOnline = userData['showOnline'] ?? true;
            bool showAbout = userData['showAbout'] ?? true;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: getAccentColor(context).withOpacity(0.5), width: 2)),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: getSurfaceColor(context),
                        child: Icon(gender == 'female' ? Icons.face_3_rounded : Icons.face_rounded, size: 65, color: getAccentColor(context)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),
                  _buildSectionTitle("PERSONAL INFO"),

                  Container(
                    decoration: BoxDecoration(color: getSurfaceColor(context), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text("Email Address", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          subtitle: Text(_emailController.text, style: TextStyle(color: getTextColor(context), fontSize: 15)),
                          trailing: IconButton(icon: Icon(Icons.edit_note, color: getAccentColor(context)), onPressed: _showEmailUpdateDialog),
                        ),
                        const Divider(height: 1),
                        _buildCustomField("Name", _nameController, Icons.person_outline),
                        const Divider(height: 1),
                        _buildCustomField("Phone", _phoneController, Icons.phone_android_outlined),
                        const Divider(height: 1),
                        _buildCustomField("About", _aboutController, Icons.info_outline),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: getAccentColor(context),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _updateProfile,
                      child: const Text('Save Profile Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 40),
                  _buildSectionTitle("APPEARANCE & PRIVACY"),

                  _buildSwitchTile(
                      "Dark Mode",
                      "Enable dark theme for eye comfort",
                      themeProvider.isDarkMode,
                          (val) => themeProvider.toggleTheme()
                  ),

                  _buildSwitchTile("Show Online Status", "Others can see your activity", showOnline, (val) => authService.updatePrivacy('showOnline', val)),
                  _buildSwitchTile("Show About Info", "Make your status visible", showAbout, (val) => authService.updatePrivacy('showAbout', val)),

                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(color: getSurfaceColor(context), borderRadius: BorderRadius.circular(18)),
                    child: ListTile(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BlockedUsersScreen())),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.block_flipped, color: Colors.redAccent, size: 20),
                      ),
                      title: Text("Blocked Users", style: TextStyle(color: getTextColor(context))),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          }
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 10),
      child: Text(title, style: TextStyle(color: getAccentColor(context).withOpacity(0.7), fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 1.5)),
    );
  }

  Widget _buildCustomField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: TextField(
        controller: controller,
        style: TextStyle(color: getTextColor(context), fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: getAccentColor(context).withOpacity(0.6), size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: getSurfaceColor(context), borderRadius: BorderRadius.circular(18)),
      child: SwitchListTile(
        title: Text(title, style: TextStyle(color: getTextColor(context), fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        value: value,
        activeColor: getAccentColor(context),
        onChanged: onChanged,
      ),
    );
  }
}