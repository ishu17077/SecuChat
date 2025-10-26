import 'package:chat/chat.dart';
import 'package:secuchat/data/constants/table_names.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:secuchat/models/chat.dart';
import 'package:secuchat/models/local_message.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteDatasource implements IDataSource {
  final Database _db;
  const SqfliteDatasource(this._db);

  @override
  Future<int> addChat(Chat chat) async {
    int id = await _db.insert(ChatTable.tableName, chat.toJSON(),
        conflictAlgorithm: ConflictAlgorithm.rollback);
    return id;
  }

  @override
  Future<int> addMessage(LocalMessage message) async {
    assert(message.chatId != null,
        "Chat Id cannot be null while inserting messages");

    final messageMap = message.toJSON();
    int res = await _db.insert(MessageTable.tableName, messageMap,
        conflictAlgorithm: ConflictAlgorithm.rollback);
    return res;
  }

  @override
  Future<void> deleteChat(String chatId) async {
    final batch = _db.batch();
    batch.delete(MessageTable.tableName,
        where: "${MessageTable.colChatId} = ?", whereArgs: [chatId]);
    batch.delete(ChatTable.tableName, where: "id = ?", whereArgs: [chatId]);

    await batch.commit(noResult: true);
  }

  @override
  Future<List<Chat>> findAllChats() async {
    return await _db.transaction((txn) async {
      final chatsWithLatestMessage = await txn.rawQuery(
          """SELECT ${MessageTable.tableName}.*,${UserTable.tableName}.* FROM
      (SELECT ${MessageTable.colChatId},
      ${MessageTable.colExecutedAt}, 
      MAX(created_at) AS created_at
      FROM ${MessageTable.tableName} GROUP BY chat_id) AS latest_messages
      INNER JOIN ${MessageTable.tableName} 
      ON ${MessageTable.tableName}.${MessageTable.colChatId} = latest_messages.${MessageTable.colChatId}
      AND ${MessageTable.tableName}.${MessageTable.colExecutedAt} = latest_messages.${MessageTable.colExecutedAt}
      INNER JOIN ${ChatTable.tableName}
      ON ${ChatTable.tableName}.${ChatTable.colId} = latest_messages.${MessageTable.colChatId}  
      INNER JOIN ${UserTable.tableName}
      ON ${UserTable.tableName}.${UserTable.colId} = ${ChatTable.tableName}.${ChatTable.colUserId}
      ORDER BY ${MessageTable.tableName}.${MessageTable.colCreatedAt} DESC""");

      if (chatsWithLatestMessage.isEmpty) {
        return [];
      }

      final chatsWithUnreadMessages =
          await txn.rawQuery("""SELECT chat_id, COUNT(*) 
      as unread FROM messages
      WHERE receipt = ?
      GROUP BY chat_id""", ["delivered"]);

      return chatsWithLatestMessage.map((element) {
        final int unread = chatsWithUnreadMessages.firstWhere(
          (ele) => element["chat_id"] == ele["chat_id"],
          orElse: () => {"unread": 0},
        )["unread"] as int;
        final User user = User.fromJSON(element);
        final Chat chat = Chat.fromJSON({
          "id": element["chat_id"],
          "user_id": user.id!,
        });

        chat.unread = unread;
        chat.from = user;
        chat.mostRecent = LocalMessage.fromJSON(element);
        return chat;
      }).toList();
    });
  }

  @override
  Future<Chat?> findChat({String? chatId, String? userId}) async {
    assert(chatId != null || userId != null,
        "Either chatId of userId must be present");
    return await _db.transaction((txn) async {
      final selectedId = chatId ?? userId;
      final selectedIdColumn =
          chatId != null ? ChatTable.colId : ChatTable.colUserId;
      final listOfChatMaps = await txn.query(
        ChatTable.tableName,
        where: "$selectedIdColumn = ?",
        whereArgs: [selectedId],
        limit: 1,
      );
      if (listOfChatMaps.isEmpty) {
        return null;
      }

      chatId ??= (listOfChatMaps.first["id"] as int).toString();
      final unread = Sqflite.firstIntValue(await txn.rawQuery(
        "SELECT COUNT(*) FROM ${MessageTable.tableName} WHERE ${MessageTable.colChatId} = ? AND ${MessageTable.colReceipt} = ?",
        [chatId, ReceiptStatus.delivered.value()],
      ));
      final mostRecentMessage = await txn.query(
        MessageTable.tableName,
        where: "${MessageTable.colChatId}  = ?",
        orderBy: "${MessageTable.colCreatedAt} DESC",
        limit: 1,
        whereArgs: [chatId],
      );
      final chat = Chat.fromJSON(listOfChatMaps.first);
      if (listOfChatMaps.first['user_id'] != null) {
        final userMap = (await txn.query(
          UserTable.tableName,
          where: "${UserTable.colId} = ?",
          whereArgs: [listOfChatMaps.first["user_id"]!],
          limit: 1,
        ))
            .first;
        User user = User.fromJSON(userMap);
        chat.from = user;
        chat.unread = unread ?? 0;
        chat.mostRecent = mostRecentMessage.isNotEmpty
            ? LocalMessage.fromJSON(mostRecentMessage.first)
            : null;
      }

      return chat;
    });
  }

  @override
  Future<List<LocalMessage>> findMessages(String chatId) async {
    return await _db.transaction((txn) async {
      final messages = await txn.query(
        MessageTable.tableName,
        where: "${MessageTable.colChatId} = ?",
        orderBy: "${MessageTable.colCreatedAt} DESC",
        whereArgs: [chatId],
      );

      return messages
          .map((messageMap) => LocalMessage.fromJSON(messageMap))
          .toList();
    });
  }

  @override
  Future<void> updateMessage(LocalMessage message) async {
    await _db.update(MessageTable.tableName, message.toJSON(),
        where: "id = ?", whereArgs: [message.message.id]);
  }

  @override
  Future<void> updateMessageReceipt(
      String messageId, ReceiptStatus status) async {
    await _db.update(MessageTable.tableName, {"receipt": status.value()},
        where: "${MessageTable.colServerId} = ?",
        whereArgs: [messageId],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<User?> findUser(String userId) async {
    final userMaps = await _db.query(UserTable.tableName,
        where: "${UserTable.colId} = ?", whereArgs: [userId], limit: 1);
    if (userMaps.isEmpty) {
      return null;
    }
    return User.fromJSON(userMaps.first);
  }

  @override
  Future<int> addUser(User user) async {
    //! ERROR PRONE due to extra columns, if that happens, please rectify broooooo!
    Map<String, dynamic> userMap = user.toJSON();
    userMap.remove("last_seen");
    userMap.remove("active");

    int userId = await _db.insert(UserTable.tableName, userMap,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return userId;
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _db.delete(
      UserTable.tableName,
      where: "${UserTable.colId} = ?",
      whereArgs: [userId],
    );
  }

  @override
  Future<void> updateUser(User user) async {
    final userMap = user.toJSON();
    userMap.remove('last_seen');
    userMap.remove('active');
    await _db.update(UserTable.tableName, userMap,
        where: "${UserTable.colId} = ?", whereArgs: [user.id]);
  }
}
