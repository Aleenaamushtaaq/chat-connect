import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _verificationId;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;


  Future<UserCredential> signIn(String email, String password) async {
    try {
      UserCredential credential =
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      User? user = credential.user;
      await user?.reload();
      user = _auth.currentUser;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        await _auth.signOut();
        throw Exception(
            "Your email is not verified. Verification link sent to your inbox.");
      }

      if (user != null && user.emailVerified) {
        await _firestore.collection('users').doc(user.uid).update({
          'isVerified': true,
        });
      }

      await updateUserStatus(true);
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception("No user found with this email.");
        case 'wrong-password':
          throw Exception("Incorrect password.");
        case 'invalid-email':
          throw Exception("Invalid email format.");
        default:
          throw Exception(e.message ?? "Login failed.");
      }
    }
  }


  Future<void> signUp(
      String email, String password, String name, String gender) async {
    try {
      final trimmedEmail = email.trim();

      UserCredential credential =
      await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password.trim(),
      );

      await credential.user!.sendEmailVerification();

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'email': trimmedEmail,
        'name': name.trim(),
        'gender': gender,
        'isVerified': false,
        'about': "Hey there! I am using this chat app.",
        'phone': '',
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
        'showOnline': true,
        'showAbout': true,
        'blockedUsers': [],
      });

      await _auth.signOut();

      throw Exception(
          "Verification email sent. Please verify your email before logging in.");
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception("This email is already registered.");
        case 'invalid-email':
          throw Exception("Invalid email address.");
        case 'weak-password':
          throw Exception("Password must be at least 6 characters.");
        default:
          throw Exception(e.message ?? "Registration failed.");
      }
    }
  }


  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }


  Future<void> updateEmail(String newEmail, String currentPassword) async {
    await _reauthenticate(currentPassword);
    await _auth.currentUser!.verifyBeforeUpdateEmail(newEmail);
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .update({'email': newEmail});
    notifyListeners();
  }


  Future<void> _reauthenticate(String password) async {
    final credential = EmailAuthProvider.credential(
      email: _auth.currentUser!.email!,
      password: password,
    );
    await _auth.currentUser!.reauthenticateWithCredential(credential);
  }


  Future<void> updateUserStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return;

    final showOnline = doc.get('showOnline') ?? true;

    await _firestore.collection('users').doc(user.uid).update({
      'isOnline': showOnline ? isOnline : false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .update(data);
    notifyListeners();
  }

  Future<void> updatePrivacy(String field, bool value) async {
    final uid = _auth.currentUser!.uid;
    await _firestore.collection('users').doc(uid).update({field: value});
    notifyListeners();
  }


  Future<String?> verifyPhoneNumber(String phone) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential cred) async {
          // Auto-signin
          final userCred = await _auth.signInWithCredential(cred);
          await _createFirestoreUser(userCred.user!);
        },
        verificationFailed: (FirebaseAuthException e) {
          throw Exception(e.message ?? "Phone verification failed.");
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> verifyOTP(String otp, String name, String gender) async {
    try {
      if (_verificationId == null) throw Exception("OTP expired.");

      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final userCred = await _auth.signInWithCredential(cred);
      await _createFirestoreUser(userCred.user!, name: name, gender: gender);

      notifyListeners();
      return null;
    } catch (e) {
      return "Invalid or expired OTP.";
    }
  }

  Future<void> _createFirestoreUser(User user, {String name = "User", String gender = "unknown"}) async {
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'gender': gender,
        'isVerified': true,
        'about': "Available",
        'showOnline': true,
        'showAbout': true,
        'blockedUsers': [],
      });
    }
  }


  Future<void> signOut() async {
    await updateUserStatus(false);
    await _auth.signOut();
    notifyListeners();
  }
}
