import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/user/user_service_contract.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserService implements IUserService {
  final FirebaseFirestore _firebaseFirestore;

  const UserService(this._firebaseFirestore);

  @override
  Future<User> connect(User user) async {
    assert(user.id != null, "User id cannot be null");
    final userPresent = await fetch(user.id!);
    user.active = true;
    user.lastSeen = DateTime.now();
    if (userPresent == null) {
      return await _registerUserToDatabase(user);
    }

    var userMap = userPresent.toJSON();

    final DocumentReference docRef = _firebaseFirestore
        .collection("users")
        .doc(userPresent.id!);
    await docRef.update(userMap);
    return userPresent;
  }

  @override
  Future<void> disconnect(User user) async {
    assert(user.id != null, "User id cannot be null");
    user.active = false;
    user.lastSeen = DateTime.now();
    Map<String, dynamic> userMap = user.toJSON();

    final DocumentReference docRef = _firebaseFirestore
        .collection("users")
        .doc(user.id);

    await docRef.update(userMap);
    _firebaseFirestore.terminate();
  }

  @override
  Future<User?> fetch(String id) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _firebaseFirestore
        .collection("users")
        .doc(id)
        .get();
    if (!doc.exists || doc.data() == null) {
      debugPrint("Unable to find user");
      return null;
    }
    if (doc.data() == null) return null;
    return _mapIdToUser(id, doc.data()!);
  }

  @override
  Future<List<User>> online() async {
    final userDocs = await _firebaseFirestore
        .collection("users")
        .where("active", isEqualTo: true)
        .get();

    List<User> users = userDocs.docChanges.map((element) {
      return _mapIdToUser(element.doc.id, element.doc.data()!);
    }).toList();

    return users;
  }

  User _mapIdToUser(String id, Map<String, dynamic> userMap) {
    return User.fromJSON({"id": id, ...userMap});
  }

  Future<User> _registerUserToDatabase(User user) async {
    await _firebaseFirestore
        .collection("users")
        .doc(user.id)
        .set(user.toJSON());
    return _mapIdToUser(user.id!, user.toJSON());
  }
}
