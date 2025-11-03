import 'package:secuchat/data/constants/table_names.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseFactory {
  //TODO: Future implementation, of how to delete message after being sent
  // static const String _colMessageIdFromServer = 'message_id_from_server';
  static LocalDatabaseFactory? _localDatabaseFactory;

  LocalDatabaseFactory._createInstance();

  factory LocalDatabaseFactory() {
    _localDatabaseFactory =
        _localDatabaseFactory ?? LocalDatabaseFactory._createInstance();
    return _localDatabaseFactory!;
  }

  static Database? _database;

  Future<Database> getDatabase() async {
    if (_database != null) {
      return _database!;
    }
    String databasePath = await getDatabasesPath();
    String dbPath = join(databasePath, "secuchat.db");
    _database = await openDatabase(dbPath,
        onCreate: _populateDb, version: 4, onUpgrade: _upgradeDb);
    return _database!;
  }

  Future<void> _populateDb(Database db, int version) async {
    await _createChatTable(db);
    await _createMessageTable(db);
    await _createUserTable(db);
    await _createIndices(db);
  }

  Future<void> _upgradeDb(Database db, int oldVer, int newVer) async {
    if (oldVer == 2 && newVer == 3) {
      await db.execute(
          """ALTER TABLE ${MessageTable.tableName} ADD COLUMN ${MessageTable.colServerId} TEXT""");
    }
    if (oldVer == 3 && newVer == 4) {
      await db.transaction((txn) async {
        await txn.execute("PRAGMA foreign_keys = OFF;");
        await txn.execute(
            "ALTER TABLE ${MessageTable.tableName} RENAME TO OldMessageTable;");

        await txn.execute("""CREATE TABLE ${MessageTable.tableName}(
    ${MessageTable.colId} INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    ${MessageTable.colChatId} TEXT NOT NULL,
    ${MessageTable.colSender} TEXT NOT NULL,
    ${MessageTable.colRecipient} TEXT,
    ${MessageTable.colReceipt} TEXT NOT NULL,
    ${MessageTable.colContents} TEXT NOT NULL,
    ${MessageTable.colServerId} TEXT UNIQUE,
    ${MessageTable.colCreatedAt} TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ${MessageTable.colExecutedAt} TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
    )""");
        await txn.execute(
            """INSERT INTO ${MessageTable.tableName} SELECT * FROM OldMessageTable 
            WHERE OldMessageTable.rowId IN 
            (SELECT MIN(rowid)
               FROM OldMessageTable
               GROUP BY server_id);""");
        // await txn.execute(
        //     "CREATE INDEX messages_index ON ${MessageTable.tableName} (${MessageTable.colChatId}, ${MessageTable.colExecutedAt} DESC, ${MessageTable.colCreatedAt} DESC, ${MessageTable.colReceipt})");
        await txn.execute("DROP TABLE OldMessageTable;");
        await txn.execute("PRAGMA foreign_keys = ON;");
      });
    }
  }

  Future<void> _createChatTable(Database db) async {
    await db.execute("""CREATE TABLE ${ChatTable.tableName} (
        ${ChatTable.colId} INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
        ${ChatTable.colUserId} TEXT UNIQUE,
        ${ChatTable.colGroupId} TEXT UNIQUE,
        ${ChatTable.colCreatedAt} TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
        CONSTRAINT CK_GroupOrUserPresent CHECK (${ChatTable.colUserId} IS NOT NULL OR ${ChatTable.colGroupId} IS NOT NULL)
        )""").then((_) {
      debugPrint("Successfully created ${ChatTable.tableName} Table");
    }).catchError((e) {
      debugPrint(" ${ChatTable.tableName} table creation failed: $e");
    });
  }

  Future<void> _createMessageTable(Database db) async {
    await db.execute("""CREATE TABLE ${MessageTable.tableName}(
    ${MessageTable.colId} INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    ${MessageTable.colChatId} TEXT NOT NULL,
    ${MessageTable.colSender} TEXT NOT NULL,
    ${MessageTable.colRecipient} TEXT,
    ${MessageTable.colReceipt} TEXT NOT NULL,
    ${MessageTable.colContents} TEXT NOT NULL,
    ${MessageTable.colServerId} TEXT UNIQUE,
    ${MessageTable.colCreatedAt} TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ${MessageTable.colExecutedAt} TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
    )""").then((_) {
      debugPrint("Successfully created ${MessageTable.tableName} table");
    }).catchError((e) {
      debugPrint("${MessageTable.tableName} table creation failed");
    });
  }

  Future<void> _createUserTable(Database db) async {
    await db.execute("""CREATE TABLE ${UserTable.tableName}(
      ${UserTable.colId} TEXT PRIMARY KEY NOT NULL,
      ${UserTable.colEmail} VARCHAR(255) NOT NULL,
      ${UserTable.colName} VARCHAR(255) NOT NULL,
      ${UserTable.colUsername} VARCHAR(255) NOT NULL,
      ${UserTable.photoUrl} TEXT,
      ${UserTable.publicKeyJwb} TEXT NOT NULL
    )""").then((_) {
      debugPrint("Successfully created ${UserTable.tableName} table");
    }).catchError((error) {
      debugPrint("${UserTable.tableName} table creation failed");
    });
  }

  Future<void> _createIndices(Database db) async {
    final batch = db.batch();
    try {
      batch.execute(
          "CREATE UNIQUE INDEX user_identify ON ${UserTable.tableName} (${UserTable.colId} , ${UserTable.colEmail}, ${UserTable.colUsername})");
      batch.execute(
          "CREATE UNIQUE INDEX chat_identify ON ${ChatTable.tableName} (${ChatTable.colId}, ${ChatTable.colUserId}, ${ChatTable.colGroupId})");
      batch.execute(
          "CREATE INDEX messages_index ON ${MessageTable.tableName} (${MessageTable.colChatId}, ${MessageTable.colExecutedAt} DESC, ${MessageTable.colCreatedAt} DESC, ${MessageTable.colReceipt})");
      await batch.commit();
    } catch (e) {
      debugPrint("Indices creation failed");
    }
  }
}
