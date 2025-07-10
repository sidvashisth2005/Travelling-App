import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/place.dart';

class UserTripsService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>> getUserTrips(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return {'wishlist': [], 'scheduled': [], 'completed': []};
    final data = doc.data() ?? {};
    return {
      'wishlist': (data['wishlist'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      'scheduled': (data['scheduled'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
      'completed': (data['completed'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
    };
  }

  

  static Future<void> setUserTrips(String uid, {
    List<Map<String, dynamic>>? wishlist,
    List<Map<String, dynamic>>? scheduled,
    List<Map<String, dynamic>>? completed,
  }) async {
    final data = <String, dynamic>{};
    if (wishlist != null) data['wishlist'] = wishlist;
    if (scheduled != null) data['scheduled'] = scheduled;
    if (completed != null) data['completed'] = completed;
    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  static Future<void> updateWishlist(String uid, List<Map<String, dynamic>> wishlist) async {
    await _firestore.collection('users').doc(uid).set({'wishlist': wishlist}, SetOptions(merge: true));
  }

  static Future<void> updateScheduled(String uid, List<Map<String, dynamic>> scheduled) async {
    await _firestore.collection('users').doc(uid).set({'scheduled': scheduled}, SetOptions(merge: true));
  }

  static Future<void> updateCompleted(String uid, List<Map<String, dynamic>> completed) async {
    await _firestore.collection('users').doc(uid).set({'completed': completed}, SetOptions(merge: true));
  }

  // Helpers to convert Place <-> Map
  static Map<String, dynamic> placeToMap(Place place) => {
    'name': place.name,
    'description': place.description,
    'imageUrl': place.imageUrl,
    'latitude': place.latitude,
    'longitude': place.longitude,
    'address': place.address,
  };

  static Place mapToPlace(Map<String, dynamic> map) => Place(
    name: map['name'] ?? '',
    description: map['description'] ?? '',
    imageUrl: map['imageUrl'] ?? '',
    latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
    longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
    address: map['address'] ?? '',
  );
} 