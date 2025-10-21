import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:chat/chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  //? Dummy Message
  // var random = Random.secure();
  final EncryptionService _encryptionService = EncryptionService();
  // print(_ivList.toString());
  IV _iv = IV.fromSecureRandom(16);
  print(_iv.toString());
  Message message = Message(
    to: 'Lalaba@testmail.com',
    time: DateTime.now(),
    iv: _iv,
    from: 'anon@testmail.com',
    contents: 'Hey?? How you doing',
  );
  final messageSendJson = message.toJSON();
  final messageSend = Message.fromJSON(messageSendJson);
  final jwb = await _encryptionService.generateKeys();
  final deriveKeyVar = await _encryptionService.deriveKey(jwb);
  final Message messageReceived = Message.fromJSON({
    'from': 'anon@testmail.com',
    'to': 'Lalaba@testmail.com',
    'contents': await _encryptionService.encrypt(
      'Hey?? How you doing',
      _iv.bytes,
      deriveKeyVar,
    ),
    'iv': _iv.base64,
    'time': Timestamp.now(),
    'chat_id': 12212,
  });
  // final Uint8List iv = Uint8List.fromList(message.chatId.codeUnits);

  //? Self-message where both reciever and sender is me

  test('Check for message encryption and decryption', () async {
    print("\x1B[34mMessage Contents: ${message.contents}\x1B[0m");
    print(
      "\x1B[36mEncrypting with public key: \x1B[35m${jwb.publicKey}\x1B[0m ",
    );
    final String encryptedMessageContents = await _encryptionService.encrypt(
      messageSend.contents,
      _iv.bytes,
      deriveKeyVar,
    );
    print("\x1B[33mEncrypted message: $encryptedMessageContents\x1B[0m");
    print(
      "\x1B[36mDecrypting message \'$encryptedMessageContents\' with private key: \x1B[31m${jwb.privateKey}\x1B[0m ",
    );
    final String decryptedMessageContents = await _encryptionService.decrypt(
      encryptedMessageContents,
      messageReceived.iv!.bytes,
      deriveKeyVar,
    );
    print("\x1B[32mDecrypted message: $decryptedMessageContents\x1B[0m");
    expectLater(decryptedMessageContents, messageSend.contents);
  });
}
