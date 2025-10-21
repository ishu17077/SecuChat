import 'dart:async';

import 'package:chat/chat.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebaseAuth;
import 'package:flutter/foundation.dart';
import 'package:secuchat/cache/local_cache.dart';
import 'package:secuchat/viewmodels/encryption/encryption_viewmodel.dart';

class AuthViewModel {
  final IUserService _userService;
  final ILocalCache _localCache;
  final EncryptionViewmodel encryptionViewmodel;
  final firebaseAuth.FirebaseAuth auth;

  const AuthViewModel(
      this.auth, this._userService, this._localCache, this.encryptionViewmodel);

  User? get signedInUser {
    User user;
    if (auth.currentUser == null) {
      signOut();
      return null;
    }
    try {
      final map = _localCache.fetch("USER");
      final res = map.isEmpty;
      if (res) {
        signOut();
        return null;
      }
      user = User.fromJSON(map);
    } catch (e) {
      signOut();
      return null;
    }
    return user;
  }

  Stream<bool> get isSignedIn {
    return auth.authStateChanges().map(
      (user) {
        return user != null ? true : false;
      },
    );
  }

  Future<User?> connectUser(User user) async {
    user.active = true;
    user.lastSeen = DateTime.now();
    //TODO: IMpl private key
    // final privateKey = await _localCache.encryptGet('private_key');
    // if (user.publicKeyJwb == null ||
    //     user.publicKeyJwb!.isEmpty ||
    //     privateKey.isEmpty) {
    //   final jwkPair = await _encryption.generateKeys();
    //   user.publicKeyJwb = jwkPair.publicKey;
    //   await _localCache.encryptSave('PRIVATE_KEY', data: jwkPair.privateKey);
    // }
    try {
      final connectedUser = await _userService.connect(user);
      await _localCache.save("USER", data: connectedUser.toJSON());

      return connectedUser;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<bool> disconnectUser(User user) async {
    user.active = true;
    user.lastSeen = DateTime.now();
    try {
      await _userService.disconnect(user);
      await _localCache.save("USER", data: user.toJSON());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    _localCache.clear("USER");
    _localCache.clear("PRIVATE_KEY");
    await auth.signOut();
  }
}
