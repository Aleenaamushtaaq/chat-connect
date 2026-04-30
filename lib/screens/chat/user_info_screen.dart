import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';

class UserInfoScreen extends StatelessWidget {
  final String userId;
  UserInfoScreen({Key? key, required this.userId}) : super(key: key);

  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser!.uid;


    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final accentPurple = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white38 : Colors.black54;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor)
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUid).snapshots(),
        builder: (context, currentUserSnapshot) {
          if (!currentUserSnapshot.hasData) return const Center(child: CircularProgressIndicator());

          final List myBlockedList = currentUserSnapshot.data?['blockedUsers'] ?? [];
          bool isUserBlockedByMe = myBlockedList.contains(userId);

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();

              var data = snapshot.data!.data() as Map<String, dynamic>;
              String gender = data['gender'] ?? 'male';
              bool isOnline = data['isOnline'] ?? false;
              bool showAbout = data['showAbout'] ?? true;
              bool showOnline = data['showOnline'] ?? true;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildProfileHeader(data, gender, accentPurple, surfaceColor, showOnline, textColor, scaffoldBg),
                    const SizedBox(height: 30),

                    _buildInfoTile(
                        "About",
                        showAbout ? (data['about'] ?? "Hey there! I am using ChatConnect.") : "Privacy Enabled",
                        Icons.info_outline,
                        surfaceColor,
                        textColor,
                        subTextColor
                    ),

                    _buildInfoTile("Email", data['email'] ?? "", Icons.email_outlined, surfaceColor, textColor, subTextColor),

                    _buildInfoTile(
                        "Status",
                        showOnline
                            ? (isOnline ? "Online Now" : "Offline")
                            : "Hidden",
                        Icons.circle,
                        surfaceColor,
                        textColor,
                        subTextColor,
                        iconColor: (showOnline && isOnline) ? Colors.greenAccent : subTextColor
                    ),

                    const SizedBox(height: 30),

                    _buildActionButton(
                      context: context,
                      title: isUserBlockedByMe ? "Unblock User" : "Block User",
                      icon: Icons.block,
                      color: isUserBlockedByMe ? Colors.greenAccent : Colors.redAccent,
                      onTap: () => _chatService.toggleBlockUser(userId, !isUserBlockedByMe),
                    ),

                    _buildActionButton(
                      context: context,
                      title: "Clear Chat History",
                      icon: Icons.delete_sweep_rounded,
                      color: isDark ? Colors.white38 : Colors.black38,
                      onTap: () => _showClearChatDialog(context, surfaceColor, textColor),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map data, String gender, Color accent, Color surface, bool showOnline, Color textColor, Color bg) {
    bool isOnline = data['isOnline'] ?? false;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [accent, Colors.cyanAccent.withOpacity(0.5)])
          ),
          child: CircleAvatar(
            radius: 75,
            backgroundColor: bg,
            child: Icon(
              gender == 'female' ? Icons.face_3_rounded : Icons.face_rounded,
              size: 90,
              color: accent,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(data['name'] ?? "User", style: TextStyle(color: textColor, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20)),
          child: Text(
            showOnline ? (isOnline ? "ACTIVE" : "OFFLINE") : "PRIVATE",
            style: TextStyle(
                color: (showOnline && isOnline) ? Colors.greenAccent : textColor.withOpacity(0.3),
                fontSize: 10,
                fontWeight: FontWeight.bold
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon, Color tileColor, Color textColor, Color subTextColor, {Color? iconColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: tileColor, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? const Color(0xFF7C4DFF), size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: subTextColor, fontSize: 12, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionButton({required BuildContext context, required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(20)
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showClearChatDialog(BuildContext context, Color surface, Color text) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: surface,
        title: Text("Clear Chat?", style: TextStyle(color: text)),
        content: Text("All messages will be removed from your screen.", style: TextStyle(color: text.withOpacity(0.6))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          TextButton(
              onPressed: () {
                _chatService.clearChat(userId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Chat cleared")));
              },
              child: const Text("CLEAR", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }
}