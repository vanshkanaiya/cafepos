import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LoginUser {
  const LoginUser({
    this.id,
    required this.email,
    required this.password,
    this.createdAt,
  });

  final int? id;
  final String email;
  final String password;
  final String? createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'created_at': createdAt,
    };
  }

  factory LoginUser.fromMap(Map<String, Object?> map) {
    return LoginUser(
      id: map['id'] as int?,
      email: map['email'] as String,
      password: map['password'] as String,
      createdAt: map['created_at'] as String?,
    );
  }
}

class MenuItem {
  const MenuItem({
    this.id,
    required this.section,
    required this.name,
    required this.price,
    required this.imagePath,
    this.createdAt,
  });

  final int? id;
  final String section;
  final String name;
  final double price;
  final String imagePath;
  final String? createdAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'section': section,
      'name': name,
      'price': price,
      'image_path': imagePath,
      'created_at': createdAt,
    };
  }

  factory MenuItem.fromMap(Map<String, Object?> map) {
    return MenuItem(
      id: map['id'] as int?,
      section: map['section'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      imagePath: map['image_path'] as String,
      createdAt: map['created_at'] as String?,
    );
  }
}

class LoginDbService {
  LoginDbService._();

  static final LoginDbService instance = LoginDbService._();

  static const String _databaseName = 'cafepos.db';
  static const int _databaseVersion = 1;
  static const String usersTable = 'users';
  static const String menuItemsTable = 'menu_items';

  static const List<MenuItem> _defaultMenuItems = [
    MenuItem(
      section: 'Momos',
      name: 'Veg Momos',
      price: 120,
      imagePath: 'assets/menu/veg_momos.png',
    ),
    MenuItem(
      section: 'Pizza',
      name: 'Margherita Pizza',
      price: 249,
      imagePath: 'assets/menu/margherita_pizza.png',
    ),
    MenuItem(
      section: 'Maggie',
      name: 'Cheese Maggie',
      price: 90,
      imagePath: 'assets/menu/cheese_maggie.png',
    ),
    MenuItem(
      section: 'Fries',
      name: 'French Fries',
      price: 100,
      imagePath: 'assets/menu/french_fries.png',
    ),
    MenuItem(
      section: 'Coffee',
      name: 'Cold Coffee',
      price: 110,
      imagePath: 'assets/menu/cold_coffee.png',
    ),
    MenuItem(
      section: 'Beverages',
      name: 'Fresh Lime Soda',
      price: 80,
      imagePath: 'assets/menu/fresh_lime_soda.png',
    ),
  ];

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    final db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );

    await _ensureTables(db);
    await _ensureDefaultUser(db);
    await _ensureDefaultMenuItems(db);
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createUsersTable(db);
    await _createMenuItemsTable(db);
  }

  Future<void> _ensureTables(Database db) async {
    await _createUsersTable(db);
    await _createMenuItemsTable(db);
  }

  Future<void> _createUsersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $usersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _createMenuItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $menuItemsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        section TEXT NOT NULL,
        name TEXT NOT NULL UNIQUE,
        price REAL NOT NULL,
        image_path TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _ensureDefaultUser(Database db) async {
    await db.insert(usersTable, {
      'email': 'user01',
      'password': '123',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _ensureDefaultMenuItems(Database db) async {
    for (final item in _defaultMenuItems) {
      await db.insert(
        menuItemsTable,
        {
          'section': item.section,
          'name': item.name,
          'price': item.price,
          'image_path': item.imagePath,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<int> createUser(LoginUser user) async {
    final db = await database;

    return db.insert(
      usersTable,
      user.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<LoginUser?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      usersTable,
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return LoginUser.fromMap(result.first);
  }

  Future<bool> validateLogin({
    required String email,
    required String password,
  }) async {
    final db = await database;
    final result = await db.query(
      usersTable,
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<List<LoginUser>> getAllUsers() async {
    final db = await database;
    final result = await db.query(usersTable, orderBy: 'id DESC');

    return result.map(LoginUser.fromMap).toList();
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return db.delete(usersTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> createMenuItem(MenuItem item) async {
    final db = await database;

    return db.insert(
      menuItemsTable,
      item.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<List<MenuItem>> getAllMenuItems() async {
    final db = await database;
    final result = await db.query(
      menuItemsTable,
      orderBy: 'section ASC, id ASC',
    );

    return result.map(MenuItem.fromMap).toList();
  }

  Future<List<MenuItem>> getMenuItemsBySection(String section) async {
    final db = await database;
    final result = await db.query(
      menuItemsTable,
      where: 'section = ?',
      whereArgs: [section],
      orderBy: 'id ASC',
    );

    return result.map(MenuItem.fromMap).toList();
  }

  Future<MenuItem?> getMenuItemByName(String name) async {
    final db = await database;
    final result = await db.query(
      menuItemsTable,
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return MenuItem.fromMap(result.first);
  }

  Future<int> updateMenuItem(MenuItem item) async {
    final db = await database;
    return db.update(
      menuItemsTable,
      item.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteMenuItem(int id) async {
    final db = await database;
    return db.delete(menuItemsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> getMenuSections() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT section FROM $menuItemsTable ORDER BY section ASC',
    );

    return result.map((row) => row['section'] as String).toList();
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
