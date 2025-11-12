import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class MiscellaneousViewmodel {
  static const int _ivLength = 12;
  static const int _saltLength = 16;
  static const int _iterations = 1000;
  static const int _keyLength = 32;
  static Uint8List encrypt(String password, String userId, Uint8List bytes) {
    final salt = generateRandomBytes(_saltLength);
    final iv = IV.fromSecureRandom(_ivLength);
    final key = Key.fromUtf8("$password$userId").stretch(
      _keyLength,
      salt: salt,
      iterationCount: _iterations,
    );
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);
    final result = Uint8List(_saltLength + _ivLength + encrypted.bytes.length);
    result.setRange(0, _saltLength, salt);
    result.setRange(_saltLength, _saltLength + _ivLength, iv.bytes);
    result.setRange(_saltLength + _ivLength, result.length, encrypted.bytes);

    return result;
  }

  static Uint8List decrypt(String password, String userId, Uint8List bytes) {
    try {
      final salt = bytes.sublist(0, _saltLength);
      final ivBytes = bytes.sublist(_saltLength, _saltLength + _ivLength);
      final ciphertext = bytes.sublist(_saltLength + _ivLength);
      final iv = IV(ivBytes);

      final key = Key.fromUtf8("$password$userId").stretch(
        _keyLength,
        salt: salt,
        iterationCount: _iterations,
      );

      final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
      final decryptedData =
          encrypter.decryptBytes(Encrypted(ciphertext), iv: iv);

      return Uint8List.fromList(decryptedData);
    } catch (e) {
      print('Decryption failed: $e');
      throw Exception(
          'Could not decrypt data. Incorrect password or corrupt data.');
    }
  }
}
