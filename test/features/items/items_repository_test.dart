// Unit tests for ItemsRepository — verifies individual item identity creation,
// potential match candidate scanning without auto-merging, and confirmation/rejection workflows.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:find_my_stuff_ai/core/database/app_database.dart';
import 'package:find_my_stuff_ai/core/database/database_migrations.dart';
import 'package:find_my_stuff_ai/core/database/schema_constants.dart';
import 'package:find_my_stuff_ai/features/ai/domain/detected_object.dart';
import 'package:find_my_stuff_ai/features/items/data/items_repository.dart';
import 'package:find_my_stuff_ai/features/items/domain/item_identity.dart';
import 'package:find_my_stuff_ai/features/items/domain/item_observation.dart';
import 'package:find_my_stuff_ai/features/memories/data/memory_repository.dart';
import 'package:find_my_stuff_ai/features/memories/domain/memory_item.dart';

void main() {
  late ItemsRepository itemsRepository;
  late MemoryRepository memoryRepository;
  late Database testDb;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    testDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: SchemaConstants.databaseVersion,
        onConfigure: DatabaseMigrations.onConfigure,
        onCreate: DatabaseMigrations.onCreate,
        onUpgrade: DatabaseMigrations.onUpgrade,
      ),
    );
    AppDatabase.instance.setDatabaseForTesting(testDb);
    itemsRepository = ItemsRepository();
    memoryRepository = MemoryRepository();
  });

  tearDown(() async {
    await testDb.close();
  });

  group('ItemsRepository', () {
    test('creates named item with reference photo and retrieves it', () async {
      final now = DateTime.now();
      final item = ItemIdentity(
        id: 'item-charger-1',
        name: 'My Anker 65W Fast Charger',
        category: 'Charger',
        description: 'Black dual-port adapter with braided cable',
        referencePhotoPath: '/storage/ref_charger.jpg',
        createdAt: now,
      );

      await itemsRepository.saveItem(item);

      final retrieved = await itemsRepository.getItemById('item-charger-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('My Anker 65W Fast Charger'));
      expect(retrieved.referencePhotoPath, equals('/storage/ref_charger.jpg'));
      expect(retrieved.category, equals('Charger'));
      expect(retrieved.status, equals(ItemStatus.lastObserved));
    });

    test('scans for candidate observations without automatically confirming or merging', () async {
      final now = DateTime.now();

      // Create an item
      final item = ItemIdentity(
        id: 'item-keys-1',
        name: 'My Apartment Keys',
        category: 'Keys',
        createdAt: now,
      );
      await itemsRepository.saveItem(item);

      // Create a memory with a detected "Keys" object
      final memory = MemoryItem(
        id: 'mem-keys-sighting',
        imagePath: '/photos/hallway.jpg',
        thumbnailPath: '/photos/hallway_thumb.jpg',
        capturedAt: now.subtract(const Duration(hours: 3)),
        createdAt: now,
        locationLabel: 'Hallway Table',
        indexingStatus: MemoryIndexingStatus.completed,
        detectedObjects: const [
          DetectedObject(
            id: 'obj-keys-1',
            memoryId: 'mem-keys-sighting',
            label: 'Keys',
            confidence: 0.94,
          ),
        ],
      );
      await memoryRepository.insertMemory(memory);

      // Scan for potential matches
      final candidates = await itemsRepository.scanForPotentialMatches('item-keys-1');
      expect(candidates.length, equals(1));
      // Must be pending user review!
      expect(candidates.first.userConfirmation, equals(ConfirmationStatus.pending));
      expect(candidates.first.locationLabel, equals('Hallway Table'));

      // Confirm match
      await itemsRepository.updateObservationConfirmation(
        candidates.first.id,
        ConfirmationStatus.confirmed,
      );

      final updatedItem = await itemsRepository.getItemById('item-keys-1');
      expect(updatedItem!.status, equals(ItemStatus.foundAndConfirmed));
      expect(updatedItem.lastObservedLocation, equals('Hallway Table'));
      expect(updatedItem.lastObservedMemoryId, equals('mem-keys-sighting'));
    });

    test('rejecting an observation does not set it as the confirmed location', () async {
      final now = DateTime.now();
      final item = ItemIdentity(
        id: 'item-wallet-1',
        name: 'My Leather Wallet',
        category: 'Wallet',
        createdAt: now,
      );
      await itemsRepository.saveItem(item);

      final memory = MemoryItem(
        id: 'mem-false-wallet',
        imagePath: '/photos/kitchen.jpg',
        thumbnailPath: '/photos/kitchen_thumb.jpg',
        capturedAt: now,
        createdAt: now,
        locationLabel: 'Kitchen Counter',
        indexingStatus: MemoryIndexingStatus.completed,
        detectedObjects: const [
          DetectedObject(
            id: 'obj-w-1',
            memoryId: 'mem-false-wallet',
            label: 'Wallet',
            confidence: 0.72,
          ),
        ],
      );
      await memoryRepository.insertMemory(memory);

      final candidates = await itemsRepository.scanForPotentialMatches('item-wallet-1');
      expect(candidates.isNotEmpty, isTrue);

      // Reject the match
      await itemsRepository.updateObservationConfirmation(
        candidates.first.id,
        ConfirmationStatus.rejected,
      );

      final updatedItem = await itemsRepository.getItemById('item-wallet-1');
      // Should not be marked as found in kitchen
      expect(updatedItem!.lastObservedLocation, isNull);
    });

    test('manual location correction overrides photo location label in observation and item identity', () async {
      final now = DateTime.now();
      final item = ItemIdentity(
        id: 'item-charger-2',
        name: 'MacBook Charger',
        category: 'Charger',
        createdAt: now,
      );
      await itemsRepository.saveItem(item);

      final memory = MemoryItem(
        id: 'mem-desk-photo',
        imagePath: '/photos/desk.jpg',
        thumbnailPath: '/photos/desk_thumb.jpg',
        capturedAt: now,
        createdAt: now,
        locationLabel: 'Bedroom Room',
        indexingStatus: MemoryIndexingStatus.completed,
        detectedObjects: const [
          DetectedObject(
            id: 'obj-charger-99',
            memoryId: 'mem-desk-photo',
            label: 'Charger',
            confidence: 0.88,
          ),
        ],
      );
      await memoryRepository.insertMemory(memory);

      final candidates = await itemsRepository.scanForPotentialMatches('item-charger-2');
      final obs = candidates.first;

      // Confirm observation
      await itemsRepository.updateObservationConfirmation(obs.id, ConfirmationStatus.confirmed);

      // Verify confirmed location initially uses photo label
      var itemNow = await itemsRepository.getItemById('item-charger-2');
      expect(itemNow!.lastObservedLocation, equals('Bedroom Room'));

      // Manually correct location to specific spot: "Study Desk Drawer"
      await itemsRepository.updateObservationLocation(obs.id, 'Study Desk Drawer');

      final observations = await itemsRepository.getObservationsForItem('item-charger-2');
      expect(observations.first.displayLocation, equals('Study Desk Drawer'));
      expect(observations.first.hasManualCorrection, isTrue);

      itemNow = await itemsRepository.getItemById('item-charger-2');
      expect(itemNow!.lastObservedLocation, equals('Study Desk Drawer'));
    });
  });
}
