import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? lastError;

  // Observable state
  final _stateController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stateStream => _stateController.stream;

  Stream<Map<String, dynamic>?> get profileStream {
    if (currentUser == null) return Stream.value(null);
    return _firestore.collection('users').doc(currentUser!.uid).snapshots().map((doc) => doc.data());
  }

  // ─── Auth ───
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> login(String email, String password) async {
    try {
      lastError = null;
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _notify();
      return credential;
    } catch (e) {
      lastError = e.toString();
      debugPrint('Login error: $e');
      return null;
    }
  }

  Future<UserCredential?> signup({
    required String email,
    required String password,
    required String name,
    required String role,
    String? storeName,
    String? studentId,
  }) async {
    try {
      lastError = null;
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'name': name,
          'email': email,
          'role': role,
          'storeName': storeName,
          'studentId': studentId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _notify();
      return credential;
    } catch (e) {
      lastError = e.toString();
      debugPrint('Signup error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _notify();
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  // ─── Food Items ───
  Stream<List<Map<String, dynamic>>> getFoodItems() {
    return _firestore.collection('foodItems').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  Future<void> addFoodItem(Map<String, dynamic> item) async {
    await _firestore.collection('foodItems').add({
      ...item,
      'createdAt': FieldValue.serverTimestamp(),
      'isAvailable': true,
    });
  }

  Future<void> updateFoodItem(String id, Map<String, dynamic> item) async {
    await _firestore.collection('foodItems').doc(id).update(item);
  }

  Future<void> toggleFoodAvailability(String id, bool currentStatus) async {
    await _firestore.collection('foodItems').doc(id).update({
      'isAvailable': !currentStatus,
    });
  }

  Future<void> deleteFoodItem(String id) async {
    await _firestore.collection('foodItems').doc(id).delete();
  }

  // ─── Orders ───
  Future<void> placeOrder({
    required List<Map<String, dynamic>> cartItems,
    required double total,
    required String studentName,
    required String studentId,
  }) async {
    if (currentUser == null) return;

    final orderData = {
      'studentUiD': currentUser!.uid,
      'studentName': studentName,
      'studentId': studentId,
      'itemsDescription': cartItems.map((item) => '${item['quantity']}x ${item['title']}').join(', '),
      'cartItems': cartItems,
      'total': total,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'Pending',
    };

    await _firestore.collection('orders').add(orderData);
  }

  Stream<List<Map<String, dynamic>>> getOrders() {
    return _firestore
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              ...data,
            };
          }).toList();
        });
  }

  Stream<List<Map<String, dynamic>>> getOrdersForUser(String uid) {
    return _firestore
        .collection('orders')
        .where('studentUiD', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
          list.sort((a, b) {
            final tA = a['timestamp'];
            final tB = b['timestamp'];
            if (tA == null && tB == null) return 0;
            if (tA == null) return 1;
            if (tB == null) return -1;
            if (tA is Timestamp && tB is Timestamp) {
              return tB.compareTo(tA);
            }
            return 0;
          });
          return list;
        });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    final orderDoc = await _firestore.collection('orders').doc(orderId).get();
    if (orderDoc.exists) {
      final orderData = orderDoc.data()!;
      await _firestore.collection('notifications').add({
        'userId': orderData['studentUiD'],
        'title': 'Order Update',
        'message': 'Your order #${orderId.substring(0, 5)} is now $status',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'order_update',
      });
    }
  }

  // ─── Notifications ───
  Stream<List<Map<String, dynamic>>> getNotifications() {
    if (currentUser == null) return Stream.value([]);
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser!.uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
      list.sort((a, b) {
        final tA = a['timestamp'];
        final tB = b['timestamp'];
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        if (tA is Timestamp && tB is Timestamp) {
          return tB.compareTo(tA);
        }
        return 0;
      });
      return list;
    });
  }

  Future<void> markNotificationAsRead(String id) async {
    await _firestore.collection('notifications').doc(id).update({'isRead': true});
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> sendPasswordResetForStudentId(String studentId) async {
    final query = await _firestore
        .collection('users')
        .where('studentId', isEqualTo: studentId)
        .get();

    if (query.docs.isEmpty) {
      throw StateError('No account was found for that Student ID.');
    }

    final email = query.docs.first.data()['email'] as String?;
    if (email == null || email.isEmpty) {
      throw StateError('The account does not have a reset email address.');
    }

    await sendPasswordResetEmail(email);
  }

  // ─── Internal ───

  void _notify() {
    _stateController.add({
      'currentUser': currentUser,
    });
  }
}
