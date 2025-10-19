import 'package:chat/chat.dart';
import 'package:flutter/cupertino.dart';
import 'package:secuchat/cache/local_cache.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:webcrypto/webcrypto.dart';

class EncryptionViewmodel {
  final IEncryption _encryption;
  final IDataSource _dataSource;
  final ILocalCache _localCache;
  List<EncrytionKey> keys = List.empty(growable: true);

  String? _privatKey;
  String? publicKey;

  EncryptionViewmodel(this._encryption, this._localCache, this._dataSource);

//TODO:n Impl this thing, this is wrong on so many levels
  Future<void> setKeys() async {
    if (_privatKey != null || _privatKey!.isNotEmpty) {
      return;
    }
    _privatKey = await _localCache.encryptGet("PRIVATE_KEY");
    try {
      publicKey = User.fromJSON(await _localCache.fetch("USER")).publicKeyJwb;
    } catch (e) {
      debugPrint(e.toString());
    }
    if (_privatKey!.isEmpty || publicKey == null) {
      final jwbkeypair = await _encryption.generateKeys();
      final userMap = _localCache.fetch("USER");
      final User user = User.fromJSON(userMap);
      user.publicKeyJwb = jwbkeypair.publicKey;
      await _localCache.save("USER", data: user.toJSON());
      await _localCache.encryptSave("PRIVATE_KEY", data: jwbkeypair.privateKey);
      _privatKey = jwbkeypair.privateKey;
    }
  }

  void getAcmKeys() {}
}

class EncrytionKey {
  final String userId;
  final AesGcmSecretKey secretKey;

  EncrytionKey(this.userId, this.secretKey);
}
