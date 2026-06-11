import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/expense.dart';
import '../models/debt.dart';
import '../models/insight.dart';
import '../models/reflection.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('kwartako.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Settings Table
    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    // 2. Expenses Table
    await db.execute('''
      CREATE TABLE expenses(
        id TEXT PRIMARY KEY,
        amount REAL,
        category TEXT,
        note TEXT,
        date TEXT
      )
    ''');

    // 3. Debts Table
    await db.execute('''
      CREATE TABLE debts(
        id TEXT PRIMARY KEY,
        name TEXT,
        originalAmount REAL,
        remainingAmount REAL,
        dueDate TEXT,
        isIOwe INTEGER,
        status TEXT
      )
    ''');

    // 4. Debt Payments Table
    await db.execute('''
      CREATE TABLE debt_payments(
        id TEXT PRIMARY KEY,
        debtId TEXT,
        amount REAL,
        date TEXT,
        FOREIGN KEY (debtId) REFERENCES debts (id) ON DELETE CASCADE
      )
    ''');

    // 5. Weekly Reflections Table
    await db.execute('''
      CREATE TABLE weekly_reflections(
        id TEXT PRIMARY KEY,
        allowance REAL,
        totalSpent REAL,
        remaining REAL,
        savings REAL,
        dailySpendingTrend TEXT,
        topCategories TEXT,
        whatWentWell TEXT,
        needsImprovement TEXT,
        aiCoachSuggestions TEXT,
        comparisonText TEXT,
        motivationalQuote TEXT
      )
    ''');

    // 6. Insights Table
    await db.execute('''
      CREATE TABLE insights(
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        type TEXT,
        category TEXT
      )
    ''');

    // Seed defaults
    await _seedDefaults(db);
  }

  Future<void> _seedDefaults(DatabaseExecutor db) async {
    // User Settings
    await db.insert('settings', {'key': 'userName', 'value': 'Alex'});
    await db.insert('settings', {'key': 'allowance', 'value': '0.0'});
    await db.insert('settings', {'key': 'disciplineScore', 'value': '10.0'});

    // Reflections
    await db.insert('weekly_reflections', {
      'id': 'current_reflection',
      ...WeeklyReflection.emptyReflection.toMap()
    });
  }

  // --- SETTINGS HELPERS ---
  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final maps = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String?;
    }
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- EXPENSES CRUD ---
  Future<List<Expense>> fetchExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<void> insertExpense(Expense expense) async {
    final db = await instance.database;
    await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await instance.database;
    await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- DEBTS CRUD ---
  Future<List<Debt>> fetchDebts() async {
    final db = await instance.database;
    final debtsResult = await db.query('debts', orderBy: 'dueDate DESC');
    
    List<Debt> debtsList = [];
    for (var debtMap in debtsResult) {
      final debtId = debtMap['id'] as String;
      final paymentsResult = await db.query(
        'debt_payments',
        where: 'debtId = ?',
        whereArgs: [debtId],
        orderBy: 'date DESC',
      );
      
      final payments = paymentsResult.map((p) => DebtPayment.fromMap(p)).toList();
      debtsList.add(Debt.fromMap(debtMap, payments));
    }
    return debtsList;
  }

  Future<void> insertDebt(Debt debt) async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.insert(
        'debts',
        debt.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      // Write payments inside the transaction context
      for (var payment in debt.payments) {
        await txn.insert(
          'debt_payments',
          payment.toMap(debt.id),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> updateDebt(Debt debt) async {
    final db = await instance.database;
    await db.update(
      'debts',
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<void> insertDebtPayment(String debtId, DebtPayment payment) async {
    final db = await instance.database;
    await db.insert(
      'debt_payments',
      payment.toMap(debtId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteDebt(String id) async {
    final db = await instance.database;
    await db.delete('debts', where: 'id = ?', whereArgs: [id]);
    await db.delete('debt_payments', where: 'debtId = ?', whereArgs: [id]);
  }

  Future<void> deleteDebtPayment(String paymentId) async {
    final db = await instance.database;
    await db.delete('debt_payments', where: 'id = ?', whereArgs: [paymentId]);
  }

  // --- INSIGHTS CRUD ---
  Future<List<Insight>> fetchInsights() async {
    final db = await instance.database;
    final result = await db.query('insights');
    return result.map((json) => Insight.fromMap(json)).toList();
  }

  Future<void> saveInsight(Insight insight) async {
    final db = await instance.database;
    await db.insert(
      'insights',
      insight.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveAllInsights(List<Insight> insights) async {
    final db = await instance.database;
    final batch = db.batch();
    batch.delete('insights'); // Clear existing insights
    for (var insight in insights) {
      batch.insert('insights', insight.toMap());
    }
    await batch.commit(noResult: true);
  }

  // --- REFLECTIONS CRUD ---
  Future<WeeklyReflection?> fetchReflection() async {
    final db = await instance.database;
    final result = await db.query(
      'weekly_reflections',
      where: 'id = ?',
      whereArgs: ['current_reflection'],
    );
    if (result.isNotEmpty) {
      return WeeklyReflection.fromMap(result.first);
    }
    return null;
  }

  Future<void> saveReflection(WeeklyReflection reflection) async {
    final db = await instance.database;
    await db.insert(
      'weekly_reflections',
      {
        'id': 'current_reflection',
        ...reflection.toMap(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- WIPE DATABASE ---
  Future<void> clearAllData() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('settings');
      await txn.delete('expenses');
      await txn.delete('debts');
      await txn.delete('debt_payments');
      await txn.delete('weekly_reflections');
      await txn.delete('insights');
      await _seedDefaults(txn);
    });
  }
}
