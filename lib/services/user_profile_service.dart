import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> saveUserProfile(String uid, {
    required String name,
    required String email,
    String? photoURL,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'photoURL': photoURL ?? '',
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  static Future<void> updateUserProfile(String uid, {
    String? name,
    String? photoURL,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (photoURL != null) data['photoURL'] = photoURL;
    if (data.isNotEmpty) {
      await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
    }
  }
} 