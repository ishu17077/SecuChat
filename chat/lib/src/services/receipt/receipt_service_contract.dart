import 'package:chat/src/models/receipt.dart';
import 'package:chat/src/models/user.dart';

abstract class IReceiptService {
  Future<Receipt> send(Receipt receipt);
  Stream<Receipt> receipts({User user});
  void dispose();
}
