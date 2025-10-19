import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ILocalCache {
  Future<void> save(String key, {required Map<String, dynamic> data});
  Map<String, dynamic> fetch(String key);
  Future<void> clear(String key);
  Future<void> encryptSave(String key, {required String data});
  Future<String> encryptGet(String key);
}

class LocalCache implements ILocalCache {
  final EncryptedSharedPreferences _encryptedSharedPrefs;

  const LocalCache(this._encryptedSharedPrefs);

  @override
  Map<String, dynamic> fetch(String key) {
    final json = _encryptedSharedPrefs.prefs!.getString(key);
    final user = jsonDecode(json ?? "{}");
    if (user["last_seen"] != null) {
      user["last_seen"] = Timestamp.fromDate(DateTime.parse(user["last_seen"]));
    }
    return user;
  }

  @override
  Future<void> save(String key, {required Map<String, dynamic> data}) async {
    data["last_seen"] = (data["last_seen"] as DateTime).toIso8601String();
    final encodeData = jsonEncode(data);
    final result =
        await _encryptedSharedPrefs.prefs!.setString(key, encodeData);
    debugPrint('Save result for $key: $result');
  }

  @override
  Future<void> encryptSave(String key, {required String data}) async {
    await _encryptedSharedPrefs.setString(key, data);
  }

  @override
  Future<String> encryptGet(String key) async {
    try {
      return await _encryptedSharedPrefs.getString(key);
    } catch (e) {
      return '';
    }
  }

  @override
  Future<void> clear(String key) async {
    await _encryptedSharedPrefs.remove(key).onError(
      (error, stackTrace) {
        debugPrint(error.toString());
        return false;
      },
    );

    await _encryptedSharedPrefs.prefs!.remove(key).onError(
      (error, stackTrace) {
        debugPrint(error.toString());
        return false;
      },
    );
  }
}
