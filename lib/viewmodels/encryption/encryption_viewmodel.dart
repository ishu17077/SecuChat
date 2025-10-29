import 'package:chat/chat.dart';
import 'package:flutter/cupertino.dart';
import 'package:secuchat/cache/local_cache.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:secuchat/viewmodels/encryption/helpers/encryption_key.dart';

class EncryptionViewmodel {
  final IEncryption encryption;
  final IUserService _userService;
  final IDataSource _dataSource;
  final ILocalCache _localCache;
  final List<EncryptionKey> keys = List.empty(growable: true);

  String? _privatKey;
  String? publicKey;

  EncryptionViewmodel(
      this.encryption, this._dataSource, this._localCache, this._userService);

//TODO:n Impl this thing, this is wrong on so many levels
  Future<String> generateKeys() async {
    final jwbKeys = await encryption.generateKeys();
    _privatKey = jwbKeys.privateKey;
    await _localCache.encryptSave('PRIVATE_KEY', data: jwbKeys.privateKey);
    publicKey = jwbKeys.publicKey;
    return jwbKeys.publicKey;
  }

//TODO:n Impl this thing, this is wrong on so many levels
  Future<void> preCacheKeys() async {
    try {
      // Get private key first
      _privatKey ??= await _localCache.encryptGet('PRIVATE_KEY');
      if (_privatKey == null) {
        debugPrint('Private key not found in cache');
        return;
      }
      final chats = await _dataSource.findAllChats();
      if (chats.isEmpty) return;
      final chatsBatch = chats.take(10).toList();
      final futureUsers =
          chatsBatch.map((chat) => _userService.fetchUserId(chat.userId));
      final users = await Future.wait(futureUsers);
      for (final user in users) {
        if (user != null && !keys.any((key) => key.userId == user.id)) {
          try {
            final encryptionKey = EncryptionKey(
                user.id!,
                await encryption.deriveKey(JsonWebKeyPair(
                    privateKey: _privatKey!, publicKey: user.publicKeyJwb!)));
            keys.add(encryptionKey);
          } catch (e) {
            debugPrint('Failed to generate key for user ${user.id}: $e');
          }
        }
      }

      debugPrint('Precached ${keys.length} encryption keys');
    } catch (e) {
      debugPrint('Error in preCacheKeys: $e');
    }
  }

  Future<EncryptionKey?> getChatAcmKey(String userId) async {
    _privatKey ??= await _localCache.encryptGet('PRIVATE_KEY');
    for (final key in keys) {
      if (key.userId == userId) return key;
    }
    try {
      User? user = await _dataSource.findUser(userId);
      if (user == null) {
        user = await _userService.fetchUserId(userId);
      } else {
        //TODO: Impl isolates
        _checkKeyUpdatesInBackground(userId, user);
      }
      final encryptionKey = EncryptionKey(
          userId,
          await encryption.deriveKey(JsonWebKeyPair(
              privateKey: _privatKey!, publicKey: user!.publicKeyJwb!)));
      keys.add(encryptionKey);
      return encryptionKey;
    } catch (_) {
      return null;
    }
  }

  void _checkKeyUpdatesInBackground(String userId, User? user) {
    _userService.fetchUserId(userId).then((value) async {
      final aesGcmKey = await encryption.deriveKey(JsonWebKeyPair(
          privateKey: _privatKey!, publicKey: user!.publicKeyJwb!));
      keys.firstWhere((element) => element.userId == userId).secretKey =
          aesGcmKey;
    });
  }
}
