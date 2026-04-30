import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../chat/chat_screen.dart';
import '../../services/chat_service.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatService _chatService = ChatService();
  String _searchQuery = "";

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return DateFormat('hh:mm a').format(date);
    }
    return DateFormat('dd/MM/yy').format(date);
  }

  @override
  Widget build(BuildContext context) {

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.white30 : Colors.black38;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          title: Text('Messages',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 26)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.settings_outlined, color: textColor),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen())),
            ),
            IconButton(
              icon: Icon(Icons.logout_rounded, color: textColor),
              onPressed: () async => await _auth.signOut(),
            ),
          ],
          bottom: TabBar(
            indicatorColor: primaryColor,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3,
            labelColor: primaryColor,
            unselectedLabelColor: subTextColor,
            tabs: const [
              Tab(child: Text("All Chats", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              Tab(child: Text("Archived", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(showOnlyArchived: false, surface: surfaceColor, text: textColor, subText: subTextColor, bg: scaffoldBg),
            _buildList(showOnlyArchived: true, surface: surfaceColor, text: textColor, subText: subTextColor, bg: scaffoldBg),
          ],
        ),
      ),
    );
  }

  Widget _buildList({required bool showOnlyArchived, required Color surface, required Color text, required Color subText, required Color bg}) {
    return Column(
      children: [
        _buildSearchField(surface, text),
        Expanded(
          child: _searchQuery.isEmpty
              ? _buildActiveChatsStream(showOnlyArchived, surface, text, subText, bg)
              : _buildGlobalUserSearch(surface, text),
        ),
      ],
    );
  }

  Widget _buildActiveChatsStream(bool showOnlyArchived, Color surface, Color text, Color subText, Color bg) {
    final currentUserId = _auth.currentUser?.uid;
    final primaryColor = Theme.of(context).primaryColor;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
      builder: (context, userDocSnapshot) {
        if (!userDocSnapshot.hasData) return const SizedBox();
        final List myBlockedUsers = userDocSnapshot.data?['blockedUsers'] ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chat_rooms')
              .where('members', arrayContains: currentUserId)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: primaryColor));
            }

            final rooms = snapshot.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final List lastChatBy = data['lastChatBy'] ?? [];
              final List archivedBy = data['archivedBy'] ?? [];
              return lastChatBy.contains(currentUserId) &&
                  (showOnlyArchived ? archivedBy.contains(currentUserId) : !archivedBy.contains(currentUserId));
            }).toList() ?? [];

            if (rooms.isEmpty) {
              return Center(child: Text(showOnlyArchived ? "No archived chats" : "No conversations yet",
                  style: TextStyle(color: subText, fontSize: 16)));
            }

            return ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final roomData = rooms[index].data() as Map<String, dynamic>;
                final String otherUserId = (roomData['members'] as List).firstWhere((id) => id != currentUserId);

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(otherUserId).snapshots(),
                  builder: (context, userSnap) {

                    if (!userSnap.hasData || userSnap.data == null || userSnap.data!.data() == null) {
                      return const SizedBox();
                    }

                    final userData = userSnap.data!.data() as Map<String, dynamic>;


                    if (userData['isVerified'] != true) return const SizedBox();

                    int unreadCount = roomData['unreadCount_$currentUserId'] ?? 0;
                    bool isBlocked = myBlockedUsers.contains(otherUserId);
                    String lastMsg = roomData['lastMessage'] ?? "";

                    String displayMsg = isBlocked ? "🚫 You blocked this user" : (lastMsg.isEmpty ? "Tap to start conversation" : lastMsg);

                    return _buildEnhancedTile(
                      uid: otherUserId,
                      data: userData,
                      lastMsg: displayMsg,
                      unreadCount: unreadCount,
                      time: _formatTime(roomData['timestamp']),
                      isArchived: showOnlyArchived,
                      isBlocked: isBlocked,
                      surface: surface,
                      text: text,
                      subText: subText,
                      bg: bg,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEnhancedTile({
    required String uid,
    required Map<String, dynamic> data,
    required String lastMsg,
    required int unreadCount,
    required String time,
    required bool isArchived,
    required bool isBlocked,
    required Color surface,
    required Color text,
    required Color subText,
    required Color bg,
  }) {
    bool hasUnread = unreadCount > 0;
    String name = data['name'] ?? 'User';
    String gender = data['gender'] ?? 'male';
    bool isOnline = data['isOnline'] ?? false;
    final primaryColor = Theme.of(context).primaryColor;

    return Dismissible(
      key: Key(uid),
      background: _buildSwipeAction(Icons.archive, Colors.green, Alignment.centerLeft),
      secondaryBackground: _buildSwipeAction(Icons.delete_sweep, Colors.redAccent, Alignment.centerRight),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.endToStart) {
          bool confirm = await _showDeleteConfirmDialog(surface, text);
          if (confirm) await _chatService.deleteFullChat(uid);
          return confirm;
        } else {
          await _chatService.toggleArchiveChat(uid, !isArchived);
          return true;
        }
      },
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (c) => ChatScreen(receiverUserId: uid, receiverUserName: name, gender: gender)
        )),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: hasUnread ? [primaryColor, Colors.cyan] : [surface, surface],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: bg,
                      child: Icon(
                        gender == 'female' ? Icons.face_3_rounded : Icons.face_rounded,
                        size: 32,
                        color: hasUnread ? text : subText,
                      ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: bg, width: 2.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(color: text, fontSize: 18, fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      lastMsg,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isBlocked ? Colors.redAccent.withOpacity(0.7) : (hasUnread ? text.withOpacity(0.8) : subText),
                        fontSize: 14,
                        fontStyle: lastMsg.contains("Tap to") ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(time, style: TextStyle(color: hasUnread ? primaryColor : subText, fontSize: 12)),
                  const SizedBox(height: 8),
                  if (hasUnread)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(20)),
                      child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeAction(IconData icon, Color color, Alignment align) {
    return Container(
      color: color.withOpacity(0.1),
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildSearchField(Color surface, Color text) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        style: TextStyle(color: text),
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: "Search people...",
          hintStyle: TextStyle(color: text.withOpacity(0.3)),
          prefixIcon: Icon(Icons.search_rounded, color: text.withOpacity(0.3)),
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildGlobalUserSearch(Color surface, Color text) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('isVerified', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final users = snapshot.data!.docs.where((doc) {

          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) return false;

          return doc.id != _auth.currentUser?.uid &&
              (data['name'] ?? '').toString().toLowerCase().contains(_searchQuery);
        }).toList();

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                  backgroundColor: surface,
                  child: Icon(
                      userData['gender'] == 'female' ? Icons.face_3_rounded : Icons.person,
                      color: text.withOpacity(0.3)
                  )
              ),
              title: Text(userData['name'] ?? 'User', style: TextStyle(color: text)),
              onTap: () {
                setState(() => _searchQuery = "");
                Navigator.push(context, MaterialPageRoute(builder: (c) => ChatScreen(receiverUserId: users[index].id, receiverUserName: userData['name'], gender: userData['gender'] ?? 'male')));
              },
            );
          },
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmDialog(Color surface, Color text) async {
    return await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Chat?", style: TextStyle(color: text)),
        content: Text("This action will remove all messages for you.", style: TextStyle(color: text.withOpacity(0.6))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("CANCEL", style: TextStyle(color: text.withOpacity(0.4)))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("DELETE", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    ) ?? false;
  }
}