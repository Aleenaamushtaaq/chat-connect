import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String? email;
  final String? phoneNumber;
  final DateTime? createdAt;
  final String about;
  final bool isOnline;
  final List<String> blockedUsers;

  UserModel({
    required this.uid,
    required this.name,
    this.email,
    this.phoneNumber,
    this.createdAt,
    this.about = "Hey there! I am using ChatConnect",
    this.isOnline = false,
    this.blockedUsers = const [],
  });
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'],
      phoneNumber: data['phoneNumber'],
      createdAt: data['createdAt']?.toDate(),
      about: data['about'] ?? "Hey there! I am using ChatConnect",
      isOnline: data['isOnline'] ?? false,
      blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'about': about,
      'isOnline': isOnline,
      'blockedUsers': blockedUsers,
    };
  }
}