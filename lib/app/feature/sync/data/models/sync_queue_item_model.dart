enum SyncQueueType { fouls, archives }

enum SyncQueueStatus { pending, processing, synced, failed }

class SyncQueueItemModel {
  const SyncQueueItemModel({
    required this.localId,
    required this.type,
    required this.status,
    required this.payload,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    this.processedAt,
    this.errorMessage,
    this.retryCount = 0,
  });

  final int localId;
  final SyncQueueType type;
  final SyncQueueStatus status;
  final Map<String, Object?> payload;
  final String description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? errorMessage;
  final int retryCount;

  SyncQueueItemModel copyWith({
    int? localId,
    SyncQueueType? type,
    SyncQueueStatus? status,
    Map<String, Object?>? payload,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    DateTime? processedAt,
    String? errorMessage,
    int? retryCount,
  }) {
    return SyncQueueItemModel(
      localId: localId ?? this.localId,
      type: type ?? this.type,
      status: status ?? this.status,
      payload: payload ?? this.payload,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  static SyncQueueType parseType(String value) {
    switch (value) {
      case 'FOULS_SYNC':
        return SyncQueueType.fouls;
      case 'ARCHIVES_SYNC':
        return SyncQueueType.archives;
      default:
        return SyncQueueType.fouls;
    }
  }

  static String serializeType(SyncQueueType type) {
    switch (type) {
      case SyncQueueType.fouls:
        return 'FOULS_SYNC';
      case SyncQueueType.archives:
        return 'ARCHIVES_SYNC';
    }
  }

  static SyncQueueStatus parseStatus(String value) {
    switch (value) {
      case 'PENDING':
        return SyncQueueStatus.pending;
      case 'PROCESSING':
        return SyncQueueStatus.processing;
      case 'SYNCED':
        return SyncQueueStatus.synced;
      case 'FAILED':
        return SyncQueueStatus.failed;
      default:
        return SyncQueueStatus.pending;
    }
  }

  static String serializeStatus(SyncQueueStatus status) {
    switch (status) {
      case SyncQueueStatus.pending:
        return 'PENDING';
      case SyncQueueStatus.processing:
        return 'PROCESSING';
      case SyncQueueStatus.synced:
        return 'SYNCED';
      case SyncQueueStatus.failed:
        return 'FAILED';
    }
  }
}

class SyncExecutionResult {
  const SyncExecutionResult({
    required this.successCount,
    required this.failedCount,
    required this.remainingCount,
    required this.requiresLogin,
    this.lastError,
  });

  final int successCount;
  final int failedCount;
  final int remainingCount;
  final bool requiresLogin;
  final String? lastError;
}
