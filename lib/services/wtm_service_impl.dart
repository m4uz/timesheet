import 'dart:convert';
import 'package:http/http.dart';
import 'package:logging/logging.dart';
import 'package:timesheet/dtos/create_timesheet_item_request_dto.dart';
import 'package:timesheet/dtos/list_worker_timesheet_items_request_dto.dart';
import 'package:timesheet/dtos/timesheet_item_dto.dart';
import 'package:timesheet/dtos/user_config_dto.dart';
import 'package:timesheet/http/http_client.dart';
import 'package:timesheet/models/result.dart';
import 'package:timesheet/services/wtm_service.dart';

class WTMServiceImpl implements IWTMService {
  final _log = Logger('WTMService');
  final HttpClient _client;
  final Uri _loadConfigAndUserInfoUrl;
  final Uri _updateUserOptionsUrl;
  final Uri _createTimesheetItemUrl;
  final Uri _listWorkerTimesheetItemsByTimeUrl;

  WTMServiceImpl({required HttpClient client, required Uri wtmBaseUrl})
    : _client = client,
      _loadConfigAndUserInfoUrl = Uri.parse(
        '${wtmBaseUrl.toString()}/loadConfigAndUserInfo',
      ),
      _updateUserOptionsUrl = Uri.parse(
        '${wtmBaseUrl.toString()}/updateUserOptions',
      ),
      _createTimesheetItemUrl = Uri.parse(
        '${wtmBaseUrl.toString()}/createTimesheetItem',
      ),
      _listWorkerTimesheetItemsByTimeUrl = Uri.parse(
        '${wtmBaseUrl.toString()}/listWorkerTimesheetItemsByTime',
      );

  @override
  Future<Result<UserConfigDto>> loadConfigAndUserInfo() async {
    _log.fine('Loading config and user info.');

    final response = await _client.get(_loadConfigAndUserInfoUrl);

    if (response == null) {
      return Result.error('No response from WTM.');
    }

    final result = _processResponse(response, UserConfigDto.fromJson);
    switch (result) {
      case OK():
        _log.fine('Config and user info loaded.');
      case Error():
        _log.fine('Failed to load config and user info.');
    }

    return result;
  }

  @override
  Future<Result<UserConfigDto>> updateUserOptions(
    UpdateUserOptionsRequestDto request,
  ) async {
    _log.fine('Updating user options.');

    final response = await _client.post(
      _updateUserOptionsUrl,
      body: request.toJson(),
    );

    if (response == null) {
      return Result.error('No response from WTM.');
    }

    final result = _processResponse(response, UserConfigDto.fromJson);
    switch (result) {
      case OK():
        _log.fine('User options updated.');
      case Error():
        _log.fine('Failed to update user options.');
    }

    return result;
  }

  @override
  Future<Result<TimesheetItemDto>> createTimesheetItem(
    CreateTimesheetItemRequestDto request,
  ) async {
    _log.fine('Creating timesheet item.');

    final response = await _client.post(
      _createTimesheetItemUrl,
      body: request.toJson(),
    );

    if (response == null) {
      return Result.error('No response from WTM.');
    }

    final result = _processResponse(response, (json) {
      final createdTimesheetItem =
          json['createdTimesheetItem'] as Map<String, dynamic>?;

      if (createdTimesheetItem == null) {
        throw Exception('Field createdTimesheetItem missing in response data.');
      }

      return TimesheetItemDto.fromJson(createdTimesheetItem);
    });

    switch (result) {
      case OK():
        _log.fine('Timesheet item created.');
      case Error():
        _log.fine('Failed to create timesheet item.');
    }

    return result;
  }

  @override
  Future<Result<List<TimesheetItemDto>>> listWorkerTimesheetItemsByTime(
    ListWorkerTimesheetItemsRequestDto request,
  ) async {
    _log.fine('Loading timesheet items.');

    final response = await _client.post(
      _listWorkerTimesheetItemsByTimeUrl,
      body: request.toJson(),
    );

    if (response == null) {
      return Result.error('No response from WTM.');
    }

    final result = _processResponse(response, (json) {
      final timesheetItemList = json['timesheetItemList'] as List<dynamic>?;

      if (timesheetItemList == null) {
        throw Exception('Field timesheetItemList missing in response data.');
      }

      return timesheetItemList
          .map(
            (item) => TimesheetItemDto.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    });

    switch (result) {
      case OK():
        _log.fine('Timesheet items loaded.');
      case Error():
        _log.fine('Failed to load timesheet items.');
    }

    return result;
  }

  Result<T> _processResponse<T>(
    Response r,
    T Function(Map<String, dynamic>) successDecoder,
  ) {
    final contentType = r.headers['content-type']?.toLowerCase() ?? '';
    if (!contentType.contains('application/json')) {
      _log.severe('Unexpected response type: $contentType.');
      return Result.error('Unexpected response type.');
    } else if (r.statusCode >= 500) {
      _log.severe('Server error: ${r.body}.');
      return Result.error('Server error.');
    } else if (r.statusCode == 401) {
      _log.warning('Unauthorized access: ${r.body}.');
      return Result.error('Unauthorized access.');
    } else if (r.statusCode == 403) {
      _log.warning('Access forbidden: ${r.body}.');
      return Result.error('Access forbidden.');
    } else if (r.statusCode == 400) {
      final errMsg = _parseErrMessage(r.body);
      _log.warning('Bad request: $errMsg.');
      return Result.error(errMsg);
    } else if (r.statusCode > 400) {
      _log.severe('Unexpected error: ${r.body}.');
      return Result.error('Unexpected error');
    } else if (r.statusCode >= 300) {
      _log.severe('Unexpected status: ${r.statusCode} ${r.body}.');
      return Result.error('Unexpected status');
    }

    try {
      final jsonData = jsonDecode(r.body) as Map<String, dynamic>;
      final decoded = successDecoder(jsonData);
      return Result.ok(decoded);
    } catch (e, s) {
      _log.severe('Failed to parse response ${r.body}.', e, s);
      return Result.error('Failed to process WTM response.');
    }
  }

  String _parseErrMessage(String responseBody) {
    try {
      /**
       * Attempt to parse an error message from standard uuAppErrorMap, such as:
       * {
       *  "uuAppErrorMap": {
       *    "error-identifier": {
       *      "message": "some message",
       *      ...Other details...
       *    }
       *  }
       * }
       */

      final jsonData = jsonDecode(responseBody) as Map<String, dynamic>;
      final uuAppErrorMap = jsonData['uuAppErrorMap'] as Map<String, dynamic>?;

      if (uuAppErrorMap == null || uuAppErrorMap.isEmpty) {
        return responseBody;
      }

      final errorKey = uuAppErrorMap.keys.first;
      final errorData = uuAppErrorMap[errorKey] as Map<String, dynamic>?;
      final message = errorData?['message'] as String?;

      return message ?? responseBody;
    } catch (e, s) {
      _log.severe('Failed to parse response $responseBody.', e, s);
      return responseBody;
    }
  }
}
