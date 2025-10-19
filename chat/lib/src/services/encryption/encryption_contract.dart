import 'dart:typed_data';

import 'package:webcrypto/webcrypto.dart';

abstract class IEncryption {
  //TODO: Asymmetric impl
  Future<JsonWebKeyPair> generateKeys();
  Future<AesGcmSecretKey> deriveKey(JsonWebKeyPair jsonWebKeyPair);
  Future<String> encrypt(
    String text,
    Uint8List? iv,
    AesGcmSecretKey aesGcmSecretKey,
  );
  Future<String> decrypt(
    String encryptedText,
    Uint8List? iv,
    AesGcmSecretKey aesGcmSecretKey,
  );
}

class JsonWebKeyPair {
  final String publicKey;
  final String privateKey;
  final EllipticCurve ellipticCurve;

  const JsonWebKeyPair({
    required this.privateKey,
    required this.publicKey,
    this.ellipticCurve = EllipticCurve.p256,
  });
}

class DecryptionException implements Exception {
  final String message;
  DecryptionException(this.message);

  @override
  String toString() {
    // TODO: implement toString

    return "Decryption Error: $message";
  }
}

class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);

  @override
  String toString() {
    // TODO: implement toString

    return "Decryption Error: $message";
  }
}
