import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

/// Local SQLite Database Helper with Versioned Schema & Immediate Write-Ordering (WP20).
/// Strictly offline, app-private, zero network sync.
class DatabaseHelper {
  static const String _dbName = 'homesets.db';
  static const int _dbVersion = 1;

  static Database? _database;
  static DatabaseFactory? _customFactory;

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  /// Allows injecting a custom DatabaseFactory (e.g. sqflite_common_ffi for headless unit tests).
  static void setCustomFactory(DatabaseFactory factory) {
    _customFactory = factory;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath;
    if (_customFactory != null) {
      dbPath = inMemoryDatabasePath;
      return await _customFactory!.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: _dbVersion,
          onCreate: _onCreate,
          onConfigure: _onConfigure,
        ),
      );
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      dbPath = '${docsDir.path}/$_dbName';
      return await openDatabase(
        dbPath,
        version: _dbVersion,
        onCreate: _onCreate,
        onConfigure: _onConfigure,
      );
    }
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign key constraints and WAL mode for crash resilience
    await db.execute('PRAGMA foreign_keys = ON;');
    // Ensure session_salvage_archive table exists for existing databases (WP-A)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS session_salvage_archive (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        routine_name TEXT NOT NULL,
        salvaged_at TEXT NOT NULL,
        parsed_sets_count INTEGER NOT NULL,
        has_corrupt_logs INTEGER NOT NULL,
        raw_completed_sets_json TEXT NOT NULL,
        raw_active_session_json TEXT NOT NULL
      );
    ''');
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. User Profile Table
    await db.execute('''
      CREATE TABLE user_profile (
        id TEXT PRIMARY KEY,
        goal TEXT NOT NULL,
        wake_time_minutes INTEGER NOT NULL,
        shift_start_minutes INTEGER NOT NULL,
        target_workouts_per_week INTEGER NOT NULL,
        avoided_joints TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    // 2. Equipment Inventory Table
    await db.execute('''
      CREATE TABLE equipment_inventory (
        id TEXT PRIMARY KEY,
        has_pull_up_bar INTEGER NOT NULL,
        has_bands INTEGER NOT NULL,
        has_door_anchor INTEGER NOT NULL,
        has_sturdy_table INTEGER NOT NULL,
        has_parallel_grip INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    // 3. Completed Workout Sessions Table
    await db.execute('''
      CREATE TABLE workout_sessions (
        id TEXT PRIMARY KEY,
        scheduled_session_id TEXT NOT NULL,
        routine_name TEXT NOT NULL,
        is_lite_mode INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        ended_at TEXT NOT NULL,
        total_duration_seconds INTEGER NOT NULL,
        is_emergency_stopped INTEGER NOT NULL,
        emergency_stop_reason TEXT
      );
    ''');

    // 4. Set Logs Table (Immediate Write-Order)
    await db.execute('''
      CREATE TABLE set_logs (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        set_index INTEGER NOT NULL,
        exercise_id TEXT NOT NULL,
        performed_reps INTEGER NOT NULL,
        band_used TEXT,
        exertion TEXT NOT NULL,
        is_pain_stopped INTEGER NOT NULL,
        pain_note TEXT,
        completed_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES workout_sessions (id) ON DELETE CASCADE
      );
    ''');

    // 5. Active Session State Table (For crash recovery and app restart resume)
    await db.execute('''
      CREATE TABLE active_session_state (
        session_id TEXT PRIMARY KEY,
        routine_name TEXT NOT NULL,
        routine_name_ar TEXT NOT NULL,
        is_lite_mode INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        current_exercise_index INTEGER NOT NULL,
        current_set_index INTEGER NOT NULL,
        completed_sets_json TEXT NOT NULL,
        active_session_json TEXT NOT NULL
      );
    ''');

    // 6. Session Salvage Archive Table (WP-A: Lossless durable quarantine for corrupt draft raw bytes)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS session_salvage_archive (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        routine_name TEXT NOT NULL,
        salvaged_at TEXT NOT NULL,
        parsed_sets_count INTEGER NOT NULL,
        has_corrupt_logs INTEGER NOT NULL,
        raw_completed_sets_json TEXT NOT NULL,
        raw_active_session_json TEXT NOT NULL
      );
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
