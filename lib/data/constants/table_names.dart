class ChatTable {
  static const String tableName = 'chats';
  static const String colId = 'id';
  static const String colUserId = 'user_id';
  //TODO: Future implementation of groups
  static const String colGroupId = "group_id";
  static const String colCreatedAt = "created_at";
}

class MessageTable {
  static const String tableName = 'messages';
  static const String colId = 'id';
  static const String colRecipient = 'recepient';
  static const String colChatId = 'chat_id';
  static const String colExecutedAt = "executed_at";
  static const String colCreatedAt = "created_at";
  static const String colSender = 'sender';
  static const String colContents = 'contents';
  static const String colReceipt = 'receipt';
}

class UserTable {
  static const String tableName = "users";
  static const String colId = "id";
  static const String colUsername = 'username';
  static const String colEmail = "email";
  static const String colName = "name";
  static const String photoUrl = "photo_url";
  static const String privateKeyJwb = "private_key_jwb";
}
