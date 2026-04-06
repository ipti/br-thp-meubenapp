import 'package:br_thp_meubenapp/app/core/storage/local/local_database.dart';
import 'package:br_thp_meubenapp/app/feature/sync/data/models/sync_queue_item_model.dart';
import 'package:sembast/sembast.dart';

class SyncQueueLocalDatasource {
  SyncQueueLocalDatasource({LocalDatabase? localDatabase})
    : _localDatabase = localDatabase ?? LocalDatabase.instance;

  final LocalDatabase _localDatabase;
  final StoreRef<int, Map<String, Object?>> _store = intMapStoreFactory.store(
    'sync_queue',
  );

  Future<int> enqueue({
    required SyncQueueType type,
    required Map<String, Object?> payload,
    required String description,
    required String createdBy,
  }) async {
    final db = await _localDatabase.database;
    return _store.add(db, {
      'type': SyncQueueItemModel.serializeType(type),
      'status': SyncQueueItemModel.serializeStatus(SyncQueueStatus.pending),
      'payload': payload,
      'description': description,
      'createdBy': createdBy,
      'createdAt': DateTime.now().toIso8601String(),
      'processedAt': null,
      'errorMessage': null,
      'retryCount': 0,
    });
  }

  Future<List<SyncQueueItemModel>> getAll() async {
    final db = await _localDatabase.database;
    final snapshots = await _store.find(
      db,
      finder: Finder(sortOrders: [SortOrder('createdAt')]),
    );
    return snapshots.map(_fromSnapshot).toList();
  }

  Future<List<SyncQueueItemModel>> getPendingAndFailed() async {
    final db = await _localDatabase.database;
    final snapshots = await _store.find(
      db,
      finder: Finder(
        filter: Filter.or([
          Filter.equals(
            'status',
            SyncQueueItemModel.serializeStatus(SyncQueueStatus.pending),
          ),
          Filter.equals(
            'status',
            SyncQueueItemModel.serializeStatus(SyncQueueStatus.failed),
          ),
        ]),
        sortOrders: [SortOrder('createdAt')],
      ),
    );
    return snapshots.map(_fromSnapshot).toList();
  }

  Future<void> markAsProcessing(int localId) {
    return _updateStatus(
      localId,
      status: SyncQueueStatus.processing,
      errorMessage: null,
    );
  }

  Future<void> markAsSynced(int localId) {
    return _updateStatus(
      localId,
      status: SyncQueueStatus.synced,
      processedAt: DateTime.now(),
      errorMessage: null,
    );
  }

  Future<void> markAsFailed(int localId, {required String errorMessage}) async {
    final db = await _localDatabase.database;
    final current = await _store.record(localId).get(db);
    final currentRetry =
        int.tryParse(current?['retryCount']?.toString() ?? '0') ?? 0;

    await _store.record(localId).update(db, {
      'status': SyncQueueItemModel.serializeStatus(SyncQueueStatus.failed),
      'retryCount': currentRetry + 1,
      'errorMessage': errorMessage,
    });
  }

  Future<void> removePendingByTypeAndMeeting({
    required SyncQueueType type,
    required int meetingId,
  }) async {
    final db = await _localDatabase.database;
    final snapshots = await _store.find(
      db,
      finder: Finder(
        filter: Filter.and([
          Filter.equals('type', SyncQueueItemModel.serializeType(type)),
          Filter.equals(
            'status',
            SyncQueueItemModel.serializeStatus(SyncQueueStatus.pending),
          ),
        ]),
      ),
    );

    for (final snapshot in snapshots) {
      final payload = snapshot.value['payload'];
      final meetingInPayload = int.tryParse(
        (payload is Map ? payload['meetingId'] : null)?.toString() ?? '',
      );
      if (meetingInPayload == meetingId) {
        await _store.record(snapshot.key).delete(db);
      }
    }
  }

  Future<void> _updateStatus(
    int localId, {
    required SyncQueueStatus status,
    DateTime? processedAt,
    String? errorMessage,
  }) async {
    final db = await _localDatabase.database;
    await _store.record(localId).update(db, {
      'status': SyncQueueItemModel.serializeStatus(status),
      'processedAt': processedAt?.toIso8601String(),
      'errorMessage': errorMessage,
    });
  }

  SyncQueueItemModel _fromSnapshot(
    RecordSnapshot<int, Map<String, Object?>> snapshot,
  ) {
    final map = snapshot.value;
    final payloadRaw = map['payload'];
    final payload = <String, Object?>{};
    if (payloadRaw is Map) {
      for (final entry in payloadRaw.entries) {
        payload[entry.key.toString()] = entry.value;
      }
    }

    return SyncQueueItemModel(
      localId: snapshot.key,
      type: SyncQueueItemModel.parseType(map['type']?.toString() ?? ''),
      status: SyncQueueItemModel.parseStatus(map['status']?.toString() ?? ''),
      payload: payload,
      description: map['description']?.toString() ?? '',
      createdBy: map['createdBy']?.toString() ?? 'usuario',
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      processedAt: DateTime.tryParse(map['processedAt']?.toString() ?? ''),
      errorMessage: map['errorMessage']?.toString(),
      retryCount: int.tryParse(map['retryCount']?.toString() ?? '') ?? 0,
    );
  }
}
