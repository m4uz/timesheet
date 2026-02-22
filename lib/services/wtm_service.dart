import 'package:timesheet/dtos/create_timesheet_item_request_dto.dart';
import 'package:timesheet/dtos/list_worker_timesheet_items_request_dto.dart';
import 'package:timesheet/dtos/timesheet_item_dto.dart';
import 'package:timesheet/dtos/user_config_dto.dart';
import 'package:timesheet/models/result.dart';

abstract class IWTMService {
  Future<Result<UserConfigDto>> loadConfigAndUserInfo();

  Future<Result<UserConfigDto>> updateUserOptions(
    UpdateUserOptionsRequestDto request,
  );

  Future<Result<TimesheetItemDto>> createTimesheetItem(
    CreateTimesheetItemRequestDto request,
  );
  Future<Result<List<TimesheetItemDto>>> listWorkerTimesheetItemsByTime(
    ListWorkerTimesheetItemsRequestDto request,
  );
}
