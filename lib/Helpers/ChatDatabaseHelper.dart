import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class ChatDatabaseHelper {
  static final ChatDatabaseHelper _instance = ChatDatabaseHelper._internal();
  static Database? _database;

  // Limits for offline storage
  static const int MAX_CONNECTIONS = 50;
  static const int MAX_MOMENTS = 50;
  static const int MAX_MESSAGES_PER_CONVERSATION = 100;

  factory ChatDatabaseHelper() => _instance;

  ChatDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'chat_database.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Conversations table
    await db.execute('''
      CREATE TABLE conversations (
        id TEXT PRIMARY KEY,
        participant_id TEXT NOT NULL,
        participant_name TEXT,
        participant_profile TEXT,
        last_message TEXT,
        last_message_time TEXT,
        unread_count INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Messages table
    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        receiver_id TEXT NOT NULL,
        message TEXT NOT NULL,
        is_text INTEGER DEFAULT 1,
        is_image INTEGER DEFAULT 0,
        is_audio INTEGER DEFAULT 0,
        is_read INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (conversation_id) REFERENCES conversations (id)
      )
    ''');

    // Connections table (likes, liked_by, matches)
    await db.execute('''
      CREATE TABLE connections (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        first_name TEXT,
        last_name TEXT,
        profile_pic TEXT,
        connection_type TEXT NOT NULL,
        match_id TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Moments table
    await db.execute('''
      CREATE TABLE moments (
        id TEXT PRIMARY KEY,
        owner_id TEXT NOT NULL,
        owner_first_name TEXT,
        owner_last_name TEXT,
        owner_profile_pic TEXT,
        hashtag TEXT,
        tagline TEXT,
        images TEXT,
        likes_count INTEGER DEFAULT 0,
        total_gifts INTEGER DEFAULT 0,
        is_liked INTEGER DEFAULT 0,
        created_at TEXT,
        cached_at TEXT
      )
    ''');

    // Create indexes for faster queries
    await db.execute('CREATE INDEX idx_messages_conversation ON messages (conversation_id)');
    await db.execute('CREATE INDEX idx_messages_created ON messages (created_at)');
    await db.execute('CREATE INDEX idx_connections_type ON connections (connection_type)');
    await db.execute('CREATE INDEX idx_moments_created ON moments (created_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add connections table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS connections (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          first_name TEXT,
          last_name TEXT,
          profile_pic TEXT,
          connection_type TEXT NOT NULL,
          match_id TEXT,
          created_at TEXT,
          updated_at TEXT
        )
      ''');

      // Add moments table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS moments (
          id TEXT PRIMARY KEY,
          owner_id TEXT NOT NULL,
          owner_first_name TEXT,
          owner_last_name TEXT,
          owner_profile_pic TEXT,
          hashtag TEXT,
          tagline TEXT,
          images TEXT,
          likes_count INTEGER DEFAULT 0,
          total_gifts INTEGER DEFAULT 0,
          is_liked INTEGER DEFAULT 0,
          created_at TEXT,
          cached_at TEXT
        )
      ''');

      await db.execute('CREATE INDEX IF NOT EXISTS idx_connections_type ON connections (connection_type)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_moments_created ON moments (created_at)');
    }
  }

  // ==================== CONVERSATION METHODS ====================

  Future<int> insertConversation(Map<String, dynamic> conversation) async {
    final db = await database;
    return await db.insert(
      'conversations',
      conversation,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getConversations() async {
    final db = await database;
    return await db.query(
      'conversations',
      orderBy: 'updated_at DESC',
    );
  }

  Future<Map<String, dynamic>?> getConversation(String id) async {
    final db = await database;
    final results = await db.query(
      'conversations',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateConversation(String id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      'conversations',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteConversation(String id) async {
    final db = await database;
    await db.delete('messages', where: 'conversation_id = ?', whereArgs: [id]);
    return await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== MESSAGE METHODS ====================

  Future<int> insertMessage(Map<String, dynamic> message) async {
    final db = await database;
    final conversationId = message['conversation_id'];
    
    // Check current count for this conversation
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM messages WHERE conversation_id = ?',
      [conversationId],
    )) ?? 0;

    // If at limit, delete oldest messages for this conversation
    if (count >= MAX_MESSAGES_PER_CONVERSATION) {
      await db.rawDelete(
        'DELETE FROM messages WHERE id IN (SELECT id FROM messages WHERE conversation_id = ? ORDER BY created_at ASC LIMIT ?)',
        [conversationId, count - MAX_MESSAGES_PER_CONVERSATION + 1],
      );
    }

    return await db.insert(
      'messages',
      message,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple messages for a conversation, maintaining the 100 message limit
  Future<void> insertMessagesForConversation(String conversationId, List<Map<String, dynamic>> messages) async {
    final db = await database;
    
    // Clear existing messages for this conversation
    await db.delete('messages', where: 'conversation_id = ?', whereArgs: [conversationId]);
    
    // Insert new ones (up to limit, most recent first)
    final batch = db.batch();
    final toInsert = messages.take(MAX_MESSAGES_PER_CONVERSATION).toList();
    for (var message in toInsert) {
      batch.insert('messages', message, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertMessages(List<Map<String, dynamic>> messages) async {
    final db = await database;
    final batch = db.batch();
    for (var message in messages) {
      batch.insert('messages', message, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getMessages(String conversationId, {int limit = 50, int offset = 0}) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<List<Map<String, dynamic>>> getUnreadMessages(String conversationId) async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'conversation_id = ? AND is_read = 0',
      whereArgs: [conversationId],
    );
  }

  Future<int> markMessagesAsRead(String conversationId) async {
    final db = await database;
    return await db.update(
      'messages',
      {'is_read': 1},
      where: 'conversation_id = ? AND is_read = 0',
      whereArgs: [conversationId],
    );
  }

  Future<int> markMessageAsSynced(String messageId) async {
    final db = await database;
    return await db.update(
      'messages',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedMessages() async {
    final db = await database;
    return await db.query(
      'messages',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
    );
  }

  Future<int> deleteMessage(String id) async {
    final db = await database;
    return await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteOldMessages(int daysOld) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld)).toIso8601String();
    return await db.delete(
      'messages',
      where: 'created_at < ?',
      whereArgs: [cutoffDate],
    );
  }

  // ==================== CONNECTION METHODS ====================

  /// Insert a connection, maintaining the 50 item limit per type
  Future<int> insertConnection(Map<String, dynamic> connection) async {
    final db = await database;
    final type = connection['connection_type'];
    
    // Check current count for this type
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM connections WHERE connection_type = ?',
      [type],
    )) ?? 0;

    // If at limit, delete oldest
    if (count >= MAX_CONNECTIONS) {
      await db.delete(
        'connections',
        where: 'id IN (SELECT id FROM connections WHERE connection_type = ? ORDER BY created_at ASC LIMIT ?)',
        whereArgs: [type, count - MAX_CONNECTIONS + 1],
      );
    }

    return await db.insert(
      'connections',
      connection,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple connections, maintaining the 50 item limit per type
  Future<void> insertConnections(List<Map<String, dynamic>> connections, String type) async {
    final db = await database;
    
    // Clear existing connections of this type
    await db.delete('connections', where: 'connection_type = ?', whereArgs: [type]);
    
    // Insert new ones (up to limit)
    final batch = db.batch();
    final toInsert = connections.take(MAX_CONNECTIONS).toList();
    for (var connection in toInsert) {
      batch.insert('connections', connection, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getConnections(String type) async {
    final db = await database;
    return await db.query(
      'connections',
      where: 'connection_type = ?',
      whereArgs: [type],
      orderBy: 'created_at DESC',
      limit: MAX_CONNECTIONS,
    );
  }

  Future<int> deleteConnection(String id) async {
    final db = await database;
    return await db.delete('connections', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearConnections(String type) async {
    final db = await database;
    await db.delete('connections', where: 'connection_type = ?', whereArgs: [type]);
  }

  // ==================== MOMENT METHODS ====================

  /// Insert a moment, maintaining the 50 item limit
  Future<int> insertMoment(Map<String, dynamic> moment) async {
    final db = await database;
    
    // Check current count
    final count = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM moments',
    )) ?? 0;

    // If at limit, delete oldest
    if (count >= MAX_MOMENTS) {
      await db.delete(
        'moments',
        where: 'id IN (SELECT id FROM moments ORDER BY cached_at ASC LIMIT ?)',
        whereArgs: [count - MAX_MOMENTS + 1],
      );
    }

    moment['cached_at'] = DateTime.now().toIso8601String();
    return await db.insert(
      'moments',
      moment,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple moments, maintaining the 50 item limit
  Future<void> insertMoments(List<Map<String, dynamic>> moments) async {
    final db = await database;
    
    // Clear existing moments
    await db.delete('moments');
    
    // Insert new ones (up to limit)
    final batch = db.batch();
    final toInsert = moments.take(MAX_MOMENTS).toList();
    final now = DateTime.now().toIso8601String();
    for (var moment in toInsert) {
      moment['cached_at'] = now;
      batch.insert('moments', moment, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getMoments({int limit = 50, int offset = 0}) async {
    final db = await database;
    return await db.query(
      'moments',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>?> getMoment(String id) async {
    final db = await database;
    final results = await db.query(
      'moments',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateMomentLike(String id, bool isLiked, int likesCount) async {
    final db = await database;
    return await db.update(
      'moments',
      {'is_liked': isLiked ? 1 : 0, 'likes_count': likesCount},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteMoment(String id) async {
    final db = await database;
    return await db.delete('moments', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearMoments() async {
    final db = await database;
    await db.delete('moments');
  }

  // ==================== UTILITY METHODS ====================

  Future<int> getUnreadCount(String conversationId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM messages WHERE conversation_id = ? AND is_read = 0',
      [conversationId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, dynamic>?> getLastMessage(String conversationId) async {
    final db = await database;
    final results = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('conversations');
    await db.delete('connections');
    await db.delete('moments');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
