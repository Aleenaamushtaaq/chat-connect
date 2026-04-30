import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatService with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;


  String _getChatRoomId(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    return ids.join('_');
  }


  Future<void> sendMessage(String receiverId, String message, {String? replyToMsg}) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatRoomId = _getChatRoomId(currentUserId, receiverId);
    final Timestamp now = Timestamp.now();

    try {
      DocumentSnapshot receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      List blockedByReceiver = (receiverDoc.data() as Map<String, dynamic>?)?['blockedUsers'] ?? [];
      bool isSenderBlocked = blockedByReceiver.contains(currentUserId);



      await _firestore.collection('chat_rooms').doc(chatRoomId).collection('messages').add({
        'senderId': currentUserId,
        'receiverId': receiverId,
        'message': message,
        'timestamp': now,
        'replyTo': replyToMsg,
        'isPinned': false,
      });

      Map<String, dynamic> roomUpdate = {
        'members': FieldValue.arrayUnion([currentUserId, receiverId]),
        'lastChatBy': FieldValue.arrayUnion([currentUserId, receiverId]),
        'timestamp': now,
        'lastMessage': message,
      };

      if (!isSenderBlocked) {
        roomUpdate['unreadCount_$receiverId'] = FieldValue.increment(1);
      }

      await _firestore.collection('chat_rooms').doc(chatRoomId).set(roomUpdate, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Send message error: $e");
    }
  }

  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    String chatRoomId = _getChatRoomId(userId, otherUserId);
    return _firestore.collection('chat_rooms').doc(chatRoomId).collection('messages').orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> markMessagesAsRead(String otherUserId) async {
    final String currentUserId = _auth.currentUser!.uid;
    final String chatRoomId = _getChatRoomId(currentUserId, otherUserId);
    try {
      await _firestore.collection('chat_rooms').doc(chatRoomId).set({
        'unreadCount_$currentUserId': 0,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Mark as read error: $e");
    }
  }

  Future<void> clearChat(String otherUserId) async {
    final currentUserId = _auth.currentUser!.uid;
    final chatRoomId = _getChatRoomId(currentUserId, otherUserId);
    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'chatClearedAt_$currentUserId': Timestamp.now(),
      'lastMessage': "",
    });

    final messages = await _firestore.collection('chat_rooms').doc(chatRoomId).collection('messages').get();
    WriteBatch batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.update(doc.reference, {'deletedBy': FieldValue.arrayUnion([currentUserId])});
    }
    await batch.commit();
  }


  Future<void> deleteFullChat(String otherUserId) async {
    final currentUserId = _auth.currentUser!.uid;
    final chatRoomId = _getChatRoomId(currentUserId, otherUserId);
    await clearChat(otherUserId);
    await _firestore.collection('chat_rooms').doc(chatRoomId).update({
      'lastChatBy': FieldValue.arrayRemove([currentUserId]),
      'lastMessage': "",
      'unreadCount_$currentUserId': 0,
    });
    notifyListeners();
  }


  Future<void> toggleArchiveChat(String otherUserId, bool archive) async {
    final currentUserId = _auth.currentUser!.uid;
    final chatRoomId = _getChatRoomId(currentUserId, otherUserId);
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'archivedBy': archive ? FieldValue.arrayUnion([currentUserId]) : FieldValue.arrayRemove([currentUserId])
    }, SetOptions(merge: true));
    notifyListeners();
  }


  Future<void> deleteMessage(String otherUserId, String messageId, bool forEveryone) async {
    final currentUserId = _auth.currentUser!.uid;
    final chatRoomId = _getChatRoomId(currentUserId, otherUserId);

    if (forEveryone==true) {
      await _firestore.collection('chat_rooms').doc(chatRoomId).collection('messages').doc(messageId).update({
        'message': '🚫 This message was deleted',
      });
    } else {
      await _firestore.collection('chat_rooms').doc(chatRoomId).collection('messages').doc(messageId).update({
        'deletedBy': FieldValue.arrayUnion([currentUserId])
      });
    }
    notifyListeners();
  }

  Future<void> toggleBlockUser(String otherUserId, bool isBlock) async {
    final currentUserId = _auth.currentUser!.uid;

    await _firestore.collection('users').doc(currentUserId).set({
      'blockedUsers': isBlock
          ? FieldValue.arrayUnion([otherUserId])
          : FieldValue.arrayRemove([otherUserId])
    }, SetOptions(merge: true));

    notifyListeners();
  }
}