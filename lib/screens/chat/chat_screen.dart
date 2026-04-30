import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:intl/intl.dart';
import '../../services/chat_service.dart';
import 'user_info_screen.dart';

class ChatScreen extends StatefulWidget {
  final String receiverUserId;
  final String receiverUserName;
  final String gender;

  const ChatScreen({
    Key? key,
    required this.receiverUserId,
    required this.receiverUserName,
    required this.gender,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();

  bool isEmojiVisible = false;
  FocusNode focusNode = FocusNode();
  bool isSearching = false;
  String searchQuery = "";
  String? replyingToMessage;
  List<String> selectedMsgIds = [];
  bool isSelectionMode = false;
  bool isOtherUserTyping = false;
  bool amIBlockedByOther = false;

  @override
  void initState() {
    super.initState();
    _chatService.markMessagesAsRead(widget.receiverUserId);
    _listenForTyping();
    _checkIfAmIBlocked();

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        setState(() => isEmojiVisible = false);
      }
      _updateTypingStatus(focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void _checkIfAmIBlocked() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverUserId)
        .snapshots()
        .listen((snap) {
      if (snap.exists && mounted) {
        List blockedList = snap.get('blockedUsers') ?? [];
        setState(() {
          amIBlockedByOther = blockedList.contains(_auth.currentUser!.uid);
        });
      }
    });
  }

  void _updateTypingStatus(bool isTyping) async {
    final myUid = _auth.currentUser!.uid;
    FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(_getRoomId())
        .set({'typing_$myUid': isTyping}, SetOptions(merge: true));
  }

  void _listenForTyping() {
    FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(_getRoomId())
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null && mounted) {
        setState(() {
          isOtherUserTyping = snapshot.data()!['typing_${widget.receiverUserId}'] ?? false;
        });
      }
    });
  }

  String _getRoomId() {
    List<String> ids = [_auth.currentUser!.uid, widget.receiverUserId];
    ids.sort();
    return ids.join('_');
  }

  void _sendMessage() async {
    String msgText = _messageController.text.trim();
    if (msgText.isNotEmpty) {
      String? currentReply = replyingToMessage;
      _messageController.clear();
      setState(() => replyingToMessage = null);
      _updateTypingStatus(false);

      await _chatService.sendMessage(
        widget.receiverUserId,
        msgText,
        replyToMsg: currentReply,
      );

      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(_getRoomId())
          .set({
        'lastMessage': msgText,
        'lastMessageSender': _auth.currentUser!.uid,
        'lastMessageTime': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }


  void _updateHomeLastMessage() async {
    final String currentUserId = _auth.currentUser!.uid;


    var messagesSnapshot = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(_getRoomId())
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(10)
        .get();

    String lastText = "No messages";
    dynamic lastTime = FieldValue.serverTimestamp();

    for (var doc in messagesSnapshot.docs) {
      List deletedBy = doc.data()['deletedBy'] ?? [];
      if (!deletedBy.contains(currentUserId)) {
        lastText = doc.data()['message'] ?? "";
        lastTime = doc.data()['timestamp'];
        break;
      }
    }

    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(_getRoomId())
        .update({
      'lastMessage': lastText,
      'lastMessageTime': lastTime,
    });
  }

  void _updateLastMessageAfterDelete(String deletedMsgText) async {
    await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(_getRoomId())
        .update({
      'lastMessage': "🚫 This message was deleted",
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  List<TextSpan> _getHighlightedText(String text, String query, Color textColor) {
    if (query.trim().isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      return [TextSpan(text: text, style: TextStyle(color: textColor, fontSize: 16))];
    }
    List<TextSpan> spans = [];
    String lowerText = text.toLowerCase();
    String lowerQuery = query.toLowerCase();
    int start = 0;
    int index = lowerText.indexOf(lowerQuery);
    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(
            text: text.substring(start, index),
            style: TextStyle(color: textColor, fontSize: 16)));
      }
      spans.add(TextSpan(
          text: text.substring(index, index + query.length),
          style: const TextStyle(
              color: Colors.black,
              backgroundColor: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 16)));
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }
    if (start < text.length) {
      spans.add(TextSpan(
          text: text.substring(start),
          style: TextStyle(color: textColor, fontSize: 16)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = isDark ? const Color(0xFF1B202D) : Colors.grey[200]!;
    final textColor = isDark ? Colors.white : Colors.black;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid).snapshots(),
      builder: (context, blockSnapshot) {
        bool iHaveBlocked = false;
        if (blockSnapshot.hasData && blockSnapshot.data!.exists) {
          List blockedList = (blockSnapshot.data!.data() as Map<String, dynamic>)['blockedUsers'] ?? [];
          iHaveBlocked = blockedList.contains(widget.receiverUserId);
        }

        if (amIBlockedByOther) {
          return Scaffold(
            backgroundColor: scaffoldBg,
            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: BackButton(color: textColor)),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off_outlined, size: 80, color: textColor.withOpacity(0.2)),
                  const SizedBox(height: 20),
                  Text("User unavailable", style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("This account is no longer available.", style: TextStyle(color: textColor.withOpacity(0.5))),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: _buildAppBar(iHaveBlocked, textColor, surfaceColor),
          body: Column(
            children: [
              _buildPinnedHeader(textColor),
              if (isSearching) _buildSearchUI(surfaceColor, textColor),
              Expanded(child: _buildMessageList(isDark, textColor)),
              if (isOtherUserTyping && !iHaveBlocked)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("${widget.receiverUserName} is typing...",
                        style: const TextStyle(color: Color(0xFF7C4DFF), fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                ),
              if (replyingToMessage != null) _buildReplyPreview(surfaceColor, textColor),
              iHaveBlocked
                  ? _buildBlockedUI(surfaceColor, textColor)
                  : (isSelectionMode ? const SizedBox() : _buildInputArea(surfaceColor, textColor)),
              if (isEmojiVisible) _buildEmojiPicker(scaffoldBg),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchUI(Color surface, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      color: surface,
      child: TextField(
        style: TextStyle(color: text),
        autofocus: true,
        decoration: InputDecoration(
            hintText: "Search in chat...",
            border: InputBorder.none,
            hintStyle: TextStyle(color: text.withOpacity(0.3))),
        onChanged: (v) => setState(() => searchQuery = v),
      ),
    );
  }

  Widget _buildMessageList(bool isDark, Color text) {
    final String currentUserId = _auth.currentUser!.uid;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('chat_rooms').doc(_getRoomId()).snapshots(),
      builder: (context, roomSnapshot) {
        Timestamp? clearedAt;
        if (roomSnapshot.hasData && roomSnapshot.data!.exists) {
          clearedAt = (roomSnapshot.data!.data() as Map<String, dynamic>)['chatClearedAt_$currentUserId'];
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _chatService.getMessages(currentUserId, widget.receiverUserId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              List deletedBy = data['deletedBy'] ?? [];
              Timestamp? msgTime = data['timestamp'] as Timestamp?;
              return !deletedBy.contains(currentUserId) &&
                  !(clearedAt != null && msgTime != null && msgTime.toDate().isBefore(clearedAt.toDate()));
            }).toList();

            return ListView.builder(
              reverse: true,
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final String msgId = docs[index].id;
                final isMe = data['senderId'] == currentUserId;
                bool isSelected = selectedMsgIds.contains(msgId);

                return Dismissible(
                  key: Key(msgId),
                  direction: DismissDirection.startToEnd,
                  confirmDismiss: (direction) async {
                    setState(() {
                      replyingToMessage = data['message'];
                      focusNode.requestFocus();
                    });
                    return false;
                  },
                  background: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.reply, color: Color(0xFF7C4DFF)),
                  ),
                  child: GestureDetector(
                    onLongPress: () => setState(() { isSelectionMode = true; selectedMsgIds.add(msgId); }),
                    onTap: () {
                      if (isSelectionMode) {
                        setState(() {
                          isSelected ? selectedMsgIds.remove(msgId) : selectedMsgIds.add(msgId);
                          if (selectedMsgIds.isEmpty) isSelectionMode = false;
                        });
                      }
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        color: isSelected ? Colors.purple.withOpacity(0.2) : Colors.transparent,
                        child: _buildBubble(data, isMe, isDark)),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBubble(Map<String, dynamic> data, bool isMe, bool isDark) {
    bool isPinned = data['isPinned'] ?? false;
    String time = data['timestamp'] != null ? DateFormat('hh:mm a').format((data['timestamp'] as Timestamp).toDate()) : '';
    Color bubbleColor = isMe ? const Color(0xFF7C4DFF) : (isDark ? const Color(0xFF1B202D) : Colors.grey[300]!);
    Color bubbleTextColor = isMe ? Colors.white : (isDark ? Colors.white : Colors.black);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isMe ? 15 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 15),
          ),
          border: isPinned ? Border.all(color: Colors.amber, width: 1.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data['replyTo'] != null)
              Container(padding: const EdgeInsets.all(5), margin: const EdgeInsets.only(bottom: 5), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(5)), child: Text(data['replyTo'], style: const TextStyle(fontSize: 12, color: Colors.grey))),
            RichText(text: TextSpan(children: _getHighlightedText(data['message'] ?? '', searchQuery, bubbleTextColor))),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPinned) const Icon(Icons.push_pin, size: 12, color: Colors.amber),
                const SizedBox(width: 4),
                Text(time, style: TextStyle(fontSize: 10, color: bubbleTextColor.withOpacity(0.5))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool iHaveBlocked, Color text, Color surface) {
    if (isSelectionMode) {
      return AppBar(
        backgroundColor: const Color(0xFF7C4DFF),
        title: Text("${selectedMsgIds.length}", style: const TextStyle(color: Colors.white)),
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() { isSelectionMode = false; selectedMsgIds.clear(); })),
        actions: [
          IconButton(icon: const Icon(Icons.push_pin, color: Colors.white), onPressed: () {
            for (var id in selectedMsgIds) { FirebaseFirestore.instance.collection('chat_rooms').doc(_getRoomId()).collection('messages').doc(id).update({'isPinned': true}); }
            setState(() { isSelectionMode = false; selectedMsgIds.clear(); });
          }),
          IconButton(icon: const Icon(Icons.delete, color: Colors.white), onPressed: () => _showDeleteDialog(surface, text)),
        ],
      );
    }
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: text),
      titleSpacing: 0,
      title: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => UserInfoScreen(userId: widget.receiverUserId))),
        child: Row(children: [
          CircleAvatar(backgroundColor: surface, child: Icon(widget.gender.toLowerCase() == 'female' ? Icons.face_3 : Icons.face, color: const Color(0xFF7C4DFF))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.receiverUserName, style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                if (isOtherUserTyping && !iHaveBlocked) const Text("typing...", style: TextStyle(color: Color(0xFF7C4DFF), fontSize: 12)),
              ],
            ),
          ),
        ]),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() => isSearching = !isSearching)),
        PopupMenuButton<String>(
          color: surface,
          onSelected: (v) async {
            if (v == 'block') {
              await _chatService.toggleBlockUser(widget.receiverUserId, !iHaveBlocked);

              await FirebaseFirestore.instance.collection('chat_rooms').doc(_getRoomId()).update({
                'lastMessage': iHaveBlocked ? "You unblocked this user" : "You blocked this user",
                'lastMessageTime': FieldValue.serverTimestamp(),
              });
            }
            if (v == 'clear') _chatService.clearChat(widget.receiverUserId);
          },
          itemBuilder: (c) => [
            PopupMenuItem(value: 'block', child: Text(iHaveBlocked ? "Unblock" : "Block", style: TextStyle(color: text))),
            PopupMenuItem(value: 'clear', child: Text("Clear Chat", style: TextStyle(color: text))),
          ],
        )
      ],
    );
  }

  Widget _buildInputArea(Color surface, Color text) => Container(
    padding: const EdgeInsets.all(10),
    child: Row(children: [
      IconButton(icon: Icon(Icons.emoji_emotions_outlined, color: text.withOpacity(0.5)), onPressed: () {
        focusNode.unfocus();
        setState(() => isEmojiVisible = !isEmojiVisible);
      }),
      Expanded(
          child: TextField(
              controller: _messageController,
              focusNode: focusNode,
              style: TextStyle(color: text),
              textInputAction: TextInputAction.send,
              onSubmitted: (value) => _sendMessage(),
              onChanged: (v) => _updateTypingStatus(v.isNotEmpty),
              decoration: InputDecoration(
                  hintText: "Message",
                  fillColor: surface,
                  filled: true,
                  hintStyle: TextStyle(color: text.withOpacity(0.3)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)
              )
          )
      ),
      const SizedBox(width: 5),
      CircleAvatar(backgroundColor: const Color(0xFF7C4DFF), child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: _sendMessage))
    ]),
  );

  Widget _buildEmojiPicker(Color bg) {
    return SizedBox(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) => _messageController.text += emoji.emoji,
        config: Config(
          height: 250,
          emojiViewConfig: EmojiViewConfig(backgroundColor: bg, columns: 7, emojiSizeMax: 32),
          categoryViewConfig: CategoryViewConfig(
            backgroundColor: bg,
            indicatorColor: const Color(0xFF7C4DFF),
            iconColorSelected: const Color(0xFF7C4DFF),
          ),
        ),
      ),
    );
  }

  Widget _buildBlockedUI(Color surface, Color text) => Container(
      padding: const EdgeInsets.all(15),
      color: surface,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text("You blocked this contact. ", style: TextStyle(color: text.withOpacity(0.5))),
        GestureDetector(
            onTap: () async {
              await _chatService.toggleBlockUser(widget.receiverUserId, false);

              await FirebaseFirestore.instance.collection('chat_rooms').doc(_getRoomId()).update({
                'lastMessage': "You unblocked this user",
                'lastMessageTime': FieldValue.serverTimestamp(),
              });
            },
            child: const Text("UNBLOCK", style: TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.bold)))
      ]));

  Widget _buildPinnedHeader(Color text) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chat_rooms').doc(_getRoomId()).collection('messages').where('isPinned', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
        var msg = snapshot.data!.docs.first;
        return Container(
            color: Colors.amber.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Row(children: [
              const Icon(Icons.push_pin, size: 16, color: Colors.amber),
              const SizedBox(width: 10),
              Expanded(child: Text(msg['message'], style: TextStyle(color: text.withOpacity(0.8)), maxLines: 1, overflow: TextOverflow.ellipsis)),
              IconButton(icon: Icon(Icons.close, size: 16, color: text.withOpacity(0.5)), onPressed: () => msg.reference.update({'isPinned': false}))
            ]));
      },
    );
  }

  Widget _buildReplyPreview(Color surface, Color text) => Container(
      padding: const EdgeInsets.all(8),
      color: surface,
      child: Row(children: [
        const Icon(Icons.reply, size: 20, color: Color(0xFF7C4DFF)),
        const SizedBox(width: 10),
        Expanded(child: Text(replyingToMessage ?? "", style: TextStyle(color: text.withOpacity(0.7)), maxLines: 1, overflow: TextOverflow.ellipsis)),
        IconButton(icon: Icon(Icons.close, size: 18, color: text.withOpacity(0.5)), onPressed: () => setState(() => replyingToMessage = null))
      ])
  );

  void _showDeleteDialog(Color surface, Color text) {
    if (selectedMsgIds.isEmpty) return;
    FirebaseFirestore.instance.collection('chat_rooms').doc(_getRoomId()).collection('messages').doc(selectedMsgIds.first).get().then((doc) {
      bool isMyMsg = doc.exists && doc['senderId'] == _auth.currentUser!.uid;
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          backgroundColor: surface,
          title: Text("Delete Message?", style: TextStyle(color: text)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            TextButton(onPressed: () async {
              for (var id in selectedMsgIds) {
                await _chatService.deleteMessage(widget.receiverUserId, id, false);
              }

              _updateHomeLastMessage();
              setState(() { isSelectionMode = false; selectedMsgIds.clear(); });
              Navigator.pop(context);
            }, child: const Text("DELETE FOR ME")),
            if (isMyMsg)
              TextButton(onPressed: () async {
                for (var id in selectedMsgIds) {
                  await _chatService.deleteMessage(widget.receiverUserId, id, true);
                  _updateLastMessageAfterDelete(id);
                }
                setState(() { isSelectionMode = false; selectedMsgIds.clear(); });
                Navigator.pop(context);
              }, child: const Text("DELETE FOR EVERYONE", style: TextStyle(color: Colors.red))),
          ],
        ),
      );
    });
  }
}