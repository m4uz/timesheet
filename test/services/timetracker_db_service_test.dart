import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:test/test.dart';
import 'package:timesheet/models/result.dart';
import 'package:timesheet/models/timetracker_item.dart';
import 'package:timesheet/services/timetracker_db_service.dart';
import 'package:timesheet/services/timetracker_db_service_impl.dart';

void main() {
  late TimetrackerDBService db;

  setUp(() async {
    db = TimetrackerDBServiceImpl(inMemoryDatabasePath);
    await db.open();
    final deleteResult = await db.deleteAll();
    if (deleteResult case Error(:final message)) {
      fail('Failed to clear database in setUp: $message');
    }
  });

  tearDown(() async {
    await db.close();
  });

  test('Test DB insert', () async {
    final mockWtmId = '692f253a389b31000c5ce028';
    final mockItemIndex = 0;
    final mockFrom = DateTime.now();
    final mockTo = DateTime.now().add(Duration(hours: 3));
    final mockSubject = 'vdt:VMH-AU:BYD.SO84.AKE~UE';
    final mockCategory = 'PROJECT';
    final mockDescription = 'Work is the curse of the drinking classes.';
    final mockStatus = TimetrackerItemStatus.staged;
    final mockStatusMsg = 'Ready to be launched';

    var item = TimetrackerItem(
      wtmId: mockWtmId,
      itemIndex: mockItemIndex,
      from: mockFrom,
      to: mockTo,
      subject: mockSubject,
      category: mockCategory,
      description: mockDescription,
      status: mockStatus,
      statusMsg: mockStatusMsg,
    );

    var result = await db.insert(item);

    expect(result, isA<OK<TimetrackerItem>>());

    switch (result) {
      case OK():
        final insertedItem = result.value;

        expect(
          insertedItem.id,
          greaterThan(-1),
          reason: 'Inserted item should have a valid database ID',
        );
        expect(insertedItem.wtmId, equals(mockWtmId));
        expect(insertedItem.itemIndex, equals(mockItemIndex));
        expect(insertedItem.from, equals(mockFrom));
        expect(insertedItem.to, equals(mockTo));
        expect(insertedItem.subject, equals(mockSubject));
        expect(insertedItem.category, equals(mockCategory));
        expect(insertedItem.description, equals(mockDescription));
        expect(insertedItem.status, equals(mockStatus));
        expect(insertedItem.statusMsg, equals(mockStatusMsg));

        print('Item ID: ${insertedItem.id}');
        print('Inserted item: $insertedItem');

      case Error():
        fail('Expected OK but got Error: ${result.message}');
    }
  });

  test('Test DB getById', () async {
    // --------------------------------------------------
    // Get existing item
    // --------------------------------------------------

    final mockWtmId = '692f253a389b31000c5ce028';
    final mockItemIndex = 0;
    final mockFrom = DateTime.now();
    final mockTo = DateTime.now().add(Duration(hours: 3));
    final mockSubject = 'vdt:VMH-AU:BYD.SO84.AKE~UE';
    final mockCategory = 'PROJECT';
    final mockDescription = 'Work is the curse of the drinking classes.';
    final mockStatus = TimetrackerItemStatus.staged;
    final mockStatusMsg = 'Ready to be launched';

    var item = TimetrackerItem(
      wtmId: mockWtmId,
      itemIndex: mockItemIndex,
      from: mockFrom,
      to: mockTo,
      subject: mockSubject,
      category: mockCategory,
      description: mockDescription,
      status: mockStatus,
      statusMsg: mockStatusMsg,
    );

    var insertResult = await db.insert(item);
    int insertedId;
    switch (insertResult) {
      case OK():
        insertedId = insertResult.value.id;
      case Error():
        fail('Insert failed: ${insertResult.message}');
    }

    var getResult = await db.getById(insertedId);
    expect(getResult, isA<OK<TimetrackerItem>>());

    switch (getResult) {
      case OK():
        final retrievedItem = getResult.value;
        expect(retrievedItem.id, equals(insertedId));
        expect(retrievedItem.wtmId, equals(mockWtmId));
        expect(retrievedItem.itemIndex, equals(mockItemIndex));
        expect(retrievedItem.from, equals(mockFrom));
        expect(retrievedItem.to, equals(mockTo));
        expect(retrievedItem.subject, equals(mockSubject));
        expect(retrievedItem.category, equals(mockCategory));
        expect(retrievedItem.description, equals(mockDescription));
        expect(retrievedItem.status, equals(mockStatus));
        expect(retrievedItem.statusMsg, equals(mockStatusMsg));

        print('Retrieved item: $retrievedItem');

      case Error():
        fail('Expected OK but got Error: ${getResult.message}');
    }

    // --------------------------------------------------
    // Get non-existing item
    // --------------------------------------------------

    var errorResult = await db.getById(99999);
    expect(errorResult, isA<Error<TimetrackerItem>>());

    switch (errorResult) {
      case OK():
        fail('Expected Error but got OK');
      case Error():
        expect(errorResult.message, isNotEmpty);
        print('Error message for non-existent ID: ${errorResult.message}');
    }
  });

  test('Test DB getAll', () async {
    // --------------------------------------------------
    // Get all items - empty DB
    // --------------------------------------------------

    var getAllResult = await db.getAll();
    expect(getAllResult, isA<OK<List<TimetrackerItem>>>());

    switch (getAllResult) {
      case OK():
        expect(getAllResult.value.length, equals(0));
      case Error():
        fail('Expected OK but got Error: ${getAllResult.message}');
    }

    // --------------------------------------------------
    // Get all saved items
    // --------------------------------------------------

    final mockWtmId1 = '692f253a389b31000c5ce028';
    final mockWtmId2 = '692f253a389b31000c5ce029';
    final mockFrom = DateTime.now();
    final mockTo = DateTime.now().add(Duration(hours: 3));
    final mockSubject = 'vdt:VMH-AU:BYD.SO84.AKE~UE';
    final mockCategory = 'PROJECT';
    final mockDescription = 'Work is the curse of the drinking classes.';
    final mockStatus = TimetrackerItemStatus.staged;
    final mockStatusMsg = 'Ready to be launched';

    var item1 = TimetrackerItem(
      wtmId: mockWtmId1,
      itemIndex: 0,
      from: mockFrom,
      to: mockTo,
      subject: mockSubject,
      category: mockCategory,
      description: mockDescription,
      status: mockStatus,
      statusMsg: mockStatusMsg,
    );

    var item2 = TimetrackerItem(
      wtmId: mockWtmId2,
      itemIndex: 1,
      from: mockFrom.add(Duration(hours: 3)),
      to: mockTo.add(Duration(hours: 3)),
      subject: mockSubject,
      category: mockCategory,
      description: mockDescription,
      status: TimetrackerItemStatus.saved,
      statusMsg: mockStatusMsg,
    );

    var insertResult1 = await db.insert(item1);
    var insertResult2 = await db.insert(item2);

    expect(insertResult1, isA<OK<TimetrackerItem>>());
    expect(insertResult2, isA<OK<TimetrackerItem>>());

    var getAllResult2 = await db.getAll();
    expect(getAllResult2, isA<OK<List<TimetrackerItem>>>());

    switch (getAllResult2) {
      case OK():
        expect(getAllResult2.value.length, equals(2));
      case Error():
        fail('Expected OK but got Error: ${getAllResult2.message}');
    }
  });

  test('Test DB insertBatch', () async {
    // --------------------------------------------------
    // Insert batch of items
    // --------------------------------------------------

    final mockWtmId1 = '692f253a389b31000c5ce028';
    final mockWtmId2 = '692f253a389b31000c5ce029';
    final mockWtmId3 = '692f253a389b31000c5ce030';
    final mockFrom = DateTime.now();
    final mockTo = DateTime.now().add(Duration(hours: 3));
    final mockSubject = 'vdt:VMH-AU:BYD.SO84.AKE~UE';
    final mockCategory = 'PROJECT';
    final mockDescription = 'Work is the curse of the drinking classes.';
    final mockStatus = TimetrackerItemStatus.staged;
    final mockStatusMsg = 'Ready to be launched';

    final items = [
      TimetrackerItem(
        wtmId: mockWtmId1,
        itemIndex: 0,
        from: mockFrom,
        to: mockTo,
        subject: mockSubject,
        category: mockCategory,
        description: mockDescription,
        status: mockStatus,
        statusMsg: mockStatusMsg,
      ),
      TimetrackerItem(
        wtmId: mockWtmId2,
        itemIndex: 1,
        from: mockFrom.add(Duration(hours: 3)),
        to: mockTo.add(Duration(hours: 3)),
        subject: mockSubject,
        category: mockCategory,
        description: mockDescription,
        status: TimetrackerItemStatus.saved,
        statusMsg: mockStatusMsg,
      ),
      TimetrackerItem(
        wtmId: mockWtmId3,
        itemIndex: 2,
        from: mockFrom.add(Duration(hours: 6)),
        to: mockTo.add(Duration(hours: 6)),
        subject: mockSubject,
        category: mockCategory,
        description: mockDescription,
        status: TimetrackerItemStatus.staged,
        statusMsg: mockStatusMsg,
      ),
    ];

    final insertBatchResult = await db.insertBatch(items);
    expect(insertBatchResult, isA<OK<List<TimetrackerItem>>>());

    switch (insertBatchResult) {
      case OK():
        final insertedItems = insertBatchResult.value;
        expect(insertedItems.length, equals(3));

        for (int i = 0; i < insertedItems.length; i++) {
          final insertedItem = insertedItems[i];
          final originalItem = items[i];

          expect(
            insertedItem.id,
            greaterThan(-1),
            reason: 'Inserted item should have a valid database ID',
          );
          expect(insertedItem.wtmId, equals(originalItem.wtmId));
          expect(insertedItem.itemIndex, equals(originalItem.itemIndex));
          expect(insertedItem.from, equals(originalItem.from));
          expect(insertedItem.to, equals(originalItem.to));
          expect(insertedItem.subject, equals(originalItem.subject));
          expect(insertedItem.category, equals(originalItem.category));
          expect(insertedItem.description, equals(originalItem.description));
          expect(insertedItem.status, equals(originalItem.status));
          expect(insertedItem.statusMsg, equals(originalItem.statusMsg));
        }

        final getAllResult = await db.getAll();
        switch (getAllResult) {
          case OK():
            expect(getAllResult.value.length, equals(3));
          case Error():
            fail('Failed to retrieve all items: ${getAllResult.message}');
        }

        print('Inserted ${insertedItems.length} items in batch');

      case Error():
        fail('Expected OK but got Error: ${insertBatchResult.message}');
    }

    // --------------------------------------------------
    // Insert empty batch
    // --------------------------------------------------

    final emptyBatchResult = await db.insertBatch([]);
    expect(emptyBatchResult, isA<OK<List<TimetrackerItem>>>());

    switch (emptyBatchResult) {
      case OK():
        expect(emptyBatchResult.value.length, equals(0));
        print('Empty batch insert returned empty list');
      case Error():
        fail('Expected OK but got Error: ${emptyBatchResult.message}');
    }
  });

  test('Test DB updateBatch', () async {
    // --------------------------------------------------
    // Update batch of items
    // --------------------------------------------------

    final mockWtmId1 = '692f253a389b31000c5ce028';
    final mockWtmId2 = '692f253a389b31000c5ce029';
    final mockWtmId3 = '692f253a389b31000c5ce030';
    final mockFrom = DateTime.now();
    final mockTo = DateTime.now().add(Duration(hours: 3));
    final mockSubject = 'vdt:VMH-AU:BYD.SO84.AKE~UE';
    final mockCategory = 'PROJECT';
    final mockDescription = 'Work is the curse of the drinking classes.';
    final mockStatus = TimetrackerItemStatus.staged;
    final mockStatusMsg = 'Ready to be launched';

    final items = [
      TimetrackerItem(
        wtmId: mockWtmId1,
        itemIndex: 0,
        from: mockFrom,
        to: mockTo,
        subject: mockSubject,
        category: mockCategory,
        description: mockDescription,
        status: mockStatus,
        statusMsg: mockStatusMsg,
      ),
      TimetrackerItem(
        wtmId: mockWtmId2,
        itemIndex: 1,
        from: mockFrom.add(Duration(hours: 3)),
        to: mockTo.add(Duration(hours: 3)),
        subject: mockSubject,
        category: mockCategory,
        description: mockDescription,
        status: TimetrackerItemStatus.saved,
        statusMsg: mockStatusMsg,
      ),
      TimetrackerItem(
        wtmId: mockWtmId3,
        itemIndex: 2,
        from: mockFrom.add(Duration(hours: 6)),
        to: mockTo.add(Duration(hours: 6)),
        subject: mockSubject,
        category: mockCategory,
        description: mockDescription,
        status: TimetrackerItemStatus.staged,
        statusMsg: mockStatusMsg,
      ),
    ];

    final insertBatchResult = await db.insertBatch(items);
    expect(insertBatchResult, isA<OK<List<TimetrackerItem>>>());

    List<TimetrackerItem> insertedItems;
    switch (insertBatchResult) {
      case OK():
        insertedItems = insertBatchResult.value;
      case Error():
        fail('Insert failed: ${insertBatchResult.message}');
    }

    final updatedTo1 = mockTo.add(Duration(hours: 1));
    final updatedTo2 = mockTo.add(Duration(hours: 4));
    final updatedTo3 = mockTo.add(Duration(hours: 7));
    final updatedSubject = 'Updated subject';
    final updatedDescription = 'Updated description';
    final updatedStatus = TimetrackerItemStatus.saved;
    final updatedStatusMsg = 'Updated status message';

    final itemsToUpdate = [
      insertedItems[0].copyWith(
        to: updatedTo1,
        subject: updatedSubject,
        description: updatedDescription,
        status: updatedStatus,
        statusMsg: updatedStatusMsg,
      ),
      insertedItems[1].copyWith(
        to: updatedTo2,
        subject: updatedSubject,
        description: updatedDescription,
        status: updatedStatus,
        statusMsg: updatedStatusMsg,
      ),
      insertedItems[2].copyWith(
        to: updatedTo3,
        subject: updatedSubject,
        description: updatedDescription,
        status: updatedStatus,
        statusMsg: updatedStatusMsg,
      ),
    ];

    final updateBatchResult = await db.updateBatch(itemsToUpdate);
    expect(updateBatchResult, isA<OK<List<TimetrackerItem>>>());

    switch (updateBatchResult) {
      case OK():
        final updatedItems = updateBatchResult.value;
        expect(updatedItems.length, equals(3));

        for (int i = 0; i < updatedItems.length; i++) {
          final updatedItem = updatedItems[i];
          final expectedItem = itemsToUpdate[i];

          expect(updatedItem.id, equals(expectedItem.id));
          expect(updatedItem.wtmId, equals(expectedItem.wtmId));
          expect(updatedItem.itemIndex, equals(expectedItem.itemIndex));
          expect(updatedItem.from, equals(expectedItem.from));
          expect(updatedItem.to, equals(expectedItem.to));
          expect(updatedItem.subject, equals(expectedItem.subject));
          expect(updatedItem.category, equals(expectedItem.category));
          expect(updatedItem.description, equals(expectedItem.description));
          expect(updatedItem.status, equals(expectedItem.status));
          expect(updatedItem.statusMsg, equals(expectedItem.statusMsg));
        }

        final getAllResult = await db.getAll();
        switch (getAllResult) {
          case OK():
            final allItems = getAllResult.value;
            expect(allItems.length, equals(3));
            for (int i = 0; i < allItems.length; i++) {
              final item = allItems[i];
              final expectedItem = itemsToUpdate[i];
              expect(item.id, equals(expectedItem.id));
              expect(item.wtmId, equals(expectedItem.wtmId));
              expect(item.itemIndex, equals(expectedItem.itemIndex));
              expect(item.from, equals(expectedItem.from));
              expect(item.to, equals(expectedItem.to));
              expect(item.subject, equals(expectedItem.subject));
              expect(item.category, equals(expectedItem.category));
              expect(item.description, equals(expectedItem.description));
              expect(item.status, equals(expectedItem.status));
              expect(item.statusMsg, equals(expectedItem.statusMsg));
            }
          case Error():
            fail('Failed to retrieve all items: ${getAllResult.message}');
        }

        print('Updated ${updatedItems.length} items in batch');

      case Error():
        fail('Expected OK but got Error: ${updateBatchResult.message}');
    }

    // --------------------------------------------------
    // Update empty batch
    // --------------------------------------------------

    final emptyBatchResult = await db.updateBatch([]);
    expect(emptyBatchResult, isA<OK<List<TimetrackerItem>>>());

    switch (emptyBatchResult) {
      case OK():
        expect(emptyBatchResult.value.length, equals(0));
        print('Empty batch update returned empty list');
      case Error():
        fail('Expected OK but got Error: ${emptyBatchResult.message}');
    }

    // --------------------------------------------------
    // Update batch with invalid ID
    // --------------------------------------------------

    final invalidItem = TimetrackerItem(
      id: -1,
      wtmId: mockWtmId1,
      itemIndex: 0,
      from: mockFrom,
      to: mockTo,
      subject: mockSubject,
      category: mockCategory,
      description: mockDescription,
      status: mockStatus,
      statusMsg: mockStatusMsg,
    );

    final invalidBatchResult = await db.updateBatch([invalidItem]);
    expect(invalidBatchResult, isA<Error<List<TimetrackerItem>>>());

    switch (invalidBatchResult) {
      case OK():
        fail('Expected Error but got OK');
      case Error():
        expect(invalidBatchResult.message, isNotEmpty);
        print('Error message for invalid ID: ${invalidBatchResult.message}');
    }
  });

  test('Test DB update', () async {
    // --------------------------------------------------
    // Update existing item
    // --------------------------------------------------

    final mockWtmId = '692f253a389b31000c5ce028';
    final mockItemIndex = 0;
    final mockFrom = DateTime.now();
    final mockTo = DateTime.now().add(Duration(hours: 3));
    final mockSubject = 'vdt:VMH-AU:BYD.SO84.AKE~UE';
    final mockCategory = 'PROJECT';
    final mockDescription = 'Work is the curse of the drinking classes.';
    final mockStatus = TimetrackerItemStatus.staged;
    final mockStatusMsg = 'Ready to be launched';

    var item = TimetrackerItem(
      wtmId: mockWtmId,
      itemIndex: mockItemIndex,
      from: mockFrom,
      to: mockTo,
      subject: mockSubject,
      category: mockCategory,
      description: mockDescription,
      status: mockStatus,
      statusMsg: mockStatusMsg,
    );

    var insertResult = await db.insert(item);
    int insertedId;
    switch (insertResult) {
      case OK():
        insertedId = insertResult.value.id;
      case Error():
        fail('Insert failed: ${insertResult.message}');
    }

    final updatedTo = mockTo.add(Duration(hours: 1));
    final updatedSubject = 'Updated subject';
    final updatedDescription = 'Updated description';
    final updatedStatus = TimetrackerItemStatus.saved;
    final updatedStatusMsg = 'Updated status message';

    item = insertResult.value;
    item.to = updatedTo;
    item.subject = updatedSubject;
    item.description = updatedDescription;
    item.status = updatedStatus;
    item.statusMsg = updatedStatusMsg;

    var updateResult = await db.update(item);
    expect(updateResult, isA<OK<TimetrackerItem>>());

    switch (updateResult) {
      case OK():
        final updatedItem = updateResult.value;
        expect(updatedItem.id, equals(insertedId));
        expect(updatedItem.wtmId, equals(mockWtmId));
        expect(updatedItem.itemIndex, equals(mockItemIndex));
        expect(updatedItem.from, equals(mockFrom));
        expect(updatedItem.to, equals(updatedTo));
        expect(updatedItem.subject, equals(updatedSubject));
        expect(updatedItem.category, equals(mockCategory));
        expect(updatedItem.description, equals(updatedDescription));
        expect(updatedItem.status, equals(updatedStatus));
        expect(updatedItem.statusMsg, equals(updatedStatusMsg));

        print('Updated item: $updatedItem');

      case Error():
        fail('Expected OK but got Error: ${updateResult.message}');
    }

    // --------------------------------------------------
    // Update non-existing item
    // --------------------------------------------------

    var nonExistentItem = TimetrackerItem(
      id: 99999,
      wtmId: mockWtmId,
      itemIndex: mockItemIndex,
      from: mockFrom,
      to: mockTo,
      subject: mockSubject,
      category: mockCategory,
      description: mockDescription,
      status: mockStatus,
      statusMsg: mockStatusMsg,
    );

    var errorResult = await db.update(nonExistentItem);
    expect(errorResult, isA<Error<TimetrackerItem>>());

    switch (errorResult) {
      case OK():
        fail('Expected Error but got OK');
      case Error():
        expect(errorResult.message, isNotEmpty);
        print('Error message for non-existent item: ${errorResult.message}');
    }
  });

  test('Test DB deleteById', () async {
    // --------------------------------------------------
    // Delete existing item
    // --------------------------------------------------

    final mockWtmId = '692f253a389b31000c5ce028';
    final mockItemIndex = 0;
    final mockFrom = DateTime.now();
    final mockTo = DateTime.now().add(Duration(hours: 3));
    final mockSubject = 'vdt:VMH-AU:BYD.SO84.AKE~UE';
    final mockCategory = 'PROJECT';
    final mockDescription = 'Work is the curse of the drinking classes.';
    final mockStatus = TimetrackerItemStatus.staged;
    final mockStatusMsg = 'Ready to be launched';

    var item = TimetrackerItem(
      wtmId: mockWtmId,
      itemIndex: mockItemIndex,
      from: mockFrom,
      to: mockTo,
      subject: mockSubject,
      category: mockCategory,
      description: mockDescription,
      status: mockStatus,
      statusMsg: mockStatusMsg,
    );

    var insertResult = await db.insert(item);
    int insertedId;
    switch (insertResult) {
      case OK():
        insertedId = insertResult.value.id;
      case Error():
        fail('Insert failed: ${insertResult.message}');
    }

    var deleteResult = await db.deleteById(insertedId);
    expect(deleteResult, isA<OK<int>>());

    switch (deleteResult) {
      case OK():
        expect(deleteResult.value, equals(1));
      case Error():
        fail('Expected OK but got Error: ${deleteResult.message}');
    }

    var getResultAfter = await db.getById(insertedId);
    expect(getResultAfter, isA<Error<TimetrackerItem>>());

    print('Deleted item with id: $insertedId');

    // --------------------------------------------------
    // Delete non-existing item
    // --------------------------------------------------

    var deleteResultNonExistent = await db.deleteById(99999);
    expect(deleteResultNonExistent, isA<Error<int>>());

    switch (deleteResultNonExistent) {
      case OK():
        fail('Expected Error but got OK');
      case Error():
        expect(deleteResultNonExistent.message, isNotEmpty);
        print(
          'Error message for non-existent item: ${deleteResultNonExistent.message}',
        );
    }
  });
}
