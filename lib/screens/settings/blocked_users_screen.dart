import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/chat_service.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatService = ChatService();
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;


    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final accentPurple = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtitleColor = isDark ? Colors.white38 : Colors.black54;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Text("Blocked Users",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: accentPurple));
          }

          List blockedIds = snapshot.data?['blockedUsers'] ?? [];

          if (blockedIds.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.block_flipped, size: 60, color: textColor.withOpacity(0.1)),
                  ),
                  const SizedBox(height: 20),
                  Text("Your block list is empty",
                      style: TextStyle(color: subtitleColor, fontSize: 16, letterSpacing: 0.5)),
                ],
              ),
            );
          }
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: blockedIds)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (!userSnapshot.hasData) return const SizedBox();

              final users = userSnapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                physics: const BouncingScrollPhysics(),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  var userData = users[index].data() as Map<String, dynamic>;
                  String uid = users[index].id;
                  String name = userData['name'] ?? "User";
                  String gender = userData['gender'] ?? 'male';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: textColor.withOpacity(0.05)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accentPurple.withOpacity(0.3), width: 1),
                        ),
                        child: CircleAvatar(
                          backgroundColor: scaffoldBg,
                          radius: 25,
                          child: Icon(
                            gender == 'female' ? Icons.face_3_rounded : Icons.face_rounded,
                            color: accentPurple,
                            size: 28,
                          ),
                        ),
                      ),
                      title: Text(name,
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 17)),
                      subtitle: const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text("Blocked",
                            style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      trailing: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.redAccent.withOpacity(0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: () => chatService.toggleBlockUser(uid, false),
                        child: const Text("Unblock",
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}