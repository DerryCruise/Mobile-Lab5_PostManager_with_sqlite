import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/post.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('posts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path, 
      version: 3, // Incremented version for user_id
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE posts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        user_id INTEGER,
        created_at INTEGER,
        updated_at INTEGER
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE posts ADD COLUMN user_id INTEGER');
    }
  }

  Future<int> insertPost(Post post) async {
    final db = await instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final postMap = post.toMap();
    postMap['created_at'] = now;
    postMap['updated_at'] = now;
    
    return await db.insert('posts', postMap);
  }

  Future<List<Post>> getAllPosts() async {
    final db = await instance.database;
    final result = await db.query(
      'posts',
      orderBy: 'updated_at DESC',
    );
    return result.map((e) => Post.fromMap(e)).toList();
  }

  Future<int> updatePost(Post post) async {
    final db = await instance.database;
    
    final existingPost = await getPostById(post.id!);
    if (existingPost != null && 
        existingPost.title == post.title && 
        existingPost.content == post.content &&
        existingPost.userId == post.userId) {
      return 0;
    }
    
    final postMap = post.toMap();
    postMap['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    
    return await db.update(
      'posts', 
      postMap,
      where: 'id = ?', 
      whereArgs: [post.id]
    );
  }

  Future<Post?> getPostById(int id) async {
    final db = await instance.database;
    final result = await db.query(
      'posts',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (result.isNotEmpty) {
      return Post.fromMap(result.first);
    }
    return null;
  }

  Future<int> deletePost(int id) async {
    final db = await instance.database;
    return await db.delete('posts', where: 'id = ?', whereArgs: [id]);
  }
}