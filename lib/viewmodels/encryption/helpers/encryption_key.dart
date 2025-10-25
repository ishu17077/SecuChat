import 'package:webcrypto/webcrypto.dart';

final class EncryptionKey {
  final String userId;
  AesGcmSecretKey secretKey;

  EncryptionKey(this.userId, this.secretKey);
}
