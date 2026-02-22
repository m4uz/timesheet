import 'dart:async';
import 'package:logging/logging.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timesheet/models/result.dart';
import 'package:timesheet/models/timetracker_item.dart';
import 'package:timesheet/services/timetracker_db_service.dart';

class TimetrackerDBServiceImpl implements TimetrackerDBService {
  final _log = Logger('TimetrackerDBService');
  final String _databasePath;
  final tableName = "timetracker_item";

  bool _isInitialized = false;

  TimetrackerDBServiceImpl(this._databasePath);

  Database? _database;

  Future<Database> get _db async {
    if (_database != null) {
      try {
        if (_database!.isOpen) {
          return _database!;
        }
      } catch (e) {
        _log.warning('Database connection was closed, reopening.');
        _database = null;
      }
    }

    try {
      _database = await _openDatabase();
      return _database!;
    } catch (e, s) {
      _database = null;
      _log.severe('Failed to open database $_databasePath.', e, s);
      rethrow;
    }
  }

  Future<Database> _openDatabase() async {
    _log.fine('Opening database $_databasePath.');

    if (!_isInitialized) {
      sqfliteFfiInit();
      _isInitialized = true;
    }

    try {
      final db = await databaseFactoryFfi.openDatabase(
        _databasePath,
        options: OpenDatabaseOptions(
          onCreate: (db, version) {
            return db.execute("""
                              CREATE TABLE $tableName (
                                  id            INTEGER PRIMARY KEY AUTOINCREMENT,
                                  wtmId         TEXT,
                                  itemIndex     INTEGER,
                                  datetimeFrom  TEXT,
                                  datetimeTo    TEXT,
                                  subject       TEXT,
                                  category      TEXT,
                                  description   TEXT,
                                  status        TEXT,
                                  statusMsg     TEXT
                              )
                              """);
          },
          version: 1,
        ),
      );

      _log.fine('Database $_databasePath opened.');
      return db;
    } catch (e) {
      _log.shout('Failed to open database $_databasePath.', e);
      rethrow;
    }
  }

  @override
  Future<void> open() async {
    await _db;
  }

  @override
  Future<void> close() async {
    if (_database != null) {
      _log.fine('Closing database $_databasePath.');
      try {
        await _database!.close();
      } catch (e) {
        _log.warning('Error closing database: $e');
      } finally {
        _database = null;
        _log.fine('Database $_databasePath closed.');
      }
    }
  }

  @override
  Future<Result<TimetrackerItem>> insert(TimetrackerItem item) async {
    _log.fine('Inserting Timetracker item ${item.toString()}.');

    try {
      final db = await _db;
      final id = await db.insert(tableName, item.toMap());
      final insertedItem = item.copyWith(id: id);

      _log.fine('Timetracker item inserted ${insertedItem.toString()}.');

      return Result.ok(insertedItem);
    } catch (e, s) {
      _log.severe(
        'Failed to insert Timetracker item ${item.toString()}.',
        e,
        s,
      );
      return Result.error('Failed to create item.');
    }
  }

  @override
  Future<Result<List<TimetrackerItem>>> insertBatch(
    List<TimetrackerItem> items,
  ) async {
    if (items.isEmpty) {
      _log.fine('Not inserting Timetracker items as empty list was provided.');
      return Result.ok([]);
    }

    _log.fine(
      'Inserting Timetracker items ${items.map((i) => i.toString()).join(', ')}.',
    );

    try {
      final db = await _db;
      final insertedItems = <TimetrackerItem>[];

      await db.transaction((txn) async {
        for (final item in items) {
          final id = await txn.insert(tableName, item.toMap());
          final insertedItem = item.copyWith(id: id);
          insertedItems.add(insertedItem);
          _log.fine('Timetracker item inserted ${insertedItem.toString()}.');
        }
      });

      return Result.ok(insertedItems);
    } catch (e, s) {
      _log.severe(
        'Failed to insert Timetracker items '
        '${items.map((i) => i.toString()).join(', ')}.',
        e,
        s,
      );
      return Result.error('Failed to create items.');
    }
  }

  @override
  Future<Result<TimetrackerItem>> getById(int id) async {
    _log.fine('Getting Timetracker item $id.');

    try {
      final db = await _db;
      final maps = await db.query(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        _log.warning('Timetracker item $id not found.');
        return Result.error('Item $id not found.');
      }

      final item = TimetrackerItem.fromMap(maps.first);
      _log.fine('Timetracker item retrieved ${item.toString()}.');
      return Result.ok(item);
    } catch (e, s) {
      _log.severe('Failed to get Timetracker item $id.', e, s);
      return Result.error('Failed to get item $id.');
    }
  }

  @override
  Future<Result<List<TimetrackerItem>>> getAll() async {
    _log.fine('Getting all Timetracker items.');

    try {
      final db = await _db;
      final itemMaps = await db.query(tableName);
      final items = itemMaps
          .map((map) => TimetrackerItem.fromMap(map))
          .toList();

      _log.fine('Retrieved ${items.length} item(s).');

      return Result.ok(items);
    } catch (e, s) {
      _log.severe('Failed to get all Timetracker items.', e, s);
      return Result.error('Failed to get all items.');
    }
  }

  @override
  Future<Result<TimetrackerItem>> update(TimetrackerItem item) async {
    _log.fine('Updating Timetracker item ${item.toString()}.');

    if (item.id == -1) {
      _log.warning('Cannot update Timetracker item without a valid ID.');
      return Result.error('Cannot update item without a valid ID.');
    }

    try {
      final db = await _db;
      final map = item.toMap();
      map.remove('id');

      final rowsUpdated = await db.update(
        tableName,
        map,
        where: 'id = ?',
        whereArgs: [item.id],
      );

      if (rowsUpdated == 0) {
        _log.warning(
          'Timetracker item ${item.toString()} not found in database.',
        );
        return Result.error('Item not found.');
      }

      _log.fine('Timetracker item updated ${item.toString()}.');
      return Result.ok(item);
    } catch (e, s) {
      _log.severe(
        'Failed to update Timetracker item ${item.toString()}.',
        e,
        s,
      );
      return Result.error('Failed to update item.');
    }
  }

  @override
  Future<Result<List<TimetrackerItem>>> updateBatch(
    List<TimetrackerItem> items,
  ) async {
    if (items.isEmpty) {
      _log.fine('Not updating Timetracker items as empty list was provided.');
      return Result.ok([]);
    }

    for (final item in items) {
      if (item.id == -1) {
        _log.warning(
          'Cannot update Timetracker item without a valid ID: '
          '${item.toString()}.',
        );
        return Result.error('Cannot update item without a valid ID.');
      }
    }

    _log.fine(
      'Updating Timetracker items '
      '${items.map((i) => i.toString()).join(', ')}.',
    );

    try {
      final db = await _db;
      final updatedItems = <TimetrackerItem>[];

      await db.transaction((txn) async {
        for (final item in items) {
          final map = item.toMap();
          map.remove('id');

          final rowsUpdated = await txn.update(
            tableName,
            map,
            where: 'id = ?',
            whereArgs: [item.id],
          );

          if (rowsUpdated == 0) {
            _log.warning(
              'Timetracker item ${item.toString()} not found in database.',
            );
            throw Exception('Item ${item.id} not found.');
          }

          updatedItems.add(item);
          _log.fine('Timetracker item updated ${item.toString()}.');
        }
      });

      return Result.ok(updatedItems);
    } catch (e, s) {
      _log.severe(
        'Failed to update Timetracker items '
        '${items.map((i) => i.toString()).join(', ')}.',
        e,
        s,
      );
      return Result.error('Failed to update items.');
    }
  }

  @override
  Future<Result<int>> deleteById(int id) async {
    _log.fine('Deleting Timetracker item $id.');

    try {
      final db = await _db;
      final rowsDeleted = await db.delete(
        tableName,
        where: 'id = ?',
        whereArgs: [id],
      );

      if (rowsDeleted == 0) {
        _log.warning('Timetracker item $id not found in database.');
        return Result.error('Item not found.');
      }

      _log.fine('Timetracker item $id deleted.');
      return Result.ok(rowsDeleted);
    } catch (e, s) {
      _log.severe('Failed to delete Timetracker item $id.', e, s);
      return Result.error('Failed to delete item $id.');
    }
  }

  @override
  Future<Result<int>> deleteAll() async {
    _log.fine('Deleting all Timetracker items.');

    try {
      final db = await _db;
      final rowsDeleted = await db.delete(tableName);

      _log.fine('Deleted $rowsDeleted Timetracker item(s).');
      return Result.ok(rowsDeleted);
    } catch (e, s) {
      _log.severe('Failed to delete all Timetracker items.', e, s);
      return Result.error('Failed to delete all items.');
    }
  }
}
