import 'dart:convert';
import 'package:chat/src/services/encryption/encryption_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:webcrypto/webcrypto.dart';

final class EncryptionService implements IEncryption {
  const EncryptionService();

  @override
  Future<String> decrypt(
    String encryptedText,
    Uint8List? iv,
    AesGcmSecretKey aesGcmSecretKey,
  ) async {
    assert(iv != null, "IV cannot be null in future impl");
    if (iv == null) {
      return encryptedText;
    }
    final messageContentsBytes = Uint8List.fromList(encryptedText.codeUnits);
    try {
      final decryptedMessageContentBytes = await aesGcmSecretKey.decryptBytes(
        messageContentsBytes,
        iv,
      );
      final decryptedMessage = String.fromCharCodes(
        decryptedMessageContentBytes,
      );
      return utf8.decode(decryptedMessage.codeUnits);
    } catch (e) {
      debugPrint("Error: Cannot decrypt message");
      throw DecryptionException(e.toString());
    }
  }

  @override
  Future<AesGcmSecretKey> deriveKey(JsonWebKeyPair jsonWebKeyPair) async {
    final publicKey = await EcdhPublicKey.importJsonWebKey(
      json.decode(jsonWebKeyPair.publicKey),
      jsonWebKeyPair.ellipticCurve,
    );

    final privateKey = await EcdhPrivateKey.importJsonWebKey(
      json.decode(jsonWebKeyPair.privateKey),
      jsonWebKeyPair.ellipticCurve,
    );
    final derivedBits = await privateKey.deriveBits(256, publicKey);
    return AesGcmSecretKey.importRawKey(derivedBits);
  }

  @override
  Future<String> encrypt(
    String text,
    Uint8List? iv,
    AesGcmSecretKey aesGcmSecretKey,
  ) async {
    assert(iv != null, "IV cannot be null in future impl");
    if (iv == null) {
      return text;
    }

    final messageContentBytes = Uint8List.fromList(utf8.encode(text));

    final encryptedMessageContentsBytes = await aesGcmSecretKey.encryptBytes(
      messageContentBytes,
      iv,
    );
    final encryptedMessageContents = String.fromCharCodes(
      encryptedMessageContentsBytes,
    );

    return encryptedMessageContents;
  }

  @override
  Future<JsonWebKeyPair> generateKeys() async {
    var eCurve = EllipticCurve.p256;
    final keyPair = await EcdhPrivateKey.generateKey(eCurve);
    return JsonWebKeyPair(
      privateKey: jsonEncode(await keyPair.privateKey.exportJsonWebKey()),
      publicKey: jsonEncode(await keyPair.publicKey.exportJsonWebKey()),
      ellipticCurve: eCurve,
    );
  }
}
