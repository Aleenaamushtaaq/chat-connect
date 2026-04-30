import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String name;
  final String email;
  final String gender;
  final void Function()? onTap;

  const UserTile({
    super.key,
    required this.name,
    required this.email,
    required this.gender,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ✨ Gender check ko lowercase kar diya taake "Female" aur "female" dono chalein
    final bool isFemale = gender.toLowerCase() == 'female';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        // ✨ Avatar Styling
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF1B202D), // Surface dark color
          child: Icon(
            isFemale ? Icons.face_3 : Icons.face,
            color: const Color(0xFF7C4DFF), // Accent Purple
            size: 28,
          ),
        ),
        // ✨ Text Styling
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          email, // HomeScreen par ye "Last Message" dikhayega
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        // ✨ WhatsApp style arrow ya trailing icon (Optional)
        trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
      ),
    );
  }
}