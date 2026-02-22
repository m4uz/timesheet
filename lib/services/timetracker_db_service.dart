import 'package:timesheet/models/result.dart';
import 'package:timesheet/models/timetracker_item.dart';

abstract class TimetrackerDBService {
  Future<void> open();
  Future<void> close();
  Future<Result<TimetrackerItem>> insert(TimetrackerItem item);
  Future<Result<List<TimetrackerItem>>> insertBatch(
    List<TimetrackerItem> items,
  );
  Future<Result<TimetrackerItem>> getById(int id);
  Future<Result<List<TimetrackerItem>>> getAll();
  Future<Result<TimetrackerItem>> update(TimetrackerItem item);
  Future<Result<List<TimetrackerItem>>> updateBatch(
    List<TimetrackerItem> items,
  );
  Future<Result<int>> deleteById(int id);
  Future<Result<int>> deleteAll();
}
